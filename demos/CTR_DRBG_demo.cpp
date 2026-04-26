#include "CTR_DRBG_core.h"
#include "CTR_DRBG_utils.h"

#include <exception>
#include <iostream>

int main() {
    try {
        std::vector<std::uint8_t> entropy =
            stringToBytes("0123456789abcdef0123456789abcdef");
        std::vector<std::uint8_t> nonce =
            stringToBytes("0003");
        std::vector<std::uint8_t> personalization =
            stringToBytes("DoAnHDL_CTR_DRBG_2");

        CTR_DRBG drbg(entropy, nonce, personalization);
        std::vector<std::uint8_t> randomBytes = drbg.generate(64);

        std::cout << "CTR_DRBG output (64 bytes): ";
        printHex(randomBytes);

        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << '\n';
        return 1;
    }
}
