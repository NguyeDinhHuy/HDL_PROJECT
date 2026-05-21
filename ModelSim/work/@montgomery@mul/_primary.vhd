library verilog;
use verilog.vl_types.all;
entity MontgomeryMul is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        a               : in     vl_logic_vector(1023 downto 0);
        b               : in     vl_logic_vector(1023 downto 0);
        m               : in     vl_logic_vector(1023 downto 0);
        result          : out    vl_logic_vector(1023 downto 0);
        done            : out    vl_logic
    );
end MontgomeryMul;
