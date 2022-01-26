const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");
const MetaMuskTokenV2 = artifacts.require("MetaMuskTokenV2");

module.exports = async function (deployer, network) {
    console.log("you are deploying with the network: ", network);

    const newInstance = await upgradeProxy(MetaMuskToken.address, MetaMuskTokenV2, { deployer });
    console.table({
        MetaMuskTokenContractV2: newInstance.address
    });
};
