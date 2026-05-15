library verilog;
use verilog.vl_types.all;
entity ctr_drbg_generate_block is
    port(
        key             : in     vl_logic_vector(255 downto 0);
        counter_in      : in     vl_logic_vector(127 downto 0);
        counter_out     : out    vl_logic_vector(127 downto 0);
        random_block    : out    vl_logic_vector(127 downto 0)
    );
end ctr_drbg_generate_block;
