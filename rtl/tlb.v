module tlb #(
    parameter VPN_W  = 20,
    parameter PPN_W  = 20,
    parameter ASID_W = 8,
    parameter ENTRIES = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Lookup
    input  wire [VPN_W-1:0]         vpn_i,
    input  wire [ASID_W-1:0]        asid_i,

    output reg                      hit_o,
    output reg  [PPN_W-1:0]         ppn_o,

    output reg                      r_o,
    output reg                      w_o,
    output reg                      x_o,
    output reg                      u_o,
    output reg                      v_o,

    // Refill from PTW
    input  wire                     refill_valid,
    input  wire [VPN_W-1:0]         refill_vpn,
    input  wire [ASID_W-1:0]        refill_asid,
    input  wire [PPN_W-1:0]         refill_ppn,

    input  wire                     refill_r,
    input  wire                     refill_w,
    input  wire                     refill_x,
    input  wire                     refill_u,
    input  wire                     refill_v
);

integer i;

reg [VPN_W-1:0] vpn_mem [0:ENTRIES-1];
reg [PPN_W-1:0] ppn_mem [0:ENTRIES-1];
reg [ASID_W-1:0] asid_mem [0:ENTRIES-1];

reg r_mem [0:ENTRIES-1];
reg w_mem [0:ENTRIES-1];
reg x_mem [0:ENTRIES-1];
reg u_mem [0:ENTRIES-1];
reg v_mem [0:ENTRIES-1];

reg [1:0] replace_ptr;

always @(*) begin
    hit_o = 1'b0;

    ppn_o = {PPN_W{1'b0}};
    r_o   = 1'b0;
    w_o   = 1'b0;
    x_o   = 1'b0;
    u_o   = 1'b0;
    v_o   = 1'b0;

    for(i=0;i<ENTRIES;i=i+1) begin
        if(v_mem[i] &&
           vpn_mem[i]  == vpn_i &&
           asid_mem[i] == asid_i) begin

            hit_o = 1'b1;

            ppn_o = ppn_mem[i];
            r_o   = r_mem[i];
            w_o   = w_mem[i];
            x_o   = x_mem[i];
            u_o   = u_mem[i];
            v_o   = v_mem[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin

        replace_ptr <= 2'd0;

        for(i=0;i<ENTRIES;i=i+1) begin
            vpn_mem[i]  <= 0;
            ppn_mem[i]  <= 0;
            asid_mem[i] <= 0;

            r_mem[i] <= 0;
            w_mem[i] <= 0;
            x_mem[i] <= 0;
            u_mem[i] <= 0;
            v_mem[i] <= 0;
        end
    end
    else begin

        if(refill_valid) begin

            vpn_mem[replace_ptr]  <= refill_vpn;
            ppn_mem[replace_ptr]  <= refill_ppn;
            asid_mem[replace_ptr] <= refill_asid;

            r_mem[replace_ptr] <= refill_r;
            w_mem[replace_ptr] <= refill_w;
            x_mem[replace_ptr] <= refill_x;
            u_mem[replace_ptr] <= refill_u;
            v_mem[replace_ptr] <= refill_v;

            replace_ptr <= replace_ptr + 1'b1;
        end
    end
end

endmodule