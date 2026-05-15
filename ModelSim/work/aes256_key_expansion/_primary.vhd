library verilog;
use verilog.vl_types.all;
entity aes256_key_expansion is
    port(
        key             : in     vl_logic_vector(255 downto 0);
        round_keys      : out    vl_logic_vector(1919 downto 0)
    );
end aes256_key_expansion;
