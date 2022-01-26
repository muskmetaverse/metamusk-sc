const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');

const privateKeyTestnet = fs.readFileSync(".private_key.testnet").toString().trim();
const privateKeyRinkebyTestnet = fs.readFileSync(".private_key_rinkeby.testnet").toString().trim();
const privateKeyMainnet = fs.readFileSync(".private_key.mainnet").toString().trim();
const { BSCSCANAPIKEY } = require('./env.json');

module.exports = {
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: "47ZH9UZCR9TXM8TUEMY1URN98WVN2MBA4T"
  },
  networks: {
    testnet: {
      provider: () => new HDWalletProvider(privateKeyTestnet, `https://data-seed-prebsc-1-s3.binance.org:8545`),
      network_id: 97,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    rinkeby_infura: {
      provider: () => new HDWalletProvider(privateKeyRinkebyTestnet, "https://rinkeby.infura.io/v3/1ce53e2b5c9348f69c352e563d543a50"),
      network_id: 4,
      gas: 4700000
    },
    bsc: {
      provider: () => new HDWalletProvider(privateKeyMainnet, `https://nd-806-882-723.p2pify.com/795b7346407efe8f554f327cd7f82396`),
      network_id: 56,
      // confirmations: 1,
      timeoutBlocks: 200,
      skipDryRun: true,
      gasPrice: 10000000000,
      gas: 9000000
    },
  },
  mocha: {},
  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      docker: false,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        evmVersion: 'byzantium', // Default: "petersburg"
        optimizer: {
          enabled: true,
          runs: 2000
        }
      }
    },
  },
  db: {
    enabled: false
  }
};
