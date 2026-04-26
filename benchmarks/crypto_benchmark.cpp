#include "AES256.h"
#include "CTR_DRBG_core.h"
#include "CTR_DRBG_utils.h"
#include "RSA.h"

#include <chrono>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {

using Clock = std::chrono::high_resolution_clock;

struct BenchmarkResult {
    std::string algorithm;
    std::string operation;
    std::size_t inputBytes{};
    std::size_t iterations{};
    double totalMicroseconds{};
    double averageMicroseconds{};
};

template <typename Function>
double measureMicroseconds(Function function) {
    const auto start = Clock::now();
    function();
    const auto end = Clock::now();

    return static_cast<double>(
        std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count()) /
        1000.0;
}

CTR_DRBG makeDrbg(const std::string& personalization) {
    return CTR_DRBG(
        stringToBytes("0123456789abcdef0123456789abcdef"),
        stringToBytes("benchmark_nonce"),
        stringToBytes(personalization));
}

std::string makeMessage(std::size_t size) {
    const std::string pattern = "DoAnHDL RSA benchmark input ";
    std::string message;
    message.reserve(size);

    while (message.size() < size) {
        message += pattern;
    }

    message.resize(size);
    return message;
}

void addResult(std::vector<BenchmarkResult>& results,
               const std::string& algorithm,
               const std::string& operation,
               std::size_t inputBytes,
               std::size_t iterations,
               double totalMicroseconds) {
    results.push_back(BenchmarkResult{
        algorithm,
        operation,
        inputBytes,
        iterations,
        totalMicroseconds,
        totalMicroseconds / static_cast<double>(iterations)});
}

void benchmarkRsa(std::vector<BenchmarkResult>& results) {
    CTR_DRBG keyDrbg = makeDrbg("DoAnHDL_RSA_keygen_bench");

    rsa_demo::KeyPair keyPair;
    const double keygenTime = measureMicroseconds([&]() {
        keyPair = rsa_demo::generateKeyPair(keyDrbg);
    });
    addResult(results, "RSA", "keygen", 0, 1, keygenTime);

    const std::vector<std::size_t> messageSizes = {16, 64, 256};

    for (std::size_t messageSize : messageSizes) {
        const std::string message = makeMessage(messageSize);
        const std::vector<std::uint8_t> plaintext = stringToBytes(message);
        std::vector<std::uint64_t> ciphertext;
        std::vector<std::uint8_t> recovered;
        std::uint64_t signature = 0;
        bool valid = false;

        const double encryptTime = measureMicroseconds([&]() {
            ciphertext = rsa_demo::encryptBytes(plaintext, keyPair);
        });
        addResult(results, "RSA", "encrypt", messageSize, 1, encryptTime);

        const double decryptTime = measureMicroseconds([&]() {
            recovered = rsa_demo::decryptBytes(ciphertext, keyPair);
        });
        addResult(results, "RSA", "decrypt", messageSize, 1, decryptTime);

        const double signTime = measureMicroseconds([&]() {
            signature = rsa_demo::signMessage(message, keyPair);
        });
        addResult(results, "RSA", "sign", messageSize, 1, signTime);

        const double verifyTime = measureMicroseconds([&]() {
            valid = rsa_demo::verifySignature(message, signature, keyPair);
        });
        addResult(results, "RSA", "verify", messageSize, 1, verifyTime);

        if (recovered != plaintext || !valid) {
            throw std::runtime_error("RSA benchmark self-check failed.");
        }
    }
}

void benchmarkCtrDrbg(std::vector<BenchmarkResult>& results) {
    const std::vector<std::size_t> outputSizes = {16, 64, 256, 1024};

    for (std::size_t outputSize : outputSizes) {
        CTR_DRBG drbg = makeDrbg("DoAnHDL_CTR_DRBG_bench");
        std::vector<std::uint8_t> output;

        const double totalTime = measureMicroseconds([&]() {
            output = drbg.generate(outputSize);
        });

        if (output.size() != outputSize) {
            throw std::runtime_error("CTR_DRBG benchmark self-check failed.");
        }

        addResult(results, "CTR_DRBG", "generate", outputSize, 1, totalTime);
    }
}

void benchmarkAes256(std::vector<BenchmarkResult>& results) {
    std::uint8_t key[AES256::KEY_SIZE];
    std::uint8_t input[AES256::BLOCK_SIZE];
    std::uint8_t output[AES256::BLOCK_SIZE];

    for (int i = 0; i < AES256::KEY_SIZE; ++i) {
        key[i] = static_cast<std::uint8_t>(i);
    }

    for (int i = 0; i < AES256::BLOCK_SIZE; ++i) {
        input[i] = static_cast<std::uint8_t>(i * 3);
        output[i] = 0;
    }

    AES256 aes(key);
    const std::size_t iterations = 10000;

    const double totalTime = measureMicroseconds([&]() {
        for (std::size_t i = 0; i < iterations; ++i) {
            aes.encryptBlock(input, output);
            input[0] = static_cast<std::uint8_t>(input[0] + output[15]);
        }
    });

    addResult(results, "AES256", "encrypt_block", AES256::BLOCK_SIZE, iterations, totalTime);
}

void printResults(const std::vector<BenchmarkResult>& results) {
    std::cout << std::left << std::setw(10) << "Algorithm"
              << std::setw(16) << "Operation"
              << std::right << std::setw(12) << "Bytes"
              << std::setw(14) << "Iterations"
              << std::setw(18) << "Total us"
              << std::setw(18) << "Average us"
              << '\n';

    for (const BenchmarkResult& result : results) {
        std::cout << std::left << std::setw(10) << result.algorithm
                  << std::setw(16) << result.operation
                  << std::right << std::setw(12) << result.inputBytes
                  << std::setw(14) << result.iterations
                  << std::setw(18) << std::fixed << std::setprecision(3)
                  << result.totalMicroseconds
                  << std::setw(18) << result.averageMicroseconds
                  << '\n';
    }
}

void writeCsv(const std::vector<BenchmarkResult>& results, const std::string& path) {
    std::ofstream file(path);

    file << "algorithm,operation,input_bytes,iterations,total_us,average_us\n";

    for (const BenchmarkResult& result : results) {
        file << result.algorithm << ','
             << result.operation << ','
             << result.inputBytes << ','
             << result.iterations << ','
             << std::fixed << std::setprecision(3) << result.totalMicroseconds << ','
             << result.averageMicroseconds << '\n';
    }
}

} // namespace

int main() {
    try {
        std::vector<BenchmarkResult> results;

        benchmarkRsa(results);
        benchmarkCtrDrbg(results);
        benchmarkAes256(results);

        printResults(results);
        writeCsv(results, "bin/benchmark_results.csv");

        std::cout << "\nCSV output: bin/benchmark_results.csv\n";
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "Benchmark error: " << ex.what() << '\n';
        return 1;
    }
}
