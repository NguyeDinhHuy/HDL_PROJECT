library verilog;
use verilog.vl_types.all;
entity serial_multiplier is
    generic(
        WIDTH           : integer := 512;
        CHUNK_WIDTH     : integer := 32
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        multiplicand_in : in     vl_logic_vector;
        multiplier_in   : in     vl_logic_vector;
        product_out     : out    vl_logic_vector;
        done            : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
    attribute mti_svvh_generic_type of CHUNK_WIDTH : constant is 1;
end serial_multiplier;
