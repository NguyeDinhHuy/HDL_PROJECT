#ifndef AES256_H
#define AES256_H

#include <cstddef>
#include <cstdint>

class AES256 {
public:
    static const int BLOCK_SIZE = 16;
    static const int KEY_SIZE = 32;
    static const int ROUND_KEY_SIZE = 240;

    AES256(const std::uint8_t key[KEY_SIZE]);

    void encryptBlock(const std::uint8_t input[BLOCK_SIZE],
                      std::uint8_t output[BLOCK_SIZE]) const;

private:
    std::uint8_t roundKeys_[ROUND_KEY_SIZE];

    static const std::uint8_t SBOX[256];
    static const std::uint8_t RCON[15];

    static std::uint8_t xtime(std::uint8_t value);
    static std::uint8_t multiply(std::uint8_t x, std::uint8_t y);

    void keyExpansion(const std::uint8_t key[KEY_SIZE]);
    void addRoundKey(std::uint8_t state[BLOCK_SIZE], int round) const;

    static void subBytes(std::uint8_t state[BLOCK_SIZE]);
    static void shiftRows(std::uint8_t state[BLOCK_SIZE]);
    static void mixColumns(std::uint8_t state[BLOCK_SIZE]);
};

#endif
