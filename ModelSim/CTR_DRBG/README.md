# CTR_DRBG Verilog Modules

Folder nay tach cac khoi loi trong `src/CTR_DRBG_core.cpp` thanh module Verilog rieng.
Testbench nam trong `verilog/CTR_DRBG_tb`.

## Mapping

| Ham C++ | Module | Testbench |
| --- | --- | --- |
| `incrementCounter()` | `ctr_drbg_increment_counter.v` | `../CTR_DRBG_tb/tb_ctr_drbg_increment_counter.v` |
| `generateBlocks()` moi block | `ctr_drbg_generate_block.v` | `../CTR_DRBG_tb/tb_ctr_drbg_generate_block.v` |
| `updateState()` | `ctr_drbg_update_state.v` | `../CTR_DRBG_tb/tb_ctr_drbg_update_state.v` |
| `bcc()` moi block | `ctr_drbg_bcc_block.v` | `../CTR_DRBG_tb/tb_ctr_drbg_bcc_block.v` |
| Sinh ung vien `p`, `q` 512-bit cho RSA | `ctr_drbg_rsa_pq_generator.v` | `../CTR_DRBG_tb/tb_ctr_drbg_rsa_pq_generator.v` |

`ctr_drbg_generate_block`, `ctr_drbg_update_state`, va `ctr_drbg_bcc_block` dung lai `aes256_encrypt_block` trong `verilog/AES256`.

## Sinh p va q cho RSA

`ctr_drbg_rsa_pq_generator` nhan:

- `entropy_seed[383:0]`: seed bi mat tu nguon entropy ben ngoai.
- `personalization[383:0]`: input tuy bien do nguoi dung/cau hinh dua vao.
- `nonce_value`: bo dem noi bo, tang 1 moi lan `start`.

Module tra ve:

- `p_candidate[511:0]`
- `q_candidate[511:0]`

Hai output nay da duoc ep bit 511 = 1 va bit 0 = 1, nen la ung vien 512-bit le. De thanh `p`, `q` RSA dung duoc, can dua tiep qua khoi kiem tra nguyen to, vi CTR_DRBG chi sinh so ngau nhien chu khong bao dam so do la so nguyen to.

Khong nen hardcode entropy trong Verilog. Neu hardcode, entropy se bi lo trong source/bitstream. Hay noi `entropy_seed` voi TRNG, PUF, noise ADC, ring oscillator sampler, hoac seed bi mat nap tu kenh an toan luc thiet bi khoi dong.

## Ghi chu

Phan Verilog nay tach cac primitive phan cung co dinh do dai block. Cac ham software bien do dai nhu `concatenateTwoInputs`, `concatenateThreeInputs`, `appendBigEndianU32`, `padData`, `buildBccInput`, va vong lap day du cua `derivationFunction()` chua duoc boc thanh mot top-level CTR_DRBG hoan chinh.

## Chay testbench voi Icarus Verilog

Chay tu thu muc goc project:

```powershell
iverilog -g2012 -I verilog/AES256 -I verilog/CTR_DRBG -o bin/tb_ctr_drbg_increment_counter.vvp verilog/CTR_DRBG/ctr_drbg_increment_counter.v verilog/CTR_DRBG_tb/tb_ctr_drbg_increment_counter.v
vvp bin/tb_ctr_drbg_increment_counter.vvp

iverilog -g2012 -I verilog/AES256 -I verilog/CTR_DRBG -o bin/tb_ctr_drbg_generate_block.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256/aes256_encrypt_block.v verilog/CTR_DRBG/ctr_drbg_increment_counter.v verilog/CTR_DRBG/ctr_drbg_generate_block.v verilog/CTR_DRBG_tb/tb_ctr_drbg_generate_block.v
vvp bin/tb_ctr_drbg_generate_block.vvp

iverilog -g2012 -I verilog/AES256 -I verilog/CTR_DRBG -o bin/tb_ctr_drbg_update_state.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256/aes256_encrypt_block.v verilog/CTR_DRBG/ctr_drbg_increment_counter.v verilog/CTR_DRBG/ctr_drbg_update_state.v verilog/CTR_DRBG_tb/tb_ctr_drbg_update_state.v
vvp bin/tb_ctr_drbg_update_state.vvp

iverilog -g2012 -I verilog/AES256 -I verilog/CTR_DRBG -o bin/tb_ctr_drbg_bcc_block.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256/aes256_encrypt_block.v verilog/CTR_DRBG/ctr_drbg_bcc_block.v verilog/CTR_DRBG_tb/tb_ctr_drbg_bcc_block.v
vvp bin/tb_ctr_drbg_bcc_block.vvp

iverilog -g2012 -I verilog/AES256 -I verilog/CTR_DRBG -o bin/tb_ctr_drbg_rsa_pq_generator.vvp verilog/AES256/aes256_key_expansion.v verilog/AES256/aes256_encrypt_block.v verilog/CTR_DRBG/ctr_drbg_increment_counter.v verilog/CTR_DRBG/ctr_drbg_generate_block.v verilog/CTR_DRBG/ctr_drbg_update_state.v verilog/CTR_DRBG/ctr_drbg_rsa_pq_generator.v verilog/CTR_DRBG_tb/tb_ctr_drbg_rsa_pq_generator.v
vvp bin/tb_ctr_drbg_rsa_pq_generator.vvp
```
