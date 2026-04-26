#include "RSA.h"

#include "CTR_DRBG_core.h"

#include <iostream>
#include <numeric>
#include <sstream>
#include <stdexcept>

namespace rsa_demo {
namespace {

std::uint64_t modAdd(std::uint64_t a, std::uint64_t b, std::uint64_t mod) {
    a %= mod;
    b %= mod;

    if (a >= mod - b) {
        return a - (mod - b);
    }

    return a + b;
}

std::uint64_t modMultiply(std::uint64_t a, std::uint64_t b, std::uint64_t mod) {
    std::uint64_t result = 0;
    std::uint64_t factor = a % mod;

    while (b > 0) {
        if ((b & 1ULL) != 0) {
            result = modAdd(result, factor, mod);
        }

        factor = modAdd(factor, factor, mod);
        b >>= 1ULL;
    }

    return result;
}

std::uint64_t modPow(std::uint64_t base, std::uint64_t exponent, std::uint64_t mod) {
    if (mod == 1) {
        return 0;
    }

    std::uint64_t result = 1 % mod;
    std::uint64_t factor = base % mod;

    while (exponent > 0) {
        if ((exponent & 1ULL) != 0) {
            result = modMultiply(result, factor, mod);
        }

        factor = modMultiply(factor, factor, mod);
        exponent >>= 1ULL;
    }

    return result;
}

std::int64_t extendedGcd(std::int64_t a, std::int64_t b, std::int64_t& x, std::int64_t& y) {
    if (b == 0) {
        x = 1;
        y = 0;
        return a;
    }

    std::int64_t x1 = 0;
    std::int64_t y1 = 0;
    const std::int64_t gcd = extendedGcd(b, a % b, x1, y1);

    x = y1;
    y = x1 - (a / b) * y1;

    return gcd;
}

std::uint64_t modInverse(std::uint64_t value, std::uint64_t mod) {
    std::int64_t x = 0;
    std::int64_t y = 0;
    const std::int64_t gcd = extendedGcd(
        static_cast<std::int64_t>(value),
        static_cast<std::int64_t>(mod),
        x,
        y);

    if (gcd != 1) {
        throw std::invalid_argument("Public exponent has no modular inverse.");
    }

    const std::int64_t reduced = x % static_cast<std::int64_t>(mod);
    return static_cast<std::uint64_t>(
        reduced >= 0 ? reduced : reduced + static_cast<std::int64_t>(mod));
}

bool isProbablePrime(std::uint64_t candidate) {
    if (candidate < 2) {
        return false;
    }

    for (const std::uint64_t prime : {
             2ULL, 3ULL, 5ULL, 7ULL, 11ULL, 13ULL,
             17ULL, 19ULL, 23ULL, 29ULL, 31ULL, 37ULL}) {
        if (candidate == prime) {
            return true;
        }

        if ((candidate % prime) == 0) {
            return false;
        }
    }

    std::uint64_t d = candidate - 1;
    int s = 0;

    while ((d & 1ULL) == 0) {
        d >>= 1ULL;
        ++s;
    }

    for (const std::uint64_t base : {
             2ULL, 325ULL, 9375ULL, 28178ULL,
             450775ULL, 9780504ULL, 1795265022ULL}) {
        if ((base % candidate) == 0) {
            continue;
        }

        std::uint64_t x = modPow(base, d, candidate);
        if (x == 1 || x == candidate - 1) {
            continue;
        }

        bool compositeWitness = true;
        for (int r = 1; r < s; ++r) {
            x = modMultiply(x, x, candidate);
            if (x == candidate - 1) {
                compositeWitness = false;
                break;
            }
        }

        if (compositeWitness) {
            return false;
        }
    }

    return true;
}

std::uint64_t randomUint64(CTR_DRBG& drbg) {
    const std::vector<std::uint8_t> bytes = drbg.generate(sizeof(std::uint64_t));
    std::uint64_t value = 0;

    for (std::uint8_t byte : bytes) {
        value = static_cast<std::uint64_t>((value << 8) | byte);
    }

    return value;
}

std::uint64_t generatePrime(CTR_DRBG& drbg,
                            unsigned int bitLength,
                            std::ostream* traceOutput,
                            const char* name) {
    if (bitLength < 8 || bitLength > 31) {
        throw std::invalid_argument("This RSA demo supports prime sizes from 8 to 31 bits.");
    }

    const std::uint64_t highBit = 1ULL << (bitLength - 1);
    const std::uint64_t mask = (1ULL << bitLength) - 1;
    std::size_t attempt = 1;

    while (true) {
        const std::uint64_t rawRandom = randomUint64(drbg);
        std::uint64_t candidate = rawRandom & mask;
        candidate |= highBit;
        candidate |= 1ULL;

        const bool prime = isProbablePrime(candidate);
        if (traceOutput != nullptr) {
            *traceOutput << name
                         << " attempt " << attempt
                         << ": random64 = " << rawRandom
                         << ", candidate = " << candidate
                         << " -> " << (prime ? "prime" : "composite")
                         << '\n';
        }

        ++attempt;

        if (prime) {
            return candidate;
        }
    }
}

std::uint64_t fnv1a64(const std::string& text) {
    std::uint64_t hash = 1469598103934665603ULL;

    for (unsigned char ch : text) {
        hash ^= static_cast<std::uint64_t>(ch);
        hash *= 1099511628211ULL;
    }

    return hash;
}

} // namespace

KeyPair generateKeyPair(CTR_DRBG& drbg,
                        unsigned int primeBitLength,
                        std::ostream* traceOutput) {
    const std::uint64_t publicExponent = 65537;

    while (true) {
        const std::uint64_t p = generatePrime(drbg, primeBitLength, traceOutput, "p");
        std::uint64_t q = generatePrime(drbg, primeBitLength, traceOutput, "q");

        while (q == p) {
            q = generatePrime(drbg, primeBitLength, traceOutput, "q");
        }

        const std::uint64_t n = p * q;
        const std::uint64_t phi = (p - 1) * (q - 1);

        if (std::gcd(publicExponent, phi) != 1) {
            if (traceOutput != nullptr) {
                *traceOutput << "gcd(e, phi) != 1, generate another p/q pair.\n";
            }
            continue;
        }

        return KeyPair{n, publicExponent, modInverse(publicExponent, phi), p, q};
    }
}

KeyPair generateKeyPair(CTR_DRBG& drbg, unsigned int primeBitLength) {
    return generateKeyPair(drbg, primeBitLength, nullptr);
}

KeyPair generateKeyPair(CTR_DRBG& drbg,
                        unsigned int primeBitLength,
                        std::ostream& traceOutput) {
    return generateKeyPair(drbg, primeBitLength, &traceOutput);
}

std::vector<std::uint64_t> encryptBytes(const std::vector<std::uint8_t>& plaintext,
                                        const KeyPair& keyPair) {
    std::vector<std::uint64_t> ciphertext;
    ciphertext.reserve(plaintext.size());

    for (std::uint8_t byte : plaintext) {
        ciphertext.push_back(modPow(byte, keyPair.e, keyPair.n));
    }

    return ciphertext;
}

std::vector<std::uint8_t> decryptBytes(const std::vector<std::uint64_t>& ciphertext,
                                       const KeyPair& keyPair) {
    std::vector<std::uint8_t> plaintext;
    plaintext.reserve(ciphertext.size());

    for (std::uint64_t block : ciphertext) {
        const std::uint64_t message = modPow(block, keyPair.d, keyPair.n);

        if (message > 0xFF) {
            throw std::runtime_error("Decrypted block does not fit in one byte.");
        }

        plaintext.push_back(static_cast<std::uint8_t>(message));
    }

    return plaintext;
}

std::uint64_t signMessage(const std::string& message, const KeyPair& keyPair) {
    const std::uint64_t digest = fnv1a64(message) % keyPair.n;
    return modPow(digest, keyPair.d, keyPair.n);
}

bool verifySignature(const std::string& message,
                     std::uint64_t signature,
                     const KeyPair& keyPair) {
    const std::uint64_t recoveredDigest = modPow(signature, keyPair.e, keyPair.n);
    return recoveredDigest == (fnv1a64(message) % keyPair.n);
}

std::string ciphertextToString(const std::vector<std::uint64_t>& ciphertext) {
    std::ostringstream oss;

    for (std::size_t i = 0; i < ciphertext.size(); ++i) {
        if (i != 0) {
            oss << ' ';
        }

        oss << ciphertext[i];
    }

    return oss.str();
}

} // namespace rsa_demo
