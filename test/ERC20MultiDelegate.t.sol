// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { Test } from "forge-std/Test.sol";

import { ERC20Votes } from "@openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

import { ENSToken } from "./ENSToken.sol";

import { Delegator } from "./Delegator.sol";

import { ERC20MultiDelegate } from "../src/ERC20MultiDelegate.sol";

contract ERC20MultiDelegateTest is Test {

    ERC20MultiDelegate private multiDelegate;
    address private ensToken;
    Delegator private delegator;

    address private source1 = makeAddr("source1");
    address private source2 = makeAddr("source2");

    address private target1 = makeAddr("target1");
    address private target2 = makeAddr("target2");

    uint256 private amount = 1e18;

    function setUp() public {

        delegator = new Delegator();

        vm.prank(address(delegator));
        ensToken = address(new ENSToken(2e18, 10e18, block.timestamp));

        multiDelegate = new ERC20MultiDelegate(ERC20Votes(ensToken), "http://localhost:8081");

        vm.prank(address(delegator));
        ENSToken(ensToken).approve(address(multiDelegate), type(uint128).max);

        vm.label(ensToken, "ENSToken");
        vm.label(address(multiDelegate), "ERC20MultiDelegate");
        vm.label(address(delegator), "delegator");
        vm.label(source1, "Source One");
        vm.label(source2, "Source Two");
        vm.label(target1, "Target One");
        vm.label(target2, "Target Two");
    }

    // Run: forge test --mc ERC20MultiDelegateTest --mt testDelegateMultiProcessDelegation -vvvv
    function testDelegateMultiProcessDelegation() public {
        uint256[] memory sources = new uint256[](0);
        
        uint256[] memory targets = new uint256[](2);
        targets[0] = uint256(uint160(target1));
        targets[1] = uint256(uint160(target2));
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        
        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);

        sources = new uint256[](2);
        sources[0] = uint256(uint160(target1));
        sources[1] = uint256(uint160(target2));

        targets[0] = uint256(uint160(source1));
        targets[1] = uint256(uint160(source2));

        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);
    }

    // Run: forge test --mc ERC20MultiDelegateTest --mt testDelegateMultiReimburse -vvvv
    function testDelegateMultiReimburse() public {
        uint256[] memory sources = new uint256[](0);
        
        uint256[] memory targets = new uint256[](2);
        targets[0] = uint256(uint160(target1));
        targets[1] = uint256(uint160(target2));
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        
        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);

        sources = new uint256[](2);
        sources[0] = uint256(uint160(target1));
        sources[1] = uint256(uint160(target2));

        targets = new uint256[](0);

        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);
    }

    // Run: forge test --mc ERC20MultiDelegateTest --mt testDelegateMultiCreateProxyAndTransfer -vvvv
    function testDelegateMultiCreateProxyAndTransfer() public {
        uint256[] memory sources = new uint256[](0);
        
        uint256[] memory targets = new uint256[](2);
        targets[0] = uint256(uint160(source1));
        targets[1] = uint256(uint160(source2));
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        
        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);
    }

    // Run: forge test --mc ERC20MultiDelegateTest --mt testHappyCase -vvvv
    function testHappyCase() public {
        uint256[] memory sources = new uint256[](0);
        
        uint256[] memory targets = new uint256[](2);
        targets[0] = uint256(uint160(source1));
        targets[1] = uint256(uint160(source2));
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        
        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);

        address sourceOneProxy = multiDelegate.retrieveProxyContractAddress(ERC20Votes(ensToken), source1);
        address sourceTwoProxy = multiDelegate.retrieveProxyContractAddress(ERC20Votes(ensToken), source2);

        // @audit-info delegator ENSToken balance is now 0
        assertEq(ENSToken(ensToken).balanceOf(address(delegator)), 0);

        // @audit-info delegator ERC1155 balance of the sources will be 1e18 each
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(source1))), 1e18);
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(source2))), 1e18);

        // @audit-info Source's proxys ENSToken balance will be 1e18 each
        assertEq(ENSToken(ensToken).balanceOf(sourceOneProxy), amount);
        assertEq(ENSToken(ensToken).balanceOf(sourceTwoProxy), amount);

        // @audit-info Source's votes will be 1e18 each
        assertEq(ENSToken(ensToken).getVotes(source1), amount);
        assertEq(ENSToken(ensToken).getVotes(source2), amount);

        sources = new uint256[](2);
        sources[0] = uint256(uint160(source1));
        sources[1] = uint256(uint160(source2));

        targets[0] = uint256(uint160(target1)); 
        targets[1] = uint256(uint160(target2));
        
        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);

        address targetOneProxy = multiDelegate.retrieveProxyContractAddress(ERC20Votes(ensToken), target1);
        address targetTwoProxy = multiDelegate.retrieveProxyContractAddress(ERC20Votes(ensToken), target2);

        // @audit-info delegator ENSToken balance is still 0
        assertEq(ENSToken(ensToken).balanceOf(address(delegator)), 0);

        // @audit-info delegator ERC1155 balance of the sources will be 0 each
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(source1))), 0);
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(source2))), 0);

        // @audit-info delegator ERC1155 balance of the targets will be 1e18 each
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(target1))), 1e18);
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(target2))), 1e18);

        // @audit-info Source's proxys ENSToken balance will be 0 each
        assertEq(ENSToken(ensToken).balanceOf(sourceOneProxy), 0);
        assertEq(ENSToken(ensToken).balanceOf(sourceTwoProxy), 0);

        // @audit-info Target's proxys ENSToken balance will be 1e18 each
        assertEq(ENSToken(ensToken).balanceOf(targetOneProxy), amount);
        assertEq(ENSToken(ensToken).balanceOf(targetTwoProxy), amount);

        // @audit-info Source's votes will be 0 each
        assertEq(ENSToken(ensToken).getVotes(source1), 0);
        assertEq(ENSToken(ensToken).getVotes(source2), 0);

        // @audit-info Target's votes will be 1e18 each
        assertEq(ENSToken(ensToken).getVotes(target1), amount);
        assertEq(ENSToken(ensToken).getVotes(target2), amount);

        sources[0] = uint256(uint160(target1));
        sources[1] = uint256(uint160(target2));

        targets = new uint256[](0);

        vm.prank(address(delegator));
        multiDelegate.delegateMulti(sources, targets, amounts);

        // @audit-info delegator ENSToken balance will be 2e18
        assertEq(ENSToken(ensToken).balanceOf(address(delegator)), 2e18);

        // @audit-info delegator ERC1155 balance of the targets will be 0 each
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(target1))), 0);
        assertEq(multiDelegate.balanceOf(address(delegator), uint256(uint160(target2))), 0);

        // @audit-info Target's proxys ENSToken balance will be 0 each
        assertEq(ENSToken(ensToken).balanceOf(targetOneProxy), 0);
        assertEq(ENSToken(ensToken).balanceOf(targetTwoProxy), 0);

        // @audit-info Target's votes will be 0 each
        assertEq(ENSToken(ensToken).getVotes(target1), 0);
        assertEq(ENSToken(ensToken).getVotes(target2), 0);
    }
}
