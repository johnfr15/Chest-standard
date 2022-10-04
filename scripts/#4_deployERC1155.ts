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
    console.log("Deploying ERC1155...")
    const ERC1155 = await ethers.getContractFactory("ChestERC1155", deployer);
    const erc1155 = await ERC1155.deploy();
    await erc1155.deployed();
  
    // Store address in file "./helpers/deployed.json"
    await deployed("ChestERC1155", hardhat.network.name, erc1155.address);

    console.log(`\nSee contract: https://mumbai.polygonscan.com/address/${erc1155.address}`)

    // Mint token id 0, 1, 2, 3
    console.log(`\nMinting token id "0, 1, 2, 3" to ${deployer.address}...`);
    tx = await erc1155.mintBatch(deployer.address, [0, 1, 2, 3], [1, 10, 100, 1000], "0x");
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
