## Installation

```bash
$ npm install truffle -g
$ npm install
```

## Deploy the app

```bash
# testnet
- make sure you have bnb balance in your wallet for deployment. Receive test bnb value from page: https://testnet.binance.org/faucet-smart
- change private key in file .private_key.testnet
- run bellow command:
  ```
  truffle migrate --reset --network testnet
  ```
  or
  ```
  truffle deploy --network testnet --reset --compile-none
  ```
  
# mainnet
- make sure you have bnb balance in your wallet for deployment.
- change private key in file .private_key.mainnet
- run bellow command:
$ truffle migrate --network bsc
```

## test on console
- refer to: https://www.trufflesuite.com/docs/truffle/testing/testing-your-contracts
- refer to: https://www.trufflesuite.com/docs/truffle/getting-started/interacting-with-your-contracts
### To launch the console, run the command:
  ```
  truffle console --network testnet
  ```
### Create a new abstraction to represent the contract at that address:
- replace "0x1234..." value by your MetaMusk contract address that you deployed before
- run bellow command in truffle console: 
  ```
  let specificInstance = await MetaMuskToken.at("0x1234...")
  ```
### Making a call to buy ICO buy bnb
- Make sure you have bnb in your wallet 
- Run bellow command in truffle console
  ```
  let result = await specificInstance.buyICO({from: accounts[0], value: web3.utils.toWei('0.01', 'ether')})
  ```
### Making a call to buy ICO buy BUSD
- Make sure you have BUSD in your wallet address
- to approve BUSD for our contract, go to this link: https://testnet.bscscan.com/address/0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee#writeContract (in this case, we are using BUSD contract address 0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee to integrate with MetaMusk token, you can change BUSD contract address by other BUSD contract address)
- connect to Web3 by wallet that you are using to test in truffle console
- at "2. approve" tab method, please fill "_spender" with MetaMusk contract address and fill "_value" equal the value that you are using to buyICOByBUSD (the value in wei format)
- click "Write" button
- go back to truffle console and run bellow command:
  ```
  let result = await specificInstance.buyICOByBUSD(web3.utils.toWei('1', 'ether'), {from: accounts[0]})
  ```

### Verify Contract on BscScan
- Get API key: https://bscscan.com/myapikey
- replace API key value in env.json file with key BSCSCANAPIKEY
- replace {contract-address} with your contract address
- replace {network-name} with network that you config in truffle-config.js file, example testnet, bsc,...
- run command:
  ```
  truffle run verify MetaMuskToken@{contract-address} --network {network-name}
  ```
- example:
  ```
  truffle run verify MetaMuskToken@0x68D2E27940CA48109Fa3DaD0D2C8B27E64a0c6cf --network testnet
  ```
- go to https://testnet.bscscan.com/proxyContractChecker?a={proxy-contract-address} (replace {proxy-contract-address} with your proxy contract address)
- click "Verify" button on page from above link
- get contract address is display at popup
- run verify again with this contract

### Testnet

```
0x0702f2048eE7498FAd9D5d868FfFbFc61EB1C469
```
─────────────────────────┬──────────────────────────────────────────────┐
│         (index)         │                    Values                    │
├─────────────────────────┼──────────────────────────────────────────────┤
│ MetaMuskTokenContractV4 │ '0x2995919424A2AAA74461785481BA6F1573da50b7' │
│ MetaMuskAirdropContract │ '0x50ca551b234581e41d9B7BF2880D647Faee2fb0e' │
│ MetaMuskICOContract │ '0x64F861c71e3AaFF9a57a3f550C7b9019478d8E57' │


let specificInstance = await MetaMuskTokenV3.at("0xc77408aaefd316790061295b0db548c2903ff41c");
let result = await specificInstance.setUnlockPerSecond(925925925925);
