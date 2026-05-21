library verilog;
use verilog.vl_types.all;
entity Fast_R2_Mod_N is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        n               : in     vl_logic_vector(1023 downto 0);
        r2_mod_n        : out    vl_logic_vector(1023 downto 0);
        done            : out    vl_logic
    );
end Fast_R2_Mod_N;
