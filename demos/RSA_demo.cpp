#include "RSA.h"

#include "CTR_DRBG_core.h"
#include "CTR_DRBG_utils.h"

#include <cstdint>
#include <exception>
#include <iostream>
#include <string>
#include <vector>

namespace {

std::string bytesToString(const std::vector<std::uint8_t>& data) {
    return std::string(data.begin(), data.end());
}

void printKeyPair(const rsa_demo::KeyPair& keyPair) {
    std::cout << "RSA key pair (demo 62-bit modulus)\n";
    std::cout << "p = " << keyPair.p << '\n';
    std::cout << "q = " << keyPair.q << '\n';
    std::cout << "n = " << keyPair.n << '\n';
    std::cout << "e = " << keyPair.e << '\n';
    std::cout << "d = " << keyPair.d << "\n\n";
}

} // namespace

int main() {
    try {
        const std::vector<std::uint8_t> entropy =
            stringToBytes("0123456789abcdef0123456789abcdef");
        const std::vector<std::uint8_t> nonce =
            stringToBytes("rsa_nonce_demo_1");
        const std::vector<std::uint8_t> personalization =
            stringToBytes("DoAnHDL_RSA");

        CTR_DRBG drbg(entropy, nonce, personalization);

        std::cout << "Qua trinh sinh p va q tu CTR_DRBG:\n";
        const rsa_demo::KeyPair keyPair = rsa_demo::generateKeyPair(drbg, 31, std::cout);
        std::cout << '\n';

        std::string message;
        std::cout << "Nhap msg_input: ";
        std::getline(std::cin, message);

        if (message.empty()) {
            message = "RSA demo";
        }

        const std::vector<std::uint8_t> plaintext = stringToBytes(message);
        const std::vector<std::uint64_t> ciphertext =
            rsa_demo::encryptBytes(plaintext, keyPair);
        const std::vector<std::uint8_t> recovered =
            rsa_demo::decryptBytes(ciphertext, keyPair);

        const std::uint64_t signature = rsa_demo::signMessage(message, keyPair);
        const bool validSignature =
            rsa_demo::verifySignature(message, signature, keyPair);
        const bool tamperedSignature =
            rsa_demo::verifySignature(message + "!", signature, keyPair);

        printKeyPair(keyPair);

        std::cout << "Plaintext          : " << message << '\n';
        std::cout << "Ciphertext blocks  : "
                  << rsa_demo::ciphertextToString(ciphertext) << '\n';
        std::cout << "Recovered plaintext: " << bytesToString(recovered) << '\n';
        std::cout << "Signature          : " << signature << '\n';
        std::cout << "Verify original    : "
                  << (validSignature ? "valid" : "invalid") << '\n';
        std::cout << "Verify tampered    : "
                  << (tamperedSignature ? "valid" : "invalid") << '\n';

        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << '\n';
        return 1;
    }
}
