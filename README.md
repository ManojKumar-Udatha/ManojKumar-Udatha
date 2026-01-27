# Reliable UART Architecture with Asynchronous FIFOs, SEC-DED Hamming Code, and 3× Oversampling

## Author
**Udatha Manoj Kumar**  
Nellore, Andhra Pradesh, India   
📧 u.manojkumar9462@gmail.com  
🔗 LinkedIn: https://linkedin.com/in/manojkumar-udatha  

---

## Professional Summary
This repository presents a robust, synthesizable UART design developed using Verilog/SystemVerilog. The architecture integrates asynchronous FIFOs for safe clock-domain crossing (CDC), SEC-DED Hamming error correction for data integrity, and a 3× oversampling receiver to improve reliability under noisy conditions. The project reflects industry-oriented RTL design and verification practices.

---

## Project Description
The UART system is designed to support reliable serial communication across independent clock domains. Asynchronous FIFOs decouple transmit and receive clock domains, while SEC-DED Hamming encoding and decoding ensure single-bit error correction and double-bit error detection. A 3× oversampling technique is implemented in the receiver to enhance noise tolerance and sampling accuracy.

The design is modular, parameterizable, and fully synthesizable, with comprehensive verification at both module and system levels.

---

## Key Features
- FSM-based UART transmitter and receiver
- Asynchronous FIFOs with CDC-safe design
- SEC-DED Hamming encoder and decoder
- 3× oversampling UART receiver for improved noise immunity
- Modular and reusable RTL architecture
- Directed, corner-case, and randomized testbench verification
- Basic functional simulation and timing analysis using Xilinx Vivado

---

## System Architecture
### Data Flow
Transmit and receive data paths are isolated using asynchronous FIFOs to safely cross clock domains.  
Encoded data is transmitted through the UART TX, received via the UART RX using 3× oversampling, and decoded using SEC-DED logic before being forwarded to the destination domain.

### Major Functional Blocks
- UART TX FSM
- UART RX FSM with oversampling logic
- Asynchronous FIFO (dual-clock)
- SEC-DED Hamming encoder/decoder
- Control and flow-management logic

Block and timing diagrams are provided in the `docs/` directory.

---

## Module Overview
### UART Transmitter (`uart_tx`)
- FSM-controlled serial transmission
- Start, data, and stop bit generation
- Configurable baud rate support

### UART Receiver (`uart_rx`)
- 3× oversampling-based bit recovery
- Mid-bit sampling for improved robustness
- Frame validation and data extraction

### Asynchronous FIFO (`async_fifo`)
- Dual-clock FIFO for clock-domain crossing
- Gray-coded read/write pointers
- Two-flop synchronizers
- Reliable full and empty detection

### SEC-DED Hamming Unit (`hamming_secded`)
- Parity-bit generation during encoding
- Syndrome computation during decoding
- Single-bit error correction
- Double-bit error detection

---

## Verification Methodology
- Module-level directed testbenches
- Corner-case testing for FIFO full/empty and CDC behavior
- System-level randomized traffic generation
- Error injection to validate SEC-DED functionality
- Functional simulation using **Xilinx Vivado**
- Basic static timing analysis to meet baud-rate requirements

---

## Tools and Technologies
- **Languages:** Verilog
- **EDA Tool:** Xilinx Vivado
- **Design Concepts:** FSM modeling, CDC handling, Testbench creation
- **Analysis:** Functional simulation

---

## Repository Structure
```text
.
├── rtl/        # Synthesizable RTL source files
├── tb/         # Module-level and system-level testbenches
├── docs/       # Architecture and timing diagrams
├── sim/        # Simulation results and waveforms
└── README.md
