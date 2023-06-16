// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

// Aave's flashLoanSimple() allows borrower to access liquidity of single reserve for the transaction.
// In this case flash loan fee is not waived nor can borrower open any debt position at the end of the transaction.
// This method is gas efficient for those trying take advantage of simple flash loan with single reserve asset.

contract SimpleFlashLoan is FlashLoanSimpleReceiverBase {
    address payable owner;

    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {}

    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        ); 
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool){

        // Funded operation 

        // Return funds
        uint256 totalAmount = amount + premium;
        IERC20(asset).approve(address(POOL), totalAmount);

        // Do nothing with the parameters
        initiator = initiator;
        params = params;

        return true;
    }

    receive() external payable {} 

}