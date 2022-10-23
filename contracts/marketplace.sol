// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

//import "myNFTcontract.sol"; // Change with your NFT contract
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title A NFT Marketplace using ERC1155,
/// @author nicokacz
/// @notice You can use this contract to list NFT on Marketplace
/// @dev All function calls are currently implemented without side effects
contract  Marketplace is ERC1155Holder {

    using Counters for Counters.Counter;
    Counters.Counter private _offerIds;
    Counters.Counter private _nftSold;
    myNFT private nftContract;
    address private owner;
    address payable marketPlace;
    uint256 private platformFee = 2;
    uint256 private deno = 100;
    uint public nbOffer = 0;

    constructor(address _nftContract, address _owner) {
        nftContract = myNFT(_nftContract); // import the contract of your nft first
        owner = _owner; // owner of the marketplace
        marketPlace = payable(_owner); //To receive the marketplace fee
    }

    struct NFTMarketItem{
        uint256 offerId;
        uint256 nftId;
        uint256 amount;
        uint256 price;
        address payable seller;
        address payable owner;
    }

    mapping(uint256 => NFTMarketItem) public marketItem;
    mapping(uint256 => NFTMarketItem) public marketItemSold;

    /// @notice Get the current id of the offers
    /// @return uint256 The current id of the offers
    function getCurrentOfferId() public view returns (uint256) {
        return _offerIds.current();
    }

    /// @notice It will list the $amount of NFT for $price to marketplace.
    /// @dev It will list NFT minted from MFTMint contract.   
    /// @param amount The amount of NFT to be listed 
    /// @param price The price of the NFT in wei    
    function listNft(uint256 nftId, uint256 amount, uint256 price) external {
        require(nftId >= 0, "NFT doesnt exist");
        require(nftId <= nftContract.getId(), "NFT does not exist");
        require(price >= 10000000000000, "Price has to be greater or equal than 0.00001 ETH");
        require(amount >= 0, "Amount has to be greater or equal than 0");
        require(amount <= nftContract.balanceOf(msg.sender, nftId), "You dont have enough NFT");

        _offerIds.increment();
        nbOffer = nbOffer + 1;
        uint256 offerId = _offerIds.current();

        marketItem[offerId] = NFTMarketItem(
            offerId,
            nftId,
            amount,
            price,
            payable(msg.sender),
            payable(msg.sender)
        );
        
        myNFT(nftContract).safeTransferFrom(msg.sender, address(this), nftId, amount, "");
    }

    event NFTBuy(uint256 offerId, uint256 nftId, address authorAddress, uint256 royaltyPer);

    /// @notice It will buy $amount NFT of the $offerId from marketplace.
    /// @param offerId The id of the offer to buy    
    /// @param amount The amount of NFT to be buyed 
    /// @dev User will able to buy NFT and transfer to respectively owner or user and platform fees, roylty fees also deducted          from this function.
    function buyNFT(uint256 offerId, uint256 amount) public payable {
        require(offerId >= 0, "Offer doesnt exist");
        require(offerId <= _offerIds.current(), "Offer does not exist");
        require(marketItem[offerId].amount >= 1, "No more NFT to sell");
        require((msg.value) >= marketItem[offerId].price * amount, "Invalid value send");
        require(marketItem[offerId].amount >= amount, "No enough NFT to sell");
        require(amount <= nftContract.balanceOf(address(this), marketItem[offerId].nftId), "The marketplace has not enough NFT");

        uint256 nftId = marketItem[offerId].nftId;
        (address authorAddress, uint256 royaltyPer) = nftContract.royaltyInfo(nftId, msg.value );
        uint256 marketFee =  (msg.value * platformFee / deno) * amount;
        address payable seller = marketItem[offerId].seller;

        // Price without royalty and fee
        (bool sent, bytes memory data) = seller.call{value: (msg.value - royaltyPer - marketFee)}("");
        require(sent, "Failed to send Ether to seller");

        // Royalties for Author
        (sent, data) = payable(authorAddress).call{value: royaltyPer}("");
        require(sent, "Failed to send Ether to author");

        // Market place
        (sent, data) = marketPlace.call{value: marketFee}("");
        require(sent, "Failed to send Ether to marketplace");

        marketItem[offerId].owner = payable(msg.sender);
        marketItem[offerId].amount = marketItem[offerId].amount - amount;
        _nftSold.increment();
        marketItemSold[_nftSold.current()] = NFTMarketItem(
            marketItem[offerId].offerId,
            marketItem[offerId].nftId,
            amount,
            marketItem[offerId].price * amount,
            payable(msg.sender),
            payable(msg.sender)
        );

        //No more item to sell in this offer, delete it
        if(marketItem[offerId].amount == 0){
            nbOffer = nbOffer - 1;
            delete(marketItem[offerId]);
        }
        
        nftContract.safeTransferFrom(address(this), msg.sender, nftId, amount, "");

        emit NFTBuy(offerId, nftId, authorAddress, royaltyPer);
    }

    event offerCancel(uint256 offerId);

    /// @notice It will cancel the $offerId of to marketplace.
    /// @dev It will remove the offer from the market place.   
    /// @param offerId The id of the offer to be cancelled
    function cancelOffer(uint256 offerId) external {
        require(offerId >= 0, "Offer doesnt exist");
        require(offerId <= _offerIds.current(), "Offer doesnt exist");
        require(marketItem[offerId].seller == msg.sender, "You are not the seller");

        uint amount = marketItem[offerId].amount;
        //Set amount to 0, no more to sell
        marketItem[offerId].amount = 0;
        delete(marketItem[offerId]);
        nbOffer = nbOffer - 1;

        //Send back the NFTs to seller
        nftContract.safeTransferFrom(address(this), msg.sender, marketItem[offerId].nftId, amount, "");

        emit offerCancel(offerId);
    }

}