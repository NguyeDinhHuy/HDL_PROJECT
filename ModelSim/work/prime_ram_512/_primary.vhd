library verilog;
use verilog.vl_types.all;
entity prime_ram_512 is
    port(
        clk             : in     vl_logic;
        we              : in     vl_logic;
        addr            : in     vl_logic_vector(6 downto 0);
        data_in         : in     vl_logic_vector(511 downto 0);
        data_out        : out    vl_logic_vector(511 downto 0)
    );
end prime_ram_512;
