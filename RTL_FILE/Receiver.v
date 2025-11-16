`timescale 1ns / 1ps

module Receiver (
    input  wire        clk_rx,
    input  wire        rst_rx,
    output wire [15:0] data_out,  
    input  wire        rd_en,    
    output wire        fifo_empty, 

    input  wire [15:0] parallel_data_in,
    input  wire        parallel_valid_in,
    output reg         parallel_ready_out
);

   
    wire        fifo_wr_en;
    wire        fifo_full;
    reg  [15:0] data_to_fifo; 

    
    FIFO fifo(
         .clk(clk_rx),
         .reset(rst_rx), 
         .data_in(data_to_fifo),
         .read_en(rd_en),
         .write_en(fifo_wr_en),
         .data_out(data_out),
         .full(fifo_full),
         .empty(fifo_empty)
    );
    
    
    
 
    parameter IDLE             = 2'b00;
    parameter WAIT_VALID_LOW   = 2'b01;

    reg [1:0] state;

   
    wire valid_sync;
    cdc_sync sync_valid (
        .clk_dest   (clk_rx),
        .rst_dest   (rst_rx),
        .signal_in  (parallel_valid_in),
        .signal_out (valid_sync)
    );
    
   
    assign fifo_wr_en = (state == WAIT_VALID_LOW) && !valid_sync;

    always @(posedge clk_rx or posedge rst_rx) begin
        if (rst_rx) begin
            state              <= IDLE;
            parallel_ready_out <= 1'b0;
            data_to_fifo       <= 16'b0;
        end
        else begin
            case (state)
            
                IDLE: begin
                    parallel_ready_out <= 1'b0;
                    
                    if (valid_sync && !fifo_full) begin 
                        data_to_fifo       <= parallel_data_in; 
                        parallel_ready_out <= 1'b1;         
                        state              <= WAIT_VALID_LOW;
                    end
                end
               
                WAIT_VALID_LOW: begin
                    if (!valid_sync) begin
                        
                        parallel_ready_out <= 1'b0; 
                        state              <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
                
            endcase
        end
    end

endmodule