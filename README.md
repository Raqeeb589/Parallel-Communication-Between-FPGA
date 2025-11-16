16-bit Parallel Communication Link Between FPGAs (CDC Bridge)
Team: RAQEEB, SAKSHAM, AAKARSH, SOHAIL

This repository contains the Verilog modules for implementing a robust 16-bit parallel communication link. Its primary purpose is to safely transfer data between two FPGAs (or any two systems) operating in asynchronous clock domains.

The design solves the critical challenge of Clock Domain Crossing (CDC) by implementing a 4-phase VALID/READY handshake protocol. This ensures a lossless, reliable data transfer link, protected from metastability.

Key Features
Lossless Data Transfer: The handshake protocol provides backpressure (using the READY signal), which prevents the transmitter from sending data until the receiver is ready. This guarantees no data is ever dropped.

Metastability-Safe: All 1-bit control signals crossing the clock boundary (parallel_valid and parallel_ready) are passed through a standard 2-flip-flop (2-FF) synchronizer.

Decoupled Buffering: Uses synchronous 16x16 FIFOs in both the transmit and receive domains. This allows the logic on each side to run independently without stalling the entire system.

Modular Design: The project is broken into four clean, reusable modules.

Architecture and Data Flow
The system is split into two halves: the transmitter (in the clk_tx domain) and the Receiver (in the clk_rx domain). They are connected by a 16-bit data bus and the 2-wire handshake.

The 4-phase handshake works as follows:

TX: After reading data from its internal FIFO, the transmitter places data on parallel_data_out and asserts parallel_valid_out HIGH.

RX: The Receiver (after synchronizing) sees valid is HIGH. If its internal FIFO is not full, it latches the data and asserts parallel_ready_out HIGH to acknowledge.

TX: The transmitter (after synchronizing) sees ready is HIGH. It de-asserts parallel_valid_out to LOW.

RX: The Receiver sees valid go LOW. It de-asserts parallel_ready_out to LOW and writes the latched data into its FIFO.

The transfer is now complete, and the transmitter is free to start the next one.
