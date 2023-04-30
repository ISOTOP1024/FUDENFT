// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FudeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is Ownable {
    struct Auction {
        uint256 tokenId;
        uint256 startingPrice;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool ended;
    }

    FudeNFT public fudeNFT;
    uint256 public auctionDuration = 86400; // 24 hours

    mapping(uint256 => Auction) public auctions;

    constructor(address _fudeNFTAddress) {
        fudeNFT = FudeNFT(_fudeNFTAddress);
    }

    function startAuction(uint256 tokenId, uint256 startingPrice) public onlyOwner {
        Auction storage auction = auctions[tokenId];
        auction.tokenId = tokenId;
        auction.startingPrice = startingPrice;
        auction.startTime = block.timestamp;
        auction.endTime = block.timestamp + auctionDuration;
        auction.highestBidder = address(0);
        auction.highestBid = 0;
        auction.ended = false;
    }

    function bid(uint256 tokenId) public payable {
        Auction storage auction = auctions[tokenId];
        require(!auction.ended, "Auction has ended");
        require(block.timestamp <= auction.endTime, "Auction has expired");
        require(msg.value > auction.highestBid, "Bid amount must be higher than the current highest bid");

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    function endAuction(uint256 tokenId) public onlyOwner {
        Auction storage auction = auctions[tokenId];
        require(!auction.ended, "Auction has already ended");
        require(block.timestamp > auction.endTime, "Auction has not yet expired");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            // Mint the NFT to the highest bidder
            fudeNFT.mintNFT(auction.highestBidder, tokenId);
            // Transfer the highest bid amount to the contract owner
            payable(owner()).transfer(auction.highestBid);
        }
    }
}
