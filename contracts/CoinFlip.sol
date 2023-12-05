// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract CoinFlip is VRFConsumerBaseV2 {

    enum CoinFlipChoice {
        HEADS,
        TAILS
    }

    struct CoinFlipStatus {
        uint256 fees;
        uint256 randomWord;
        address player;
        bool didWin;
        bool fulfilled;
        CoinFlipChoice choice;
    }

    error CoinFlip__EntryFeesNotEnough();
    error CoinFlip__RequestNotFound();

    mapping (uint256 => CoinFlipStatus) public s_status;

    uint256 s_entryFees = 0.01 ether;

    VRFCoordinatorV2Interface immutable i_vrfCoordinator;

    address constant vrfAddress = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    uint16 private constant s_blockConfirmations = 3;
    uint64 private immutable s_subscriptionId;
    uint32 private constant s_gasLane = 100000;
    uint32 private constant s_numWords = 1;
    bytes32 private constant s_keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2
    (
        vrfAddress
    ) {
        i_vrfCoordinator = VRFCoordinatorV2Interface
        (
            vrfAddress
        );
        s_subscriptionId = subscriptionId;
    }

    function flip(CoinFlipChoice choice) external payable returns(uint256 requestId){
        if(msg.value != s_entryFees) {
            revert CoinFlip__EntryFeesNotEnough();
        }

        requestId = i_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_blockConfirmations,
            s_gasLane,
            s_numWords
        );

        s_status[requestId] = CoinFlipStatus(
            {
            fees: s_gasLane,
            randomWord: 0,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice
            }
        );
        
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if(s_status[requestId].fees < 0) {
            revert CoinFlip__RequestNotFound();
        }

        s_status[requestId].fulfilled = true;
        s_status[requestId].randomWord = randomWords[0];

        CoinFlipChoice result = CoinFlipChoice.HEADS;

        if(randomWords[0] % 2 == 0) {
            result = CoinFlipChoice.TAILS; // If the random Word is even, it is tails
        }

        if(s_status[requestId].choice == result) {
            s_status[requestId].didWin = true;
            (bool success, ) = payable(s_status[requestId].player).call{value: s_entryFees * 2}("");
            require(success, "Transation failed");
        }
    }

    function getStatus(uint256 requestId) public view returns(CoinFlipStatus memory) {
        return s_status[requestId];
    }
}
