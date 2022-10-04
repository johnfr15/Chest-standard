import hardhat from "hardhat";
import { readFile } from "fs/promises";
import { ethers } from "hardhat";

const FILE_PATH = "./helpers/deployed.json";

async function main() {
  const deployers = await ethers.getSigners();
  const [deployer] = deployers;
  let contracts;

  try {
    contracts = JSON.parse(await readFile(FILE_PATH, "utf-8"));
  } catch (error: any) {
    console.log(error.message);
  }

  const chest = await ethers.getContractAt("Chest", contracts.Chest[hardhat.network.name].address, deployer);

  console.log("Tokens in chest\n");
  const loots = await chest.look();
  console.log("items: ", loots.items)
  console.log("tokenIds: ", loots.tokenIds)
  console.log("amounts: ", loots.amounts)
  console.log("type_: ", loots.type_)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
