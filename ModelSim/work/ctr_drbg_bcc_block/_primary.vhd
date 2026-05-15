library verilog;
use verilog.vl_types.all;
entity ctr_drbg_bcc_block is
    port(
        key             : in     vl_logic_vector(255 downto 0);
        chaining_value  : in     vl_logic_vector(127 downto 0);
        data_block      : in     vl_logic_vector(127 downto 0);
        next_chaining_value: out    vl_logic_vector(127 downto 0)
    );
end ctr_drbg_bcc_block;
