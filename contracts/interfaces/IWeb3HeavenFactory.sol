pragma solidity >= 0.8.0;

interface IWeb3HeavenFactory {
    function createMonument(address _applicant, uint256 _monumentId) external returns (address monument);
}