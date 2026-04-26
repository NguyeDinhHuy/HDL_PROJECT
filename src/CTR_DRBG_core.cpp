#include "CTR_DRBG_core.h"

#include "AES256.h"

#include <stdexcept>

CTR_DRBG::CTR_DRBG(const std::vector<std::uint8_t>& entropy,
                   const std::vector<std::uint8_t>& nonce,
                   const std::vector<std::uint8_t>& personalization) {
    clearState();
    reseedCounter_ = 0;

    std::vector<std::uint8_t> seedMaterial =
        concatenateThreeInputs(entropy, nonce, personalization);
    std::vector<std::uint8_t> seed =
        derivationFunction(seedMaterial, SEED_LENGTH);

    updateState(seed);
    reseedCounter_ = 1;
}

void CTR_DRBG::reseed(const std::vector<std::uint8_t>& entropy,
                      const std::vector<std::uint8_t>& additionalInput) {
    std::vector<std::uint8_t> seedMaterial =
        concatenateTwoInputs(entropy, additionalInput);
    std::vector<std::uint8_t> seed =
        derivationFunction(seedMaterial, SEED_LENGTH);

    updateState(seed);
    reseedCounter_ = 1;
}

std::vector<std::uint8_t> CTR_DRBG::generate(
    std::size_t numberOfBytes,
    const std::vector<std::uint8_t>& additionalInput) {
    if (reseedCounter_ > RESEED_INTERVAL) {
        throw std::runtime_error("CTR_DRBG requires reseed before generating more output.");
    }

    std::vector<std::uint8_t> seedFromAdditionalInput;
    bool hasAdditionalInput = !additionalInput.empty();

    if (hasAdditionalInput) {
        seedFromAdditionalInput = derivationFunction(additionalInput, SEED_LENGTH);
        updateState(seedFromAdditionalInput);
    }

    std::vector<std::uint8_t> output;
    output.reserve(numberOfBytes);
    generateBlocks(numberOfBytes, output);

    if (hasAdditionalInput) {
        updateState(seedFromAdditionalInput);
    } else {
        std::vector<std::uint8_t> emptyData;
        updateState(emptyData);
    }

    ++reseedCounter_;
    return output;
}

std::uint64_t CTR_DRBG::reseedCounter() const {
    return reseedCounter_;
}

void CTR_DRBG::clearState() {
    for (int i = 0; i < KEY_SIZE; ++i) {
        key_[i] = 0;
    }

    for (int i = 0; i < BLOCK_SIZE; ++i) {
        V_[i] = 0;
    }
}

void CTR_DRBG::incrementCounter() {
    for (int i = BLOCK_SIZE - 1; i >= 0; --i) {
        V_[i] = static_cast<std::uint8_t>(V_[i] + 1);

        if (V_[i] != 0) {
            break;
        }
    }
}

void CTR_DRBG::generateBlocks(std::size_t numberOfBytes,
                              std::vector<std::uint8_t>& output) {
    AES256 cipher(key_);

    while (output.size() < numberOfBytes) {
        std::uint8_t encryptedCounter[BLOCK_SIZE];

        incrementCounter();
        cipher.encryptBlock(V_, encryptedCounter);

        for (int i = 0; i < BLOCK_SIZE && output.size() < numberOfBytes; ++i) {
            output.push_back(encryptedCounter[i]);
        }
    }
}

void CTR_DRBG::updateState(const std::vector<std::uint8_t>& providedData) {
    std::vector<std::uint8_t> temp;
    AES256 cipher(key_);

    temp.reserve(SEED_LENGTH);

    while (temp.size() < SEED_LENGTH) {
        std::uint8_t encryptedCounter[BLOCK_SIZE];

        incrementCounter();
        cipher.encryptBlock(V_, encryptedCounter);

        for (int i = 0; i < BLOCK_SIZE; ++i) {
            temp.push_back(encryptedCounter[i]);
        }
    }

    if (!providedData.empty()) {
        if (providedData.size() < SEED_LENGTH) {
            throw std::invalid_argument("providedData must contain 48 bytes.");
        }

        for (int i = 0; i < SEED_LENGTH; ++i) {
            temp[i] = static_cast<std::uint8_t>(temp[i] ^ providedData[i]);
        }
    }

    loadKeyFromSeed(temp);
    loadCounterFromSeed(temp);
}

void CTR_DRBG::loadKeyFromSeed(const std::vector<std::uint8_t>& seed) {
    for (int i = 0; i < KEY_SIZE; ++i) {
        key_[i] = seed[i];
    }
}

void CTR_DRBG::loadCounterFromSeed(const std::vector<std::uint8_t>& seed) {
    for (int i = 0; i < BLOCK_SIZE; ++i) {
        V_[i] = seed[KEY_SIZE + i];
    }
}

std::vector<std::uint8_t> CTR_DRBG::concatenateTwoInputs(
    const std::vector<std::uint8_t>& first,
    const std::vector<std::uint8_t>& second) {
    std::vector<std::uint8_t> result;

    result.reserve(first.size() + second.size());

    for (std::size_t i = 0; i < first.size(); ++i) {
        result.push_back(first[i]);
    }

    for (std::size_t i = 0; i < second.size(); ++i) {
        result.push_back(second[i]);
    }

    return result;
}

std::vector<std::uint8_t> CTR_DRBG::concatenateThreeInputs(
    const std::vector<std::uint8_t>& first,
    const std::vector<std::uint8_t>& second,
    const std::vector<std::uint8_t>& third) {
    std::vector<std::uint8_t> result = concatenateTwoInputs(first, second);

    result.reserve(first.size() + second.size() + third.size());

    for (std::size_t i = 0; i < third.size(); ++i) {
        result.push_back(third[i]);
    }

    return result;
}

void CTR_DRBG::appendBigEndianU32(std::uint32_t value,
                                  std::vector<std::uint8_t>& output) {
    output.push_back(static_cast<std::uint8_t>((value >> 24) & 0xFF));
    output.push_back(static_cast<std::uint8_t>((value >> 16) & 0xFF));
    output.push_back(static_cast<std::uint8_t>((value >> 8) & 0xFF));
    output.push_back(static_cast<std::uint8_t>(value & 0xFF));
}

std::vector<std::uint8_t> CTR_DRBG::padData(const std::vector<std::uint8_t>& input) {
    std::vector<std::uint8_t> padded;

    for (std::size_t i = 0; i < input.size(); ++i) {
        padded.push_back(input[i]);
    }

    padded.push_back(0x80);

    while ((padded.size() % BLOCK_SIZE) != 0) {
        padded.push_back(0x00);
    }

    return padded;
}

void CTR_DRBG::buildBccInput(std::uint32_t counter,
                             const std::vector<std::uint8_t>& data,
                             std::vector<std::uint8_t>& output) {
    output.clear();

    appendBigEndianU32(counter, output);

    for (std::size_t i = 0; i < data.size(); ++i) {
        output.push_back(data[i]);
    }

    while ((output.size() % BLOCK_SIZE) != 0) {
        output.push_back(0x00);
    }
}

std::vector<std::uint8_t> CTR_DRBG::bcc(const std::uint8_t key[KEY_SIZE],
                                        const std::vector<std::uint8_t>& data) {
    if ((data.size() % BLOCK_SIZE) != 0) {
        throw std::invalid_argument("BCC input must be aligned to block size.");
    }

    AES256 cipher(key);
    std::uint8_t chainingValue[BLOCK_SIZE];

    for (int i = 0; i < BLOCK_SIZE; ++i) {
        chainingValue[i] = 0;
    }

    for (std::size_t offset = 0; offset < data.size(); offset += BLOCK_SIZE) {
        std::uint8_t block[BLOCK_SIZE];
        std::uint8_t encryptedBlock[BLOCK_SIZE];

        for (int i = 0; i < BLOCK_SIZE; ++i) {
            block[i] = static_cast<std::uint8_t>(data[offset + i] ^ chainingValue[i]);
        }

        cipher.encryptBlock(block, encryptedBlock);

        for (int i = 0; i < BLOCK_SIZE; ++i) {
            chainingValue[i] = encryptedBlock[i];
        }
    }

    std::vector<std::uint8_t> result;

    for (int i = 0; i < BLOCK_SIZE; ++i) {
        result.push_back(chainingValue[i]);
    }

    return result;
}

std::vector<std::uint8_t> CTR_DRBG::derivationFunction(
    const std::vector<std::uint8_t>& input,
    std::size_t outputLength) {
    std::uint8_t dfKey[KEY_SIZE];

    for (int i = 0; i < KEY_SIZE; ++i) {
        dfKey[i] = static_cast<std::uint8_t>(i);
    }

    std::vector<std::uint8_t> S;
    std::uint32_t inputLengthBits = static_cast<std::uint32_t>(input.size() * 8);
    std::uint32_t outputLengthBits = static_cast<std::uint32_t>(outputLength * 8);

    appendBigEndianU32(inputLengthBits, S);
    appendBigEndianU32(outputLengthBits, S);

    for (std::size_t i = 0; i < input.size(); ++i) {
        S.push_back(input[i]);
    }

    S = padData(S);

    std::vector<std::uint8_t> temp;
    std::uint32_t counter = 0;

    while (temp.size() < SEED_LENGTH) {
        std::vector<std::uint8_t> bccInput;
        std::vector<std::uint8_t> block;

        buildBccInput(counter, S, bccInput);
        block = bcc(dfKey, bccInput);

        for (std::size_t i = 0; i < block.size(); ++i) {
            temp.push_back(block[i]);
        }

        ++counter;
    }

    std::uint8_t key[KEY_SIZE];
    std::uint8_t X[BLOCK_SIZE];

    for (int i = 0; i < KEY_SIZE; ++i) {
        key[i] = temp[i];
    }

    for (int i = 0; i < BLOCK_SIZE; ++i) {
        X[i] = temp[KEY_SIZE + i];
    }

    AES256 cipher(key);
    std::vector<std::uint8_t> requestedBytes;

    requestedBytes.reserve(outputLength);

    while (requestedBytes.size() < outputLength) {
        std::uint8_t nextX[BLOCK_SIZE];

        cipher.encryptBlock(X, nextX);

        for (int i = 0; i < BLOCK_SIZE; ++i) {
            X[i] = nextX[i];
        }

        for (int i = 0; i < BLOCK_SIZE && requestedBytes.size() < outputLength; ++i) {
            requestedBytes.push_back(X[i]);
        }
    }

    return requestedBytes;
}
