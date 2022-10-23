# marketplace

Solidity NFT marketplace with royalties enabled

## Getting Started

 - Copy the github URL of marketplace.sol file
 - Go to https://remix.ethereum.org/, click on open from github and paste the previous URL
 - Import your NFT contract (ERC1155 & IERC2981Royalties compliant) in your workplace in remix
 - Deploy your NFT contract and copy the address
 - Update "myNFT" with the name of your NFT contract
 - Save and compile
 - Deploy with the address of your NFT contract
 - Mint some of your NFT
 - Call *listNft* to add an offer with the id of your NFT (don't forget to call setApprovalForAll of your NFT contract with the address of the marketplace)

## Overview

 - *listNft* : Create an offer with the NFT, the amount of NFT & the price of sell (for one NFT). The NFTs will be send to the contract.
 - *buyNFT* : Buy an amount of NFTs of an offer. (don't forget to attach some ETH to pay). 2% fees will go to the owner of the marketplace contract and x% (x comes from royaltyInfo() getter from the NFT contract) will go to the author of the NFT (this x% depends on how is implemented the royalty in the NFT contract).
 - *cancelOffer* : remove an offer (thanks to its id) from the marketplace. You have to be the seller to remove it.

## License

This contract is released under the [MIT License].
