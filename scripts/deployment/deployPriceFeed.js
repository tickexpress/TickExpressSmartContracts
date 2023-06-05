const hre = require("hardhat")

async function deployPriceFeed() {
    const [deployer] = await hre.ethers.getSigners()

    console.log("Deploying PriceFeed with the account:", deployer.address)

    const Contract = await hre.ethers.getContractFactory("PriceFeed")
    const contract = await Contract.deploy()

    console.log("PriceFeed address:", contract.address)
}

module.exports = { deployPriceFeed }
