// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {FlashLoanReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract FlashLoan is FlashLoanReceiverBase {
    address payable public owner; //owner if the contract
    
    constructor(address _addressProvider) FlashLoanReceiverBase(IPoolAddressesProvider(_addressProvider)){
        owner = payable(msg.sender);
    }
    
    // initiator allows tracking where the loan request came from
    // params allows passing additional data or parameters to the executeOperation function 
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {

       //operation once loan is received 
        uint256 paramValue = abi.decode(params, (uint256));
        uint256 amountToTransfer = amount + paramValue;

        IERC20(asset).transfer(initiator, amountToTransfer);

        //swap USDC to DAI
        address[] memory path1 = new address[](2);
        path1[0] = asset;
        path1[1] = 0x3B19a8FAa70D2db7BDd9a3ff4c4FD4B116b41D3F; //DAI address
        uint[] memory amounts1 = IUniswapV2Router02(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984).swapExactTokensForTokens(amountToTransfer, 0, path1, address(this), block.timestamp);

        //swap DAI to Tether
        address[] memory path2 = new address[](2);
        path2[0] = 0x3B19a8FAa70D2db7BDd9a3ff4c4FD4B116b41D3F; //DAI address
        path2[1] = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9; //Tether address
        uint[] memory amounts2 = IUniswapV2Router02(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984).swapExactTokensForTokens(amounts1[1], 0, path2, address(this), block.timestamp);

        //swap Tether to USDC
        address[] memory path3 = new address[](2);
        path3[0] = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9; //Tether address
        path3[1] = asset;
        uint[] memory amounts3 = IUniswapV2Router02(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984).swapExactTokensForTokens(amounts2[1], 0, path3, address(this), block.timestamp);

        // now return loan plus fee
       uint256 amountOwed = amounts3[1] + premium;
       require(IERC20(asset).approve(address(POOL), amountOwed), "Token approval failed");
       require(IERC20(asset).transfer(address(POOL), amountOwed), "Token transfer failed");
       return true;
    }

    // function to request loan of specified amount
    // modes passes in type of debt position to open if loan is not returned, pass in 0 for no debt
    // onBehalfOf delegates the incurred debt if mode is not 0
    // referral code of zero, part of no campaign 
    function requestFlashLoan(address _token, uint256 _amount) public onlyOwner {
        address receiverAddress = address(this);
        address[] memory assets = new address[](1);
        assets[0] = _token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;
    
        // call the aave lending pool contract and start loan
        POOL.flashLoan(
            receiverAddress, 
            assets,
            amounts,
            modes,
            onBehalfOf,
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