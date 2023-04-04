// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address payable public owner; //owner if the contract
    
    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)){
        owner = payable(msg.sender);
    }
    
    // initiator allows tracking where the loan request came from
    // params allows passing additional data or parameters to the executeOperation function 
    function executeOperation(
        address asset,
        uint256 amount, 
        uint256 premium, 
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

       //operation once loan is received 
        uint256 paramValue = abi.decode(params, (uint256));
        uint256 amountToTransfer = amount + paramValue;

        IERC20(asset).transfer(initiator, amountToTransfer);


        // now return loan plus fee
       uint256 amountOwed = amount + premium;
       IERC20(asset).approve(address(POOL), amountOwed);
       return true;
    }

    //function to request loan of specified amount
    //referral code of zero, part of no campaign 
    function requestFlashLoan(address _token, uint256 _amount) public onlyOwner {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount =  _amount;
        bytes memory params = "";
        uint16 referralCode = 0;
    
        // call the aave lending pool contract and start loan
        POOL.flashLoanSimple(
            receiverAddress, 
            asset,
            amount,
            params,
            referralCode
        );
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));   
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner");
        // The underscore represents the body of the function you are modifying
        _;
    }

    // fallback function to receive ETH payments
    // automatically called whenever the contract receives ETH that was not sent with a specific function call.
    receive() external payable {}






}