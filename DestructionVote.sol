// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DestructionVote is ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public fudeNFT;
    IERC20 public fudeToken;

    uint256 public constant VOTE_COST = 1 * 10**18;
    uint256 public constant VOTE_THRESHOLD = 500 * 10**18;

    struct Vote {
        bool active;
        address initiator;
        uint256 votes;
        uint256 endTimestamp;
    }

    mapping(uint256 => Vote) public votes;

    event VoteStarted(uint256 tokenId, address initiator);
    event Voted(uint256 tokenId, address voter, uint256 amount);
    event VoteEnded(uint256 tokenId, bool destroyed);

    constructor(IERC721 _fudeNFT, IERC20 _fudeToken) {
        fudeNFT = _fudeNFT;
        fudeToken = _fudeToken;
    }

    function startDestructionVote(uint256 tokenId) external {
        require(fudeNFT.ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(!votes[tokenId].active, "Vote already active");

        votes[tokenId] = Vote(true, msg.sender, 0, block.timestamp + 7 days);

        emit VoteStarted(tokenId, msg.sender);
    }

    function vote(uint256 tokenId, uint256 amount) external nonReentrant {
        require(votes[tokenId].active, "No active vote for this NFT");
        require(amount >= VOTE_COST, "Insufficient vote amount");

        uint256 voteAmount = amount.div(VOTE_COST).mul(VOTE_COST);
        fudeToken.transferFrom(msg.sender, address(this), voteAmount);
        votes[tokenId].votes = votes[tokenId].votes.add(voteAmount);

        emit Voted(tokenId, msg.sender, voteAmount);
    }

    function endDestructionVote(uint256 tokenId) external nonReentrant {
        require(votes[tokenId].active, "No active vote for this NFT");
        require(block.timestamp >= votes[tokenId].endTimestamp, "Vote still ongoing");

        votes[tokenId].active = false;
        bool destroyed = false;

        if (votes[tokenId].votes >= VOTE_THRESHOLD) {
            fudeNFT.burn(tokenId);
            destroyed = true;
        } else {
            fudeToken.transfer(votes[tokenId].initiator, votes[tokenId].votes);
        }

        emit VoteEnded(tokenId, destroyed);
    }
}
