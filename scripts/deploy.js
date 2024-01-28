const hre = require("hardhat");

async function main() {
  const signers = await hre.ethers.getSigners();
  const deployer = signers[0]; // Utiliser le premier compte pour le déploiement
  const papple = "0xfcf5c02cA529081d65E40C3F770a2123c8300aA4"
  const usdc = "0x6F971137752B3eD21C23FEf40fa51AdCDc837028"
  console.log("Deploying contracts with the account:", deployer.address);

  // Déployer le contrat TropicalShares
  console.log("deploying TropicalShares" )
  const TropicalShares = await hre.ethers.getContractFactory("TropicalShares");
  console.log('tropicalShares getContractFactory')
  const tropicalShares = await TropicalShares.deploy();
  console.log("deploy")
  //await tropicalShares.deployed();
  console.log("TropicalShares deployed to:", await tropicalShares.getAddress());
 
  // Déployer le contrat DAO
  const DAO = await hre.ethers.getContractFactory("TropicalDAO");
  const dao = await DAO.deploy(tropicalShares.getAddress(), papple, usdc);
  //const dao = await DAO.deploy();
  //await dao.deployed();
  console.log("DAO deployed to:", await dao.getAddress());


  // Déployer le contrat TropicalVault
  const TropicalVault = await hre.ethers.getContractFactory("TropicalVault");
  const tropicalVault = await TropicalVault.deploy(tropicalShares.getAddress(),papple);
  //await tropicalVault.deployed();
  console.log("TropicalVault deployed to:",await tropicalVault.getAddress());
  

  // Déployer le contrat PaymentSplitter
  const PaymentSplitter = await hre.ethers.getContractFactory("PaymentSplitter");
  const paymentSplitter = await PaymentSplitter.deploy(tropicalShares.getAddress(), papple, usdc);
  //await paymentSplitter.deployed();
  console.log("PaymentSplitter deployed to:", await paymentSplitter.getAddress());

  console.log(`Verify TropicalShares with : npx hardhat verify --network mantleTest ${await tropicalShares.getAddress()}`)
  console.log(`Verify DAO with : npx hardhat verify --network mantleTest ${await dao.getAddress()} ${await tropicalShares.getAddress()} ${papple} ${usdc}`)
  console.log(`Verify Vault with : npx hardhat verify --network mantleTest ${await tropicalVault.getAddress()} ${await tropicalShares.getAddress()} ${papple}`)
  console.log(`Verify paymentsplitter with : npx hardhat verify --network mantleTest ${await paymentSplitter.getAddress()} ${await tropicalShares.getAddress()} ${papple} ${usdc}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
