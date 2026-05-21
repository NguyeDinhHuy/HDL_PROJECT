library verilog;
use verilog.vl_types.all;
entity rsa_key_d_generator is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        phi             : in     vl_logic_vector(1023 downto 0);
        private_d       : out    vl_logic_vector(1023 downto 0);
        done            : out    vl_logic;
        phi_invalid     : out    vl_logic
    );
end rsa_key_d_generator;
