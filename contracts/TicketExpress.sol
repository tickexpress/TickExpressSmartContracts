// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceFeed.sol";

contract TicketExpress is ERC721, Ownable, PriceFeed {
    event TicketMinted(address recipient, uint256 ticketId);
    event TicketListedForSale(uint256 ticketId, address seller, uint256 price);
    event TicketUnlisted(uint256 ticketId, address seller);
    event TicketSold(uint256 ticketId, address buyer, uint256 price);
    event EventCreated(
        uint256 eventId,
        string name,
        uint256 ticketPrice,
        uint256 totalTickets
    );
    event EventCancelled(uint256 eventId);

    uint256 public ticketId;

    struct CryptoPayment {
        address tokenAddress;
        uint256 amount;
    }

    struct Event {
        string name;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
        bool isCancelled;
    }
    Event[] public events;

    struct TicketForSale {
        uint256 ticketId;
        uint256 price;
    }
    mapping(uint256 => TicketForSale) public ticketsForSale;

    constructor() ERC721("TicketExpress", "TICK") {}

    function mintTicket(address to, uint256 eventId) public onlyOwner {
        require(eventId < events.length, "Event does not exist");
        require(!events[eventId].isCancelled, "Event is cancelled");
        require(
            events[eventId].ticketsSold < events[eventId].totalTickets,
            "No tickets available"
        );
        ticketId++;
        _mint(to, ticketId);
        emit TicketMinted(to, ticketId);
    }

    function createEvent(
        string memory _name,
        uint256 _ticketPrice,
        uint256 _totalTickets
    ) public onlyOwner {
        events.push(
            Event({
                name: _name,
                ticketPrice: _ticketPrice,
                totalTickets: _totalTickets,
                ticketsSold: 0,
                isCancelled: false
            })
        );
        emit EventCreated(
            events.length - 1,
            _name,
            _ticketPrice,
            _totalTickets
        );
    }

    function cancelEvent(uint256 _eventId) public onlyOwner {
        require(_eventId < events.length, "Event does not exist");
        events[_eventId].isCancelled = true;
        emit EventCancelled(_eventId);
    }

    function listTicketForSale(uint256 _ticketId, uint256 _price) public {
        require(
            ownerOf(_ticketId) == msg.sender,
            "You are not the owner of this ticket"
        );
        ticketsForSale[_ticketId] = TicketForSale({
            ticketId: _ticketId,
            price: _price
        });
        emit TicketListedForSale(_ticketId, msg.sender, _price);
    }

    function unlistTicketForSale(uint256 _ticketId) public {
        require(
            ownerOf(_ticketId) == msg.sender,
            "You are not the owner of this ticket"
        );
        delete ticketsForSale[_ticketId];
        emit TicketUnlisted(_ticketId, msg.sender);
    }

    function buyNewTicket(uint256 _eventId) public payable {
        require(_eventId < events.length, "Event does not exist");
        require(!events[_eventId].isCancelled, "Event is cancelled");
        require(
            events[_eventId].ticketsSold < events[_eventId].totalTickets,
            "No tickets available"
        );
        require(msg.value == events[_eventId].ticketPrice, "Incorrect price");
        ticketId++;
        _mint(msg.sender, ticketId);
        events[_eventId].ticketsSold++;
    }

    function buyTicketForSale(
        uint256 _ticketId,
        CryptoPayment memory payment
    ) public {
        // Make sure the ticket is for sale
        require(ticketsForSale[_ticketId].price != 0, "Ticket is not for sale");

        // Get the sale price of the ticket in USD
        uint256 salePriceUSD = ticketsForSale[_ticketId].price;

        // Get the latest price for the cryptocurrency
        int256 latestPrice = getLatestPrice(payment.tokenAddress);

        // Convert the sale price to the equivalent amount of the cryptocurrency
        // Assuming that the price is in USD and the latestPrice is the price of 1 token in USD
        uint256 salePriceInCrypto = (salePriceUSD * 1e8) / uint256(latestPrice); // Chainlink price feeds have 8 decimal places

        // Compare the amount of the cryptocurrency sent with the sale price
        require(payment.amount >= salePriceInCrypto, "Insufficient payment");

        // Transfer the tokens from the buyer to the seller
        IERC20 token = IERC20(payment.tokenAddress);
        address seller = ownerOf(_ticketId);
        require(
            token.transferFrom(msg.sender, seller, payment.amount),
            "Token transfer failed"
        );

        // Transfer the ticket from the seller to the buyer
        _transfer(seller, msg.sender, _ticketId);

        // Unlist the ticket
        delete ticketsForSale[_ticketId];

        emit TicketSold(_ticketId, msg.sender, payment.amount);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
