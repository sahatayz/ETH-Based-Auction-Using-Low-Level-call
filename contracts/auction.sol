// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    uint256 bidDuration;
    uint256 minBidAmount;
    address payable sellerAddress;

    uint256 startTime;
    uint256 endTime;

    address highestBidder;
    uint256 highestBid;
    mapping(address => uint256) public bids;

    //Emit BidPlaced, AuctionEnded, and FundsWithdrawn events.

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
        require(msg.sender != address(0));
        require(msg.value > highestBid, "value < highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        // payable(highestBidder).transfer(highestBid);
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // function placeBid(address bidder, uint value) internal
    //         returns (bool success)
    // {
    //     if (value <= highestBid) {
    //         return false;
    //     }
    //     if (highestBidder != address(0)) {
    //         pendingReturns[highestBidder] += highestBid;
    //     }
    //     highestBid = value;
    //     highestBidder = bidder;
    //     return true;
    // }

    function withdraw() external {
        uint256 balance = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function getTimeLeft() public view returns (uint) {
        if (endTime <= block.timestamp) return 0;
        return endTime - block.timestamp;
    }

    function getHighestBid() public view returns (uint) {
        return highestBid;
    }
}
