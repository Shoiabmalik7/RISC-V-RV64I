# RISC-V-RV64I

Overview
The RISC-V RV64I processor implemented here is a 64-bit, 5-stage pipelined processor that supports the basic RV64I instruction set architecture. It uses a pipeline consisting of five stages: Fetch, Decode, Execute, Memory, and Write-back (IF, ID, EX, MEM, WB). Each stage performs specific tasks, and instructions pass through these stages during execution. This processor supports a variety of instruction types including R-type, I-type, S-type, B-type, L-type, and J-type instructions.

Processor Architecture

The processor consists of:

Registers: 32 general-purpose 64-bit registers (RegFile[0:31]), where registers are accessed for various operations.
Memory: A block of memory (Mem[0:1023]), supporting 1024 64-bit words for data storage and instruction fetching.
Control Logic: Handles the flow of instructions through the pipeline, including branching, ALU operations, and memory operations.
Pipeline Stages

Instruction Fetch (IF):

PC Register: The Program Counter (PC) holds the address of the instruction to fetch.
Memory Fetch: The instruction is fetched from memory using the current PC value.
Next PC Calculation: The next instruction’s address is computed by incrementing the current PC by 4 (standard for RISC-V).
Instruction Register: The fetched instruction is stored in the IF_ID_IR register.

Logic:

When clk rises, the instruction at IF_PC is fetched from memory and stored in IF_ID_IR.
IF_PC is incremented to point to the next instruction.

Instruction Decode (ID):

Register File Access: The two source registers (rs1 and rs2) specified by the instruction are read from the register file.
Immediate Generation: Depending on the instruction type (R-type, I-type, etc.), the immediate value is computed and extended to 64 bits.
Instruction Register: The instruction is passed to the next stage in ID_EX_IR.
Next PC: The next instruction address is also passed along to the EX stage.

Logic:

For R-type instructions, the operands are taken from the register file.
For I-type instructions, an immediate is generated and sign-extended.
Other types (S-type, B-type, etc.) have corresponding logic for their immediate value generation.

Execute (EX):

ALU Operations: The ALU performs the required operation based on the instruction’s opcode.
Memory Address Calculation: For load/store instructions, the ALU computes the memory address.
Branch Condition Check: For branch instructions, the condition is checked (e.g., BEQ, BNE).
ALU Result: The result of the ALU operation is stored in EX_MEM_ALUOut.

Logic:

Depending on the instruction type (R-type, I-type, etc.), the ALU performs the correct operation.
The result is stored in EX_MEM_ALUOut, which will be used in the MEM stage.

Memory (MEM):

Memory Access: For load instructions, the memory address computed in the EX stage is used to fetch the data from memory.
Data Store: For store instructions, the data from the source register is written to the computed memory address.
ALU Result Forwarding: For non-memory instructions, the ALU result is forwarded to the next stage.

Logic:

If the instruction is a load, the data from memory is stored in MEM_WB_LMD.
If the instruction is a store, the data is written to memory at the address computed in the EX stage.

Write-back (WB):

Register Write: The result (either from the ALU or from memory) is written back to the register file.
HALT Condition: If the processor encounters a halt instruction, it sets the HALTED flag to stop the processor.

Logic:

For ALU instructions and load instructions, the result is written back to the destination register (rd).
The halt instruction sets the HALTED flag, stopping the pipeline from advancing.
Instruction Types and Formats

R-Type:

Used for operations between two registers (e.g., ADD, SUB, AND, OR).
Format: opcode(7 bits) | rd(5 bits) | funct3(3 bits) | rs1(5 bits) | rs2(5 bits) | funct7(7 bits)

I-Type:

Used for immediate operations (e.g., ADDI, ANDI).
Format: opcode(7 bits) | rd(5 bits) | funct3(3 bits) | rs1(5 bits) | imm(12 bits)

S-Type:

Used for store instructions (e.g., SW, SH).
Format: opcode(7 bits) | imm[4:0](5 bits) | funct3(3 bits) | rs1(5 bits) | rs2(5 bits) | imm[11:5](7 bits)

B-Type:

Used for branch instructions (e.g., BEQ, BNE).
Format: opcode(7 bits) | imm[11:5](7 bits) | rs1(5 bits) | rs2(5 bits) | funct3(3 bits) | imm[4:1](4 bits) | imm[0](1 bit)

L-Type:

Used for load instructions (e.g., LW, LH).
Format: opcode(7 bits) | rd(5 bits) | funct3(3 bits) | rs1(5 bits) | imm(12 bits)

J-Type:

Used for jump instructions (e.g., JAL, JALR).
Format: opcode(7 bits) | rd(5 bits) | imm(20 bits)

Control Signals:

Instruction Decode: The opcode is decoded in the ID stage to determine which type of instruction it is (R-type, I-type, etc.). Based on the instruction type, the appropriate signals are generated to control the ALU, memory access, and register write operations.

ALU Control: The ALU performs different operations based on the funct3 and funct7 fields of R-type instructions (e.g., ADD, SUB, AND, OR). The ALU operation is selected by these fields.

Memory Control: For load and store instructions, the memory is accessed to read or write data. The address for memory access is computed in the EX stage.

Branch Control: For branch instructions, the branch condition (e.g., equality check for BEQ) is checked. If the branch is taken, the next instruction address is modified to the branch target address.


Memory Handling:

Load: Load instructions fetch data from memory based on the computed address in the EX stage. This data is forwarded to the WB stage.
Store: Store instructions write data to memory at the computed address in the EX stage.
HALT Mechanism
When the processor encounters a HALT instruction (opcode == 7'b1111111), the HALTED flag is set to 1, stopping the pipeline from fetching further instructions. This is a mechanism to end the execution of the program.

Final Remarks:
This RISC-V RV64I processor design in Verilog implements a 5-stage pipeline with support for a variety of instruction types, including arithmetic, logic, memory, and control instructions. The processor is designed for modularity and ease of understanding, with clear separation of concerns across different pipeline stages. The use of comments throughout the code helps to clarify the functionality of each part of the design.

By understanding the stages of the pipeline and how each instruction is processed, users can extend the design to support more complex features or optimize it for specific use cases.
