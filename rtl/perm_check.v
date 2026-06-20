module perm_check(
    input  wire priv,          // 0 = User, 1 = Supervisor
    input  wire acc_load,
    input  wire acc_store,
    input  wire acc_ifetch,

    input  wire pV,
    input  wire pR,
    input  wire pW,
    input  wire pX,
    input  wire pU,

    output wire allow,
    output wire pfault,
    output wire xfault
);

    wire user_ok;

    assign user_ok = (~priv) ? pU : 1'b1;

    wire r_ok;
    wire w_ok;
    wire x_ok;

    assign r_ok = acc_load   ? (pR & user_ok) : 1'b1;
    assign w_ok = acc_store  ? (pW & user_ok) : 1'b1;
    assign x_ok = acc_ifetch ? (pX & user_ok) : 1'b1;

    assign allow  = pV & r_ok & w_ok & x_ok;

    assign pfault = pV & user_ok &
                   ((acc_load  & ~pR) |
                    (acc_store & ~pW));

    assign xfault = pV & user_ok &
                   (acc_ifetch & ~pX);

endmodule