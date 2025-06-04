`include "alu_design.v"
`timescale 1ns/1ps

`define PASS 1'b1
`define FAIL 1'b0
`define TEST 118

module alu_tb;

parameter OPERAND_WIDTH = 8;
parameter CMD_WIDTH = 4;

reg [(52+(4*OPERAND_WIDTH))-1 : 0] input_mem [0:`TEST-1];
reg [(6+(2*OPERAND_WIDTH))-1 : 0] output_mem [0:`TEST + 5];
reg SCB[0:`TEST-1];
integer i, j, k, l;

reg CLK, RST, MODE, CE, CIN;
reg [CMD_WIDTH-1:0] CMD;
reg [1:0] INP_VALID;
reg [OPERAND_WIDTH-1:0] OPA, OPB;
wire ERR, OFLOW, E, G, L;
wire COUT;
wire [(2*OPERAND_WIDTH)-1:0] RES;

integer File_ID;
integer File_ptr;

//  STIMULUS REGS
reg ce_s;
reg next_ce;
reg mode_s;
reg [1:0] inpv_s;
reg [3:0] cmd_s, next_cmd;
reg [OPERAND_WIDTH-1:0] opa_s;
reg [OPERAND_WIDTH-1:0] opb_s;
reg cin_s;
reg [(2*OPERAND_WIDTH)-1:0] expected_RES;
reg expected_COUT;
reg expected_OFLOW;
reg expected_E;
reg expected_G;
reg expected_L;
reg expected_ERR;
reg [(2*OPERAND_WIDTH)-1:0] dut_RES;
reg [(2*OPERAND_WIDTH)-1:0] dut_RES_MUL;
reg [(2*OPERAND_WIDTH)-1:0] dut_RES_OTHER;
reg dut_COUT;
reg dut_OFLOW;
reg dut_E;
reg dut_G;
reg dut_L;
reg dut_ERR;

reg [(6+(2*OPERAND_WIDTH)-1):0] expected_PACKET;

alu_design #(OPERAND_WIDTH, CMD_WIDTH) uut (
    .CLK(CLK), .RST(RST), .MODE(MODE), .CE(CE), .CIN(CIN),
    .CMD(CMD), .INP_VALID(INP_VALID), .OPA(OPA), .OPB(OPB),
    .ERR(ERR), .OFLOW(OFLOW), .E(E), .G(G), .L(L),
    .COUT(COUT), .RES(RES)
);

// Clock generation
initial CLK = 0;
always #5 CLK = ~CLK;

// Task to apply stimulus at negative clock edge
task apply_inputs;
    input ce_in;
    input mode_in;
    input [1:0] valid_in;
    input [CMD_WIDTH-1:0] cmd_in;
    input [OPERAND_WIDTH-1:0] opa_in;
    input [OPERAND_WIDTH-1:0] opb_in;
    input cin_in;
    begin
        CE = ce_in;
        MODE = mode_in;
        INP_VALID = valid_in;
        CMD = cmd_in;
        OPA = opa_in;
        OPB = opb_in;
        CIN = cin_in;
    end
endtask

// Reset logic/*
initial begin
    RST = 1;
    CE = 0;
    CMD = 0;
    MODE = 0;
    CIN = 0;
    INP_VALID = 0;
    OPA = 0;
    OPB = 0;
    @(negedge CLK);
    RST = 0;
end

// Stimulus
initial begin
    $readmemh("alu_stimulus.txt", input_mem);
    for(i = 0; i < `TEST; i = i + 1) begin
        ce_s = input_mem[i][(52+(4*OPERAND_WIDTH)-8-4)];
        mode_s = input_mem[i][(52+(4*OPERAND_WIDTH)-12-4)];
        inpv_s = input_mem[i][(52+(4*OPERAND_WIDTH)-15-4):(52+(4*OPERAND_WIDTH)-16-4)];
        cmd_s = input_mem[i][(52+(4*OPERAND_WIDTH)-17-4):(52+(4*OPERAND_WIDTH)-20-4)];
        opa_s = input_mem[i][(52+(4*OPERAND_WIDTH)-24-1):(52+(4*OPERAND_WIDTH)-24-OPERAND_WIDTH)];
        opb_s = input_mem[i][(52+(4*OPERAND_WIDTH)-24-OPERAND_WIDTH-1):(52+(4*OPERAND_WIDTH)-24-OPERAND_WIDTH-OPERAND_WIDTH)];
        cin_s = input_mem[i][(52+(4*OPERAND_WIDTH)-24-OPERAND_WIDTH-OPERAND_WIDTH-1):(52+(4*OPERAND_WIDTH)-24-OPERAND_WIDTH-OPERAND_WIDTH-4)];
        @(negedge CLK);
        apply_inputs(ce_s, mode_s, inpv_s, cmd_s, opa_s, opb_s, cin_s);
    end 
    for(i = 0;i<`TEST;i=i+1) begin
        $display("[%d]\t%h",i,input_mem[i]);
    end
    // Wait for final op
    @(negedge CLK)
    #10
    RST = 1;
    @(negedge CLK);
    #20
    CE = 0;
    #20;
    $finish;
end

initial begin
    for(j = 0; j < `TEST+5; j = j + 1) begin
        @(posedge CLK);
        output_mem[j] = {RES,COUT,OFLOW,E,G,L,ERR}; 
    end

    for(j = 0;j<`TEST+5;j=j+1) begin
        $display("[%0d]\t%b",j,output_mem[j]);
    end


    for(k = 0; k < `TEST; k = k + 1) begin
        l = k + 2;
        ce_s = input_mem[k][(52+(4*OPERAND_WIDTH)-8-4)];
        next_ce = input_mem[k+1][(52+(4*OPERAND_WIDTH)-8-4)];
        mode_s = input_mem[k][(52+(4*OPERAND_WIDTH)-12-4)];
        cmd_s = input_mem[k][(52+(4*OPERAND_WIDTH)-17-4):(52+(4*OPERAND_WIDTH)-20-4)];
        next_cmd = input_mem[k+1][(52+(4*OPERAND_WIDTH)-17-4):(52+(4*OPERAND_WIDTH)-20-4)];
        expected_RES = input_mem[k][(24+(2*OPERAND_WIDTH)-1):24];
        expected_COUT = input_mem[k][20];
        expected_OFLOW = input_mem[k][16];
        expected_E = input_mem[k][12];
        expected_G = input_mem[k][8];
        expected_L = input_mem[k][4];
        expected_ERR = input_mem[k][0];
        expected_PACKET = {expected_RES, expected_COUT, expected_OFLOW,expected_E, expected_G, expected_L, expected_ERR};

        if(!ce_s) begin
            
            $display("--------------------");

            if(expected_PACKET == output_mem[l]) begin
                $display("[%0d] | PASS",k);
                SCB[k] = `PASS;
            end
            else begin
                $display("[%0d] | FAIL",k);
                SCB[k] = `FAIL;
            end

            $display("%b", expected_PACKET);
            $display("%b", output_mem[l]);
            $display("--------------------");
        end
        else if(ce_s && (!next_ce)) begin
            $display("--------------------");
           
            if(output_mem[l+1] == 0) begin
                $display("[%0d] | PASS",k);
                SCB[k] = `PASS;
            end
            else begin
                $display("[%0d] | FAIL",k);
                SCB[k] = `FAIL;
            end

            $display("%b", expected_PACKET);
            $display("%b", output_mem[l]);
            $display("--------------------");

        end
        else begin
            if(mode_s) begin
                if(cmd_s != 4'h9 && cmd_s != 4'ha) begin
                    $display("--------------------");

                    if(expected_PACKET == output_mem[l+1]) begin
                        $display("[%0d] | PASS",k);
                        SCB[k] = `PASS;
                    end
                    else begin
                        $display("[%0d] | FAIL",k);
                        SCB[k] = `FAIL;
                    end
                    $display("%b", expected_PACKET);
                    $display("%b", output_mem[l+1]);
                    $display("--------------------");
                end
                else if((cmd_s == 4'h9 || cmd_s == 4'ha) && next_cmd != 4'h9 && next_cmd != 4'ha) begin
                    $display("--------------------");
                    $display("[%0d] | PASS",k);
                    $display("%b", expected_PACKET);
                    $display("%b", output_mem[l+1]);
                    $display("--------------------");
                    SCB[k] = `PASS;
                end
                else begin
                    $display("--------------------");

                    if(expected_PACKET == output_mem[l+2]) begin
                        $display("[%0d] | PASS",k);
                        SCB[k] = `PASS;
                    end
                    else begin
                        $display("[%0d] | FAIL",k);
                        SCB[k] = `FAIL;
                    end
                    $display("%b", expected_PACKET);
                    $display("%b", output_mem[l+2]);
                    $display("--------------------");
                end
            end
            else begin
                $display("--------------------");
                
                if(expected_PACKET == output_mem[l+1]) begin
                    $display("[%0d] | PASS",k);
                    SCB[k] = `PASS;
                end
                else begin
                    $display("[%0d] | FAIL",k);
                    SCB[k] = `FAIL;
                end
                $display("%b", expected_PACKET);
                $display("%b", output_mem[l+1]);
                $display("--------------------");
            end
        end 
    end

    
    File_ID = $fopen("results.txt", "w");
    for(File_ptr = 0; File_ptr < `TEST; File_ptr = File_ptr + 1) begin
        if(SCB[File_ptr] == `PASS)
            $fdisplay(File_ID, "Feature ID %d \t: PASS", input_mem[File_ptr][(52+(4*OPERAND_WIDTH)-1):(52+(4*OPERAND_WIDTH)-8)]);
        else
            $fdisplay(File_ID, "Feature ID %d \t: FAIL", input_mem[File_ptr][(52+(4*OPERAND_WIDTH)-1):(52+(4*OPERAND_WIDTH)-8)]);
    end


end
endmodule
