const { ethers } = require("hardhat");
require('dotenv').config()

async function main() {

    //const Pineapple = await ethers.getContractFactory("Pineapple");
    //const pineapple = await Pineapple.deploy();
    //const Usdc = await ethers.getContractFactory("USDC");
    //const usdc = await Usdc.deploy(ethers.utils.parseUnits("10000",6));
    const usdcAddress = "0x6F971137752B3eD21C23FEf40fa51AdCDc837028"
    const pappleAddress ="0xfcf5c02cA529081d65E40C3F770a2123c8300aA4"
    const TropicalLaunchpad = await ethers.getContractFactory("TropicalLaunchpadTest");
    const tropicalLaunchpad = await TropicalLaunchpad.deploy("0xc53e90C93AbADa68C9B2aDfe7e32476A7D6643fa" ,pappleAddress,usdcAddress); 


  //await greeter.deployed();

  
  console.log("Tropical Address", tropicalLaunchpad.address);

  console.log(`run: npx hardhat verify --network ${process.env.HARDHAT_NETWORK} ${tropicalLaunchpad.address} ${pappleAddress} ${usdcAddress} to verify.` );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});