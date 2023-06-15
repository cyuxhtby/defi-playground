// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface CometInterface {
    function mint() external payable;
    function redeem(uint256 amount) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract LendRedeem is Ownable {
    CometInterface public cToken;

    constructor(address cToken_address) {
        cToken = CometInterface(cToken_address);
    }

    function supplyAssetToCompound() public payable onlyOwner {
        // Amount of current contract's Ether balance
        uint256 balance = address(this).balance;
        // Mint cTokens by supplying Ether to Compound
        cToken.mint{value: balance}();
    }

    function redeemAsset() public onlyOwner {
        // Get the amount of cTokens in the contract
        uint256 amount = cToken.balanceOf(address(this));
        // Redeem the cTokens for the underlying asset
        require(cToken.redeem(amount) == 0, "Failed to redeem cToken");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
