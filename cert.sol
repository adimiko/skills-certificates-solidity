pragma solidity ^0.8.7;

contract Certificates {

    string constant ISSUED = "ISSUED";
    string constant REVOKED = "REVOKED";

    struct Certificate {
        string name;
        address issuedBy;
        string status;
        uint256 momentOfIssue;
        uint256 validUntil;
    }

    struct Description {
        string description;
    }

    mapping(address => mapping(string => Certificate)) private _certificate;

    mapping(address => mapping(string => Description)) private _description;

    function createOrUpdateDescription(string calldata name, string calldata description) external {
        _description[msg.sender][name].description = description;
    }

    function getMyCertyficate(string calldata hash) external view returns (Certificate memory, Description memory) {
        return getCertyficate(msg.sender, hash);
    }

    function getCertyficate(address issuedTo, string calldata hash) public view returns (Certificate memory, Description memory) {
        require(_certificate[issuedTo][hash].issuedBy != address(0), "Certificate does not exist");
        require(compareStrings(_certificate[issuedTo][hash].status, ISSUED), "Certificate does not exist");
        require(!(_certificate[issuedTo][hash].validUntil > 0 && _certificate[issuedTo][hash].validUntil <= block.timestamp), "Certificate is expired");
        
        return (_certificate[issuedTo][hash], _description[_certificate[issuedTo][hash].issuedBy][_certificate[issuedTo][hash].name]);
    }

    function issueCertificate(string calldata name, address issuedTo, string calldata hash) external {
        issueCertificate(name, issuedTo, hash, 0);
    }

    function issueCertificate(string calldata name, address issuedTo, string calldata hash, uint numberOfMonths) public {
        validateCertificate(issuedTo, hash);

        uint256 timestamp = block.timestamp;
        _certificate[issuedTo][hash].name = name;
        _certificate[issuedTo][hash].issuedBy = msg.sender;
        _certificate[issuedTo][hash].status = ISSUED;
        _certificate[issuedTo][hash].momentOfIssue = timestamp;

        if(numberOfMonths > 0)
        {
            _certificate[issuedTo][hash].validUntil = timestamp + (numberOfMonths * 2592000);
        }
        else
        {
            _certificate[issuedTo][hash].validUntil = 0;
        }
    }

    function revokeCertificate(address issuedTo, string calldata hash) external {
        checkSenderIsIssuer(issuedTo, hash);

        _certificate[issuedTo][hash].status = REVOKED;
    }

    function restoreCertificate(address issuedTo, string calldata hash) external {
        checkSenderIsIssuer(issuedTo, hash);

        require(compareStrings(_certificate[issuedTo][hash].status, REVOKED), "Certificate is not revoked");

        _certificate[issuedTo][hash].status = ISSUED;
    }

    function updateCertificate(address issuedTo, string calldata previousHash, string calldata newHash) external {
        checkSenderIsIssuer(issuedTo, previousHash);

        _certificate[issuedTo][newHash].issuedBy = _certificate[issuedTo][previousHash].issuedBy;
        _certificate[issuedTo][newHash].status = _certificate[issuedTo][previousHash].status ;
        _certificate[issuedTo][newHash].momentOfIssue = _certificate[issuedTo][previousHash].momentOfIssue;
        _certificate[issuedTo][newHash].validUntil = _certificate[issuedTo][previousHash].validUntil;

        _certificate[issuedTo][previousHash].issuedBy = address(0);
        _certificate[issuedTo][previousHash].status = "";
        _certificate[issuedTo][previousHash].momentOfIssue = 0;
        _certificate[issuedTo][previousHash].validUntil = 0;
    }

    function checkSenderIsIssuer(address issuedTo, string calldata hash) private view {
        require(_certificate[issuedTo][hash].issuedBy == msg.sender, "You are not issuer this certificate");
    }

    function validateCertificate(address issuedTo, string calldata hash) private pure {
        require(issuedTo != address(0), "Invalid argument issuedTo");
        uint hashLength = bytes(hash).length;
        require(hashLength == 64 || hashLength == 128, "Invalid argument hash");
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}