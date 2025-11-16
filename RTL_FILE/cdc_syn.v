
module cdc_sync (
    input   clk_dest,  
    input   rst_dest,  
    input   signal_in, 
    output  signal_out 
);

   
    reg s1_sync_reg ;
    reg s2_sync_reg ;

    always @(posedge clk_dest or posedge rst_dest) begin
        if (rst_dest) begin
            s1_sync_reg <= 1'b0;
            s2_sync_reg <= 1'b0;
        end
        else begin
            s1_sync_reg <= signal_in;
            s2_sync_reg <= s1_sync_reg;
        end
    end

    assign signal_out = s2_sync_reg;

endmodule