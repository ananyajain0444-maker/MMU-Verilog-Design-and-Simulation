`timescale 1ns/1ps

module mmu_tb;

reg clk;
reg rst_n;

reg req_valid;
reg [31:0] req_va;
reg [7:0]  req_asid;

reg acc_load;
reg acc_store;
reg acc_ifetch;

reg priv;
reg bypass;

reg [19:0] satp_base_ppn;

wire rsp_valid;
wire [31:0] rsp_pa;

wire page_fault;
wire exec_fault;
wire bus_fault;

wire mem_req;
wire [31:0] mem_addr;
wire mem_rdy;
wire [31:0] mem_rdata;
wire mem_err;

mmu dut (
    .clk(clk),
    .rst_n(rst_n),

    .req_valid(req_valid),
    .req_va(req_va),
    .req_asid(req_asid),

    .acc_load(acc_load),
    .acc_store(acc_store),
    .acc_ifetch(acc_ifetch),

    .priv(priv),
    .bypass(bypass),

    .satp_base_ppn(satp_base_ppn),

    .rsp_valid(rsp_valid),
    .rsp_pa(rsp_pa),

    .page_fault(page_fault),
    .exec_fault(exec_fault),
    .bus_fault(bus_fault),

    .mem_req(mem_req),
    .mem_addr(mem_addr),

    .mem_rdy(mem_rdy),
    .mem_rdata(mem_rdata),
    .mem_err(mem_err)
);

mem_bram mem (
    .clk(clk),

    .req(mem_req),
    .addr(mem_addr),

    .rdy(mem_rdy),
    .rdata(mem_rdata),
    .err(mem_err)
);

always #5 clk = ~clk;

initial begin

    $dumpfile("mmu.vcd");
    $dumpvars(0, mmu_tb);

    clk = 0;
    rst_n = 0;

    req_valid = 0;
    req_va = 0;
    req_asid = 8'h01;

    acc_load = 0;
    acc_store = 0;
    acc_ifetch = 0;

    priv = 0;
    bypass = 0;

    satp_base_ppn = 20'h00000;

    #20;
    rst_n = 1;

    //--------------------------------------------------
    // Test 1 : TLB Miss -> PTW Refill
    //--------------------------------------------------

    #20;

    req_va = 32'h00001000;
    req_valid = 1;
    acc_load = 1;

    #10;
    req_valid = 0;

    #100;

    //--------------------------------------------------
    // Test 2 : TLB Hit
    //--------------------------------------------------

    req_va = 32'h00001000;
    req_valid = 1;
    acc_load = 1;

    #10;
    req_valid = 0;

    #50;

    //--------------------------------------------------
    // Test 3 : Execute Access
    //--------------------------------------------------

    acc_load   = 0;
    acc_ifetch = 1;

    req_va = 32'h00002000;
    req_valid = 1;

    #10;
    req_valid = 0;

    #100;

    //--------------------------------------------------
    // Test 4 : Bypass Mode
    //--------------------------------------------------

    bypass = 1;

    acc_ifetch = 0;
    acc_load   = 1;

    req_va = 32'h12345678;
    req_valid = 1;

    #10;
    req_valid = 0;

    #50;

    bypass = 0;

    //--------------------------------------------------
    // Finish
    //--------------------------------------------------

    #100;

    $display("Simulation Completed");
    $finish;

end

always @(posedge clk) begin

    if(rsp_valid) begin
        $display("[%0t] Physical Address = %h",
                 $time, rsp_pa);
    end

    if(page_fault) begin
        $display("[%0t] PAGE FAULT", $time);
    end

    if(exec_fault) begin
        $display("[%0t] EXECUTE FAULT", $time);
    end

    if(bus_fault) begin
        $display("[%0t] BUS FAULT", $time);
    end

end

endmodule