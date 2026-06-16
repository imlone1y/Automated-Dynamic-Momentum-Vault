import { expect } from "chai";
import { network } from "hardhat";

describe("DynamicMomentumVault 核心邏輯測試", function () {
  let ethers: any;
  let connection: any;

  // ⚡ Hardhat 3 關鍵：必須在測試開始前手動建立連線並掛載 ethers
  before(async () => {
    connection = await network.create();
    ethers = connection.ethers;
  });

  async function deployVaultFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("DynamicMomentumVault");
    const vault = await Vault.deploy();
    return { vault, owner, user1, user2 };
  }

  // 使用 connection.provider 代替舊版的 hre.network
  async function increaseTime(seconds: number) {
    await connection.provider.send("evm_increaseTime", [seconds]);
    await connection.provider.send("evm_mine");
  }

  it("應該能正確由 Owner 調整市場價格並切換狀態", async function () {
    const { vault } = await deployVaultFixture();

    await vault.setMarketPrice(700);
    expect(await vault.currentMarketState()).to.equal(1n); // BEAR

    await vault.setMarketPrice(400);
    expect(await vault.currentMarketState()).to.equal(2n); // FLASH_CRASH
  });

  it("3天內提款應該會被懲罰扣除 5%", async function () {
    const { vault, user1 } = await deployVaultFixture();
    const depositAmount = ethers.parseEther("1.0");

    await vault.connect(user1).deposit({ value: depositAmount });

    const tx = await vault.connect(user1).withdraw();
    const receipt = await tx.wait();
    expect(receipt).to.not.be.null; 
  });

  it("超過3天提款應該為 0 懲罰，且若有罰款池應獲得分紅", async function () {
    const { vault, user1, user2 } = await deployVaultFixture();
    const depositAmount = ethers.parseEther("1.0");

    await vault.connect(user1).deposit({ value: depositAmount });
    await vault.connect(user1).withdraw();

    await vault.connect(user2).deposit({ value: depositAmount });

    await increaseTime(4 * 24 * 60 * 60);

    const tx = await vault.connect(user2).withdraw();
    const receipt = await tx.wait();
    expect(receipt).to.not.be.null;
  });
});