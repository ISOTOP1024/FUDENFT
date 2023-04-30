// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FudeToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 100000000 * 10**18;
    uint256 public constant TARGET_PRICE = 1000 * 10**18;
    uint256 public constant PERCENTAGE_CHANGE = 1;

    AggregatorV3Interface internal priceFeed;

    mapping(address => bool) private _frozenAccounts;

    event FrozenFunds(address target, bool frozen);

    constructor(AggregatorV3Interface _priceFeed) ERC20("FudeToken", "FUDE") {
        _mint(msg.sender, TOTAL_SUPPLY);
        priceFeed = _priceFeed;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        uint256 adjustedAmount = adjustAmount(amount);
        _mint(to, adjustedAmount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        _frozenAccounts[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function isFrozen(address target) public view returns (bool) {
        return _frozenAccounts[target];
    }

    function getLatestPrice() public view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

/********************************************************************************
 *   function adjustAmount(uint256 amount) private view returns (uint256) {
 *       int price = getLatestPrice();
 *       if (price >= int(TARGET_PRICE)) {
 *           return amount.add(amount.mul(PERCENTAGE_CHANGE).div(10000));
 *       } else {
 *           return amount.sub(amount.mul(PERCENTAGE_CHANGE).div(10000));
 *       }
 *   }
 ********************************************************************************/

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!_frozenAccounts[from], "ERC20: token transfer from a frozen address");
        require(!_frozenAccounts[to], "ERC20: token transfer to a frozen address");
        super._beforeTokenTransfer(from, to, amount);
    }
}
