const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const MetaMuskToken = artifacts.require("MetaMuskToken");
const MetaMuskTokenV5 = artifacts.require("MetaMuskTokenV5");

module.exports = async function (deployer, network) {
    console.log("you are deploying with the network: ", network);

    const newInstance = await upgradeProxy(MetaMuskToken.address, MetaMuskTokenV5, { deployer });
    console.table({
        MetaMuskTokenContractV4: newInstance.address
    });
};
