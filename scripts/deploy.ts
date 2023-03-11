import { ethers } from "hardhat";

async function main() {
  const Token = await ethers.getContractFactory("Token")
  const token = await Token.deploy(1000, 18)
  await token.deployed()
  console.log(`Token is deployed to the address ${token.address}`)

  const Collection = await ethers.getContractFactory("collections")
  const collection = await Collection.deploy(token.address)
  console.log(`Collection is deployed to the address ${collection.address}`)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
