// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './Web3Heaven.sol';
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Web3HeavenFactory is Ownable, ReentrancyGuard {

    mapping(address => mapping(uint256 => address)) public getMonument;
    mapping(address => address[]) public getMonumentForApplicant;
    address public getLadder;

    event MonumentCreated(address indexed applicant, address indexed monument, uint256 id, uint256);

    constructor(address _owner) public {
        initializeOwner(_owner);
    }

    function Ladder(address _ladder) public onlyOwner {
        getLadder = _ladder;
    }

    function createMonument(address _applicant, uint256 _monumentId) external nonReentrant returns (address monument) {
        require(msg.sender == getLadder, "Web3Heaven: INVALID_LADDER");
        require(getMonument[_applicant][_monumentId] == address(0), "Web3Heaven: MONUMENT_EXISTS");
        bytes memory bytecode = type(Web3Heaven).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_applicant, _monumentId));
        assembly {
            monument := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getMonumentForApplicant[_applicant].push(monument);
        getMonument[_applicant][_monumentId] = monument;
        emit MonumentCreated(_applicant, monument, _monumentId, getMonumentForApplicant[_applicant].length);
    }

    function getNumber(address applicant) public view returns (uint256) {
        return getMonumentForApplicant[applicant].length;
    }

    function getMonumentByApplicant(address applicant) public view returns (address[] memory) {
        return getMonumentForApplicant[applicant];
    }
}