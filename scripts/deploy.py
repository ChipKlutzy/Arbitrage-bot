from brownie import Arbitragebot, network, accounts, config, chain, testToken, interface

def get_account():

    LIVE_NETWORKS = ["mainnet", "polygon-main"]

    if(network.show_active() in LIVE_NETWORKS):
        sender = accounts.add(
            config["wallets"][network.show_active()]["private-key"]
        )
    else:
        sender = accounts[-1]

    return sender


def main():

    sender = get_account()

    print(sender)

    print(f"Deploying the required contracts on {network.show_active()}..............\n")

    AB = Arbitragebot.deploy(
            config["networks"][network.show_active()]["weth_address"],
            config["networks"][network.show_active()]["address_provider"],
            config["networks"][network.show_active()]["uni_router"],
            config["networks"][network.show_active()]["sushi_router"],
            {'from': sender}
    )

    WETH = interface.IERC20(config["networks"][network.show_active()]["weth_address"])

    WETH.transfer(AB.address, 1e18, {'from': sender})

    arbPath = [
        config["networks"][network.show_active()]["weth_address"],
        config["networks"][network.show_active()]["usdc_address"]
    ]

    AB.flashloan(config["networks"][network.show_active()]["weth_address"], 1e18, 1, arbPath, 1e18)

    print(WETH.balanceOf(AB.address))







    







