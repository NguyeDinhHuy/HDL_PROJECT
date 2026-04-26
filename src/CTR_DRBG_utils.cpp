#include "CTR_DRBG_utils.h"

#include <iomanip>
#include <iostream>

std::vector<std::uint8_t> stringToBytes(const std::string& text) {
    std::vector<std::uint8_t> bytes;

    for (std::size_t i = 0; i < text.size(); ++i) {
        bytes.push_back(static_cast<std::uint8_t>(text[i]));
    }

    return bytes;
}

void printHex(const std::vector<std::uint8_t>& data) {
    for (std::size_t i = 0; i < data.size(); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0')
                  << static_cast<int>(data[i]);
    }

    std::cout << std::dec << '\n';
}
