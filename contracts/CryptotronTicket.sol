// SPDX-License-Identifier: MIT

/// @custom:created-with-openzeppelin-wizard https://wizard.openzeppelin.com

/// @custom:security-contact andrewnovikoff@outlook.com

/*_________________________________________CRYPTOTRON_________________________________________*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DateTime.sol";
import "./Base64.sol";

/**
 * @dev Custom errors
 */
error OF();
error PF();

contract CryptotronTicket is ERC721, ERC721Enumerable, ERC721Burnable {

    enum lotteryState {
        OPEN,
        PROCESSING,
        OVER
    }

    /**
   * @dev Type declarations
   */
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    lotteryState private s_lotteryState;
    address payable private owner;
    uint256[] private mintedIds;
    string private _wonTokenURI = "ipfs://QmTszrQX61t3xkRMAE94Mtqqjs9UnQE9GJCfWjbqZE78gi";
    string private _averageTokenURI;
    mapping(uint256 => string) private _tokenURIs;
    bool private isLotteryOver = false;
    uint256 private winnerId;
    address private lotteryAddress = address(payable(0x0));
    uint256 private tokensCount = 25;
    uint256 public dateRun;

    /**
   * @dev Modifiers
   */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OF();
        }
        _;
    }

    modifier onlyLottery() {
        if (msg.sender != lotteryAddress) {
            revert PF();
        }
        _;
    }

    /**
   * @dev {ERC721} default constructor
   */
    constructor() ERC721("CryptotronTicket", "CLT") {
        owner = payable(msg.sender);
    }

    /**
   * @dev  Safely transfers the ownership of a given token ID to another address If the target 
   * address is a contract, it must implement {IERC721Receiver.onERC721Received}, which is 
   * called upon a safe transfer. Requires the msg.sender to be the owner, approved, or operator.
   */
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        mintedIds.push(tokenId);
    }

    function getDrawDate() public view returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(dateRun);
        return string(abi.encodePacked(Strings.toString(year), '.', month < uint256(10) ? "0" : "", Strings.toString(month), '.', day < uint256(10) ? "0" : "", Strings.toString(day)));
    }

    function getLotteryContractAddress() public view returns (string memory){
        if (lotteryAddress == address(0x0)) {
            return "Not assigned";
        } else {
            return Strings.toHexString(uint160(lotteryAddress), 20);
        }
    }

    function getLotteryStatus() public view returns (string memory) {
        if (s_lotteryState == lotteryState.OPEN) {
            return "Active";
        } else if (s_lotteryState == lotteryState.PROCESSING) {
            return "Processing";
        } else if (s_lotteryState == lotteryState.OVER) {
            return "Over";
        }
    }

    function getWinStatus(uint256 tokenId) public view returns (string memory) {
        if (s_lotteryState == lotteryState.OVER) {
            if (tokenId == winnerId) {
                return "Won!";
            } else {
                return "Next time...";
            }
        } else if (s_lotteryState == lotteryState.PROCESSING) {
            return "Processing";
        } else {
            return "Coming Soon";
        }
    }

    /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{',
                    '"name": "CryptoTron Ticket #', Strings.toString(tokenId), ' ' , unicode"—" , ' ', getLotteryStatus() ,'",',
                    '"image": "https://ipfs.io/ipfs/QmWVGGW5GGoczosF8oLWnBsAddT9MQ45VSd5cZHZkWcevj?filename=winn.png",',
                    '"attributes": [{"trait_type": "Chance", "value": "1 to 25" },',
                    '{"trait_type": "Prize", "value": "0.1 ETH" },',
                    '{"trait_type": "Project", "value": "Cryptotron" },',
                    '{"trait_type": "State", "value": "', getWinStatus(tokenId), '" },',
                    '{"trait_type": "Draw Date", "value": "', getDrawDate(), '" }',
                    '],'
                    '"description": '
                        '"Image generated by DALL', unicode"·" ,'E. Lottery contract address - ', getLotteryContractAddress(), '"',
                    '}'
                )
            )));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    

    /**
   * @dev used for setting lottery contract
   */
    function _setLotteryAddress(address _lotteryAddress) public onlyOwner {
        lotteryAddress = payable(_lotteryAddress);
    }

    /**
   * Hook, which is being used for implementing IERC721Receiver
   */
    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
   * @dev See {ERC721-_burn}. This override additionally checks to see if a
   * token-specific URI was set for the token, and if so, it deletes the token URI from
   * the storage mapping.
   */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
   * @dev Returns true if this contract implements the interface defined by interfaceId.
   */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //
    function setDateRun(uint256 _dateRun) external onlyLottery {
        s_lotteryState = lotteryState.OPEN;
        dateRun = _dateRun;
    }

    //
    function setProcessing() external onlyLottery {
        s_lotteryState = lotteryState.PROCESSING;
    }

    //
    function setOver() external onlyLottery {
        s_lotteryState = lotteryState.OVER;
    }

    //
    function setWinnerId(uint256 tokenId) external onlyLottery {
        winnerId = tokenId;
    }

    /**
   * @dev Function that's being used by lottery contract to get the amount of participating tickets
   */
    function sold() external view returns (uint256 totalAmountSold) {
        totalAmountSold = mintedIds.length;
        return totalAmountSold;
    }
}