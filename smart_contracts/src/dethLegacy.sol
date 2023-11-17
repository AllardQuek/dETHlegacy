// SPDX-License-Identifier: GPL-3.0

//pragma solidity ^0.8.16;
pragma solidity ^0.8.0;

import "@uma/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import "@uma/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

contract DETH {

    mapping(uint256 => uint256) public registration;
    
    bytes32 public immutable defaultIdentifier;
    OptimisticOracleV3Interface oo;

    constructor(address _optimisticOracleV3){
        oo = OptimisticOracleV3Interface(_optimisticOracleV3);
        defaultIdentifier = oo.defaultIdentifier();
    }

    // TODO bytes32
    function initWill(uint256 id) public {
        registration[id] = 1;
    }


    function startClaim(uint256 id, uint256 ipfsHash, address tokenAddress) public payable{
        require (registration[id]!=0, "hashedId not registered");

        uint256 bond = oo.getMinimumBond(address(tokenAddress));
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), bond);
        IERC20(tokenAddress).approve(address(oo), bond);

        //TODO real ids and hashes
        bytes32 assertionId = oo.assertTruth(
            abi.encodePacked(
                "CLAIM: File in IPFS hash 0x",
                ClaimData.toUtf8Bytes(bytes32(ipfsHash)),
                " proves the death of a person who fulfills the hash",
                ClaimData.toUtf8Bytes(bytes32(id)),
                " with asserter: 0x",
                ClaimData.toUtf8BytesAddress(msg.sender),
                " at timestamp: ",
                ClaimData.toUtf8BytesUint(block.timestamp),
                " in the DataAsserter contract at 0x",
                ClaimData.toUtf8BytesAddress(address(this)),
                " is valid."
            ),
            msg.sender, //asserter
            address(this), //callbackRecipient
            address(0), // escalationManager.
            9999999, //liveness
            IERC20(tokenAddress), //ERC20 address for bond
            bond, //amount
            defaultIdentifier, //defaultIdentifier
            bytes32(0) // domainId.
        );
    }

}