import hardhat from "hardhat";
import { ethers } from "hardhat";
import { deployed } from "../lib/deployed";

async function main() {
  try {
    const deployers = await ethers.getSigners();
    const [deployer] = deployers;
    let tx, receipt;
  
    console.log("Deployer: ", deployer.address);
    console.log("balance: ", ethers.utils.formatEther(await deployer.getBalance()), "MATIC\n");
    
    // Deploying token
    console.log("Deploying ERC20...")
    const ERC20 = await ethers.getContractFactory("ChestERC20", deployer);
    const erc20 = await ERC20.deploy();
    await erc20.deployed();
    
    // Store address in file "./helpers/deployed.json"
    await deployed("ChestERC20", hardhat.network.name, erc20.address);

    console.log(`\nSee contract: https://mumbai.polygonscan.com/address/${erc20.address}`)

    // Mint 10 token
    console.log(`\nMinting 1000000 tokens to ${deployer.address}...`);
    tx = await erc20.mint(ethers.utils.parseEther("1000000"));
    receipt = await tx.wait();
    console.log("Tokens minted sucessfully !");
    console.log(`\nSee tx: https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`)

  } catch (error: any) {
    console.log(error.message);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
