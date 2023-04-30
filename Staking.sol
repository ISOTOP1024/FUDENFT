// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Staking is ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public fudeNFT;
    IERC20 public fudeToken;
    AggregatorV3Interface public priceFeed;

    uint256 public constant BASE_REWARD_PER_MINUTE = 1000 * 10**18;
    uint256 public constant MINUTES_IN_DAY = 1440;

    struct StakeInfo {
        uint256 stakeTimestamp;
        uint256 claimedRewards;
    }

    mapping(address => mapping(uint256 => StakeInfo)) public stakes;
    uint256 public totalStakedNFTs;

    event Staked(address indexed staker, uint256 tokenId);
    event Unstaked(address indexed staker, uint256 tokenId);
    event Claimed(address indexed staker, uint256 tokenId, uint256 amount);

    constructor(IERC721 _fudeNFT, IERC20 _fudeToken, AggregatorV3Interface _priceFeed) {
        fudeNFT = _fudeNFT;
        fudeToken = _fudeToken;
        priceFeed = _priceFeed;
    }

    function stake(uint256 tokenId) external nonReentrant {
        require(fudeNFT.ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        fudeNFT.transferFrom(msg.sender, address(this), tokenId);

        stakes[msg.sender][tokenId] = StakeInfo(block.timestamp, 0);
        totalStakedNFTs = totalStakedNFTs.add(1);

        emit Staked(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external nonReentrant {
        require(fudeNFT.ownerOf(tokenId) == address(this), "NFT not staked");
        require(stakes[msg.sender][tokenId].stakeTimestamp > 0, "NFT not staked by this user");

        _claimReward(msg.sender, tokenId);

        fudeNFT.transferFrom(address(this), msg.sender, tokenId);

        totalStakedNFTs = totalStakedNFTs.sub(1);
        delete stakes[msg.sender][tokenId];

        emit Unstaked(msg.sender, tokenId);
    }

    function claimReward(uint256 tokenId) external nonReentrant {
        require(fudeNFT.ownerOf(tokenId) == address(this), "NFT not staked");
        require(stakes[msg.sender][tokenId].stakeTimestamp > 0, "NFT not staked by this user");

        _claimReward(msg.sender, tokenId);
    }

    function _claimReward(address user, uint256 tokenId) private {
        uint256 pendingReward = calculateReward(user, tokenId);
        if (pendingReward > 0) {
            fudeToken.transfer(user, pendingReward);
            stakes[user][tokenId].claimedRewards = stakes[user][tokenId].claimedRewards.add(pendingReward);
            emit Claimed(user, tokenId, pendingReward);
        }
    }

    function calculateReward(address user, uint256 tokenId) public view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[user][tokenId];
        if (stakeInfo.stakeTimestamp == 0) {
            return 0;
        }
        uint256 timeStaked = block.timestamp.sub(stakeInfo.stakeTimestamp);
        uint256 minutesStaked = timeStaked.div(60);
        uint256 totalRewards = REWARD_PER_MINUTE.mul(minutesStaked);
        uint256 userRewards = totalRewards.mul(1).div(totalStakedNFTs);

        uint256 pendingReward = userRewards.sub(stakeInfo.claimedRewards);

        return pendingReward;
    }
    
    function getClaimedRewards(address user, uint256 tokenId) public view returns (uint256) {
        return stakes[user][tokenId].claimedRewards;
    }

    function getUnclaimedRewards(address user, uint256 tokenId) public view returns (uint256) {
        return calculateReward(user, tokenId);
    }

    function getTotalRewards(address user, uint256 tokenId) public view returns (uint256) {
        uint256 claimedRewards = getClaimedRewards(user, tokenId);
        uint256 unclaimedRewards = getUnclaimedRewards(user, tokenId);
       return claimedRewards.add(unclaimedRewards);
    }
    
    function adjustedRewardPerMinute() public view returns (uint256) {
        int256 latestPrice = getLatestFudeTokenPrice();
        if (latestPrice > 10 * 10**18) {
            uint256 priceIncrease = uint256(latestPrice - 10 * 10**18).div(10**18);
            uint256 adjustmentFactor = priceIncrease.mul(1).div(10000); // 0.01% per 1 USDT increase
            uint256 adjustedReward = BASE_REWARD_PER_MINUTE.mul(10000 + adjustmentFactor).div(10000);
            return adjustedReward;
        } else {
            return BASE_REWARD_PER_MINUTE;
        }
    }

    function getLatestFudeTokenPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

}


