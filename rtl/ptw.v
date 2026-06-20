module ptw #(
    parameter VAW = 32,
    parameter PAW = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 en,

    input  wire                 miss_req,
    input  wire [VAW-13:0]      miss_vpn,
    input  wire [7:0]           miss_asid,

    input  wire [PAW-13:0]      satp_base_ppn,

    output reg                  mem_req,
    output reg [PAW-1:0]        mem_addr,

    input  wire                 mem_rdy,
    input  wire [31:0]          mem_rdata,
    input  wire                 mem_err,

    output reg                  rf_valid,
    output reg [VAW-13:0]       rf_vpn,
    output reg [7:0]            rf_asid,
    output reg [PAW-13:0]       rf_ppn,

    output reg                  rf_r,
    output reg                  rf_w,
    output reg                  rf_x,
    output reg                  rf_u,
    output reg                  rf_v,

    output reg                  bus_fault
);

localparam IDLE = 2'b00;
localparam READ = 2'b01;
localparam OUT  = 2'b10;

reg [1:0] state;

wire [PAW-1:0] pte_addr;

assign pte_addr = {satp_base_ppn,12'b0} + {miss_vpn,2'b00};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        mem_req <= 0;
        mem_addr <= 0;
        rf_valid <= 0;
        bus_fault <= 0;
    end
    else if(en) begin

        rf_valid <= 0;
        bus_fault <= 0;

        case(state)

            IDLE: begin
                if(miss_req) begin
                    mem_req <= 1'b1;
                    mem_addr <= pte_addr;
                    state <= READ;
                end
            end

            READ: begin
                if(mem_rdy) begin

                    mem_req <= 1'b0;

                    if(mem_err) begin
                        bus_fault <= 1'b1;
                        state <= IDLE;
                    end
                    else begin

                        rf_vpn  <= miss_vpn;
                        rf_asid <= miss_asid;

                        rf_ppn <= mem_rdata[31:12];

                        rf_v <= mem_rdata[11];
                        rf_r <= mem_rdata[10];
                        rf_w <= mem_rdata[9];
                        rf_x <= mem_rdata[8];
                        rf_u <= mem_rdata[7];

                        rf_valid <= 1'b1;

                        state <= OUT;
                    end
                end
            end

            OUT: begin
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end

        endcase
    end
end

endmodule