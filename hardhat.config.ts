import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import * as dotenv from 'dotenv';

dotenv.config();

//console.log(process.env)

let privateKey1 = process.env.ACCOUNT_PRIVATE_KEY1;
let privateKey2 = process.env.ACCOUNT_PRIVATE_KEY2;
let privateKey3 = process.env.ACCOUNT_PRIVATE_KEY3;
let privateKey4 = process.env.ACCOUNT_PRIVATE_KEY4;
let privateKey5 = process.env.ACCOUNT_PRIVATE_KEY5;
let etherscanKey = process.env.apiKey;


const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
              version: "0.8.2",
            },
          
          ],
        },
     // solidity version
    defaultNetwork: "mantleTest",
    networks: {
        mantle: {
        url: "https://rpc.mantle.xyz", //mainnet
        accounts: [privateKey1,privateKey2,privateKey3,privateKey4,privateKey5],
        },
        mantleTest: {
        url: "https://rpc.testnet.mantle.xyz", // testnet
        accounts: [privateKey1,privateKey2,privateKey3,privateKey4,privateKey5]
        }
    },
    etherscan: {
        apiKey: "CFIP3IHXHPRCGS9KT6RSJKKAXBKQCHP51C",
        customChains: [
            {
                network: "mantleTest",
                chainId: 5001,
                urls: {
                apiURL: "https://explorer.testnet.mantle.xyz/api",
                browserURL: "https://explorer.testnet.mantle.xyz"
                }
            }
        ]
    },
};
export default config;