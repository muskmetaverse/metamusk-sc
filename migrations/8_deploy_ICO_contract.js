const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");
const MetaMuskICO = artifacts.require("MetaMuskICO");

const START_TIME_ICO = 1636340453;
const END_TIME_ICO = 1667851253;
const TOTAL_AMOUNT_PER_BUSD = 50000000;
const BUSD_CONTRACT_ADDRESS = '0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee';
// because testnet does not have busd/bnb, so for test we use DAI/BNB
const PRICE_FEED_ADDRESS = '0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c';

module.exports = async function (deployer) {
    const instance = await deployProxy(MetaMuskICO, [
        START_TIME_ICO,
        END_TIME_ICO,
        TOTAL_AMOUNT_PER_BUSD,
        BUSD_CONTRACT_ADDRESS,
        MetaMuskToken.address,
        PRICE_FEED_ADDRESS
    ], { deployer });

    console.table({
        MetaMuskICOContract: instance.address
    });
};
