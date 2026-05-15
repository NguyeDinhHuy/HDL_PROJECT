library verilog;
use verilog.vl_types.all;
entity ctr_drbg_increment_counter is
    port(
        counter_in      : in     vl_logic_vector(127 downto 0);
        counter_out     : out    vl_logic_vector(127 downto 0)
    );
end ctr_drbg_increment_counter;
