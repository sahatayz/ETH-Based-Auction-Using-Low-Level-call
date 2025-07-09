# ETH Auction Smart Contract

A basic English-style auction contract that allows users to bid with ETH, tracks the highest bid, and handles fund distribution.

## Features
- Accepts ETH bids from participants
- Tracks highest bidder and bid amount
- Minimum bid amount enforcement
- Bid increment validation (must exceed previous bid by at least minBidAmount)
- Withdrawal functionality for losing bidders
- Auction finalization by owner
- Time-based auction duration
- Event logging for key actions

## Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    uint256 public bidDuration;
    uint256 public minBidAmount;
    address payable public sellerAddress;

    uint256 public startTime;
    uint256 public endTime;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
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
            "Bid increment must be >= minBidAmount"
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
```
## Deployment Parameters
When deploying the contract, you need to provide:

- **_bidDuration:** Auction duration in seconds (≥ 60)

- **_startAfter:** Delay before auction starts in seconds

- **_minBidAmount:** Minimum bid amount in wei (≥ 1 ETH worth of wei)

- **_sellerAddress:** Seller's payable address

## Key Functions
- **placeBid():** Submit a new bid (must attach ETH)

- **withdraw():** Withdraw refunded bids

- **endAuction():** Finalize auction and pay seller (owner only)

- **getTimeLeft():** View remaining auction time

- **getHighestBid():** View current highest bid amount

## Bid Requirements
- Bid must be placed within auction timeframe

- Bid must be higher than current highest bid

- Bid increment must be ≥ minBidAmount

- First bid must be ≥ minBidAmount

Events
- **BidPlaced:** Emitted when a new bid is placed

- **AuctionEnded:** Emitted when auction is finalized

- **FundsWithdrawn:** Emitted when a bidder withdraws funds

## Security Notes
- Only contract owner can end auction

- Funds are protected through withdrawal pattern

- Bid validation prevents underbidding

- Time-based auction constraints

License
- MIT License
