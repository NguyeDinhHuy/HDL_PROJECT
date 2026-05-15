library verilog;
use verilog.vl_types.all;
entity RSA_Top is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        keygen_start    : in     vl_logic;
        entropy_seed    : in     vl_logic_vector(383 downto 0);
        personalization : in     vl_logic_vector(383 downto 0);
        p               : out    vl_logic_vector(511 downto 0);
        q               : out    vl_logic_vector(511 downto 0);
        n               : out    vl_logic_vector(1023 downto 0);
        phi             : out    vl_logic_vector(1023 downto 0);
        public_e        : out    vl_logic_vector(1023 downto 0);
        private_d       : out    vl_logic_vector(1023 downto 0);
        key_valid       : out    vl_logic;
        keygen_busy     : out    vl_logic;
        keygen_done     : out    vl_logic;
        rsa_start       : in     vl_logic;
        rsa_decrypt     : in     vl_logic;
        rsa_data_in     : in     vl_logic_vector(1023 downto 0);
        rsa_data_out    : out    vl_logic_vector(1023 downto 0);
        rsa_done        : out    vl_logic;
        send_start      : in     vl_logic;
        message_in      : in     vl_logic_vector(1023 downto 0);
        ciphertext_out  : out    vl_logic_vector(1023 downto 0);
        send_busy       : out    vl_logic;
        send_done       : out    vl_logic;
        receive_start   : in     vl_logic;
        ciphertext_in   : in     vl_logic_vector(1023 downto 0);
        security_key_in : in     vl_logic_vector(1023 downto 0);
        message_out     : out    vl_logic_vector(1023 downto 0);
        receive_busy    : out    vl_logic;
        receive_done    : out    vl_logic;
        security_key_ok : out    vl_logic;
        security_error  : out    vl_logic
    );
end RSA_Top;
