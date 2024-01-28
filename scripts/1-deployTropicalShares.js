const { ethers, upgrades } = require("hardhat");

async function main() {
    const TropicalShares = await ethers.getContractFactory("TropicalShares");
    console.log("Deploying TropicalShares...");

    const tropicalShares = await upgrades.deployProxy(TropicalShares, [], { initializer: 'initialize' });
    //await tropicalShares.deployed();
    console.log("TropicalShares deployed to:", await tropicalShares.getAddress());
    console.log(`to verify type :  npx hardhat verify --network mantleTest ${await tropicalShares.getAddress()} `)
    
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
