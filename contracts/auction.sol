// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    uint256 bidDuration;
    uint256 minBidAmount;
    address payable sellerAddress;

    uint256 startTime;
    uint256 endTime;
    bool ended;

    address highestBidder;
    uint256 highestBid;
    mapping(address => uint256) public bids;

    event BidPlaced(address indexed bidder, uint256 bid);
    event AuctionEnded(address indexed winner, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor(
        uint256 _bidDuration,
        uint256 _startAfter,
        uint256 _minBidAmount,
        address payable _sellerAddress
    ) Ownable(msg.sender) {
        require(_bidDuration >= 60, "Duration must be >= 60");
        require(_minBidAmount >= 1, "Minimum bid amount must be >= 1 ETH");
        require(_sellerAddress != address(0), "Invalid address!");

        bidDuration = _bidDuration;
        minBidAmount = _minBidAmount;
        sellerAddress = _sellerAddress;
        startTime = block.timestamp + _startAfter;
        endTime = startTime + _bidDuration;
    }

    function placeBid() external payable {
        require(startTime <= block.timestamp);
        require(getTimeLeft() > 0, "Auction has ended.");
        require(!ended, "Auction has ended.");
        require(msg.sender != address(0));
        require(msg.value > highestBid, "value < highest");
        require(
            msg.value - highestBid >= minBidAmount,
            "The bid amount must be at least as much as the 'minBidAmount' of the previous bid."
        );

        if (highestBidder == address(0)) {
            require(msg.value >= minBidAmount, "Below minimum bid");
        }

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 balance = bids[msg.sender];
        require(balance > 0);

        bids[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");

        emit FundsWithdrawn(msg.sender, balance);
    }

    function getTimeLeft() public view returns (uint) {
        if (endTime <= block.timestamp) return 0;
        return endTime - block.timestamp;
    }

    function getHighestBid() public view returns (uint) {
        return highestBid;
    }

    function endAuction() external onlyOwner {
        require(getTimeLeft() == 0, "Auction has ended.");
        ended = true;

        (bool success, ) = sellerAddress.call{value: highestBid}("");
        require(success, "Transfer failed.");

        emit AuctionEnded(highestBidder, highestBid);
    }
}
