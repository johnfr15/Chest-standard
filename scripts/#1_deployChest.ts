import hardhat from "hardhat";
import { ethers } from "hardhat";
import { deployed } from "../lib/deployed";

async function main() {
  const deployers = await ethers.getSigners()
  const [deployer] = deployers

  console.log("Deployer: ", deployer.address)
  console.log("balance: ", ethers.utils.formatEther(await deployer.getBalance()), "MATIC\n")

  console.log("Deploying chest...");
  const Chest = await ethers.getContractFactory("Chest", deployer)
  const chest = await Chest.deploy("My beautiful chest", "gw3s")
  await chest.deployed()

  await deployed("Chest", hardhat.network.name, chest.address);

  console.log(`\nSee contract: https://mumbai.polygonscan.com/address/${chest.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
