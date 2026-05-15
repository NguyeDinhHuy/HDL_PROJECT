library verilog;
use verilog.vl_types.all;
entity ModExp is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        base_in         : in     vl_logic_vector(1023 downto 0);
        exp_in          : in     vl_logic_vector(1023 downto 0);
        mod_in          : in     vl_logic_vector(1023 downto 0);
        r2_mod_n        : in     vl_logic_vector(1023 downto 0);
        result          : out    vl_logic_vector(1023 downto 0);
        done            : out    vl_logic
    );
end ModExp;
