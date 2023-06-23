import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import dotenv from "dotenv";

const result = dotenv.config();

if (result.error) {
  throw result.error;
}

const config: HardhatUserConfig = {
  solidity: "0.8.10",
  networks: {
    hardhat: {},
    sepolia: {
      url: process.env.INFURA_URL, 
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
};

export default config;
