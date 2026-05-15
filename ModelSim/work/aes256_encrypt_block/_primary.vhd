library verilog;
use verilog.vl_types.all;
entity aes256_encrypt_block is
    port(
        block_in        : in     vl_logic_vector(127 downto 0);
        key             : in     vl_logic_vector(255 downto 0);
        block_out       : out    vl_logic_vector(127 downto 0)
    );
end aes256_encrypt_block;
