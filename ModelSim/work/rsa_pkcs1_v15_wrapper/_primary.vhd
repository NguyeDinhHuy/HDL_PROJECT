library verilog;
use verilog.vl_types.all;
entity rsa_pkcs1_v15_wrapper is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        mode            : in     vl_logic;
        message_in_936  : in     vl_logic_vector(935 downto 0);
        message_out_936 : out    vl_logic_vector(935 downto 0);
        padded_msg_1024 : out    vl_logic_vector(1023 downto 0);
        decrypted_msg_1024: in     vl_logic_vector(1023 downto 0);
        ready           : out    vl_logic;
        padding_error   : out    vl_logic
    );
end rsa_pkcs1_v15_wrapper;
