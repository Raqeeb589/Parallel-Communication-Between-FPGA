
module FIFO(
    input clk,
    input reset, 
    input [15:0] data_in,
    input read_en,
    input write_en,
    
    output reg [15:0] data_out,
    output  full,
    output  empty

    );
    
    reg [15:0]mem[15:0];
    reg [4:0]rd_pointer;
    reg [4:0]wr_pointer;
   

   
    always@(posedge clk)
    begin
        if(reset) begin
            data_out <= 166'd0;
            rd_pointer <= 5'd0;
            wr_pointer <= 5'd0;
        end
        else begin
            if(write_en && !full)
            begin
                    mem[wr_pointer[3:0]] <= data_in;
                    wr_pointer <= wr_pointer + 1; 
            end
            else if(read_en && !empty)begin
                data_out <= mem[rd_pointer[3:0]]; 
                rd_pointer <= rd_pointer + 1; 
            end
        end
    end
    
    assign full = (wr_pointer == {~rd_pointer[4],rd_pointer[3:0]});
    assign empty = wr_pointer == rd_pointer;
    
endmodule

