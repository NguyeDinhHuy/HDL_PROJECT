#ifndef CTR_DRBG_UTILS_H
#define CTR_DRBG_UTILS_H

#include <cstdint>
#include <string>
#include <vector>

std::vector<std::uint8_t> stringToBytes(const std::string& text);
void printHex(const std::vector<std::uint8_t>& data);

#endif
