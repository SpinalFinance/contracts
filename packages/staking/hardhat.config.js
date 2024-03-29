require("@nomicfoundation/hardhat-toolbox")
require("hardhat-deploy")
require("hardhat-deploy-ethers")
require("./tasks")
require("dotenv").config()
require("module")

const PRIVATE_KEY = process.env.PRIVATE_KEY
const USEAGE_MODE = "DEV"
module.exports = {
    solidity: "0.8.17",
    defaultNetwork: "wallaby",
    networks: {
        wallaby: {
            chainId: 31415,
            url: "https://wallaby.node.glif.io/rpc/v0",
            accounts: [PRIVATE_KEY],
        },
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
}
