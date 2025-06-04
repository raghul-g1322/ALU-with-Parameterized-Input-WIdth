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

// Registers for Pipeling
reg [3:0] t_CMD;
reg [OPERAND_WIDTH-1:0] t_OPA, t_OPB;
reg t_CIN, temp_ovr_cin;
reg t_MODE;
reg TEMP_MODE;
reg [3:0]TEMP_CMD;
reg [1:0] t_INP_VALID;
reg [OPERAND_WIDTH-1:0] shf_MUL;
reg [(2*OPERAND_WIDTH)-1:0] t_MUL;
reg [OPERAND_WIDTH-1:0] temp_ovr_a, temp_ovr_b;

// Always Block for Initializing and Pipeling the Inputs
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

// Always block for ALU Computations
always @ (posedge CLK or posedge RST) begin
    if(RST) begin           // Reset will result is ZERO
        RES <= 0;
        ERR <= 1'b0;
        t_MUL <= 0;
        E <= 1'b0;
        G <= 1'b0;
        L <= 1'b0;
    end
    else begin
        if(CE) begin
            if(t_MODE) begin                // MODE = 1 (ARITHMETIC)
                if(t_CMD != 4'd9 && t_CMD != 4'd10)     // If Command is not multiplication make res = 0
                    RES <= 0;
                ERR <= 1'b0;
                E <= 1'b0;
                G <= 1'b0;
                L <= 1'b0;
                t_MUL <= 0;
                case(t_INP_VALID)
                    2'b00 : begin                   // Both Operands are Invalid
                                RES <= 0;
                                ERR <= 1'b1;
                                E <= 1'b0;
                                G <= 1'b0;
                                L <= 1'b0;
                            end
                    2'b01 : begin                   // Only OPA is VALID
                                case(t_CMD)     
                                    4'b0100 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + 1;      // Increment OPA    
                                              end
                                    4'b0101 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - 1;      // Decrement OPB
                                              end
                                    default : begin                                     // Invalid CMD for Single Input (OPA)
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    2'b10 : begin                   // Only OPB is VALID
                                case(t_CMD)
                                    4'b0110 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB + 1;      // Increment OPB
                                              end
                                    4'b0111 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB - 1;      // Decrement OPB
                                              end
                                    default : begin                                     // Invalid CMD for Single Input (OPB)
                                                RES <= 0;   
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    default : begin                                                     // When Both Operands are VALID
                                case(t_CMD)
                                    4'b0000 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB;          // ADDITION
                                              end
                                    4'b0001 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB;          // SUBTRACTION
                                              end
                                    4'b0010 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + t_OPB + t_CIN;  // ADDITION WITH CARRY
                                              end
                                    4'b0011 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - t_OPB - t_CIN;  // SUBTRACTION WITH BORROW
                                              end
                                    4'b0100 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA + 1;              // INCREMENT OPA 
                                              end
                                    4'b0101 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPA - 1;              // DECREMENT OPA
                                              end
                                    4'b0110 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB + 1;              // INCREMENT OPB 
                                              end
                                    4'b0111 : begin
                                                RES[OPERAND_WIDTH:0] <= t_OPB - 1;              // DECREMENT OPB
                                              end
                                    4'b1000 : begin                                             // UNSIGNED COMPARISON
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
                                                t_MUL <= (t_OPA + 1) * (t_OPB + 1);             // MULTIPLICATION (OPA+1) x (OPB+1)
                                                RES <= t_MUL;
                                              end
                                    4'b1010 : begin
                                                t_MUL <= (shf_MUL) * (t_OPB);                   // MULTIPLICATION (OPA << 1) x (OPB)
                                                RES <= t_MUL;
                                              end
                                    4'b1011 : begin                                             // Signed ADDITION and COMPARISON
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
                                    4'b1100 : begin                                             // Signed SUBTRACTION and COMPARISON                  
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
                                    default :  begin                                            // Invalid CMD for Both Inputs
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
            else begin                  // MODE = 0 (LOGICAL OPERATION)
                RES <= 0;
                ERR <= 1'b0;
                E <= 1'b0;
                G <= 1'b0;
                L <= 1'b0;
                case(t_INP_VALID)           
                    2'b00 : begin                   // Both Inputs are INVALID
                                RES <= 0;
                                ERR <= 1'b1;
                                E <= 1'b0;
                                G <= 1'b0;
                                L <= 1'b0;
                            end
                    2'b01 : begin                   // Only OPA is VALID
                                case(t_CMD)
                                    4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};         // NOT ~OPA
                                    4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};     // Right Shift OPA
                                    4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};     // Left Shift OPA
                                    default : begin                                             // Invalid CMD for Single Input (OPA)
                                                RES <= 0;
                                                ERR <= 1'b1;
                                                E <= 1'b0;
                                                G <= 1'b0;
                                                L <= 1'b0;
                                              end
                                endcase
                            end
                    2'b10 : begin                   // Only OPA is VALID
                                case(t_CMD)
                                    4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};         // NOT ~OPA
                                    4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};     // Right Shift OPB
                                    4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};     // Left Shift OPA
                                    default : begin                                             // Invalid CMD for Single Input (OPB)
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
                                    4'b0000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA & t_OPB)};  // Bitwise AND
                                    4'b0001 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA & t_OPB)}; // Bitwise NAND
                                    4'b0010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA | t_OPB)};  // Bitwise OR
                                    4'b0011 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA | t_OPB)}; // Bitwise NOR
                                    4'b0100 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA ^ t_OPB)};  // Bitwise XOR
                                    4'b0101 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA ^ t_OPB)}; // Bitwise XNOR
                                    4'b0110 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPA)};         // Bitwise NOT - OPA
                                    4'b0111 : RES[OPERAND_WIDTH:0] <= {1'b0, ~(t_OPB)};         // Bitwise NOT - OPB
                                    4'b1000 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA >> 1)};     // Shift Right OPA
                                    4'b1001 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPA << 1)};     // Shift Left OPA
                                    4'b1010 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB >> 1)};     // Shift Right OPB
                                    4'b1011 : RES[OPERAND_WIDTH:0] <= {1'b0, (t_OPB << 1)};     // Shift Left OPB
                                    4'b1100 :   begin                                           // Rotate LEFT
                                                    RES[OPERAND_WIDTH-1:0] <= (t_OPA << t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA >> (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
                                                    if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
                                                        ERR <= 1;
                                                    else
                                                        ERR <= 0;
                                                end
                                    4'b1101 :   begin                                           // Rotate RIGHT
                                                    RES[OPERAND_WIDTH-1:0] <= (t_OPA >> t_OPB[($clog2(OPERAND_WIDTH) - 1):0]) | (t_OPA << (OPERAND_WIDTH - t_OPB[($clog2(OPERAND_WIDTH) - 1):0]));
                                                    if(|(t_OPB[OPERAND_WIDTH-1 : ($clog2(OPERAND_WIDTH) + 1)]))
                                                        ERR <= 1;
                                                    else
                                                        ERR <= 0;
                                                end


                                    default :  begin                                            // Invalid CMD for Both Inputs
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
        else begin   // When CE = 0
            RES <= 0;
            ERR <= 1'b0;
            E <= 1'b0;
            G <= 1'b0;
            L <= 1'b0;
        end
    end   
end

// For Multiplication CMD = 4'b1010
always @ (*) begin  
    if(t_CMD == 4'hA)
        shf_MUL = t_OPA << 1;
    else
        shf_MUL = 0;
end

// Overflow Calculation
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

// Carry Out Calculation
assign COUT = ((TEMP_MODE) && (TEMP_CMD == 4'd0 || TEMP_CMD == 4'd2 || TEMP_CMD == 4'd4 || TEMP_CMD == 4'd6 || TEMP_CMD == 4'd11)) ? RES[8] : 0;


endmodule
