import { expect } from "chai"
import { ethers } from "hardhat"

describe("Token", async () => {
  let Token: any
  let owner: any
  let tokenContract: any
  let address1: any
  let address2: any
  let address3: any
  let address: any

  beforeEach(async () => {
    Token = await ethers.getContractFactory("Token");
    [owner, address1, address2, address3, ...address] = await ethers.getSigners();
    tokenContract = await Token.deploy(1000, 18);
  })

  describe("Token contract deployment", async () => {

    it("Should set the totalsupply", async () => {
      let amount = Number(await tokenContract.totalSupply())
      expect(amount).to.equal(Number((10**18) * 1000))
    })

    it("Should set all the totalsupply to the owner address", async () => {
      expect(await tokenContract.balanceOf(owner.address)).to.equal(await tokenContract.totalSupply())
    })

  })

  describe("Token Faucet", async () => {

    it("addresses should get 100 token when they called faucet", async () => {
      await tokenContract.connect(address1).Faucet()
      expect(await tokenContract.balanceOf(address1.address)).to.equal('100')
    })
  })

  describe("Collection", async () => {
    let Collection: any
    let collectionContract: any

    beforeEach(async () => {
      Collection = await ethers.getContractFactory("collections")
      collectionContract = await Collection.connect(owner).deploy(tokenContract.address)
    })

    describe("Collection contract deployment", async () => {

      it("Should set the listing price of NFTs", async () => {
        const listingPrice = await collectionContract.getListingPrice()
        expect(Number(listingPrice)).to.equal(10)
      })

      it("Should update the listing price of the NFT", async () => {
        await collectionContract.connect(owner).updateListingPrice(5)
        const listingPrice = await collectionContract.getListingPrice()
        expect(Number(listingPrice)).to.equal(5)
      })

      it("Should revert the transaction since only owner can call this function", async () => {
        expect(await collectionContract.connect(address1).updateListingPrice(5).toString())
        .to.be.revertedWith('Only Owner can call this function')
      })
    })

    describe("NFT creation Errors", async () => {

      it("Should revert the transaction because of insufficient balance", async () => {
        expect(await collectionContract.connect(address1).createNFT("ABC", 10).toString())
        .to.be.revertedWith('Insufficient balance')
      })

      it("Should revert the transaction because price is 0", async () => {
        expect(await collectionContract.connect(address1).createNFT("ABC", 0).toString())
        .to.be.revertedWith('Price should be greater then 0')
      })

      it("Should revert the transaction because of insufficient allowance", async () => {
        await tokenContract.connect(address1).Faucet()
        expect(await collectionContract.connect(address1).createNFT("ABC", 10).toString())
        .to.be.revertedWith('ERC20: insufficient allowance')
      })

    })

    describe("Create NFT", async () => {

      it("Should create a NFT", async () => {
        await tokenContract.connect(address1).Faucet()
        await tokenContract.connect(address1).approve(collectionContract.address, 10)
        await collectionContract.connect(address1).createNFT("ABC", 10)
        const NFT = await collectionContract.getListedTokenForId(1)

        expect(NFT.tokenId.toString()).to.equal('1')
        expect(NFT.owner).to.equal(collectionContract.address)
        expect(NFT.seller).to.equal(address1.address)
        expect(NFT.price.toString()).to.equal('10')
        expect(NFT.sold).to.equal(false)
      })
    })

    describe("Review on a NFT", async () => {
      it("Should create a Review", async () => {
        await tokenContract.connect(address1).Faucet()
        await tokenContract.connect(address1).approve(collectionContract.address, 10)
        await collectionContract.connect(address1).createNFT("ABC", 10)
        
        await collectionContract.connect(address2).giveReview(1, 4, "Nice NFT")
        const review = await collectionContract.getAllReviewOfANFT(1)
        expect(Number(review[0].tokenId)).to.equal(1)
        expect(review[0].user).to.equal(address2.address)
        expect(review[0].user).to.equal(address2.address)
        expect(Number(review[0].rating)).to.equal(4)
        expect(review[0].review).to.equal('Nice NFT')

      })
    })

    describe("Buy NFT", async () => {
      
      it("Should buy a NFT", async () => {
        await tokenContract.connect(address1).Faucet()
        await tokenContract.connect(address1).approve(collectionContract.address, 10)
        await collectionContract.connect(address1).createNFT("ABC", 15)

        await tokenContract.connect(address2).Faucet()
        await tokenContract.connect(address2).approve(collectionContract.address, 15)
        await collectionContract.connect(address2).buyNFT(1)
        const NFT = await collectionContract.getListedTokenForId(1)

        expect(NFT.tokenId.toString()).to.equal('1')
        expect(NFT.owner).to.equal(address2.address)
        expect(NFT.seller).to.equal('0x0000000000000000000000000000000000000000')
        expect(NFT.price.toString()).to.equal('15')
        expect(NFT.sold).to.equal(true)
      })
    })

    describe("List NFT for sell", async () => {

      it("Should list a NFT to collections", async () => {
        await tokenContract.connect(address1).Faucet()
        await tokenContract.connect(address1).approve(collectionContract.address, 10)
        await collectionContract.connect(address1).createNFT("ABC", 15)

        await tokenContract.connect(address2).Faucet()
        await tokenContract.connect(address2).approve(collectionContract.address, 15)
        await collectionContract.connect(address2).buyNFT(1)

        await tokenContract.connect(address2).approve(collectionContract.address, 10)
        await collectionContract.connect(address2).listForSale(1, 17)
        const NFT = await collectionContract.getListedTokenForId(1)

        expect(NFT.tokenId.toString()).to.equal('1')
        expect(NFT.owner).to.equal(collectionContract.address)
        expect(NFT.seller).to.equal(address2.address)
        expect(NFT.price.toString()).to.equal('17')
        expect(NFT.sold).to.equal(false)

      })
    })

  })

})
