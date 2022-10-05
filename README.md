# Chest standard

This is a reference implementation of the **Chest** standard *(AKA loot box)*.

## Installation

1. Clone this repo:
```console
git clone https://github.com/Gotchi-web3-school/Chest-standard.git
```

2. Install NPM packages:
```console
cd Chest-standard
npm install
```

3. Insert your wallet private key
*/.env*
```
DEPLOYER_PRIVATE_KEY = // Input your key
```

## Deployment

**Note:** Once the installation is done in the following deployment you will 
1. Deploy a chest & some tokens.
2. Deposit them in the chest.
3. Withdraw (loot) them.
Those will occur into 8 steps as follow.

### STEP 1: deploy Chest.sol
*/contracts/Chest/Chest.sol* 

In the first step we will simply deploy the chest on mumbai network.

```console
npx hardhat --network mumbai run scripts/1_deployChest.ts
```

You should now be able to see this on your console to see your chest on mumbai network.
```
Deploying chest...
Chest deployed on mumbai at 0xc4072a54ede62bf252D394DB1f7eaE01DeFa7030
updating ./helpers/deployed.json with Chest on mumbai at 0xc4072a54ede62bf252D394DB1f7eaE01DeFa7030

See contract: https://mumbai.polygonscan.com/address/0xc4072a54ede62bf252D394DB1f7eaE01DeFa7030
```

### STEP 2 -> 3 -> 4: deploy some tokens
*/contracts/Chest/Tokens.sol* 

In order to check all the potential of the chest smart contract let's also deploy & mint some 
- ERC20 token
- ERC721 token
- ERC1155 token

2. 
```console
npx hardhat --network mumbai run scripts/2_deployERC20.ts
```

3. 
```console
npx hardhat --network mumbai run scripts/3_deployERC721.ts
```

4. 
```console
npx hardhat --network mumbai run scripts/4_deployERC1155.ts
```

**Note:** You can see the deployed address in that file `./helpers/deployed.json` at any time 

### STEP 5: Whitelist the deployed token to be stored in chest
*/contracts/Chest/extensions/ChestHolder.sol*  
`function addWhiteList(address[] memory tokens, uint8[] memory tokenType_) external`

Now that we are all set having our tokens and chest deployed, we will need to whitelist our recent deployed token's address to the chest
so we can deposit them into it.  

**Note:** When a chest is deployed nothing can go inside this will be the very first step after the deployment.
Whitelisting token is important in order to avoid malicious tokens enter the chest.
**Note:** Only the owner of the chest can whitelist.

```console
npx hardhat --network mumbai run scripts/5_addWhitelist.ts
```

### STEP 6: Deposit tokens
*/contracts/Chest/Chest.sol*  
`function batchDeposit(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external virtual returns(bool success) `

Well now that our tokens are whitelist let's deposit them into the chest !  
**Note** Only the owner of the chest can deposit.
**Note** The chest smart contract needs to be approved to make the deposti.

```console
npx hardhat --network mumbai run scripts/6_batchDeposit.ts
```

You should now be able to see the tx on your console.
```
Batch depositing token:
    ChestERC20 => Address: 0xefec9dfdB33E1Ca06eBf70715fAeE74a53B1B182 id: 0 amounts: 12345000000000000000000
    Chest721 => Address: 0x011Ae6E8B3a3d428B3927428F995a28FC2b211A9 id: 0 amounts: 1
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 0 amounts: 1
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 1 amounts: 10
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 2 amounts: 100
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 3 amounts: 1000
    
Tokens Deposited sucessfully !

See tx: https://mumbai.polygonscan.com/tx/0xc5eefd3a5bf3dcf1cfd9a185f4da7a24b45444b8fd1d96698d7d668f5b01bfa9
```

### STEP 7: Look what's in the chest
*/contracts/Chest/Chest.sol*  
`function look() external view returns (address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts, uint8[] memory type_)`

Everyone can now see what is in the chest.  

```console
npx hardhat --network mumbai run scripts/7_look.ts
```

You should see the following output on your console with of course different addresses.
**Note:** The following output is a standardized information output, it will always give an object ordered that way.
It will be easier to interact with more chests for futur smart contract integration.

```
Tokens in chest

items:  [
  '0xefec9dfdB33E1Ca06eBf70715fAeE74a53B1B182',
  '0x011Ae6E8B3a3d428B3927428F995a28FC2b211A9',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853'
]
tokenIds:  [
  BigNumber { value: "0" },
  BigNumber { value: "0" },
  BigNumber { value: "0" },
  BigNumber { value: "1" },
  BigNumber { value: "2" },
  BigNumber { value: "3" }
]
amounts:  [
  BigNumber { value: "12345000000000000000000" },
  BigNumber { value: "1" },
  BigNumber { value: "1" },
  BigNumber { value: "10" },
  BigNumber { value: "100" },
  BigNumber { value: "1000" }
]
type_:  [ 1, 2, 3, 3, 3, 3 ]
```

### STEP 8: Loot tokens
*/contracts/Chest/Chest.sol*  
`function loot(address item, uint256 tokenId, uint256 amount) external virtual returns (address[] memory items, uint256[] memory, tokenIds, uint256[] memory amounts, uint8[] memory type_)`  
`function batchLoot(address[] memory items, uint256[] memory tokenIds, uint256[] memory amounts) external virtual returns(address[] memory items_, uint256[] memory tokenIds_, uint256[] memory amounts_, uint8[] memory type_)`

Good job if you arrived that far this will be the last step (and the most funny one 🥳) let's loot partially the chest 🥷  

**Note** Everyone can loot any amounts of items in the chest.

```console
npx hardhat --network mumbai run scripts/8_batchLoot.ts
```

You should now be able to see the tx on your console.
```
Batch looting token:
    ChestERC20 => Address: 0xefec9dfdB33E1Ca06eBf70715fAeE74a53B1B182 id: 0 amounts: 45000000000000000000
    Chest721 => Address: 0x011Ae6E8B3a3d428B3927428F995a28FC2b211A9 id: 0 amounts: 1
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 1 amounts: 10
    Chest1155 => Address: 0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853 id: 3 amounts: 1000
    
Tokens Looted sucessfully !

See tx: https://mumbai.polygonscan.com/tx/0x4134263a1475b3ea284cc80cc805bd82bb78f7e8e609b79f53262747163eb542

Looted:

items:  [
  '0xefec9dfdB33E1Ca06eBf70715fAeE74a53B1B182',
  '0x011Ae6E8B3a3d428B3927428F995a28FC2b211A9',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853',
  '0xeaF5A2612BC8fe1807414047e1e7A1A18d35C853'
]
tokenIds:  [
  BigNumber { value: "0" },
  BigNumber { value: "0" },
  BigNumber { value: "1" },
  BigNumber { value: "3" }
]
amounts:  [
  BigNumber { value: "45000000000000000000" },
  BigNumber { value: "1" },
  BigNumber { value: "10" },
  BigNumber { value: "1000" }
]
type_:  [ 1, 2, 3, 3 ]
```

## Author

This example implementation was written by Jonathan Tondelier.

Contact:

- https://twitter.com/john_gotchi
- jonh.t@icloud.com
- https://github.com/johnfr14

## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.
