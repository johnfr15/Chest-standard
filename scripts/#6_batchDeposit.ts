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
  const erc20 = await ethers.getContractAt("ChestERC20", contracts.ChestERC20[hardhat.network.name].address, deployer);
  const erc721 = await ethers.getContractAt("ChestERC721", contracts.ChestERC721[hardhat.network.name].address, deployer);
  const erc1155 = await ethers.getContractAt("ChestERC1155", contracts.ChestERC1155[hardhat.network.name].address, deployer);

  // Approving our 3 differents token to our chest to be able to deposit them.
  console.log(`Approving 1000000 ERC20 (${erc20.address}) to chest...`);
  tx = await erc20.approve(chest.address, ethers.utils.parseEther("1000000"));
  await tx.wait();
  console.log("Approved successfully !\n");

  console.log(`Approving all of your ERC721 (${erc721.address}) ids to chest...`);
  tx = await erc721.setApprovalForAll(chest.address, true);
  await tx.wait();
  console.log("Approved successfully !\n");  

  console.log(`Approving all of your ERC1155 (${erc1155.address}) ids to chest...`);
  tx = await erc1155.setApprovalForAll(chest.address, true);
  await tx.wait();
  console.log("Approved successfully !\n");  

  // As we are depositing 6 tokens we need to set up the 3 parameters needed for the function
  // 1. An array of addresses
  // 2. An array of ids
  // 3. An array of amounts
  tokens.push(contracts.ChestERC20[hardhat.network.name].address);
  ids.push(0);
  amounts.push(ethers.utils.parseEther("12345"));
  
  tokens.push(contracts.ChestERC721[hardhat.network.name].address);
  ids.push(0);
  amounts.push(1);
  
  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(0);
  amounts.push(1);
    
  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(1);
  amounts.push(10);

  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(2);
  amounts.push(100);

  tokens.push(contracts.ChestERC1155[hardhat.network.name].address);
  ids.push(3);
  amounts.push(1000);

  console.log(
    `Batch depositing token:
    ChestERC20 => Address: ${tokens[0]} id: ${ids[0]} amounts: ${amounts[0]}
    Chest721 => Address: ${tokens[1]} id: ${ids[1]} amounts: ${amounts[1]}
    Chest1155 => Address: ${tokens[2]} id: ${ids[2]} amounts: ${amounts[2]}
    Chest1155 => Address: ${tokens[3]} id: ${ids[3]} amounts: ${amounts[3]}
    Chest1155 => Address: ${tokens[4]} id: ${ids[4]} amounts: ${amounts[4]}
    Chest1155 => Address: ${tokens[5]} id: ${ids[5]} amounts: ${amounts[5]}
    `
  );

  tx = await chest.batchDeposit(tokens, ids, amounts);
  receipt = await tx.wait();
  console.log("Tokens Deposited sucessfully !");
  console.log(`\nSee tx: https://mumbai.polygonscan.com/tx/${receipt.transactionHash}`)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
