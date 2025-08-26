# 🖤 Onyx‑Society

![Solidity](https://img.shields.io/badge/Solidity-0.8.x-363636?logo=solidity&logoColor=white)
![Hardhat](https://img.shields.io/badge/Hardhat-Toolbox-f8dc3d?logo=ethereum&logoColor=000)
![Ethers.js](https://img.shields.io/badge/Ethers.js-6.x-2c3e50)
![Node](https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-22c55e)

> Koleksi **smart contract ERC‑721** bertema *Luxe Black Card* dengan **allowlist (Merkle)**, **public mint**, **royalty EIP‑2981**, dan utilitas **perk claim**.  
> Repo ini sudah lengkap dengan kontrak, script deploy, generator Merkle, dan frontend statis.

---

## ✨ Fitur Utama
- **ERC‑721** (NFT) dengan fase **Allowlist** (Merkle proof) & **Public Mint**.
- **EIP‑2981 Royalty** — penerima & basis poin royalty di‑set saat deploy.
- **Perk Claim** — fungsi khusus untuk klaim *perk/benefit* (sesuaikan di kontrak).
- **Merkle Allowlist** — `allowlist.csv` → `proofs.json` + **Merkle Root**.
- **Frontend** minimalis: koneksi wallet (Ethers v6), tombol mint/claim, tema black–gold.

---

## 📁 Struktur Proyek
```
onyx-society/
├─ contracts/
│  └─ LuxeBlackCard.sol         # Smart contract ERC-721 (allowlist, public mint, EIP-2981, perk claim)
├─ scripts/
│  └─ deploy.js                 # Script deploy Hardhat (set constructor params, cetak alamat kontrak)
├─ merkle/
│  ├─ allowlist.csv             # Daftar address + maxAllowance (input)
│  └─ generateAllowlist.js      # Generator Merkle root & proofs.json
│  # (output saat dijalankan: proofs.json)
├─ frontend/
│  ├─ index.html                # Landing page mint (tema black–gold)
│  ├─ styles.css                # Styling mewah simpel
│  ├─ app.js                    # Logika Ethers v6; isi CONTRACT_ADDRESS setelah deploy
│  ├─ assets/
│  │  └─ logo.svg               # Logo ONYX
│  └─ abi/
│     └─ LuxeBlackCard.json     # ABI minimal untuk frontend
├─ test/                        # (placeholder untuk unit test)
├─ hardhat.config.ts            # Konfigurasi Hardhat (optimizer, networks)
├─ package.json                 # Scripts (compile/deploy/allowlist) & deps (OZ, toolbox, merkletree)
├─ .env.example                 # Template env (PRIVATE_KEY, RPC, ROYALTY_RECEIVER)
├─ README.md                    # Panduan cepat (compile, deploy, allowlist, frontend)
└─ LICENSE                      # MIT
```

---

## 🛠 Prasyarat
- **Node.js 18+** (disarankan 20+)
- **npm**/pnpm
- Akun RPC (Alchemy/Infura/Ankr, dsb.) untuk testnet
- **Wallet dev** (PRIVATE_KEY khusus; *jangan* wallet utama)

---

## ⚙️ Setup & Instalasi
```bash
git clone https://github.com/Nadir-N3/Onyx-Society.git
cd Onyx-Society

# install deps
npm install
# atau: pnpm install
```

Salin `.env.example` → `.env`, lalu isi:
```
PRIVATE_KEY=0xabc...def          # private key wallet DEV
RPC_URL=https://sepolia.infura.io/v3/<your_key>
ROYALTY_RECEIVER=0xYourRoyaltyAddress
ROYALTY_BPS=500                  # contoh 5.00% = 500 basis poin
CHAIN_ID=11155111                # contoh: Sepolia
```

> **Keamanan**: jangan commit `.env`. Gunakan wallet dev terpisah.

---

## 🌲 Allowlist (Merkle)
1) Siapkan **`merkle/allowlist.csv`** berformat:
```
address,maxAllowance
0x1111...aaaa,2
0x2222...bbbb,1
```
2) Hasilkan **Merkle Root** & **proofs.json**:
```bash
node merkle/generateAllowlist.js
```
Output:
- **`proofs.json`** tersimpan di folder `merkle/`  
- **Merkle Root** tampil di terminal → dipakai di **constructor** atau setter kontrak

> Jika kamu ingin *non‑allowlist* dulu, set root ke nilai kosong/`bytes32(0)` sesuai implementasi kontrakmu.

---

## 📦 Compile & Deploy
Compile:
```bash
npx hardhat compile
```

Buka **`scripts/deploy.js`** dan **isi parameter constructor** kontrak, contoh umum:
```js
// Contoh (SESUAIKAN dengan LuxeBlackCard.sol kamu)
const name = "Luxe Black Card";
const symbol = "LUXE";
const baseURI = "ipfs://<CID>/";     // kalau pakai metadata IPFS
const maxSupply = 888;
const allowlistRoot = "<MERKLE_ROOT>";  // dari langkah Merkle di atas
const royaltyReceiver = process.env.ROYALTY_RECEIVER;
const royaltyBps = Number(process.env.ROYALTY_BPS || 500);
```
Deploy ke **node lokal**:
```bash
npx hardhat node
# terminal lain
npx hardhat run scripts/deploy.js --network localhost
```
Deploy ke **testnet** (contoh: Sepolia, asalkan `hardhat.config.ts` sudah ada `networks.sepolia`):
```bash
npx hardhat run scripts/deploy.js --network sepolia
```
Script akan **mencetak alamat kontrak** — salin alamat itu untuk frontend.

---

## 💻 Frontend (Mint UI)
1) **Perbarui alamat kontrak** di `frontend/app.js`:
```js
const CONTRACT_ADDRESS = "0x..."; // alamat hasil deploy
```
2) Pastikan **ABI** di `frontend/abi/LuxeBlackCard.json` sesuai versi kontrak (ambil dari `artifacts/.../LuxeBlackCard.json` → field `abi`).  
3) Jalankan frontend:
```bash
# buka langsung
#   double-click frontend/index.html
# atau serve:
npx serve frontend
# atau:
npx live-server frontend
```
Metamask harus berada di jaringan yang sama (mis. Sepolia).

---

## 🧪 Testing (opsional)
Tambahkan unit test di folder `test/` (Mocha/Chai dari Hardhat).  
Menjalankan test:
```bash
npx hardhat test
```

---

## 🧯 Troubleshooting
- **`HH8`/argumen jaringan** → cek `hardhat.config.ts` (pastikan `networks.<nama>` & `.env` benar).
- **`insufficient funds` (testnet)** → isi faucet pada wallet dev.
- **`invalid proof` saat allowlist mint** → alamat tidak ada di CSV / proofs salah / root belum diset.
- **Frontend tidak connect** → pastikan CONTRACT_ADDRESS benar, ABI cocok, dan chain ID sesuai.
- **Royalties tidak muncul di marketplace** → pastikan EIP‑2981 aktif & receiver/BPS benar saat deploy.

---

## 📜 Lisensi
**MIT** — lihat `LICENSE`.

---

## 🙌 Kredit
Dibuat oleh **Nadir‑N3** — [X](https://x.com/Naadiir_08) · [Instagram](https://instagram.com/__naadiir.fx)
