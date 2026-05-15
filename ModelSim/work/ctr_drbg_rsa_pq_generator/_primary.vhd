library verilog;
use verilog.vl_types.all;
entity ctr_drbg_rsa_pq_generator is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        entropy_seed    : in     vl_logic_vector(383 downto 0);
        personalization : in     vl_logic_vector(383 downto 0);
        p_candidate     : out    vl_logic_vector(511 downto 0);
        q_candidate     : out    vl_logic_vector(511 downto 0);
        nonce_value     : out    vl_logic_vector(127 downto 0);
        done            : out    vl_logic
    );
end ctr_drbg_rsa_pq_generator;
