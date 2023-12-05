const { ethers, run, network } = require("hardhat");

const deploy = async () => {

    const CoinFlip = await ethers.deployContract("CoinFlip", [7487]);
    console.log("Deploying contract...");
    await CoinFlip.waitForDeployment(6);
    console.log(`Contract Deployed to: ${CoinFlip.target}`)

    const args = [7487]

    if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        await CoinFlip.waitForDeployment(6);
        await verify(CoinFlip.target, args)
    } else {
        console.log("Contract cannot be verified on Hardhat Network")
    }

    const sendVal = ethers.utils.parseEther("0.1")
    const flip = await CoinFlip.flip(0, { value: sendVal });
    await flip.wait(3);
    console.log(`Flipped!`);
}

const verify = async (contractAddress, args) => {
    console.log("Verifying contract....")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArgs: args
        })
    } catch (error) {
        if (error.message.toLowerCase().includes("already verified")) {
            console.log("Already verified...!")
        } else {
            console.log(error);
        }
    }
}

deploy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
