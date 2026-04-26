#ifndef RSA_H
#define RSA_H

#include <cstdint>
#include <iosfwd>
#include <string>
#include <vector>

class CTR_DRBG;

namespace rsa_demo {

struct KeyPair {
    std::uint64_t n{};
    std::uint64_t e{};
    std::uint64_t d{};
    std::uint64_t p{};
    std::uint64_t q{};
};

KeyPair generateKeyPair(CTR_DRBG& drbg, unsigned int primeBitLength = 31);

KeyPair generateKeyPair(CTR_DRBG& drbg,
                        unsigned int primeBitLength,
                        std::ostream& traceOutput);

std::vector<std::uint64_t> encryptBytes(const std::vector<std::uint8_t>& plaintext,
                                        const KeyPair& keyPair);

std::vector<std::uint8_t> decryptBytes(const std::vector<std::uint64_t>& ciphertext,
                                       const KeyPair& keyPair);

std::uint64_t signMessage(const std::string& message, const KeyPair& keyPair);

bool verifySignature(const std::string& message,
                     std::uint64_t signature,
                     const KeyPair& keyPair);

std::string ciphertextToString(const std::vector<std::uint64_t>& ciphertext);

} // namespace rsa_demo

#endif
