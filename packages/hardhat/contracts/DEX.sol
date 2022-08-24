// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract
    uint public totalLiquidity;
    //uint public liquidity;
    mapping (address => uint) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address trader, string txDescription, uint ethIn, uint tokenOut);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address trader, string txDescription, uint ethOut, uint tokenIn);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    //event LiquidityProvided(uint addedLPT);
    event LiquidityProvided(address liquidityProvider, uint256 tokensInput, uint256 ethInput, uint256 lptMinted);
    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    //event LiquidityRemoved(uint removedLPT);
    event LiquidityRemoved(address liquidityRemover, uint256 tokensOutput, uint256 ethOutput, uint256 lptBurned);

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: init - already has liquidity.");
        //token.transfer(address(this), tokens);
        totalLiquidity = address(this).balance; 
        liquidity[msg.sender] = totalLiquidity;
        require(
            token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer did not transact");
        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {
        uint256 xInputTaxed = xInput.mul(997);
        uint256 numerator = xInputTaxed.mul(yReserves);
        uint256 denominator = xReserves.mul(1000).add(xInputTaxed);
        return numerator / denominator;
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     *
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        //require(msg.value > uint(0) && address(msg.sender).balance >= msg.value, "DEX.ethToToken needs proper ETH amount");
        require(msg.value > uint(0), "DEX.ethToToken needs more than 0 ETH");
        require(address(msg.sender).balance >= msg.value, "(you got) not enough ETH to send to DEX.ethToToken");
        uint tokenOut = price(
            msg.value, 
            address(this).balance.sub(msg.value), //ethReserve
            token.balanceOf(address(this)) ); //tokenReserve
        //token.approve(address(this), tokenOut);
        //token.transferFrom(address(this), address(msg.sender), tokenOut);
        token.transfer(address(msg.sender), tokenOut);
        emit EthToTokenSwap(msg.sender, "Eth to Balloons", msg.value, tokenOutput);
        return tokenOut;
    }
    /**
     * @notice sends Ether to DEX in exchange for $BAL
     
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokenOutput = price(msg.value, ethReserve, token_reserve);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap.");
        emit EthToTokenSwap(msg.sender, "Eth to Balloons", msg.value, tokenOutput);
        return tokenOutput;
    }
    */

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        //require(tokenInput > uint(0) && token.balanceOf(msg.sender), "DEX.ethToToken needs proper amount of Tokens");
        //require(token.allowance(address(msg.sender), address(this)) >= tokenInput, "please approve proper amount of tokens");
        require(tokenInput > uint(0), "DEX.ethToToken needs more than zero Tokens.");
        require(tokenInput <= token.balanceOf(msg.sender), "DEX.ethToToken needs proper amount of Tokens (u put too much)");
        uint ethOut = price(tokenInput, token.balanceOf(address(this)), address(this).balance);
        //token.transferFrom(msg.sender, address(this), ethOut); //made a mistake here before mixing up ethOut with tokenInput
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        //payable(msg.sender).transfer(ethOut); //is this still not recommended to use?
        (bool sent, bytes memory data) = payable(msg.sender).call{value: ethOut}("");
        require(sent, "Failed to send Ether");
        emit TokenToEthSwap(msg.sender, "Balloons to ETH", ethOutput, tokenInput);
        return ethOut;
    }
    
    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether

    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 ethOutput = price(tokenInput, token_reserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        (bool sent, ) = msg.sender.call{ value: ethOutput }("");
        require(sent, "tokenToEth: revert in transferring eth to you!");
        emit TokenToEthSwap(msg.sender, "Balloons to ETH", ethOutput, tokenInput);
        return ethOutput;
    }
    */

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. 
            That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf 
            by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet 
            with respect to the price outlined by the AMM.

    function deposit() public payable returns (uint256 tokensDeposited) {
        //deposit means user sends ETH & Token to the contract (with proper amounts each)
        //x * y = k + addedLiquidity
        uint256 eth_reserve = address(this).balance.sub(msg.value);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
        uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);
        totalLiquidity = totalLiquidity.add(liquidity_minted);
        require(token.transferFrom(msg.sender, address(this), token_amount), "please *approve* trading of BAL");
        emit LiquidityProvided(totalLiquidity - liquidity[msg.sender]);
        return liquidity_minted;
    }
    */

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
    
    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = amount.mul(address(this).balance) / totalLiquidity;
        uint256 token_amount = amount.mul(token_reserve) / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender].sub(eth_amount);
        totalLiquidity = totalLiquidity.sub(eth_amount);
        payable(msg.sender).transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount));
        emit LiquidityRemoved(totalLiquidity - liquidity[msg.sender]);
        return (eth_amount, token_amount);
    }
     */

    function deposit() public payable returns (uint256 tokensDeposited) {
        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;

        tokenDeposit = (msg.value.mul(tokenReserve) / ethReserve).add(1);
        uint256 liquidityMinted = msg.value.mul(totalLiquidity) / ethReserve;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidityMinted);
        totalLiquidity = totalLiquidity.add(liquidityMinted);

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
        return tokenDeposit;
    }

    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {
        require(liquidity[msg.sender] >= amount, "withdraw: sender does not have enough liquidity to withdraw.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethWithdrawn;

        ethWithdrawn = amount.mul(ethReserve) / totalLiquidity;

        uint256 tokenAmount = amount.mul(tokenReserve) / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender].sub(amount);
        totalLiquidity = totalLiquidity.sub(amount);
        (bool sent, ) = payable(msg.sender).call{ value: ethWithdrawn }("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenAmount));
        emit LiquidityRemoved(msg.sender, amount, ethWithdrawn, tokenAmount);
        return (ethWithdrawn, tokenAmount);
    }

    receive() external payable {
        ethToToken();
    }
}
