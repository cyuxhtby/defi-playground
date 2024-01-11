// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IGhoToken} from './interfaces/IGhoToken.sol';
import {IGhoFlashMinter} from './interfaces/IGhoFlashMinter.sol';

// This contract allows for the initialization of a flashloan from aave's GhoFlashMinter 
// GhoFlashMinter will then call the onFlashLoan function of this demo contract to log the amount borrowed

contract FlashMint is IERC3156FlashBorrower{

    IGhoFlashMinter public flashMinter;
    IGhoToken public immutable GHO_TOKEN;
    address public owner;

    event FlashLoanReceived(address token, uint256 amount, uint256 fee);

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /**
    * @param ghoFlashMinter The address of the GhoFlashMinter contract
    * @param ghoToken The address of the GHO token contract
    */
    constructor(address ghoFlashMinter, address ghoToken){
        flashMinter = IGhoFlashMinter(ghoFlashMinter);
        GHO_TOKEN = IGhoToken(ghoToken);
        owner = msg.sender;
    }

    function onFlashLoan(
        address /* initiator */,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata /* data */
    ) external override returns (bytes32) {
        require(address(flashMinter) == msg.sender, 'FlashMint: Loan must come from GhoFlashMinter');
        require(token == address(GHO_TOKEN), 'FlashMint: Token must be GHO');

        emit FlashLoanReceived(token, amount, fee);

        // repay loan plus the fee (contract must have some initial GHO to cover fee)
        require(GHO_TOKEN.transfer(address(flashMinter), amount + fee), 'FlashMint: Repayment failed');

        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }
    
    // 'this' returns the type of this contract which is `IERC3156FlashBorrower`
    function initiateFlashLoan(uint256 amount) external {
        address token = address(GHO_TOKEN);
        bytes memory data = '';
        flashMinter.flashLoan(this, token, amount, data);
    }

    function ghoBalance() external view returns (uint256) {
        return GHO_TOKEN.balanceOf(address(this));
    }

     function withdrawGho(uint256 amount) external onlyOwner {
        require(GHO_TOKEN.balanceOf(address(this)) >= amount, "FlashMint: Insufficient GHO balance");
        require(GHO_TOKEN.transfer(msg.sender, amount), "FlashMint: GHO withdrawal failed");
    }
}