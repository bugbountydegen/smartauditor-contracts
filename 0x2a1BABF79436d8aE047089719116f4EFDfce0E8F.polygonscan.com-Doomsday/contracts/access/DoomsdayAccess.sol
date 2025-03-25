//SPDX-License-Identifier: You smell
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../survivors/IDoomsdaySurvivors.sol";

contract DoomsdayAccess is Ownable{

    bytes32 merkleRoot;

    IDoomsdaySurvivors survivors;

    constructor(bytes32 _merkleRoot, address _survivors){
        merkleRoot = _merkleRoot;
        survivors = IDoomsdaySurvivors(_survivors);
    }

    function hasAccess(bytes32[] memory proof, address _address)  public view returns(bool){
        if(survivors.balanceOf(_address) > 0) return true;
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(proof,merkleRoot,leaf);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner{
        merkleRoot = _merkleRoot;
    }
    function updateSurvivors(address _survivors) public onlyOwner{
        survivors = IDoomsdaySurvivors(_survivors);
    }
}