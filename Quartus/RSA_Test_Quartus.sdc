# 90 MHz clock constraint for top-level clk input.
# Period = 1 / 90 MHz = 11.111 ns
create_clock -name clk -period 11.111 [get_ports {clk}]

derive_clock_uncertainty
