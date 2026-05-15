# AES256 Verilog Core

Folder nay chi giu phan AES-256 toi thieu can cho CTR_DRBG sinh random `p` va `q` RSA.

## Module Con Lai

| Muc dich | File |
| --- | --- |
| Bang SBOX, RCON, xtime, multiply dung noi bo | `aes256_common.vh` |
| Tao round key AES-256 | `aes256_key_expansion.v` |
| Ma hoa 1 block 128-bit bang AES-256 | `aes256_encrypt_block.v` |

`CTR_DRBG` dung `aes256_encrypt_block` de sinh cac block random 128-bit. AES o day khong dung de ma hoa tin nhan RSA, chi la block cipher ben trong CTR_DRBG.

## Chay Testbench

Chay tu thu muc goc project:

```powershell
iverilog -g2012 -I verilog/AES256 -o bin/tb_aes256_key_expansion.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256_tb/tb_aes256_key_expansion.v
vvp bin/tb_aes256_key_expansion.vvp

iverilog -g2012 -I verilog/AES256 -o bin/tb_aes256_encrypt_block.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256/aes256_encrypt_block.v verilog/AES256_tb/tb_aes256_encrypt_block.v
vvp bin/tb_aes256_encrypt_block.vvp
```
