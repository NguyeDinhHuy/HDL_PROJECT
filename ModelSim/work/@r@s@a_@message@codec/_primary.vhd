library verilog;
use verilog.vl_types.all;
entity RSA_MessageCodec is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        encrypt_start   : in     vl_logic;
        message_in      : in     vl_logic_vector(1023 downto 0);
        public_exponent : in     vl_logic_vector(1023 downto 0);
        public_modulus  : in     vl_logic_vector(1023 downto 0);
        ciphertext_out  : out    vl_logic_vector(1023 downto 0);
        encrypt_busy    : out    vl_logic;
        encrypt_done    : out    vl_logic;
        decrypt_start   : in     vl_logic;
        security_key    : in     vl_logic_vector(1023 downto 0);
        message_out     : out    vl_logic_vector(1023 downto 0);
        decrypt_busy    : out    vl_logic;
        decrypt_done    : out    vl_logic;
        decrypt_match   : out    vl_logic;
        input_error     : out    vl_logic
    );
end RSA_MessageCodec;
