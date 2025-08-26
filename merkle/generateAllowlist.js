import fs from "fs";
import keccak256 from "keccak256";
import { MerkleTree } from "merkletreejs";

/**
 * CSV format:
 * address,maxAllowance
 * 0xabc...,2
 * 0xdef...,1
 */
const csv = fs.readFileSync(new URL("./allowlist.csv", import.meta.url)).toString().trim().split(/\r?\n/);
const entries = csv.slice(1).map(line => {
  const [address, max] = line.split(",");
  return { address: address.trim(), max: Number(max.trim()) };
});

const leaves = entries.map(e => keccak256(Buffer.from((e.address.toLowerCase() + e.max))));
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root = "0x" + tree.getRoot().toString("hex");
console.log("Merkle Root:", root);

// write proofs.json
const proofs = {};
for (const e of entries) {
  const leaf = keccak256(Buffer.from((e.address.toLowerCase() + e.max)));
  proofs[e.address.toLowerCase()] = {
    maxAllowance: e.max,
    proof: tree.getHexProof(leaf)
  };
}
fs.writeFileSync(new URL("./proofs.json", import.meta.url), JSON.stringify({ root, proofs }, null, 2));
console.log("Saved to merkle/proofs.json");
