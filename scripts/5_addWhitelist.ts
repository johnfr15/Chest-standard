import hardhat from "hardhat";
import { readFile } from "fs/promises";
import { ethers } from "hardhat";

const FILE_PATH = "./helpers/deployed.json";

async function main() {
  const deployers = await ethers.getSigners();
  const [deployer] = deployers;
  let tx, receipt, contracts;
  let whitelist = [];

  console.log("Deployer: ", deployer.address);
  console.log("balance: ", ethers.utils.formatEther(await deployer.getBalance()), "MATIC");

  try {
    contracts = JSON.parse(await readFile(FILE_PATH, "utf-8"));
  } catch (error: any) {
    console.log(error.message);
  }

  const chest = await ethers.getContractAt("Chest", contracts.Chest[hardhat.network.name].address, deployer);

  // Add addresses to whitelist and the type of the token
  whitelist.push(contracts.ChestERC20[hardhat.network.name].address);
  whitelist.push(contracts.ChestERC721[hardhat.network.name].address);
  whitelist.push(contracts.ChestERC1155[hardhat.network.name].address);

  console.log("whitelisting =>", whitelist, "...");
  tx = await chest.addWhitelist(whitelist);
  receipt = await tx.wait();
  console.log("Whitelisted sucessfully !");
  console.log(`\nSee tx: https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
