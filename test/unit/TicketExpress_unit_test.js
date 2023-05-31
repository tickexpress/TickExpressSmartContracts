const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("TicketExpress", function () {
    let TicketExpress, ticketExpress, owner, addr1, addr2

    beforeEach(async function () {
        TicketExpress = await ethers.getContractFactory("TicketExpress")
        ;[owner, addr1, addr2, _] = await ethers.getSigners()
        ticketExpress = await TicketExpress.deploy()
        await ticketExpress.deployed()
    })

    describe("mintTicket", function () {
        it("Should mint a ticket", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).mintTicket(addr1.address, 0)
            expect(await ticketExpress.ownerOf(1)).to.equal(addr1.address)
        })

        it("Should fail if not owner", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await expect(
                ticketExpress.connect(addr2).mintTicket(addr1.address, 0)
            ).to.be.revertedWith("Ownable: caller is not the owner")
        })
    })

    describe("createEvent", function () {
        it("Should create a new event", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            let event = await ticketExpress.events(0)
            expect(event.name).to.equal("Event 1")
            expect(event.ticketPrice).to.equal(ethers.utils.parseEther("1"))
            expect(event.totalTickets).to.equal(10)
        })

        it("Should fail if not owner", async function () {
            await expect(
                ticketExpress
                    .connect(addr1)
                    .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            ).to.be.revertedWith("Ownable: caller is not the owner")
        })
    })

    describe("cancelEvent", function () {
        it("Should cancel an event", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).cancelEvent(0)
            let event = await ticketExpress.events(0)
            expect(event.isCancelled).to.equal(true)
        })

        it("Should fail if not owner", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await expect(ticketExpress.connect(addr1).cancelEvent(0)).to.be.revertedWith(
                "Ownable: caller is not the owner"
            )
        })
    })

    describe("listTicketForSale", function () {
        it("Should list a ticket for sale", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).mintTicket(addr1.address, 0)
            await ticketExpress.connect(addr1).listTicketForSale(1, ethers.utils.parseEther("2"))
            let ticketForSale = await ticketExpress.ticketsForSale(1)
            expect(ticketForSale.price).to.equal(ethers.utils.parseEther("2"))
        })

        it("Should fail if not owner of the ticket", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).mintTicket(addr1.address, 0)
            await expect(
                ticketExpress.connect(addr2).listTicketForSale(1, ethers.utils.parseEther("2"))
            ).to.be.revertedWith("You are not the owner of this ticket")
        })
    })

    describe("unlistTicketForSale", function () {
        it("Should unlist a ticket for sale", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).mintTicket(addr1.address, 0)
            await ticketExpress.connect(addr1).listTicketForSale(1, ethers.utils.parseEther("2"))
            await ticketExpress.connect(addr1).unlistTicketForSale(1)
            let ticketForSale = await ticketExpress.ticketsForSale(1)
            expect(ticketForSale.price).to.equal(0)
        })

        it("Should fail if not owner of the ticket", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress.connect(owner).mintTicket(addr1.address, 0)
            await ticketExpress.connect(addr1).listTicketForSale(1, ethers.utils.parseEther("2"))
            await expect(ticketExpress.connect(addr2).unlistTicketForSale(1)).to.be.revertedWith(
                "You are not the owner of this ticket"
            )
        })
    })

    // buyNewTicket and buyTicketForSale tests are more complex and require mocking or deploying additional contracts.

    describe("withdraw", function () {
        it("Should withdraw balance", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress
                .connect(addr1)
                .buyNewTicket(0, { value: ethers.utils.parseEther("1") })
            await ticketExpress.connect(owner).withdraw(ethers.utils.parseEther("1"))
            expect(await ethers.provider.getBalance(ticketExpress.address)).to.equal(0)
        })

        it("Should fail if not owner", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress
                .connect(addr1)
                .buyNewTicket(0, { value: ethers.utils.parseEther("1") })
            await expect(
                ticketExpress.connect(addr1).withdraw(ethers.utils.parseEther("1"))
            ).to.be.revertedWith("Ownable: caller is not the owner")
        })

        it("Should fail if trying to withdraw more than balance", async function () {
            await ticketExpress
                .connect(owner)
                .createEvent("Event 1", ethers.utils.parseEther("1"), 10)
            await ticketExpress
                .connect(addr1)
                .buyNewTicket(0, { value: ethers.utils.parseEther("1") })
            await expect(
                ticketExpress.connect(owner).withdraw(ethers.utils.parseEther("2"))
            ).to.be.revertedWith("Insufficient balance")
        })
    })
})
