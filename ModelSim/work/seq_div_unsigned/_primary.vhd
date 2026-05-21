library verilog;
use verilog.vl_types.all;
entity seq_div_unsigned is
    generic(
        WIDTH           : integer := 32;
        COUNT_WIDTH     : integer := 6
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        dividend        : in     vl_logic_vector;
        divisor         : in     vl_logic_vector;
        quotient        : out    vl_logic_vector;
        remainder       : out    vl_logic_vector;
        done            : out    vl_logic;
        divide_by_zero  : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
    attribute mti_svvh_generic_type of COUNT_WIDTH : constant is 1;
end seq_div_unsigned;
