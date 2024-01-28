

 
  const { ethers, upgrades } = require("hardhat");

async function main() {
    const PaymentSplitter = await ethers.getContractFactory("PaymentSplitter");
    console.log("Deploying PaymentSplitter...");


    const tropicalSharesAddress = "0xbE733B8dd6F9E72Def716D9F36F154c81f6eF3C7" 
    const pappleAddress = "0xfcf5c02cA529081d65E40C3F770a2123c8300aA4" 
    const usdcAddress = "0x6F971137752B3eD21C23FEf40fa51AdCDc837028" 

    const paymentSplitter = await upgrades.deployProxy(
        PaymentSplitter, 
        [tropicalSharesAddress, pappleAddress, usdcAddress], 
        { initializer: 'initialize' }
    );
   // await paymentSplitter.deployed();
    console.log("PaymentSplitter deployed to:",await  paymentSplitter.getAddress());

    console.log(`to verify type :  npx hardhat verify --network mantleTest ${await paymentSplitter.getAddress()} `)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
