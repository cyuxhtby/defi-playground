import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.10",
  networks: {
    hardhat: {},
    mainnet: {
      url: "process.env.INFURA_URL",
      accounts: []
    },
  },
};

export default config;
