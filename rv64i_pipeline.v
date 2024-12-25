module rv64i_pipeline(clk, reset);
  input clk, reset;                    // Clock and reset signals

  // Pipeline registers
  reg [63:0] IF_PC, IF_ID_IR, IF_ID_NPC;      // IF stage: PC, Instruction Register, Next PC
  reg [63:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;  // ID stage: Instruction Register, Next PC, A, B, Immediate
  reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;  // Instruction types
  reg [63:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;    // EX stage: Instruction Register, ALU result, B register
  reg        EX_MEM_cond;                        // Condition flag for branch
  reg [63:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD; // MEM stage: Instruction Register, ALU result, Load Memory Data

  // Registers and memory
  reg [63:0] RegFile [0:31];                   // Register file (32 registers)
  reg [63:0] Mem [0:1023];                     // 1024x64-bit memory
  
  // Instruction type encodings (opcode values)
  parameter R_TYPE = 7'b0110011, I_TYPE = 7'b0010011, S_TYPE = 7'b0100011, B_TYPE = 7'b1100011;
  parameter L_TYPE = 7'b0000011, J_TYPE = 7'b1101111, NOP = 7'b0000000;
  
  // Instruction formats
  parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, JUMP = 3'b101;
  parameter HALT = 3'b110;  // Halt instruction
  
  reg HALTED;             // Flag to signal halt state
  
  // Handling the fetch stage (IF)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      IF_PC <= 0;
      HALTED <= 0;
    end else if (HALTED == 0) begin
      IF_ID_IR <= Mem[IF_PC];  // Fetch instruction from memory
      IF_ID_NPC <= IF_PC + 4; // Next PC is current PC + 4
      IF_PC <= IF_PC + 4;      // Increment the PC by 4 for next instruction
    end
  end
  
  // Handling the decode stage (ID)
  always @(posedge clk) begin
    if (HALTED == 0) begin
      ID_EX_IR <= IF_ID_IR;
      ID_EX_NPC <= IF_ID_NPC;
      ID_EX_A <= RegFile[IF_ID_IR[19:15]];  // Register rs1
      ID_EX_B <= RegFile[IF_ID_IR[24:20]];  // Register rs2
      
      // Immediate generation
      case (IF_ID_IR[6:0])
        R_TYPE: ID_EX_Imm <= 64'b0;  // R-type does not need immediate
        I_TYPE: ID_EX_Imm <= {{52{IF_ID_IR[31]}}, IF_ID_IR[31:20]};  // I-type immediate
        S_TYPE: ID_EX_Imm <= {{52{IF_ID_IR[31]}}, IF_ID_IR[31:25], IF_ID_IR[11:7]};  // S-type immediate
        B_TYPE: ID_EX_Imm <= {{51{IF_ID_IR[31]}}, IF_ID_IR[7], IF_ID_IR[30:25], IF_ID_IR[11:8], 1'b0};  // B-type immediate
        L_TYPE: ID_EX_Imm <= {{52{IF_ID_IR[31]}}, IF_ID_IR[31:20]};  // L-type immediate
        J_TYPE: ID_EX_Imm <= {{43{IF_ID_IR[31]}}, IF_ID_IR[19:12], IF_ID_IR[20], IF_ID_IR[30:21], 1'b0}; // J-type immediate
        default: ID_EX_Imm <= 64'b0;
      endcase
    end
  end
  
  // ALU operations (EX stage)
  always @(posedge clk) begin
    if (HALTED == 0) begin
      EX_MEM_IR <= ID_EX_IR;
      EX_MEM_type <= ID_EX_type;
      EX_MEM_cond <= 0; // Default condition is false
      case (ID_EX_type)
        RR_ALU: begin
          case (ID_EX_IR[6:0])  // Check opcode
            R_TYPE: begin
              case (ID_EX_IR[14:12])  // ALU function
                3'b000: EX_MEM_ALUOut <= ID_EX_A + ID_EX_B;  // ADD
                3'b001: EX_MEM_ALUOut <= ID_EX_A - ID_EX_B;  // SUB
                3'b010: EX_MEM_ALUOut <= ID_EX_A & ID_EX_B;  // AND
                3'b011: EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;  // OR
                3'b100: EX_MEM_ALUOut <= ID_EX_A ^ ID_EX_B;  // XOR
                3'b101: EX_MEM_ALUOut <= ID_EX_A << ID_EX_B[4:0]; // SLL
                default: EX_MEM_ALUOut <= 64'b0;
              endcase
            end
          endcase
        end
        RM_ALU: begin
          EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;  // Immediate operations (I-type)
        end
        LOAD, STORE: begin
          EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;  // Memory address calculation
          EX_MEM_B <= ID_EX_B;  // Data to store if it's a store instruction
        end
        BRANCH: begin
          EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;  // Branch target address
          EX_MEM_cond <= (ID_EX_A == 0);  // Branch condition (zero check)
        end
        JUMP: begin
          EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;  // Jump target address
        end
        default: EX_MEM_ALUOut <= 64'b0;
      endcase
    end
  end

  // Handling the memory stage (MEM)
  always @(posedge clk) begin
    if (HALTED == 0) begin
      MEM_WB_IR <= EX_MEM_IR;
      MEM_WB_type <= EX_MEM_type;
      
      case (EX_MEM_type)
        LOAD: MEM_WB_LMD <= Mem[EX_MEM_ALUOut];  // Load data from memory
        STORE: Mem[EX_MEM_ALUOut] <= EX_MEM_B;  // Store data to memory
        default: begin
          MEM_WB_ALUOut <= EX_MEM_ALUOut;  // For ALU operations
        end
      endcase
    end
  end
  
  // Handling the write-back stage (WB)
  always @(posedge clk) begin
    if (HALTED == 0) begin
      case (MEM_WB_type)
        RR_ALU: RegFile[MEM_WB_IR[11:7]] <= MEM_WB_ALUOut;  // Write back to rd
        RM_ALU: RegFile[MEM_WB_IR[11:7]] <= MEM_WB_ALUOut;  // Write back to rd
        LOAD: RegFile[MEM_WB_IR[11:7]] <= MEM_WB_LMD;  // Write back load data
        HALT: HALTED <= 1;  // Set HALTED flag
      endcase
    end
  end
endmodule
