# Do_An_HDL

Project demo AES-256, CTR_DRBG, va RSA bang C++.

## Cau truc thu muc

- `include/`: cac file header dung chung.
- `src/`: ma nguon thuat toan.
- `demos/`: chuong trinh demo co ham `main()`.
- `tests/`: testbench.
- `bin/`: file `.exe` sau khi build.

## Build

```powershell
.\build.ps1 all
```

Build rieng RSA demo:

```powershell
.\build.ps1 rsa
```

Build benchmark:

```powershell
.\build.ps1 benchmark
```

## Run

```powershell
.\bin\RSA_demo.exe
.\bin\CTR_DRBG_demo.exe
.\bin\CTR_DRBG_tb.exe
.\bin\crypto_benchmark.exe
```

Luu y: RSA trong project nay la ban demo hoc tap voi modulus 62-bit, khong dung cho bao mat thuc te.

Benchmark se in bang thoi gian ra terminal va ghi file `bin/benchmark_results.csv`.
