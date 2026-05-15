library verilog;
use verilog.vl_types.all;
entity ctr_drbg_update_state is
    port(
        key             : in     vl_logic_vector(255 downto 0);
        counter_in      : in     vl_logic_vector(127 downto 0);
        provided_data   : in     vl_logic_vector(383 downto 0);
        has_provided_data: in     vl_logic;
        next_key        : out    vl_logic_vector(255 downto 0);
        next_counter    : out    vl_logic_vector(127 downto 0)
    );
end ctr_drbg_update_state;
