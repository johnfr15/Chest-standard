import { readFile, writeFile } from "fs/promises";
import chalk from "chalk";

const FILE_PATH = './helpers/deployed.json';
/*
  This function should be called after a successuf deployment in your scripts.
  It will create/update a file named deployed.json containing deployment informations of your smart contracts.
  DO NOT EDIT deployed.json MANUALLY, this is an automatically generated file.
*/
export const deployed = async (contractName: string, networkName: string, address: string): Promise<void> => {
  console.log(chalk.green.bold(`${contractName} deployed on ${networkName} at ${address}`));
  console.log(chalk.green(`updating ${FILE_PATH} with ${contractName} on ${networkName} at ${address}`));
  // Open and Read current FILE_PATH if exists
  let jsonString: string = '';
  let obj: {[key: string]: Object} = {};
  try {
    jsonString = await readFile(FILE_PATH, 'utf-8');
    obj = JSON.parse(jsonString);
  } catch (e) {
    // If does not exist, do nothing
  }
  const _addrObj: {[key: string]: string} = {};
  const _chainObj: {[key: string]: Object} = {};
  let _networksObj: {[key: string]: Object} = {};

  _addrObj.address = address;
  _chainObj[networkName] = _addrObj;
  _networksObj = { ...obj[contractName], ..._chainObj };
  obj[contractName] = _networksObj;
  
  jsonString = JSON.stringify(obj);

  try {
    await writeFile(FILE_PATH, jsonString);
  } catch (e: any) {
    console.log(e.message);
    throw e;
  }
};
