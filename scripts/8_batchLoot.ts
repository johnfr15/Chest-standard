import hardhat from "hardhat";
import { readFile } from "fs/promises";
import { ethers } from "hardhat";

const FILE_PATH = "./helpers/deployed.json";

async function main() {
  const deployers = await ethers.getSigners();
  const [deployer] = deployers;
  let tx, receipt, contracts;
  let tokens = [];
  let ids = [];
  let amounts = [];

  console.log("Deployer: ", deployer.address);
  console.log("balance: ", ethers.utils.formatEther(await deployer.getBalance()), "MATIC\n");

  try {
    contracts = JSON.parse(await readFile(FILE_PATH, "utf-8"));
  } catch (error: any) {
    console.log(error.message);
  }

  const chest = await ethers.getContractAt("Chest", contracts.Chest[hardhat.network.name].address, deployer);

  // As we are looting 4 tokens we need to set up the 3 parameters needed for the function
  // 1. An array of addresses
  // 2. An array of ids
  // 3. An array of amounts
  tokens.push(contracts.ChestERC20[hardhat.network.name].address);
  ids.push(0);
  amounts.push(ethers.utils.parseEther("45"));
  
  tokens.push(contracts.ChestERC721[hardhat.network.name].address);
  ids.push(0);
  amounts.push(1);
    
  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(1);
  amounts.push(10);

  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(3);
  amounts.push(1000);

  console.log(
    `Batch looting token:
    ChestERC20 => Address: ${tokens[0]} id: ${ids[0]} amounts: ${amounts[0]}
    Chest721 => Address: ${tokens[1]} id: ${ids[1]} amounts: ${amounts[1]}
    Chest1155 => Address: ${tokens[2]} id: ${ids[2]} amounts: ${amounts[2]}
    Chest1155 => Address: ${tokens[3]} id: ${ids[3]} amounts: ${amounts[3]}
    `
  );
  const looted = await chest.callStatic.batchLoot(tokens, ids, amounts);
  tx = await chest.batchLoot(tokens, ids, amounts);
  receipt = await tx.wait();
  console.log("Tokens Looted sucessfully !");
  console.log(`\nSee tx: https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`)

  console.log("Looted:\n");
  console.log("items: ", looted.items_);
  console.log("tokenIds: ", looted.tokenIds_);
  console.log("amounts: ", looted.amounts_);
  console.log("type_: ", looted.type_);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
