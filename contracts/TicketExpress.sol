// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Imports */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceFeed.sol";

/* Errors */

/**@title A Ticket service Contract
 * @author Feed-dev
 * @notice This contract is for creating a ticket service and was part of the chainlink hackathon submission spring 2023
 * @dev This implements Chainlink pricefeeds and ERC721
 */

contract TicketExpress is ERC721, Ownable, PriceFeed {
    /* Type declarations */
    struct Ticket {
        address owner;
        uint256 purchasePrice;
        uint256 purchaseDate;
        bool isForSale;
        uint256 salePrice;
    }
    struct Event {
        string name;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
        bool isCancelled;
        uint256 eventDate;
    }

    /* State Variables */
    uint256 public ticketId = 0;
    uint256 public eventId = 0;
    mapping(uint256 => Event) public events;
    mapping(string => uint256) public eventNamesToIds;
    mapping(uint256 => mapping(uint256 => Ticket)) public eventTickets;
    uint256[] public ongoingEvents;
    uint256[] public cancelledEvents;

    /* Events */
    event TicketMinted(address recipient, uint256 ticketId, uint256 eventId);
    event TicketListedForSale(
        uint256 ticketId,
        uint256 eventId,
        address seller,
        uint256 price
    );
    event TicketUnlisted(uint256 ticketId, uint256 eventId, address seller);
    event TicketSold(
        uint256 ticketId,
        uint256 eventId,
        address buyer,
        uint256 price
    );
    event EventCreated(
        uint256 eventId,
        string name,
        uint256 ticketPrice,
        uint256 totalTickets,
        uint256 eventDate
    );
    event EventCancelled(uint256 eventId);

    /* Modifiers */

    /* Contract constructor */
    constructor() ERC721("TicketExpress", "TICK") {}

    /* Main functions */

    function mintTicket(address to, string memory _eventName) public onlyOwner {
        uint256 _eventId = getEventId(_eventName);
        require(_eventId <= eventId, "Event does not exist");
        require(!events[_eventId].isCancelled, "Event is cancelled");
        require(
            events[_eventId].ticketsSold < events[_eventId].totalTickets,
            "No tickets available"
        );
        ticketId++;
        _mint(to, ticketId);
        eventTickets[_eventId][ticketId] = Ticket(
            to,
            events[_eventId].ticketPrice,
            block.timestamp,
            false,
            0
        );
        events[_eventId].ticketsSold++;
        emit TicketMinted(to, ticketId, _eventId);
    }

    function createEvent(
        string memory _name,
        uint256 _ticketPrice,
        uint256 _totalTickets,
        uint256 _eventDate // Added event date parameter
    ) public onlyOwner {
        require(eventNamesToIds[_name] == 0, "Event name already exists"); // Check if event with same name exists
        eventId++; // Increment eventId before using it
        Event memory newEvent = Event({
            name: _name,
            ticketPrice: _ticketPrice,
            totalTickets: _totalTickets,
            ticketsSold: 0,
            isCancelled: false,
            eventDate: _eventDate
        });

        events[eventId] = newEvent;
        eventNamesToIds[_name] = eventId;
        emit EventCreated(
            eventId,
            _name,
            _ticketPrice,
            _totalTickets,
            _eventDate
        );
    }

    function deleteEvent(string memory _name) public onlyOwner {
        require(eventNamesToIds[_name] > 0, "Event does not exist"); // Check if event exists
        uint256 _eventId = eventNamesToIds[_name]; // Get event ID using name
        require(_eventId <= eventId, "Event does not exist");

        delete events[_eventId]; // Delete the event from the 'events' mapping

        // Remove the event from the 'ongoingEvents' array if it exists there
        for (uint256 i = 0; i < ongoingEvents.length; i++) {
            if (ongoingEvents[i] == _eventId) {
                ongoingEvents[i] = ongoingEvents[ongoingEvents.length - 1];
                ongoingEvents.pop();
                break;
            }
        }

        // Remove the event from the 'cancelledEvents' array if it exists there
        for (uint256 i = 0; i < cancelledEvents.length; i++) {
            if (cancelledEvents[i] == _eventId) {
                cancelledEvents[i] = cancelledEvents[
                    cancelledEvents.length - 1
                ];
                cancelledEvents.pop();
                break;
            }
        }

        delete eventNamesToIds[_name]; // Delete the event ID from the 'eventNamesToIds' mapping
    }

    function buyNewTicket(string memory _eventName) public payable {
        uint256 _eventId = getEventId(_eventName);
        require(_eventId <= eventId, "Event does not exist");
        require(!events[_eventId].isCancelled, "Event is cancelled");
        require(
            events[_eventId].ticketsSold < events[_eventId].totalTickets,
            "No tickets available"
        );
        require(
            msg.value >= events[_eventId].ticketPrice,
            "Insufficient funds to buy ticket"
        );
        ticketId++;
        _mint(msg.sender, ticketId);
        eventTickets[_eventId][ticketId] = Ticket(
            msg.sender,
            events[_eventId].ticketPrice,
            block.timestamp,
            false,
            0
        );
        events[_eventId].ticketsSold++;
        emit TicketMinted(msg.sender, ticketId, _eventId);
    }

    function listTicketForSale(
        uint256 _ticketId,
        string memory _eventName,
        uint256 _price
    ) public {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        require(ownerOf(_ticketId) == msg.sender, "Not the ticket owner");
        require(!events[_eventId].isCancelled, "Event is cancelled");
        eventTickets[_eventId][_ticketId].isForSale = true;
        eventTickets[_eventId][_ticketId].salePrice = _price;
        emit TicketListedForSale(_ticketId, _eventId, msg.sender, _price);
    }

    function unlistTicket(uint256 _ticketId, string memory _eventName) public {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        require(ownerOf(_ticketId) == msg.sender, "Not the ticket owner");
        eventTickets[_eventId][_ticketId].isForSale = false;
        emit TicketUnlisted(_ticketId, _eventId, msg.sender);
    }

    function buyTicketForSale(
        uint256 _ticketId,
        string memory _eventName
    ) public payable {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        require(
            eventTickets[_eventId][_ticketId].isForSale,
            "Ticket is not for sale"
        );
        require(
            msg.value >= eventTickets[_eventId][_ticketId].salePrice,
            "Insufficient funds to buy ticket"
        );
        address previousOwner = ownerOf(_ticketId);
        _transfer(previousOwner, msg.sender, _ticketId);
        eventTickets[_eventId][_ticketId].owner = msg.sender;
        eventTickets[_eventId][_ticketId].isForSale = false;
        emit TicketSold(
            _ticketId,
            _eventId,
            msg.sender,
            eventTickets[_eventId][_ticketId].salePrice
        );
    }

    function cancelEvent(string memory _eventName) public onlyOwner {
        uint256 _eventId = getEventId(_eventName);
        require(_eventId <= eventId, "Event does not exist");
        events[_eventId].isCancelled = true;
        emit EventCancelled(_eventId);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    /* View / Pure functions */
    function getEventId(string memory _name) public view returns (uint256) {
        return eventNamesToIds[_name];
    }

    function getEventName(
        uint256 _eventId
    ) public view returns (string memory) {
        require(_eventId <= eventId, "Event does not exist");
        return events[_eventId].name;
    }

    function getTicketOwner(
        uint256 _ticketId,
        string memory _eventName
    ) public view returns (address) {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        return eventTickets[_eventId][_ticketId].owner;
    }

    function getOngoingEvents() public view returns (uint256[] memory) {
        return ongoingEvents;
    }

    function getEventDetails(
        string memory _eventName
    )
        public
        view
        returns (string memory, uint256, uint256, uint256, bool, uint256)
    {
        uint256 _eventId = getEventId(_eventName);
        require(_eventId <= eventId, "Event does not exist");
        return (
            events[_eventId].name,
            events[_eventId].ticketPrice,
            events[_eventId].totalTickets,
            events[_eventId].ticketsSold,
            events[_eventId].isCancelled,
            events[_eventId].eventDate
        );
    }

    function getTicketDetails(
        uint256 _ticketId,
        string memory _eventName
    ) public view returns (address, uint256, uint256, bool, uint256) {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        return (
            eventTickets[_eventId][_ticketId].owner,
            eventTickets[_eventId][_ticketId].purchasePrice,
            eventTickets[_eventId][_ticketId].purchaseDate,
            eventTickets[_eventId][_ticketId].isForSale,
            eventTickets[_eventId][_ticketId].salePrice
        );
    }

    function getTicketPrice(
        uint256 _ticketId,
        string memory _eventName
    ) public view returns (uint256) {
        uint256 _eventId = getEventId(_eventName);
        require(_exists(_ticketId), "Ticket does not exist");
        return eventTickets[_eventId][_ticketId].purchasePrice;
    }
}
