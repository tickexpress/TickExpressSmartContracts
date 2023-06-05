const hre = require("hardhat")

async function deployTicketExpress() {
    const [deployer] = await hre.ethers.getSigners()

    console.log("Deploying TicketExpress with the account:", deployer.address)

    const Contract = await hre.ethers.getContractFactory("TicketExpress")
    const contract = await Contract.deploy()

    console.log("TicketExpress address:", contract.address)
}

module.exports = { deployTicketExpress }
