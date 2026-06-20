module mem_bram #(
    parameter AW = 32,
    parameter DW = 32,
    parameter DEPTH = 1024
)(
    input  wire             clk,

    input  wire             req,
    input  wire [AW-1:0]    addr,

    output reg              rdy,
    output reg  [DW-1:0]    rdata,
    output reg              err
);

reg [DW-1:0] mem [0:DEPTH-1];

initial begin
    $readmemh("tb/pt.mem", mem);
end

wire [31:0] word_addr;

assign word_addr = addr >> 2;

always @(posedge clk) begin

    rdy <= 1'b0;
    err <= 1'b0;

    if(req) begin

        if(word_addr < DEPTH) begin

            rdata <= mem[word_addr];
            rdy   <= 1'b1;
            err   <= 1'b0;

        end
        else begin

            rdata <= 32'h00000000;
            rdy   <= 1'b1;
            err   <= 1'b1;

        end
    end
end

endmodule