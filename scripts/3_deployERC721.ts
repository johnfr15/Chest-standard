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
    console.log("Deploying ERC721...");
    const ERC721 = await ethers.getContractFactory("ChestERC721", deployer);
    const erc721 = await ERC721.deploy("chestNFT", "CHESTNFT");
    await erc721.deployed();
    
    // Store address in file "./helpers/deployed.json"
    await deployed("ChestERC721", hardhat.network.name, erc721.address);

    console.log(`\nSee contract: https://mumbai.polygonscan.com/address/${erc721.address}`);

    // Mint token id 0
    console.log(`\nMinting token id "0" to ${deployer.address}...`);
    tx = await erc721.safeMint(deployer.address, "");
    receipt = await tx.wait();
    console.log("Token minted sucessfully !");
    console.log(`\nSee tx: https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`);

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
