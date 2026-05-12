module aes256_key_expansion (
    input  wire [255:0]  key,
    output reg  [1919:0] round_keys
);

`include "aes256_common.vh"

integer i;
integer bytes_generated;
integer rcon_index;
reg [7:0] rk [0:239];
reg [7:0] temp [0:3];
reg [7:0] first;

always @(*) begin
    for (i = 0; i < 240; i = i + 1) begin
        rk[i] = 8'h00;
    end

    for (i = 0; i < 32; i = i + 1) begin
        rk[i] = key[255 - (i * 8) -: 8];
    end

    bytes_generated = 32;
    rcon_index = 1;

    while (bytes_generated < 240) begin
        for (i = 0; i < 4; i = i + 1) begin
            temp[i] = rk[bytes_generated - 4 + i];
        end

        if ((bytes_generated % 32) == 0) begin
            first = temp[0];
            temp[0] = aes256_sbox_value(temp[1]) ^ aes256_rcon_value(rcon_index[3:0]);
            temp[1] = aes256_sbox_value(temp[2]);
            temp[2] = aes256_sbox_value(temp[3]);
            temp[3] = aes256_sbox_value(first);
            rcon_index = rcon_index + 1;
        end else if ((bytes_generated % 32) == 16) begin
            for (i = 0; i < 4; i = i + 1) begin
                temp[i] = aes256_sbox_value(temp[i]);
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            if (bytes_generated < 240) begin
                rk[bytes_generated] = rk[bytes_generated - 32] ^ temp[i];
                bytes_generated = bytes_generated + 1;
            end
        end
    end

    for (i = 0; i < 240; i = i + 1) begin
        round_keys[1919 - (i * 8) -: 8] = rk[i];
    end
end

endmodule
