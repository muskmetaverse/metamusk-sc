const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");
const MetaMuskAirdrop = artifacts.require("MetaMuskAirdrop");

const OPERATOR_ADDRESS = '0x096E36E51AbdAD5387E826Fef1fd0D3B70D3b201';

module.exports = async function (deployer) {
    const instance = await deployProxy(MetaMuskAirdrop, [
        MetaMuskToken.address,
        OPERATOR_ADDRESS
    ], { deployer });

    console.table({
        MetaMuskAirdropContract: instance.address
    });
};
