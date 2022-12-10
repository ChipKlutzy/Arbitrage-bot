//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./FlashLoanReceiverBase.sol";

import "@uniswap/contracts/interfaces/IERC20.sol";
import "@uniswap/contracts/interfaces/IUniswapV2Router02.sol";

contract Arbitragebot is FlashLoanReceiverBase {

    address WETH;
    address payable owner;

    // QuickSwap (Router02) Polygon
    IUniswapV2Router02 private uniRouter;
    // SushiSwap (Router02) Polygon
    IUniswapV2Router02 private sushiRouter;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an Owner !!!");
        _;
    }

    constructor(address _WETH, address _provider, address _uniRouter, address _sushiRouter) FlashLoanReceiverBase(_provider) {
        WETH = _WETH;
        uniRouter = IUniswapV2Router02(_uniRouter);
        sushiRouter = IUniswapV2Router02(_sushiRouter);
        owner = payable(msg.sender);
    }

    function executeOperation(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums, address initiator, bytes calldata params) external returns (bool) {
        //require(initiator == owner, "Execute Operation Not an Owner !!!");
        // decoding params
        (uint8 direc, address[] memory arbPath, uint amount) = abi.decode(params, (uint8, address[], uint));
        // making arbitrage using Flashloaned Amounts
        arb(direc, arbPath, amount);
        // Repaying flashloans 
        for(uint i = 0; i < assets.length; i++) {
            uint amountOwed = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwed);
        }
        
        return true;
    } 

    function swap(IUniswapV2Router02 _router, address _tokenIn, address _tokenOut, uint _amountIn) internal returns (bool) {
        // approving router contract before trade
        require(IERC20(_tokenIn).approve(address(_router), _amountIn), "Router01 approval failed !!!");

        address[] memory path;

        if((_tokenIn == WETH) || (_tokenOut == WETH)) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH; // gives best possible trade when using WETH
            path[2] = _tokenOut;
        }
        
        uint[] memory amountOutMin = _router.getAmountsOut(_amountIn, path); // less than this min reverts trade
        uint len = amountOutMin.length;
        uint deadline = block.timestamp + 30 seconds; 
        _router.swapExactTokensForTokens(_amountIn, amountOutMin[len - 1], path, address(this), deadline);

        return true;
    }

    function arb(uint8 _direc, address[] memory _arbPath, uint _amount) internal {
        // from DEX & to DEX  
        (IUniswapV2Router02 DEX1, IUniswapV2Router02 DEX2) = _direc == 0 ? (uniRouter, sushiRouter) : (sushiRouter, uniRouter);
        
        // DEX1 swap 
        bool s1 = swap(DEX1, _arbPath[0], _arbPath[1], _amount);
        // DEX2 swap
        uint bal = IERC20(_arbPath[1]).balanceOf(address(this));
        bool s2 = swap(DEX2, _arbPath[1], _arbPath[0], bal);
        // at this point we have completed arbitrage trade

        require((s1 && s2), "Swapping Error !!!");

        uint finalBal = IERC20(_arbPath[0]).balanceOf(address(this));
        uint profit = calProfits(finalBal, _amount); // lets calculate arbitrage profit

        require(profit > 0, "No Profits in arbitrage strategy");

    }

    function calProfits(uint bal, uint amount) private pure returns (uint) {
        return bal - amount;
    }

    // this is the function a user needs to call to initiate a flashLoan
    function flashloan(address DebtAsset, uint256 FlashloanAmount, uint8 direc, address[] memory arbPath, uint amountIn) public onlyOwner {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = DebtAsset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = FlashloanAmount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);

        bytes memory params = abi.encode(direc, arbPath, amountIn);
        uint16 referalCode = 0;

        LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referalCode);
    }

    function withDraw(address asset) external onlyOwner returns (bool) {
        uint amount = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transfer(owner, amount);
        return true;
    }
}