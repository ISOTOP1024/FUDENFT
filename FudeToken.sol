// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/extensions/BEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract FudeToken is BEP20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _frozenAccounts;

    constructor() BEP20("FudeToken", "FUDE") {
        _mint(msg.sender, 100000000 * 10**decimals()); // Mint 100 million tokens to the deployer
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function freezeAccount(address account) external onlyOwner {
        _frozenAccounts.add(account);
    }

    function unfreezeAccount(address account) external onlyOwner {
        _frozenAccounts.remove(account);
    }

    function isAccountFrozen(address account) public view returns (bool) {
        return _frozenAccounts.contains(account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!isAccountFrozen(from), "Token transfer from a frozen account is not allowed");
        require(!isAccountFrozen(to), "Token transfer to a frozen account is not allowed");
    }

    // Any additional functionality specific to FudeToken should go here
}
