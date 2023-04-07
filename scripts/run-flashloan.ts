import { ethers } from "hardhat";

async function main() {



  const FlashLoan = await ethers.getContractFactory("FlashLoan");
  const flashLoan = await FlashLoan.attach("<FLASH_LOAN_CONTRACT_ADDRESS>");

  const usdcAddress = "0x07865c6e87b9f70255377e024ace6630c1eaa37f"; // USDC address on Goerli testnet
  const amount = ethers.utils.parseUnits("10", 6); // 10 USDC

  console.log(`Executing flash loan with ${amount.toString()} USDC...`);

  const tx = await flashLoan.requestFlashLoan(usdcAddress, amount);
  console.log(`View transaction at: https://goerli.etherscan.io/tx/${tx.hash}`);

  await tx.wait();

  console.log("Flash loan executed successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});