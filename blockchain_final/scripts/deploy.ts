import { network } from "hardhat";

async function main() {
  const connection = await network.create();
  const { ethers } = connection;

  console.log("正在準備部署 DynamicMomentumVault 合約...");
  
  const Vault = await ethers.getContractFactory("DynamicMomentumVault");
  const vault = await Vault.deploy();

  await vault.waitForDeployment();
  const address = await vault.getAddress();

  console.log(`🚀 合約已成功部署！`);
  console.log(`👉 合約地址: ${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});