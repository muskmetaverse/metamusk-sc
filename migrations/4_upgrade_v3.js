const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");
const MetaMuskTokenV3 = artifacts.require("MetaMuskTokenV3");

module.exports = async function (deployer, network) {
    console.log("you are deploying with the network: ", network);

    const newInstance = await upgradeProxy(MetaMuskToken.address, MetaMuskTokenV3, { deployer });
    console.table({
        MetaMuskTokenContractV3: newInstance.address
    });
};
