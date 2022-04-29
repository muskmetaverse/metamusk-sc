const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskAirdrop = artifacts.require("MetaMuskAirdrop");

const OPERATOR_ADDRESS = '0x40BD94033dEb6D3d9EE1c8CFBfFae33fC11FB63d';

module.exports = async function (deployer) {
    const instance = await deployProxy(MetaMuskAirdrop, [
        "0xE95BA178Fc5A9ad4C4dF9ee79dBD34C76F96584E",
        OPERATOR_ADDRESS
    ], { deployer });

    console.table({
        MetaMuskAirdropContract: instance.address
    });
};
