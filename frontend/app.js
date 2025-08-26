// Minimal Ethers v6 frontend to mint ONYX
const CONTRACT_ADDRESS = "0xYourContractAddress"; // <-- set after deploy
const CONTRACT_ABI = [
  {"inputs":[{"internalType":"string","name":"name_","type":"string"},{"internalType":"string","name":"symbol_","type":"string"},{"internalType":"string","name":"baseURI_","type":"string"},{"internalType":"uint256","name":"maxSupply_","type":"uint256"},{"internalType":"uint256","name":"mintPriceWei_","type":"uint256"},{"internalType":"address","name":"royaltyReceiver_","type":"address"},{"internalType":"uint96","name":"royaltyFeeNumerator_","type":"uint96"}],"stateMutability":"nonpayable","type":"constructor"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"quantity","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"paid","type":"uint256"}],"name":"PublicMint","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"quantity","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"paid","type":"uint256"}],"name":"AllowlistMint","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"},{"indexed":true,"internalType":"bytes32","name":"perkId","type":"bytes32"},{"indexed":true,"internalType":"address","name":"claimer","type":"address"},{"indexed":false,"internalType":"string","name":"details","type":"string"}],"name":"PerkClaimed","type":"event"},
  {"inputs":[],"name":"totalMinted","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"maxSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"mintPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"allowlistActive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"publicSaleActive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"uint256","name":"quantity","type":"uint256"}],"name":"mintPublic","outputs":[],"stateMutability":"payable","type":"function"}
];

const $ = (sel) => document.querySelector(sel);
const connectBtn = $("#connectBtn");
const mintBtn = $("#mintBtn");
const qtyInput = $("#quantity");
const plus = $("#plus");
const minus = $("#minus");

let provider, signer, contract;

async function connect() {
  if (!window.ethereum) {
    alert("Please install MetaMask.");
    return;
  }
  await window.ethereum.request({ method: "eth_requestAccounts" });
  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  connectBtn.textContent = (await signer.getAddress()).slice(0,6) + "..." + (await signer.getAddress()).slice(-4);
  contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  await refreshStats();
}

async function refreshStats() {
  try {
    const [s, m, p] = await Promise.all([
      contract.totalMinted(),
      contract.maxSupply(),
      contract.mintPrice()
    ]);
    $("#supply").textContent = s.toString();
    $("#max").textContent = m.toString();
    $("#price").textContent = ethers.formatEther(p);
  } catch (e) {
    console.warn(e);
  }
}

async function mint() {
  try {
    const q = Math.max(1, parseInt(qtyInput.value || "1", 10));
    const price = await contract.mintPrice();
    const total = price * BigInt(q);
    const tx = await contract.mintPublic(q, { value: total });
    mintBtn.disabled = true;
    mintBtn.textContent = "Minting...";
    await tx.wait();
    await refreshStats();
    mintBtn.textContent = "Mint Now";
    mintBtn.disabled = false;
    alert("Mint successful!");
  } catch (e) {
    console.error(e);
    mintBtn.textContent = "Mint Now";
    mintBtn.disabled = false;
    alert(e?.shortMessage || e?.message || "Mint failed");
  }
}

connectBtn.addEventListener("click", connect);
mintBtn.addEventListener("click", mint);
plus.addEventListener("click", () => qtyInput.value = Math.max(1, (parseInt(qtyInput.value||"1",10)+1)));
minus.addEventListener("click", () => qtyInput.value = Math.max(1, (parseInt(qtyInput.value||"1",10)-1)));

window.addEventListener("load", refreshStats);
