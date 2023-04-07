import {ethers} from "hardhat";
import '@nomiclabs/hardhat-ethers';


const AVAX_FUJI_POOL_PROVIDER: string = "0x220c6A7D868FC38ECB47d5E69b99e9906300286A";
const USDC_ADDRESS: string = "0x6a17716Ce178e84835cfA73AbdB71cb455032456";
const USDC_DECIMALS: number = 6;
const FLASHLOAN_AMOUNT: ethers.BigNumber =  ethers.utils.parseUnits("1000", USDC_DECIMALS);

// USDC transfer function ABI
const USDC_ABI = ["function transfer(address to, uint256 value) external returns (bool)"];

async function main(): Promise<void>{
  try{
    console.log(`Requesting flashloan of ${FLASHLOAN_AMOUNT/1e6} USDC...`);

  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  }
}

main();