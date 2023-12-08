const { assert, expect } = require("chai");

describe("CoinFlip", async () => {
  let CoinFlip;
  beforeEach(async () => {
    const args = ["0x6B4c0b11bd7fE1E9e9a69297347cFDccA416dF5F"]

    CoinFlip = await ethers.deployContract("CoinFlip", args);
    console.log("Deploying contract...");
    await CoinFlip.waitForDeployment(6);
    console.log(`Contract Deployed to: ${CoinFlip.target}`)
  })

  describe("Flip", async () => {
    it("should revert if entry fees isn't passed", async () => {
      const flip = await CoinFlip.flip(0);
      await expect(flip).to.be.revertedWith("CoinFlip__EntryFeesNotEnough");
    });
  });
});
