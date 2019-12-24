pragma solidity ^0.5.0;

contract TicketingSystem {

    struct Artist {
        address payable owner;
        bytes32 name;
        uint256 artistCategory;
        uint256 totalTicketSold;
    }

    struct Venue {
        address payable owner;
        bytes32 name;
        uint256 capacity; 
        uint256 standardComission;
    }

    struct Concert {
        uint256 concertDate;
        uint256 totalSoldTicket;
        uint256 totalMoneyCollected;
        uint256 artistId;
        uint256 venueId;
        uint256 ticketPrice;
        bool validatedByArtist;
        bool validatedByVenue;
    }

    struct Ticket {
        bool isAvailable;
        address payable owner;
        uint256 amountPaid;
        uint256 concertId;
        bool isAvailableForSale;
        uint256 resalePrice;
    }

    mapping (uint256 => Artist) public artistsRegister;
    mapping (uint256 => Venue) public venuesRegister;
    mapping (uint256 => Ticket) public ticketsRegister;
    mapping (uint256 => Concert) public concertsRegister;

    uint256 artistCompt;
    uint256 venueCompt;
    uint256 concertCompt;
    uint256 ticketCompt;

    modifier isOwner(address owner) {
      require (msg.sender == owner, "Sender is not the owner");
      _;
  }

  constructor() public {
  }

  function createArtist(bytes32  _name, uint256  _type) public {
    artistCompt ++;
    artistsRegister[artistCompt] = Artist(msg.sender, _name, _type, 0);
}

function modifyArtist(uint _artistId, bytes32 _name, uint _artistCategory, address payable _newOwner) public isOwner(artistsRegister[_artistId].owner) {
    artistsRegister[_artistId] = Artist(_newOwner, _name, _artistCategory, artistsRegister[_artistId].totalTicketSold);
}

function createVenue(bytes32 _name, uint256 _space, uint256 _standardComission) public {
    venueCompt ++;
    venuesRegister[venueCompt] = Venue(msg.sender, _name, _space, _standardComission);
}

function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _standardComission, address payable _newOwner) public isOwner(venuesRegister[_venueId].owner) {
    venuesRegister[_venueId] = Venue(_newOwner, _name, _capacity, _standardComission);
}

function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice) public {
    concertCompt ++;
    concertsRegister[concertCompt] = Concert(_concertDate, 0, 0, _artistId, _venueId, _ticketPrice, false, false);
}

function validateConcert(uint256 _concertId) public {
    if(msg.sender == artistsRegister[concertsRegister[_concertId].artistId].owner) {
        concertsRegister[_concertId].validatedByArtist = true;
    }
    else if(msg.sender == venuesRegister[concertsRegister[_concertId].venueId].owner) {
        concertsRegister[_concertId].validatedByVenue = true;
    }
}

function emitTicket(uint _concertId, address payable _ticketOwner) public isOwner(artistsRegister[concertsRegister[_concertId].artistId].owner) {
    ticketCompt++;
    ticketsRegister[ticketCompt] = Ticket(true, _ticketOwner, 0, _concertId, false, 0);
    concertsRegister[_concertId].totalSoldTicket++;
}

function buyTicket(uint256 _concertId) public payable {
    require(concertsRegister[_concertId].validatedByArtist == true && concertsRegister[_concertId].validatedByVenue == true, "Concert is not confirmed by artist and venue");
    require(msg.value == concertsRegister[_concertId].ticketPrice, "Amount sent is not equal to ticket price");
    require(now < concertsRegister[_concertId].concertDate, "Concert has already happened");
    ticketCompt ++;
    ticketsRegister[ticketCompt] = Ticket(true, msg.sender, concertsRegister[_concertId].ticketPrice, _concertId, false, 0);
    concertsRegister[_concertId].totalMoneyCollected += concertsRegister[_concertId].ticketPrice;
    concertsRegister[_concertId].totalSoldTicket ++; 
}

function useTicket(uint256 _ticketId) public isOwner(ticketsRegister[_ticketId].owner) {
    require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByArtist == true && concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue == true, "Concert is not confirmed by artist and venue");
    require(msg.sender != address(0));
    require(now > (concertsRegister[ticketsRegister[_ticketId].concertId].concertDate - 24 * 1 hours) && now < concertsRegister[ticketsRegister[_ticketId].concertId].concertDate , "Concert is not within 24 hours");
    delete ticketsRegister[_ticketId];
}

function transferTicket(uint _ticketId, address payable _newOwner) public isOwner(ticketsRegister[_ticketId].owner) {
    ticketsRegister[_ticketId].owner = _newOwner;
}

function cashOutConcert(uint _concertId, address payable _cashOutAddress) public isOwner(artistsRegister[concertsRegister[_concertId].artistId].owner) {
    require(concertsRegister[_concertId].concertDate < now, "Concert has not yet happened");
    _cashOutAddress.transfer(concertsRegister[_concertId].totalMoneyCollected - venuesRegister[concertsRegister[_concertId].venueId].standardComission);
    venuesRegister[concertsRegister[_concertId].venueId].owner.transfer(venuesRegister[concertsRegister[_concertId].venueId].standardComission);
    artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold += concertsRegister[_concertId].totalSoldTicket;
}

function offerTicketForSale(uint _ticketId, uint _salePrice) public isOwner(ticketsRegister[_ticketId].owner) {
    require(_salePrice < ticketsRegister[_ticketId].amountPaid, "Sale price can not be superior to original price");
    ticketsRegister[_ticketId].isAvailableForSale = true;
    ticketsRegister[_ticketId].resalePrice = _salePrice;
}

function buySecondHandTicket(uint _ticketId) public payable {
    require(msg.value == ticketsRegister[_ticketId].resalePrice && ticketsRegister[_ticketId].isAvailableForSale == true);
    ticketsRegister[_ticketId] = Ticket(true, msg.sender, msg.value, ticketsRegister[_ticketId].concertId, false, 0);
}

}
