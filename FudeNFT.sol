// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FudeToken.sol";

contract FudeNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    FudeToken private fudeToken;
    uint256 public mintedNFTs;
    address payable public withdrawalAddress; // 设置收款地址
    string private _baseTokenURI;
    bool public isRevealed = false;

    constructor(
        string memory baseTokenURI_,
        address fudeTokenAddress,
        address payable withdrawalAddress_
    ) ERC721("Fude NFT", "FUDE") {
        _baseTokenURI = baseTokenURI_;
        fudeToken = FudeToken(fudeTokenAddress);
        withdrawalAddress = withdrawalAddress_;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
        mintedNFTs += 1;
        if (mintedNFTs > 200 && mintedNFTs % 10 == 0) {
            withdrawFunds();
        }
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if (!isRevealed) {
            return baseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) {
            uint256 fudeTokenBalance = fudeToken.balanceOf(to);
            require(fudeTokenBalance >= 10**17, "Not enough FudeToken to transfer NFT"); // 0.1 FudeToken

            fudeToken.burnFrom(to, 10**17); // 消耗0.1 FudeToken
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawFunds() private {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            withdrawalAddress.transfer(balance);
        }
    }
}

