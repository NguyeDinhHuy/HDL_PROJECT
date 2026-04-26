#ifndef CTR_DRBG_CORE_H
#define CTR_DRBG_CORE_H

#include <cstddef>
#include <cstdint>
#include <vector>

class CTR_DRBG {
public:
    static const int BLOCK_SIZE = 16;
    static const int KEY_SIZE = 32;
    static const int SEED_LENGTH = KEY_SIZE + BLOCK_SIZE;
    static const std::uint64_t RESEED_INTERVAL = 1ULL << 32;

    CTR_DRBG(const std::vector<std::uint8_t>& entropy,
             const std::vector<std::uint8_t>& nonce,
             const std::vector<std::uint8_t>& personalization = std::vector<std::uint8_t>());

    void reseed(const std::vector<std::uint8_t>& entropy,
                const std::vector<std::uint8_t>& additionalInput = std::vector<std::uint8_t>());

    std::vector<std::uint8_t> generate(
        std::size_t numberOfBytes,
        const std::vector<std::uint8_t>& additionalInput = std::vector<std::uint8_t>());

    std::uint64_t reseedCounter() const;

private:
    std::uint8_t key_[KEY_SIZE];
    std::uint8_t V_[BLOCK_SIZE];
    std::uint64_t reseedCounter_;

    void clearState();
    void incrementCounter();
    void updateState(const std::vector<std::uint8_t>& providedData);
    void generateBlocks(std::size_t numberOfBytes, std::vector<std::uint8_t>& output);
    void loadKeyFromSeed(const std::vector<std::uint8_t>& seed);
    void loadCounterFromSeed(const std::vector<std::uint8_t>& seed);

    static std::vector<std::uint8_t> concatenateTwoInputs(
        const std::vector<std::uint8_t>& first,
        const std::vector<std::uint8_t>& second);

    static std::vector<std::uint8_t> concatenateThreeInputs(
        const std::vector<std::uint8_t>& first,
        const std::vector<std::uint8_t>& second,
        const std::vector<std::uint8_t>& third);

    static void appendBigEndianU32(std::uint32_t value, std::vector<std::uint8_t>& output);
    static std::vector<std::uint8_t> padData(const std::vector<std::uint8_t>& input);
    static void buildBccInput(std::uint32_t counter,
                              const std::vector<std::uint8_t>& data,
                              std::vector<std::uint8_t>& output);
    static std::vector<std::uint8_t> bcc(const std::uint8_t key[KEY_SIZE],
                                         const std::vector<std::uint8_t>& data);
    static std::vector<std::uint8_t> derivationFunction(const std::vector<std::uint8_t>& input,
                                                        std::size_t outputLength);
};

#endif
