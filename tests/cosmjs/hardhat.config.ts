import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
    },
    acorndev: {
      url: "https://jsonrpc.dev.acornchain.org",
    }
  }
};

export default config;
