const { ethers, upgrades } = require("hardhat");

async function main() {
  const signers = await hre.ethers.getSigners();
  const deployer = signers[0]; // Utiliser le premier compte pour le déploiement
  const pappleAddress = "0xfcf5c02cA529081d65E40C3F770a2123c8300aA4"
  const tropicalSharesAddress = "0xbE733B8dd6F9E72Def716D9F36F154c81f6eF3C7"
  console.log("Deploying contracts with the account:", deployer.address);

 
  // Déployer le contrat PaymentSplitter
  const TropicalVault = await ethers.getContractFactory("TropicalVault");
    const tropicalVault = await upgrades.deployProxy(TropicalVault, [tropicalSharesAddress, pappleAddress], { kind: 'uups' });
    //await tropicalVault.deployed();
    console.log("TropicalVault deployed to:", await tropicalVault.getAddress());
    console.log(`to verify type :  npx hardhat verify --network mantleTest ${await tropicalVault.getAddress()} `)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
