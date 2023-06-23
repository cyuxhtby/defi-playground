import { ethers } from "hardhat";

async function main() {

  console.log("Script started");

  const FlashLoan = await ethers.getContractFactory("FlashLoan");
  console.log("Contract factory obtained");

  const flashLoan = FlashLoan.attach("0x3F4fD9888DAA2A437123Dfa6D0ae4Bb2Fe1EE18b");

  // Sepolia testnet mintable token addresses
  const usdcAddress = "0xda9d4f9b69ac6C22e444eD9aF0CfC043b7a7f53f";
  const daiAddress = "0x68194a729C2450ad26072b3D33ADaCbcef39D574";
  const usdtAddress = "0x0Bd5F04B456ab34a2aB3e9d556Fe5b3A41A0BC8D";
  const amount = ethers.utils.parseUnits("10", 6); // 10 USDC

  // Set token addresses in the FlashLoan contract
  await flashLoan.setTokenAddress("DAI", daiAddress);
  await flashLoan.setTokenAddress("USDT", usdtAddress);

  // Listen for BalanceUpdate events from the contract
  flashLoan.on("BalanceUpdate", (tokenSymbol, tokenAddress, balance) => {
    console.log(`Balance Update - Token Symbol: ${tokenSymbol}, Token Address: ${tokenAddress}, Balance: ${ethers.utils.formatUnits(balance, 6)}`);
  });

  console.log(`Executing flash loan with ${amount.toString()} USDC...`);

  // Request a flash loan
  const tx = await flashLoan.requestFlashLoan(usdcAddress, amount, {
    gasLimit: 3000000,
  });
  console.log(`Transaction sent: https://explorer.sepolia.aave.com/tx/${tx.hash}`); // Sepolia explorer

  // Wait for the transaction to be mined
  const receipt = await tx.wait();
  console.log(`Transaction confirmed in block ${receipt.blockNumber}`);

  console.log("Flash loan executed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
