import {ethers} from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contract with this address: ", deployer.address);

    const addressProviderAddress = '0xC911B590248d127aD18546B186cC6B324e99F02c'; // Goerli address

    const SimpleFlashLoan = await ethers.getContractFactory("SimpleFlashLoan");
    const simpleFlashLoan = await SimpleFlashLoan.deploy(addressProviderAddress);
    await simpleFlashLoan.deployed();

    console.log("SimpleFlashLoan deployed to: ", simpleFlashLoan.address);


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });