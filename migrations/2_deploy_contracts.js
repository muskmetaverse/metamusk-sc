const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");

// testnet
const START_TIME_ICO = 1636340453;
const END_TIME_ICO = 1667851253;
const TOTAL_AMOUNT_PER_BUSD = 50000000;
const PERCENT_UNLOCK_PER_DAY = 50;  // value * 100
const BUSD_CONTRACT_ADDRESS = '0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee';
const OPERATOR_ADDRESS = '0x096E36E51AbdAD5387E826Fef1fd0D3B70D3b201';
const PRICE_FEED_ADDRESS = '0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c';        // because testnet does not have busd/bnb, so for test we use DAI/BNB

// for mainnet
// const START_TIME_ICO = 1636340453;
// const END_TIME_ICO = 1667851253;
// const TOTAL_AMOUNT_PER_BUSD = 10;
// const PERCENT_UNLOCK_PER_DAY = 50;  // value * 100
// const BUSD_CONTRACT_ADDRESS = '';
// const OPERATOR_ADDRESS = '';
// const PRICE_FEED_ADDRESS = '';

module.exports = async function (deployer, network) {
    console.log("you are deploying with the network: ", network);

    const instance = await deployProxy(MetaMuskToken, [
        START_TIME_ICO,
        END_TIME_ICO,
        TOTAL_AMOUNT_PER_BUSD,
        PERCENT_UNLOCK_PER_DAY,
        BUSD_CONTRACT_ADDRESS,
        OPERATOR_ADDRESS,
        PRICE_FEED_ADDRESS
    ], { deployer });

    console.table({
        MetaMuskTokenContract: instance.address
    });
};
