// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;
pragma abicoder v2;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract SimpleSwap {
    ISwapRouter public immutable swapRouter;
    
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    uint24 public constant poolFee = 3000; // 0.3% pool fee

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @notice swapUSDCforDAI swaps a fixed amount of USDC for a maximum possible amount of DAI
    /// using the USDC/DAI 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its USDC for this function to succeed.
    /// @param amountIn The exact amount of USDC that will be swapped for DAI.
    /// @return amountOut The amount of DAI received.
    function swapUSDCforDAI(uint256 amountIn) external returns (uint256 amountOut) {
        // Transfer the specified amount of USDC to this contract.
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountIn);

        // Approve the router to spend USDC.
        TransferHelper.safeApprove(USDC, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: DAI,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }
}
