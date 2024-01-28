const { ethers, upgrades } = require("hardhat");

async function main() {
    const TropicalLaunchpad = await ethers.getContractFactory("TropicalLaunchpad");
    console.log("Deploying TropicalLaunchpad...");

    // Remplacez ces valeurs par les adresses réelles nécessaires pour votre fonction initialize
    const walletAddress = "0xa1a44A4130DAD46483d9881F04c12ffFc7E1C61F"; // vault proxy Address
    const pappleTokenAddress = "0xfcf5c02cA529081d65E40C3F770a2123c8300aA4"; // Adress Papple token 
    const usdcTokenAddress = "0x6F971137752B3eD21C23FEf40fa51AdCDc837028"; // token USDC

    const tropicalLaunchpad = await upgrades.deployProxy(
        TropicalLaunchpad, 
        [walletAddress, pappleTokenAddress, usdcTokenAddress], 
        { initializer: 'initialize' }
    );
    //await tropicalLaunchpad.deployed();
    console.log("TropicalLaunchpad deployed to:", await tropicalLaunchpad.getAddress());
    console.log(`to verify type :  npx hardhat verify --network mantleTest ${await tropicalLaunchpad.getAddress()} `)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });