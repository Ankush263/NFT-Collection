// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Token is ERC20 {
  constructor(uint256 _totalSupply, uint8 _decimal) ERC20("Token", "TKN") {
    _mint(msg.sender, _totalSupply * (10 ** _decimal));
  }
  function Faucet() public {
    _mint(msg.sender, 100);
  }
}

contract collections is ERC721URIStorage {

  using Counters for Counters.Counter;
  Counters.Counter private _nftIds;
  Counters.Counter private _nftsSold;

  IERC20 public immutable token;

  constructor(address _token) ERC721("CollectionNFT", "CNFT") {
    token = IERC20(_token);
    owner = payable(msg.sender);
  }

  uint256 listingPrice = 10;
  address payable owner;

  struct NFT {
    uint256 tokenId;
    address payable owner;
    address payable seller;
    uint256 price;
    bool sold;
  }

  struct Review {
    uint256 tokenId;
    address user;
    uint8 rating;
    string review;
  }

  Review[] public reviews;

  mapping(uint256 => NFT) private idOfNFT;
  mapping(uint256 => Review[]) public review;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only Owner can call this function");
    _;
  }

  function updateListingPrice(uint256 _price) public onlyOwner {
    listingPrice = _price;
  }

  function getListingPrice() public view returns(uint256) {
    return listingPrice;
  }

  function getListedTokenForId(uint256 _id) public view returns(NFT memory) {
    return idOfNFT[_id];
  }

  function giveReview(uint256 _id, uint8 _rating, string memory _review) public {
    require(idOfNFT[_id].owner != msg.sender, "Owner can't review to NFT");
    require(idOfNFT[_id].seller != msg.sender, "Seller can't review to NFT");
    require(_id <= _nftIds.current(), "This NFT id does not exists");
    require(_rating <= 5, "rating should be less then or equal 5");
    require(_rating >= 1, "rating should be greater then or equal 1");

    Review memory tempReview = Review (
      _id,
      msg.sender,
      _rating,
      _review
    );
    reviews.push(tempReview);
    review[_id].push(tempReview);
    
  }

  function getAllReviewOfANFT(uint256 _id) public view returns(Review[] memory) {
    return review[_id];
  }

  function createNFT(string memory _URI, uint256 _price) public returns(uint256) {
    _nftIds.increment();
    uint256 newNFTId = _nftIds.current();

    _mint(msg.sender, newNFTId);
    _setTokenURI(newNFTId, _URI);
    createListedNFT(newNFTId, _price);
    return newNFTId;
  }

  function createListedNFT(uint256 _id, uint256 _price) private {
    require(_price > 0, "Price should be greater then 0");
    require(token.balanceOf(msg.sender) >= listingPrice, "Insufficient balance");

    idOfNFT[_id] = NFT (
      _id,
      payable(address(this)),
      payable(msg.sender),
      _price,
      false
    );
    _transfer(msg.sender, address(this), _id);
    token.transferFrom(msg.sender, address(this), listingPrice);
  }

  function listForSale(uint256 _id, uint256 _price) payable public {
    require(idOfNFT[_id].owner == msg.sender, "You are not the owner of this NFT");
    require(_price > 0, "Price should be greater then 0");
    require(token.balanceOf(msg.sender) >= listingPrice, "Insufficient fund");

    idOfNFT[_id] = NFT (
      _id,
      payable(address(this)),
      payable(msg.sender),
      _price,
      false
    );

    _nftsSold.decrement();

    _transfer(msg.sender, address(this), _id);
    token.transferFrom(msg.sender, address(this), listingPrice);
  }

  function buyNFT(uint256 _id) payable public {
    uint256 price = idOfNFT[_id].price;
    require(token.balanceOf(msg.sender) >= price, "Insufficient Price");
    
    token.transferFrom(msg.sender, idOfNFT[_id].seller, price);

    idOfNFT[_id] = NFT (
      _id,
      payable(msg.sender),
      payable(address(0)),
      price,
      true
    );

    _nftsSold.increment();
    _transfer(address(this), msg.sender, _id);
  }

  function fetchAllUnsoldNFTs() public view returns(NFT[] memory) {
    uint256 nftCount = _nftIds.current();
    uint256 unsoldNFTCount = _nftIds.current() - _nftsSold.current();
    uint256 currentIndex = 0;

    NFT[] memory nfts = new NFT[](unsoldNFTCount);
    for(uint256 i = 0; i < nftCount; i++) {
      if(idOfNFT[i + 1].owner == address(this)) {
        uint256 currentId = i + 1;
        NFT storage currentNFT = idOfNFT[currentId];
        nfts[currentIndex] = currentNFT;
        currentIndex ++;
      }
    }
    return nfts;
  }

  function fetchAllNFTs() public view returns(NFT[] memory) {
    uint256 totalNFTCount = _nftIds.current();
    uint256 currentIndex = 0;

    NFT[] memory nfts = new NFT[](totalNFTCount);
    for(uint i = 0; i < totalNFTCount; i++) {
      uint256 currentId = i + 1;
      NFT storage currentNFT = idOfNFT[currentId];
      nfts[currentIndex] = currentNFT;
      currentIndex += 1;
    }
    return nfts;
  }

  function fetchMyNFTs() public view returns(NFT[] memory) {
    uint256 totalItemCount = _nftIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for(uint256 i = 0; i < totalItemCount; i++) {
      if(idOfNFT[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    NFT[] memory nfts = new NFT[](itemCount);
    for(uint256 i = 0; i < totalItemCount; i++) {
      if(idOfNFT[i + 1].owner == msg.sender) {
        uint256 currentId = i + 1;
        NFT storage currentItem = idOfNFT[currentId];
        nfts[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return nfts;
  }

  function fetchListedNFTs() public view returns(NFT[] memory) {
    uint256 totalItemCount = _nftIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for(uint256 i = 0; i < totalItemCount; i++) {
      if(idOfNFT[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    NFT[] memory nfts = new NFT[](itemCount);
    for(uint256 i = 0; i < totalItemCount; i++) {
      if(idOfNFT[i + 1].seller == msg.sender) {
        uint256 currentId = i + 1;
        NFT storage currentNFT = idOfNFT[currentId];
        nfts[currentIndex] = currentNFT;
        currentIndex += 1;
      }
    }
    return nfts;
  }

}
