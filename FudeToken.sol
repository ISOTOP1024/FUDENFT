// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FudeToken is ERC20, Ownable {

    constructor() ERC20("Fude Token", "FUDE") {
        _mint(msg.sender, 100000000 * 10**18);
    }


    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
