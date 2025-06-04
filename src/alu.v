module alu_design #(parameter OPERAND_WIDTH = 8, parameter CMD_WIDTH = 4)(
    // INPUTS
    input CLK, RST, MODE, CE, CIN,                                    
    input [CMD_WIDTH-1:0] CMD,
    input [1:0] INP_VALID,
    input [OPERAND_WIDTH-1:0] OPA, OPB,
    // OUTPUTS
    output reg ERR, OFLOW, E, G, L,
    output COUT,
    output reg [(2*OPERAND_WIDTH)-1:0] RES
);

// REGISTERS for PIPELING
reg [3:0] t_CMD;
reg [OPERAND_WIDTH-1:0] t_OPA, t_OPB;
reg t_CIN, temp_ovr_cin;
reg t_MODE;
reg TEMP_MODE;
reg [3:0]TEMP_CMD;
reg [1:0] t_INP_VALID;
reg [OPERAND_WIDTH-1:0] shf_MUL;
  reg [(2*OPERAND_WIDTH)-1:0] t_MUL; // Temporary reg for Multiplication Result
reg [OPERAND_WIDTH-1:0] temp_ovr_a, temp_ovr_b;

// ALWAYS block for Initializing and Pipeling the inputs
always @ (posedge CLK or posedge RST) begin
     if(RST) begin
        t_OPA <= 0;
        t_OPB <= 0;
        t_CMD <= 0;
        temp_ovr_a <= 0;
        temp_ovr_b <= 0;
        TEMP_MODE <= 0;
        TEMP_CMD <= 0;
        temp_ovr_cin <= 0;
        t_MODE <= 0;
        t_INP_VALID <=0;
        t_CIN <= 0;
    end
    else if(CE) begin
        t_OPA <= OPA;
        t_OPB <= OPB;
        temp_ovr_a <= t_OPA;
        temp_ovr_b <= t_OPB;
        TEMP_MODE <= t_MODE;
        TEMP_CMD <= t_CMD;
        temp_ovr_cin <= t_CIN;
        t_CMD <= CMD;
        t_MODE <= MODE;
        t_INP_VALID <= INP_VALID;
        t_CIN <= CIN;       
    end
    else begin
        t_OPA <= 0;
        t_OPB <= 0;
        t_CMD <= 0;
        temp_ovr_a <= 0;
        temp_ovr_b <= 0;
        t_MODE <= 0;
        t_INP_VALID <= 0;
        t_CIN <= 0;
    end  
end

// ALWAYS block for ALU Computation
always @ (posedge CLK or posedge RST) begin
    if(RST) begin
        RES <= 0;
        ERR <= 1'b0;
        t_MUL <= 0;
        E <= 1'b0;
        G <= 1'b0;
        L <= 1'b0;
    end
    else begin
        if(CE) begin
          if(t_MODE) begin                                                        // MODE = 1 (ARITHMETIC)
                if(t_CMD != 4'd9 && t_CMD != 4'd10)
                    RES <= 0;
                ERR <= 1'b0;
                E <= 1'b0;
                G <= 1'b0;
                L <= 1'b0;
                t_MUL <= 0;
            case(t_INP_VALID)                                                   // Both Operands are INVALID         
                    2'b00 : begin
                                RES <= 0;
                                ERR <= 1'b1;
                                E <= 1'b0;
                                G <= 1'b0;
                                L <= 1'b0;
                            end
                    2'b01 : begin                                              // Only Operand A is VALID         
                                case(t_CMD)
                                    4'b0100 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + 1;      //
                                              end
                                    4'b0101 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - 1;
                                              end
                                    default : begin
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    2'b10 : begin
                                case(t_CMD)
                                    4'b0110 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB + 1;
                                              end
                                    4'b0111 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB - 1;
                                              end
                                    default : begin
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    default : begin
                                case(t_CMD)
                                    4'b0000 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB;
                                              end
                                    4'b0001 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB;
                                              end
                                    4'b0010 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB + t_CIN;
                                              end
                                    4'b0011 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB - t_CIN;
                                              end
                                    4'b0100 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + 1;
                                              end
                                    4'b0101 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - 1;
                                              end
                                    4'b0110 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB + 1;
                                              end
                                    4'b0111 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB - 1;
                                              end
                                    4'b1000 : begin
                                                RES <= 0;
                                                if(t_OPA == t_OPB) begin
                                                    E <= 1;
                                                    G <= 0;
                                                    L <= 0;
                                                end
                                                else if(t_OPA > t_OPB) begin
                                                    E <= 0;
                                                    G <= 1;
                                                    L <= 0;
                                                end
                                                else begin
                                                    E <= 0;
                                                    G <= 0;
                                                    L <= 1;
                                                end
                                              end
                                    4'b1001 : begin
                                                t_MUL <= (t_OPA + 1) * (t_OPB + 1);
                                                RES <= t_MUL;
                                              end
                                    4'b1010 : begin
                                                t_MUL <= (shf_MUL) * (t_OPB);
                                                RES <= t_MUL;
                                              end
                                    4'b1011 : begin
                                                RES[OPERAND_WIDTH:0] <= ($signed(t_OPA)) + ($signed(t_OPB));
                                                if(t_OPA == t_OPB) begin
                                                    E <= 1;
                                                    G <= 0;
                                                    L <= 0;
                                                end
                                                else if(($signed(t_OPA)) > ($signed(t_OPB))) begin
                                                    E <= 0;
                                                    G <= 1;
                                                    L <= 0;
                                                end
                                                else begin
                                                    E <= 0;
                                                    G <= 0;
                                                    L <= 1;
                                                end
                                              end
                                    4'b1100 : begin
                                                RES[OPERAND_WIDTH:0] <= ($signed(t_OPA)) - ($signed(t_OPB));
                                                if(t_OPA == t_OPB) begin
                                                    E <= 1;
                                                    G <= 0;
                                                    L <= 0;
                                                end
                                                else if(($signed(t_OPA)) > ($signed(t_OPB))) begin
                                                    E <= 0;
                                                    G <= 1;
                                                    L <= 0;
                                                end
                                                else begin
                                                    E <= 0;
                                                    G <= 0;
                                                    L <= 1;
                                                end
                                              end
                                    default :  begin
                                                 RES <= 0;
                                                 ERR <= 1'b1;
                                                 E <= 1'b0;
                                                 G <= 1'b0;
                                                 L <= 1'b0;
                                               end
                                endcase
                            end
                endcase
            end
            else begin
                RES <= 0;
                ERR <= 1'b0;
                E <= 1'b0;
                G <= 1'b0;
                L <= 1'b0;
                case(t_INP_VALID)
                    2'b00 : begin
                                RES <= 0;
                                ERR <= 1'b1;
                                E <= 1'b0;
                                G <= 1'b0;
                                L <= 1'b0;
                            end
                    2'b01 : begin
                                case(t_CMD)
                                    4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};
                                    4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};
                                    4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};
                                    default : begin
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    2'b10 : begin
                                case(t_CMD)
                                    4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};
                                    4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};
                                    4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};
                                    default : begin
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    default : begin
                                case(t_CMD)
                                    4'b0000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA & t_OPB)};
                                    4'b0001 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA & t_OPB)};
                                    4'b0010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA | t_OPB)};
                                    4'b0011 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA | t_OPB)};
                                    4'b0100 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA ^ t_OPB)};
                                    4'b0101 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA ^ t_OPB)};
                                    4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};
                                    4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};
                                    4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};
                                    4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};
                                    4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};
                                    4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};
                                    4'b1100 :   begin
                                                    RES[OPERAND_WIDTH-1:0] <= (t_OPA << t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA >> (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
                                                    if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
                                                        ERR <= 1;
                                                    else
                                                        ERR <= 0;
                                                end
                                    4'b1101 :   begin
                                                    RES[OPERAND_WIDTH-1:0] <= (t_OPA >> t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA << (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
                                                    if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
                                                        ERR <= 1;
                                                    else
                                                        ERR <= 0;
                                                end


                                    default :  begin
                                                    RES <= 0;
                                                    ERR <= 1'b1;
                                                    E <= 1'b0;
                                                    G <= 1'b0;
                                                    L <= 1'b0;
                                                end
                                endcase
                            end
                endcase
            end
        end
        else begin
            RES <= 0;
            ERR <= 1'b0;
            E <= 1'b0;
            G <= 1'b0;
            L <= 1'b0;
        end
    end   
end

always @ (*) begin
    if(t_CMD == 4'hA)
        shf_MUL = t_OPA << 1;
    else
        shf_MUL = 0;
end

always @ (*) begin
    if(TEMP_MODE) begin
        case(TEMP_CMD)
            4'd1 : OFLOW = (temp_ovr_a < temp_ovr_b);
            4'd3 : OFLOW = ((temp_ovr_a < temp_ovr_b) || (temp_ovr_a == temp_ovr_b && temp_ovr_cin == 1));
            4'd5 : OFLOW = (temp_ovr_a < 1);
            4'd7 : OFLOW = (temp_ovr_b < 1);
            4'd11 : OFLOW = (temp_ovr_a[OPERAND_WIDTH-1] & temp_ovr_b[OPERAND_WIDTH-1] & (~RES[OPERAND_WIDTH-1])) | ((~temp_ovr_a[OPERAND_WIDTH-1]) & (~temp_ovr_b[OPERAND_WIDTH-1]) & RES[OPERAND_WIDTH-1]);
            4'd12 : OFLOW = ((~temp_ovr_a[OPERAND_WIDTH-1]) & temp_ovr_b[OPERAND_WIDTH-1] & RES[OPERAND_WIDTH-1]) | (temp_ovr_a[OPERAND_WIDTH-1] & (~temp_ovr_b[OPERAND_WIDTH-1]) & (~RES[OPERAND_WIDTH-1]));
            default : OFLOW = 0;
        endcase
    end
    else
        OFLOW = 0;
end
assign COUT = ((TEMP_MODE) && (TEMP_CMD == 4'd0 || TEMP_CMD == 4'd2 || TEMP_CMD == 4'd4 || TEMP_CMD == 4'd6 || TEMP_CMD == 4'd11)) ? RES[8] : 0;


endmodule
