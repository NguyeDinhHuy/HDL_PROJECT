function [7:0] aes256_sbox_value;
    input [7:0] in;
    begin
        case (in)
            8'h00: aes256_sbox_value = 8'h63; 8'h01: aes256_sbox_value = 8'h7c;
            8'h02: aes256_sbox_value = 8'h77; 8'h03: aes256_sbox_value = 8'h7b;
            8'h04: aes256_sbox_value = 8'hf2; 8'h05: aes256_sbox_value = 8'h6b;
            8'h06: aes256_sbox_value = 8'h6f; 8'h07: aes256_sbox_value = 8'hc5;
            8'h08: aes256_sbox_value = 8'h30; 8'h09: aes256_sbox_value = 8'h01;
            8'h0a: aes256_sbox_value = 8'h67; 8'h0b: aes256_sbox_value = 8'h2b;
            8'h0c: aes256_sbox_value = 8'hfe; 8'h0d: aes256_sbox_value = 8'hd7;
            8'h0e: aes256_sbox_value = 8'hab; 8'h0f: aes256_sbox_value = 8'h76;
            8'h10: aes256_sbox_value = 8'hca; 8'h11: aes256_sbox_value = 8'h82;
            8'h12: aes256_sbox_value = 8'hc9; 8'h13: aes256_sbox_value = 8'h7d;
            8'h14: aes256_sbox_value = 8'hfa; 8'h15: aes256_sbox_value = 8'h59;
            8'h16: aes256_sbox_value = 8'h47; 8'h17: aes256_sbox_value = 8'hf0;
            8'h18: aes256_sbox_value = 8'had; 8'h19: aes256_sbox_value = 8'hd4;
            8'h1a: aes256_sbox_value = 8'ha2; 8'h1b: aes256_sbox_value = 8'haf;
            8'h1c: aes256_sbox_value = 8'h9c; 8'h1d: aes256_sbox_value = 8'ha4;
            8'h1e: aes256_sbox_value = 8'h72; 8'h1f: aes256_sbox_value = 8'hc0;
            8'h20: aes256_sbox_value = 8'hb7; 8'h21: aes256_sbox_value = 8'hfd;
            8'h22: aes256_sbox_value = 8'h93; 8'h23: aes256_sbox_value = 8'h26;
            8'h24: aes256_sbox_value = 8'h36; 8'h25: aes256_sbox_value = 8'h3f;
            8'h26: aes256_sbox_value = 8'hf7; 8'h27: aes256_sbox_value = 8'hcc;
            8'h28: aes256_sbox_value = 8'h34; 8'h29: aes256_sbox_value = 8'ha5;
            8'h2a: aes256_sbox_value = 8'he5; 8'h2b: aes256_sbox_value = 8'hf1;
            8'h2c: aes256_sbox_value = 8'h71; 8'h2d: aes256_sbox_value = 8'hd8;
            8'h2e: aes256_sbox_value = 8'h31; 8'h2f: aes256_sbox_value = 8'h15;
            8'h30: aes256_sbox_value = 8'h04; 8'h31: aes256_sbox_value = 8'hc7;
            8'h32: aes256_sbox_value = 8'h23; 8'h33: aes256_sbox_value = 8'hc3;
            8'h34: aes256_sbox_value = 8'h18; 8'h35: aes256_sbox_value = 8'h96;
            8'h36: aes256_sbox_value = 8'h05; 8'h37: aes256_sbox_value = 8'h9a;
            8'h38: aes256_sbox_value = 8'h07; 8'h39: aes256_sbox_value = 8'h12;
            8'h3a: aes256_sbox_value = 8'h80; 8'h3b: aes256_sbox_value = 8'he2;
            8'h3c: aes256_sbox_value = 8'heb; 8'h3d: aes256_sbox_value = 8'h27;
            8'h3e: aes256_sbox_value = 8'hb2; 8'h3f: aes256_sbox_value = 8'h75;
            8'h40: aes256_sbox_value = 8'h09; 8'h41: aes256_sbox_value = 8'h83;
            8'h42: aes256_sbox_value = 8'h2c; 8'h43: aes256_sbox_value = 8'h1a;
            8'h44: aes256_sbox_value = 8'h1b; 8'h45: aes256_sbox_value = 8'h6e;
            8'h46: aes256_sbox_value = 8'h5a; 8'h47: aes256_sbox_value = 8'ha0;
            8'h48: aes256_sbox_value = 8'h52; 8'h49: aes256_sbox_value = 8'h3b;
            8'h4a: aes256_sbox_value = 8'hd6; 8'h4b: aes256_sbox_value = 8'hb3;
            8'h4c: aes256_sbox_value = 8'h29; 8'h4d: aes256_sbox_value = 8'he3;
            8'h4e: aes256_sbox_value = 8'h2f; 8'h4f: aes256_sbox_value = 8'h84;
            8'h50: aes256_sbox_value = 8'h53; 8'h51: aes256_sbox_value = 8'hd1;
            8'h52: aes256_sbox_value = 8'h00; 8'h53: aes256_sbox_value = 8'hed;
            8'h54: aes256_sbox_value = 8'h20; 8'h55: aes256_sbox_value = 8'hfc;
            8'h56: aes256_sbox_value = 8'hb1; 8'h57: aes256_sbox_value = 8'h5b;
            8'h58: aes256_sbox_value = 8'h6a; 8'h59: aes256_sbox_value = 8'hcb;
            8'h5a: aes256_sbox_value = 8'hbe; 8'h5b: aes256_sbox_value = 8'h39;
            8'h5c: aes256_sbox_value = 8'h4a; 8'h5d: aes256_sbox_value = 8'h4c;
            8'h5e: aes256_sbox_value = 8'h58; 8'h5f: aes256_sbox_value = 8'hcf;
            8'h60: aes256_sbox_value = 8'hd0; 8'h61: aes256_sbox_value = 8'hef;
            8'h62: aes256_sbox_value = 8'haa; 8'h63: aes256_sbox_value = 8'hfb;
            8'h64: aes256_sbox_value = 8'h43; 8'h65: aes256_sbox_value = 8'h4d;
            8'h66: aes256_sbox_value = 8'h33; 8'h67: aes256_sbox_value = 8'h85;
            8'h68: aes256_sbox_value = 8'h45; 8'h69: aes256_sbox_value = 8'hf9;
            8'h6a: aes256_sbox_value = 8'h02; 8'h6b: aes256_sbox_value = 8'h7f;
            8'h6c: aes256_sbox_value = 8'h50; 8'h6d: aes256_sbox_value = 8'h3c;
            8'h6e: aes256_sbox_value = 8'h9f; 8'h6f: aes256_sbox_value = 8'ha8;
            8'h70: aes256_sbox_value = 8'h51; 8'h71: aes256_sbox_value = 8'ha3;
            8'h72: aes256_sbox_value = 8'h40; 8'h73: aes256_sbox_value = 8'h8f;
            8'h74: aes256_sbox_value = 8'h92; 8'h75: aes256_sbox_value = 8'h9d;
            8'h76: aes256_sbox_value = 8'h38; 8'h77: aes256_sbox_value = 8'hf5;
            8'h78: aes256_sbox_value = 8'hbc; 8'h79: aes256_sbox_value = 8'hb6;
            8'h7a: aes256_sbox_value = 8'hda; 8'h7b: aes256_sbox_value = 8'h21;
            8'h7c: aes256_sbox_value = 8'h10; 8'h7d: aes256_sbox_value = 8'hff;
            8'h7e: aes256_sbox_value = 8'hf3; 8'h7f: aes256_sbox_value = 8'hd2;
            8'h80: aes256_sbox_value = 8'hcd; 8'h81: aes256_sbox_value = 8'h0c;
            8'h82: aes256_sbox_value = 8'h13; 8'h83: aes256_sbox_value = 8'hec;
            8'h84: aes256_sbox_value = 8'h5f; 8'h85: aes256_sbox_value = 8'h97;
            8'h86: aes256_sbox_value = 8'h44; 8'h87: aes256_sbox_value = 8'h17;
            8'h88: aes256_sbox_value = 8'hc4; 8'h89: aes256_sbox_value = 8'ha7;
            8'h8a: aes256_sbox_value = 8'h7e; 8'h8b: aes256_sbox_value = 8'h3d;
            8'h8c: aes256_sbox_value = 8'h64; 8'h8d: aes256_sbox_value = 8'h5d;
            8'h8e: aes256_sbox_value = 8'h19; 8'h8f: aes256_sbox_value = 8'h73;
            8'h90: aes256_sbox_value = 8'h60; 8'h91: aes256_sbox_value = 8'h81;
            8'h92: aes256_sbox_value = 8'h4f; 8'h93: aes256_sbox_value = 8'hdc;
            8'h94: aes256_sbox_value = 8'h22; 8'h95: aes256_sbox_value = 8'h2a;
            8'h96: aes256_sbox_value = 8'h90; 8'h97: aes256_sbox_value = 8'h88;
            8'h98: aes256_sbox_value = 8'h46; 8'h99: aes256_sbox_value = 8'hee;
            8'h9a: aes256_sbox_value = 8'hb8; 8'h9b: aes256_sbox_value = 8'h14;
            8'h9c: aes256_sbox_value = 8'hde; 8'h9d: aes256_sbox_value = 8'h5e;
            8'h9e: aes256_sbox_value = 8'h0b; 8'h9f: aes256_sbox_value = 8'hdb;
            8'ha0: aes256_sbox_value = 8'he0; 8'ha1: aes256_sbox_value = 8'h32;
            8'ha2: aes256_sbox_value = 8'h3a; 8'ha3: aes256_sbox_value = 8'h0a;
            8'ha4: aes256_sbox_value = 8'h49; 8'ha5: aes256_sbox_value = 8'h06;
            8'ha6: aes256_sbox_value = 8'h24; 8'ha7: aes256_sbox_value = 8'h5c;
            8'ha8: aes256_sbox_value = 8'hc2; 8'ha9: aes256_sbox_value = 8'hd3;
            8'haa: aes256_sbox_value = 8'hac; 8'hab: aes256_sbox_value = 8'h62;
            8'hac: aes256_sbox_value = 8'h91; 8'had: aes256_sbox_value = 8'h95;
            8'hae: aes256_sbox_value = 8'he4; 8'haf: aes256_sbox_value = 8'h79;
            8'hb0: aes256_sbox_value = 8'he7; 8'hb1: aes256_sbox_value = 8'hc8;
            8'hb2: aes256_sbox_value = 8'h37; 8'hb3: aes256_sbox_value = 8'h6d;
            8'hb4: aes256_sbox_value = 8'h8d; 8'hb5: aes256_sbox_value = 8'hd5;
            8'hb6: aes256_sbox_value = 8'h4e; 8'hb7: aes256_sbox_value = 8'ha9;
            8'hb8: aes256_sbox_value = 8'h6c; 8'hb9: aes256_sbox_value = 8'h56;
            8'hba: aes256_sbox_value = 8'hf4; 8'hbb: aes256_sbox_value = 8'hea;
            8'hbc: aes256_sbox_value = 8'h65; 8'hbd: aes256_sbox_value = 8'h7a;
            8'hbe: aes256_sbox_value = 8'hae; 8'hbf: aes256_sbox_value = 8'h08;
            8'hc0: aes256_sbox_value = 8'hba; 8'hc1: aes256_sbox_value = 8'h78;
            8'hc2: aes256_sbox_value = 8'h25; 8'hc3: aes256_sbox_value = 8'h2e;
            8'hc4: aes256_sbox_value = 8'h1c; 8'hc5: aes256_sbox_value = 8'ha6;
            8'hc6: aes256_sbox_value = 8'hb4; 8'hc7: aes256_sbox_value = 8'hc6;
            8'hc8: aes256_sbox_value = 8'he8; 8'hc9: aes256_sbox_value = 8'hdd;
            8'hca: aes256_sbox_value = 8'h74; 8'hcb: aes256_sbox_value = 8'h1f;
            8'hcc: aes256_sbox_value = 8'h4b; 8'hcd: aes256_sbox_value = 8'hbd;
            8'hce: aes256_sbox_value = 8'h8b; 8'hcf: aes256_sbox_value = 8'h8a;
            8'hd0: aes256_sbox_value = 8'h70; 8'hd1: aes256_sbox_value = 8'h3e;
            8'hd2: aes256_sbox_value = 8'hb5; 8'hd3: aes256_sbox_value = 8'h66;
            8'hd4: aes256_sbox_value = 8'h48; 8'hd5: aes256_sbox_value = 8'h03;
            8'hd6: aes256_sbox_value = 8'hf6; 8'hd7: aes256_sbox_value = 8'h0e;
            8'hd8: aes256_sbox_value = 8'h61; 8'hd9: aes256_sbox_value = 8'h35;
            8'hda: aes256_sbox_value = 8'h57; 8'hdb: aes256_sbox_value = 8'hb9;
            8'hdc: aes256_sbox_value = 8'h86; 8'hdd: aes256_sbox_value = 8'hc1;
            8'hde: aes256_sbox_value = 8'h1d; 8'hdf: aes256_sbox_value = 8'h9e;
            8'he0: aes256_sbox_value = 8'he1; 8'he1: aes256_sbox_value = 8'hf8;
            8'he2: aes256_sbox_value = 8'h98; 8'he3: aes256_sbox_value = 8'h11;
            8'he4: aes256_sbox_value = 8'h69; 8'he5: aes256_sbox_value = 8'hd9;
            8'he6: aes256_sbox_value = 8'h8e; 8'he7: aes256_sbox_value = 8'h94;
            8'he8: aes256_sbox_value = 8'h9b; 8'he9: aes256_sbox_value = 8'h1e;
            8'hea: aes256_sbox_value = 8'h87; 8'heb: aes256_sbox_value = 8'he9;
            8'hec: aes256_sbox_value = 8'hce; 8'hed: aes256_sbox_value = 8'h55;
            8'hee: aes256_sbox_value = 8'h28; 8'hef: aes256_sbox_value = 8'hdf;
            8'hf0: aes256_sbox_value = 8'h8c; 8'hf1: aes256_sbox_value = 8'ha1;
            8'hf2: aes256_sbox_value = 8'h89; 8'hf3: aes256_sbox_value = 8'h0d;
            8'hf4: aes256_sbox_value = 8'hbf; 8'hf5: aes256_sbox_value = 8'he6;
            8'hf6: aes256_sbox_value = 8'h42; 8'hf7: aes256_sbox_value = 8'h68;
            8'hf8: aes256_sbox_value = 8'h41; 8'hf9: aes256_sbox_value = 8'h99;
            8'hfa: aes256_sbox_value = 8'h2d; 8'hfb: aes256_sbox_value = 8'h0f;
            8'hfc: aes256_sbox_value = 8'hb0; 8'hfd: aes256_sbox_value = 8'h54;
            8'hfe: aes256_sbox_value = 8'hbb; 8'hff: aes256_sbox_value = 8'h16;
            default: aes256_sbox_value = 8'h00;
        endcase
    end
endfunction

function [7:0] aes256_rcon_value;
    input [3:0] in;
    begin
        case (in)
            4'h0: aes256_rcon_value = 8'h00; 4'h1: aes256_rcon_value = 8'h01;
            4'h2: aes256_rcon_value = 8'h02; 4'h3: aes256_rcon_value = 8'h04;
            4'h4: aes256_rcon_value = 8'h08; 4'h5: aes256_rcon_value = 8'h10;
            4'h6: aes256_rcon_value = 8'h20; 4'h7: aes256_rcon_value = 8'h40;
            4'h8: aes256_rcon_value = 8'h80; 4'h9: aes256_rcon_value = 8'h1b;
            4'ha: aes256_rcon_value = 8'h36; 4'hb: aes256_rcon_value = 8'h6c;
            4'hc: aes256_rcon_value = 8'hd8; 4'hd: aes256_rcon_value = 8'hab;
            4'he: aes256_rcon_value = 8'h4d;
            default: aes256_rcon_value = 8'h00;
        endcase
    end
endfunction

function [7:0] aes256_xtime_value;
    input [7:0] value;
    begin
        aes256_xtime_value = value[7] ? ((value << 1) ^ 8'h1b) : (value << 1);
    end
endfunction

function [7:0] aes256_multiply_value;
    input [7:0] x;
    input [7:0] y;
    integer i;
    reg [7:0] value;
    reg [7:0] factor;
    begin
        aes256_multiply_value = 8'h00;
        value = x;
        factor = y;
        for (i = 0; i < 8; i = i + 1) begin
            if (factor[0]) begin
                aes256_multiply_value = aes256_multiply_value ^ value;
            end
            value = aes256_xtime_value(value);
            factor = factor >> 1;
        end
    end
endfunction
