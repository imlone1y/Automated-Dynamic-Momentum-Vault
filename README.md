# 基於時間與價格波動的自動動態動量保險庫 Automated Dynamic Momentum Vault

本項目為東華大學區塊鏈原理與應用期末作業，未經允許禁止使用、轉買。

---

## Run the project

1. Move to workspace folder
```bash
cd /blockchain_final
```

2. Install dependency [hardhat 3](https://hardhat.org/), [MetaMask](https://metamask.io/)
```bash
npx hardhat --init
```

3. Create test account
```bash
npx hardhat node
```

4. Compile smart contract under /contracts
```bash
npx hardhat compile
```

5. Deploy smart contract
```bash
npx hardhat run scripts/deploy.ts --network localhost
```

6. Change the contract address in `index.html` file, line `132` to the address that generate by contract
![contract_address_pic](/pic/contract_address.png)

7. Run website (May need to install `Live Server` extension in VScode)
```bash
python3 -m http.server 5500
```
