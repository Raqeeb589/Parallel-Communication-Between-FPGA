`timescale 1ns / 1ps

module tb;

    reg clk_tx;
    reg rst_tx;
    reg clk_rx;
    reg rst_rx;

    
    reg  [15:0] test_data_in;
    reg         test_wr_en;
    wire        tx_fifo_full;


    wire [15:0] final_data_out;
    reg         test_rd_en;
    wire        rx_fifo_empty;

    
    wire [15:0] link_data;
    wire        link_valid;
    wire        link_ready;

    
    reg  [15:0] sent_data_queue [$:1023]; 
    integer     tx_count = 0;
    integer     rx_count = 0;
    integer     error_count = 0;

   
    /*localparam CLK_TX_PERIOD = 10; // 100 MHz
    localparam CLK_RX_PERIOD = 13; // ~77 MHz*/

    initial begin
        clk_tx = 0;
        forever #5 clk_tx = ~clk_tx; //100MHz
    end

    initial begin
        clk_rx = 0;
        forever #12.5 clk_rx = ~clk_rx; //80Mhz
    end

   
    transmitter DUT_tx (
        .clk_tx(clk_tx),
        .rst_tx(rst_tx),
        .data_in(test_data_in),
        .wr_en(test_wr_en),
        .fifo_full(tx_fifo_full),
        .parallel_data_out(link_data),
        .parallel_valid_out(link_valid),
        .parallel_ready_in(link_ready)
    );

   
    Receiver DUT_rx (
        .clk_rx(clk_rx),
        .rst_rx(rst_rx),
        .data_out(final_data_out),
        .rd_en(test_rd_en),
        .fifo_empty(rx_fifo_empty),
        .parallel_data_in(link_data),
        .parallel_valid_in(link_valid),
        .parallel_ready_out(link_ready)
    );

    
    initial begin
        rst_tx = 1;
        rst_rx = 1;
        test_wr_en = 0;
        test_data_in = 16'd0;
        $display("T=%0t: --- System Reset ---", $time);
        /*#(max(CLK_TX_PERIOD, CLK_RX_PERIOD) * 10);*/
        #20;
        rst_tx = 0;
        rst_rx = 0;
        $display("T=%0t: --- Reset Released ---", $time);

        // 2. Send 40 words
        $display("T=%0t [TX]: Sending 40 words...", $time);
        repeat (40) begin
            wait(!tx_fifo_full); // Wait if FIFO is full (tests back-pressure)
            @(posedge clk_tx);
            test_data_in <= tx_count + 16'hAAAA; // Send known data
            test_wr_en   <= 1;
            sent_data_queue.push_back(tx_count + 16'hAAAA); // Store for checking
            tx_count     <= tx_count + 1;
            
            @(posedge clk_tx);
            test_wr_en <= 0;
        end
        $display("T=%0t [TX]: Finished sending %0d words.", $time, tx_count);

        // 3. Wait for all data to be processed
        #(200); // Wait long enough
        
        // 4. Final Check
        $display("--- Testbench Finished ---");
        $display("Total Sent:     %0d", tx_count);
        $display("Total Received: %0d", rx_count);
        $display("Total Errors:   %0d", error_count);
        
        if (error_count == 0 && tx_count > 0 && tx_count == rx_count) begin
            $display("--- *** TEST PASSED *** ---");
        end else begin
            $display("--- *** TEST FAILED *** ---");
        end
        $stop;
    end

    // --- RX Verification (Data Checker) ---
    
    // Greedy read: Read whenever the FIFO is not empty
    assign test_rd_en = !rx_fifo_empty;
    
    initial begin
        reg last_read_en;
        @(negedge rst_rx); // Wait for reset to end
        
        last_read_en = 0;
        
        forever @(posedge clk_rx) begin
            // Check if a read was issued *last* cycle
            if (last_read_en) begin
                // Data is valid THIS cycle (due to synchronous-read FIFO)
                verify_data(final_data_out);
            end
            
            // Store the read signal for next cycle
            // 'test_rd_en' is assigned combinatorially (!rx_fifo_empty)
            last_read_en <= test_rd_en; 
        end
    end

    // --- Verification Task ---
    task verify_data;
        input [15:0] received_data;
        reg [15:0] expected_data;

        if (sent_data_queue.size() == 0) begin
            $error("T=%0t [RX]: Read from an empty queue! RX FIFO was not empty?", $time);
            error_count = error_count + 1;
            return;
        end
        
        expected_data = sent_data_queue.pop_front();
        
        if (received_data === expected_data) begin
            $display("T=%0t [RX]: Data OK. Got %0d", $time, received_data);
        end else begin
            $error("T=%0t [RX]: --- DATA MISMATCH ---", $time);
            $error("               Got: 0x%h, Expected: %0d", received_data, expected_data);
            error_count = error_count + 1;
        end
        rx_count = rx_count + 1;
    endtask


endmodule