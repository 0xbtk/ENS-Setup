// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { Test } from "forge-std/Test.sol";

import { ERC20Votes } from "@openzeppelin//token/ERC20/extensions/ERC20Votes.sol";

import { ENSToken } from "./ENSToken.sol";

import { Deployer } from "./Deployer.sol";

import { ERC20MultiDelegate } from "../src/ERC20MultiDelegate.sol";

contract ERC20MultiDelegateTest is Test {

    ERC20MultiDelegate private multiDelegate;
    address private votesToken;
    Deployer private deployer;

    address private source1 = makeAddr("source1");
    address private source2 = makeAddr("source2");

    address private target1 = makeAddr("target1");
    address private target2 = makeAddr("target2");

    uint256 private amount = 1e18;

    function setUp() public {

        deployer = new Deployer();

        vm.prank(address(deployer));
        votesToken = address(new ENSToken(100e18, 100_000e18, block.timestamp));

        multiDelegate = new ERC20MultiDelegate(ERC20Votes(votesToken), "http://localhost:8081");

        vm.prank(address(deployer));
        ENSToken(votesToken).approve(address(multiDelegate), type(uint128).max);

        vm.label(votesToken, "MockERC20");
        vm.label(address(multiDelegate), "ERC20MultiDelegate");
        vm.label(address(deployer), "deployer");
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
        
        vm.prank(address(deployer));
        multiDelegate.delegateMulti(sources, targets, amounts);

        sources = new uint256[](2);
        sources[0] = uint256(uint160(target1));
        sources[1] = uint256(uint160(target2));

        targets[0] = uint256(uint160(source1));
        targets[1] = uint256(uint160(source2));

        vm.prank(address(deployer));
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
        
        vm.prank(address(deployer));
        multiDelegate.delegateMulti(sources, targets, amounts);

        sources = new uint256[](2);
        sources[0] = uint256(uint160(target1));
        sources[1] = uint256(uint160(target2));

        targets = new uint256[](0);

        vm.prank(address(deployer));
        multiDelegate.delegateMulti(sources, targets, amounts);
    }

    // Run: forge test --mc ERC20MultiDelegateTest --mt testDelegateMultiCreateProxyAndTransfer -vvvv
    function testDelegateMultiCreateProxyAndTransfer() public {
        uint256[] memory sources = new uint256[](0);
        
        uint256[] memory targets = new uint256[](2);
        targets[0] = uint256(uint160(target1));
        targets[1] = uint256(uint160(target2));
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        
        vm.prank(address(deployer));
        multiDelegate.delegateMulti(sources, targets, amounts);
    }
}