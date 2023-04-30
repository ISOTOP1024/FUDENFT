// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FudeToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant TOTAL_SUPPLY = 100000000 * 10**18;

    mapping(address => bool) private _frozenAccounts;

    event FrozenFunds(address target, bool frozen);

    constructor() ERC20("FudeToken", "FUDE") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!_frozenAccounts[from], "ERC20: token transfer from a frozen address");
        require(!_frozenAccounts[to], "ERC20: token transfer to a frozen address");
        super._beforeTokenTransfer(from, to, amount);
    }
}
