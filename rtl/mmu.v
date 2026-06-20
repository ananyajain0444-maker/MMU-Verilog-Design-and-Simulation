module mmu #(
    parameter VAW = 32,
    parameter PAW = 32
)(
    input  wire                 clk,
    input  wire                 rst_n,

    input  wire                 req_valid,
    input  wire [VAW-1:0]       req_va,
    input  wire [7:0]           req_asid,

    input  wire                 acc_load,
    input  wire                 acc_store,
    input  wire                 acc_ifetch,

    input  wire                 priv,

    input  wire                 bypass,

    input  wire [PAW-13:0]      satp_base_ppn,

    output reg                  rsp_valid,
    output reg  [PAW-1:0]       rsp_pa,

    output reg                  page_fault,
    output reg                  exec_fault,
    output reg                  bus_fault,

    output wire                 mem_req,
    output wire [PAW-1:0]       mem_addr,

    input  wire                 mem_rdy,
    input  wire [31:0]          mem_rdata,
    input  wire                 mem_err
);

wire [19:0] vpn;
wire [11:0] off;

assign vpn = req_va[31:12];
assign off = req_va[11:0];

wire tlb_hit;
wire [19:0] tlb_ppn;

wire p_r;
wire p_w;
wire p_x;
wire p_u;
wire p_v;

wire allow;
wire pfault;
wire xfault;

wire ptw_rf_valid;
wire [19:0] ptw_rf_vpn;
wire [7:0]  ptw_rf_asid;
wire [19:0] ptw_rf_ppn;

wire ptw_rf_r;
wire ptw_rf_w;
wire ptw_rf_x;
wire ptw_rf_u;
wire ptw_rf_v;

wire ptw_bus_fault;

reg miss_req;

localparam IDLE     = 2'b00;
localparam WAIT_PTW = 2'b01;

reg [1:0] state;

tlb u_tlb (
    .clk(clk),
    .rst_n(rst_n),

    .vpn_i(vpn),
    .asid_i(req_asid),

    .hit_o(tlb_hit),
    .ppn_o(tlb_ppn),

    .r_o(p_r),
    .w_o(p_w),
    .x_o(p_x),
    .u_o(p_u),
    .v_o(p_v),

    .refill_valid(ptw_rf_valid),
    .refill_vpn(ptw_rf_vpn),
    .refill_asid(ptw_rf_asid),
    .refill_ppn(ptw_rf_ppn),

    .refill_r(ptw_rf_r),
    .refill_w(ptw_rf_w),
    .refill_x(ptw_rf_x),
    .refill_u(ptw_rf_u),
    .refill_v(ptw_rf_v)
);

perm_check u_perm (
    .priv(priv),

    .acc_load(acc_load),
    .acc_store(acc_store),
    .acc_ifetch(acc_ifetch),

    .pV(p_v),
    .pR(p_r),
    .pW(p_w),
    .pX(p_x),
    .pU(p_u),

    .allow(allow),
    .pfault(pfault),
    .xfault(xfault)
);

ptw u_ptw (
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),

    .miss_req(miss_req),
    .miss_vpn(vpn),
    .miss_asid(req_asid),

    .satp_base_ppn(satp_base_ppn),

    .mem_req(mem_req),
    .mem_addr(mem_addr),

    .mem_rdy(mem_rdy),
    .mem_rdata(mem_rdata),
    .mem_err(mem_err),

    .rf_valid(ptw_rf_valid),
    .rf_vpn(ptw_rf_vpn),
    .rf_asid(ptw_rf_asid),
    .rf_ppn(ptw_rf_ppn),

    .rf_r(ptw_rf_r),
    .rf_w(ptw_rf_w),
    .rf_x(ptw_rf_x),
    .rf_u(ptw_rf_u),
    .rf_v(ptw_rf_v),

    .bus_fault(ptw_bus_fault)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin

        state <= IDLE;

        rsp_valid   <= 0;
        rsp_pa      <= 0;

        page_fault  <= 0;
        exec_fault  <= 0;
        bus_fault   <= 0;

        miss_req    <= 0;

    end
    else begin

        rsp_valid  <= 0;
        miss_req   <= 0;

        page_fault <= 0;
        exec_fault <= 0;
        bus_fault  <= 0;

        case(state)

            IDLE: begin

                if(req_valid) begin

                    if(bypass) begin

                        rsp_valid <= 1'b1;
                        rsp_pa    <= req_va;

                    end
                    else if(tlb_hit) begin

                        if(allow) begin

                            rsp_valid <= 1'b1;
                            rsp_pa    <= {tlb_ppn,off};

                        end
                        else begin

                            page_fault <= pfault;
                            exec_fault <= xfault;

                        end
                    end
                    else begin

                        miss_req <= 1'b1;
                        state    <= WAIT_PTW;

                    end
                end
            end

            WAIT_PTW: begin

                if(ptw_bus_fault) begin

                    bus_fault <= 1'b1;
                    state     <= IDLE;

                end
                else if(ptw_rf_valid) begin

                    rsp_valid <= 1'b1;
                    rsp_pa    <= {ptw_rf_ppn,off};

                    state <= IDLE;

                end
            end

            default: begin
                state <= IDLE;
            end

        endcase
    end
end

endmodule