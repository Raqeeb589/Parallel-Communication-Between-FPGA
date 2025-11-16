`timescale 1ns / 1ps

module transmitter (

    input          clk_tx,
    input          rst_tx,
    input   [15:0] data_in,  
    input          wr_en,   
    output         fifo_full, 


    output reg  [15:0] parallel_data_out,
    output reg         parallel_valid_out,
    input          parallel_ready_in
);


    wire [15:0] fifo_rd_data;
    wire        fifo_empty;
    wire        fifo_rd_en; 

    
    FIFO fifo(
         .clk(clk_tx),
         .reset(rst_tx), 
         .data_in(data_in),
         .read_en(fifo_rd_en),
         .write_en(wr_en),
         .data_out(fifo_rd_data),
         .full(fifo_full),
         .empty(fifo_empty)
    );
    
    parameter IDLE             = 3'b000;
    parameter DATA_READY        = 3'b001;
    parameter WAIT_ACK         = 3'b010;
    parameter WAIT_READY_LOW   = 3'b100; 

    reg [2:0] state;

    wire ready_sync;
    
    cdc_sync sync_ready (
        .clk_dest   (clk_tx),
        .rst_dest   (rst_tx),
        .signal_in  (parallel_ready_in),
        .signal_out (ready_sync)
    );

    assign fifo_rd_en = (state == IDLE) && !fifo_empty;
    
    always @(posedge clk_tx or posedge rst_tx) begin
        if (rst_tx) begin
            state                <= IDLE;
            parallel_data_out    <= 16'b0;
            parallel_valid_out   <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    parallel_valid_out <= 1'b0;
                    if (fifo_rd_en) begin 
                        state <= DATA_READY;
                    end
                end
                DATA_READY: begin
                    parallel_data_out <= fifo_rd_data; 
                    parallel_valid_out <= 1'b1;      
                    state              <= WAIT_ACK;
            end

                WAIT_ACK: begin
                    if (ready_sync) begin
                        parallel_valid_out <= 1'b0;  
                        state              <= WAIT_READY_LOW;
                    end
                end

                WAIT_READY_LOW: begin
                    if (!ready_sync) begin
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