param(
    [ValidateSet("rsa", "ctr-drbg", "ctr-drbg-test", "benchmark", "all")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

$Compiler = "C:\Users\NguyenHuy\Downloads\mingw64\bin\g++.exe"
$CommonArgs = @(
    "-std=c++17",
    "-Wall",
    "-Wextra",
    "-pedantic",
    "-Iinclude"
)

New-Item -ItemType Directory -Force bin | Out-Null

function Build-RsaDemo {
    & $Compiler @CommonArgs `
        "demos/RSA_demo.cpp" `
        "src/RSA.cpp" `
        "src/CTR_DRBG_core.cpp" `
        "src/CTR_DRBG_utils.cpp" `
        "src/AES256.cpp" `
        "-o" "bin/RSA_demo.exe"
    if ($LASTEXITCODE -ne 0) { throw "Build RSA demo failed." }
}

function Build-CtrDrbgDemo {
    & $Compiler @CommonArgs `
        "demos/CTR_DRBG_demo.cpp" `
        "src/CTR_DRBG_core.cpp" `
        "src/CTR_DRBG_utils.cpp" `
        "src/AES256.cpp" `
        "-o" "bin/CTR_DRBG_demo.exe"
    if ($LASTEXITCODE -ne 0) { throw "Build CTR_DRBG demo failed." }
}

function Build-CtrDrbgTest {
    & $Compiler @CommonArgs `
        "tests/CTR_DRBG_tb.cpp" `
        "src/CTR_DRBG_core.cpp" `
        "src/CTR_DRBG_utils.cpp" `
        "src/AES256.cpp" `
        "-o" "bin/CTR_DRBG_tb.exe"
    if ($LASTEXITCODE -ne 0) { throw "Build CTR_DRBG test failed." }
}

function Build-Benchmark {
    & $Compiler @CommonArgs `
        "benchmarks/crypto_benchmark.cpp" `
        "src/RSA.cpp" `
        "src/CTR_DRBG_core.cpp" `
        "src/CTR_DRBG_utils.cpp" `
        "src/AES256.cpp" `
        "-o" "bin/crypto_benchmark.exe"
    if ($LASTEXITCODE -ne 0) { throw "Build benchmark failed." }
}

switch ($Target) {
    "rsa" { Build-RsaDemo }
    "ctr-drbg" { Build-CtrDrbgDemo }
    "ctr-drbg-test" { Build-CtrDrbgTest }
    "benchmark" { Build-Benchmark }
    "all" {
        Build-RsaDemo
        Build-CtrDrbgDemo
        Build-CtrDrbgTest
        Build-Benchmark
    }
}

Write-Host "Build completed: $Target"
