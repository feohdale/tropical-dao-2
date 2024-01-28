

  const { ethers, upgrades } = require("hardhat");

  async function main() {
      const TropicalDAO = await ethers.getContractFactory("TropicalDAO");
      console.log("Deploying TropicalDAO...");
  
      // Remplacez ces valeurs par les adresses réelles nécessaires pour votre fonction initialize
      const tropicalSharesAddress = "0xbE733B8dd6F9E72Def716D9F36F154c81f6eF3C7"; // Adresse du contrat TropicalShares
      const pappleTokenAddress = "0xfcf5c02cA529081d65E40C3F770a2123c8300aA4"; // Adresse du token Papple
      const usdcTokenAddress = "0x6F971137752B3eD21C23FEf40fa51AdCDc837028"; // Adresse du token USDC
  
      const tropicalDAO = await upgrades.deployProxy(
          TropicalDAO, 
          [tropicalSharesAddress, pappleTokenAddress, usdcTokenAddress], 
          { initializer: 'initialize' }
      );
      //await tropicalDAO.deployed();
      console.log("TropicalDAO deployed to:", await tropicalDAO.getAddress());
      console.log(`to verify type :  npx hardhat verify --network mantleTest ${await tropicalDAO.getAddress()} `)
  }
  
  main()
      .then(() => process.exit(0))
      .catch(error => {
          console.error(error);
          process.exit(1);
      });
  