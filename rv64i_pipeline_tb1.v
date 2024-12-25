module rv64i_pipeline_tb;
  reg clk;
  reg reset;

  // Instantiate the pipeline processor
  rv64i_pipeline uut (
    .clk(clk),
    .reset(reset)
  );

  // Memory initialization
  initial begin
    // Initialize memory with some instructions for testing
    uut.Mem[0] = 64'h0000000000000000;  // NOP instruction at PC=0
    uut.Mem[4] = 64'h0000000000010013;  // I-type instruction: ADDI
    uut.Mem[8] = 64'h0000000000020023;  // S-type instruction: STORE
    uut.Mem[12] = 64'h0000000000030033; // B-type instruction: Branch
    uut.Mem[16] = 64'h0000000000040043; // R-type instruction: ADD
    uut.Mem[20] = 64'h0000000000050053; // J-type instruction: JUMP
    uut.Mem[24] = 64'h0000000000060063; // HALT instruction
  end

  // Clock generation
  always begin
    #5 clk = ~clk;  // Clock period is 10 time units
  end

  // Test sequence
  initial begin
    // Initialize signals
    clk = 0;
    reset = 1;

    // Apply reset
    #10 reset = 0;

    // Wait for a few clock cycles to observe behavior
    #100;

    // Halt the processor (after processing all instructions)
    uut.HALTED = 1;

    // Observe output waveforms
    $finish;
  end

  // Display waveforms for key signals
  initial begin
    $dumpfile("rv64i_pipeline_tb.vcd");  // Generate VCD file for waveform
    $dumpvars(0, rv64i_pipeline_tb);

    // Observing key signals in the waveform:
    // PC, Instruction Registers (IF_ID_IR, ID_EX_IR, EX_MEM_IR), ALUOut, Mem, and RegFile
    // These will give a comprehensive view of the pipeline stages and the values being processed.

    $monitor("Time=%0t, PC=%h, IF_ID_IR=%h, ID_EX_IR=%h, EX_MEM_IR=%h, MEM_WB_IR=%h, Mem[4]=%h, RegFile[0]=%h, RegFile[1]=%h, RegFile[2]=%h, HALTED=%b",
             $time, uut.IF_PC, uut.IF_ID_IR, uut.ID_EX_IR, uut.EX_MEM_IR, uut.MEM_WB_IR,
             uut.Mem[4], uut.RegFile[0], uut.RegFile[1], uut.RegFile[2], uut.HALTED);
  end

endmodule
