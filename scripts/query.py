import requests, json, time

def main():
    # These URL are Matic Network Subgraphs of respective Exchanges
    uni_url = "https://api.thegraph.com/subgraphs/name/impermax-finance/impermax-x-uniswap-v2-polygon-v3"
    sushi_url = "https://api.thegraph.com/subgraphs/name/sushiswap/matic-exchange"

    Unibody = """
    {
    pair(
        id: "0x853Ee4b2A13f8a742d64C8F088bE7bA2131f670d"
    ) {
        id 
        token0 {
        symbol
        }
        token1 {
        symbol
        }
        token0Price
        token1Price
    }
    }
    """

    Sushibody = """
    {
    pair(
        id: "0x34965ba0ac2451a34a0471f04cca3f990b8dea27"
    ) {
        id 
        token0 {
        symbol
        }
        token1 {
        symbol
        }
        token0Price
        token1Price
    }
    }
    """

    c = 0
    while(c <=100):

        print(f"\niter : {c}\n")

        uni_response = requests.post(url=uni_url, json={"query": Unibody})
        sushi_response = requests.post(url=sushi_url, json={"query": Sushibody})
        
        if(uni_response.status_code == 200):
            Json_Response_uni = json.loads(uni_response.content)
            uni_eth_price = float(Json_Response_uni["data"]["pair"]["token0Price"])
            uni_usdc_price = float(Json_Response_uni["data"]["pair"]["token1Price"])

        if(sushi_response.status_code == 200):
            Json_Response_sushi = json.loads(sushi_response.content)
            sushi_eth_price = float(Json_Response_sushi["data"]["pair"]["token0Price"])
            sushi_usdc_price = float(Json_Response_sushi["data"]["pair"]["token1Price"])

        print(f"\nSushiswap ETH Price : {sushi_eth_price} USDC\n")
        print(f"Uniswap ETH Price : {uni_eth_price} USDC\n")
        print(f"Price Difference : {uni_eth_price - sushi_eth_price} USDC\n")
        print("***************************************************************\n")
        print(f"\nSushiswap ETH Price : {sushi_usdc_price} ETH\n")
        print(f"Uniswap ETH Price : {uni_usdc_price} ETH\n")
        print(f"Price Difference : {uni_usdc_price - sushi_usdc_price} ETH\n")

        c+=1 


