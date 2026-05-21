library verilog;
use verilog.vl_types.all;
entity RSA_Top is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        mode            : in     vl_logic;
        prime_addr      : in     vl_logic_vector(6 downto 0);
        plaintext_in    : in     vl_logic_vector(935 downto 0);
        ciphertext_in   : in     vl_logic_vector(1023 downto 0);
        ciphertext_out  : out    vl_logic_vector(1023 downto 0);
        plaintext_out   : out    vl_logic_vector(935 downto 0);
        done            : out    vl_logic;
        error           : out    vl_logic
    );
end RSA_Top;
