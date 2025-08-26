import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const name = "ONYX Society";
  const symbol = "ONYX";
  const baseURI = "ipfs://YOUR_COLLECTION_BASE_URI/"; // ensure trailing slash
  const maxSupply = 999;
  const mintPriceWei = ethers.parseEther("0.08"); // 0.08 ETH
  const royaltyReceiver = process.env.ROYALTY_RECEIVER || (await ethers.getSigners())[0].address;
  const royaltyFeeNumerator = 500; // 5%

  const LuxeBlackCard = await ethers.getContractFactory("LuxeBlackCard");
  const contract = await LuxeBlackCard.deploy(
    name,
    symbol,
    baseURI,
    maxSupply,
    mintPriceWei,
    royaltyReceiver,
    royaltyFeeNumerator
  );
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log("LuxeBlackCard deployed to:", address);

  // OPTIONAL: set a PaymentSplitter already deployed (enter the address after deployment)
  // await (await contract.setPaymentSplitter("0xSplitterAddress")).wait();

  // OPTIONAL: set merkle root for allowlist
  // await (await contract.setMerkleRoot("0x...")).wait();

  // Enable sales when ready
  // await (await contract.setSaleState(true, true)).wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
