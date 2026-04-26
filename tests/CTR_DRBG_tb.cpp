#include <cstdint>
#include <exception>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "CTR_DRBG_core.h"
#include "CTR_DRBG_utils.h"

static std::string toHex(const std::vector<std::uint8_t>& data) {
    std::ostringstream oss;
    oss << std::hex << std::setfill('0');
    for (std::uint8_t byte : data) {
        oss << std::setw(2) << static_cast<int>(byte);
    }
    return oss.str();
}

static void expectTrue(bool condition, const std::string& testName, const std::string& detail) {
    if (!condition) {
        throw std::runtime_error(testName + " FAILED: " + detail);
    }
    std::cout << "[PASS] " << testName << '\n';
}

static void testKnownAnswer() {
    const auto entropy = stringToBytes("0123456789abcdef0123456789abcdef");
    const auto nonce = stringToBytes("unique_nonce_123");
    const auto personalization = stringToBytes("DoAnHDL_CTR_DRBG");

    CTR_DRBG drbg(entropy, nonce, personalization);
    const auto output = drbg.generate(64);

    const std::string expected =
        "e0a22d1c36b31e3e9f173de3f6c4fc01"
        "d0d114b70fc77d108c68e7cfec154ac9"
        "f7ace5fd1818980a569c5a1a6f60578c"
        "45533907c33f25aaa569a875d46e34e4";

    expectTrue(
        toHex(output) == expected,
        "Known-answer test",
        "Output mismatch with software golden vector.");
}

static void testDeterministicSeed() {
    const auto entropy = stringToBytes("0123456789abcdef0123456789abcdef");
    const auto nonce = stringToBytes("unique_nonce_123");
    const auto personalization = stringToBytes("DoAnHDL_CTR_DRBG");

    CTR_DRBG drbgA(entropy, nonce, personalization);
    CTR_DRBG drbgB(entropy, nonce, personalization);

    const auto outputA = drbgA.generate(64);
    const auto outputB = drbgB.generate(64);

    expectTrue(
        outputA == outputB,
        "Deterministic seed test",
        "Same seed material should produce identical output.");
}

static void testAdditionalInputChangesOutput() {
    const auto entropy = stringToBytes("0123456789abcdef0123456789abcdef");
    const auto nonce = stringToBytes("unique_nonce_123");
    const auto personalization = stringToBytes("DoAnHDL_CTR_DRBG");
    const auto additionalInput = stringToBytes("frame_0001");

    CTR_DRBG drbgA(entropy, nonce, personalization);
    CTR_DRBG drbgB(entropy, nonce, personalization);

    const auto outputWithoutAdditional = drbgA.generate(64);
    const auto outputWithAdditional = drbgB.generate(64, additionalInput);

    expectTrue(
        outputWithoutAdditional != outputWithAdditional,
        "Additional input test",
        "additionalInput should perturb the generated stream.");
}

static void testReseedChangesStreamAndCounter() {
    const auto entropy = stringToBytes("0123456789abcdef0123456789abcdef");
    const auto nonce = stringToBytes("unique_nonce_123");
    const auto personalization = stringToBytes("DoAnHDL_CTR_DRBG");
    const auto newEntropy = stringToBytes("fedcba9876543210fedcba9876543210");
    const auto reseedInput = stringToBytes("reseed_phase");

    CTR_DRBG drbg(entropy, nonce, personalization);
    const auto firstOutput = drbg.generate(32);
    const auto counterAfterGenerate = drbg.reseedCounter();

    drbg.reseed(newEntropy, reseedInput);
    const auto secondOutput = drbg.generate(32);

    expectTrue(
        firstOutput != secondOutput,
        "Reseed output test",
        "Reseed must change the output stream.");

    expectTrue(
        counterAfterGenerate == 2,
        "Reseed counter before reseed test",
        "Counter should increment after generate.");

    expectTrue(
        drbg.reseedCounter() == 2,
        "Reseed counter after reseed test",
        "After reseed then generate, counter should be 2.");
}

static void testZeroLengthGenerate() {
    const auto entropy = stringToBytes("0123456789abcdef0123456789abcdef");
    const auto nonce = stringToBytes("unique_nonce_123");

    CTR_DRBG drbg(entropy, nonce);
    const auto output = drbg.generate(0);

    expectTrue(
        output.empty(),
        "Zero-length generate test",
        "Generating 0 bytes should return an empty vector.");
}

int main() {
    try {
        testKnownAnswer();
        testDeterministicSeed();
        testAdditionalInputChangesOutput();
        testReseedChangesStreamAndCounter();
        testZeroLengthGenerate();

        std::cout << "\nAll CTR_DRBG tests passed.\n";
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << '\n' << ex.what() << '\n';
        return 1;
    }
}
