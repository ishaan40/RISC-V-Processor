# RISC-V Processor

This is a 2-month long final project for the course ECE411 offered at the University of Illinois at Urbana-Champaign.

The project is an accurate representation of a 32-bit 5-stage pipelined RISC-V processor. The processor has support for/contains:

  - Forwarding Unit (for consecutive instructions with data dependencies)
  - Hazard Detection Unit (for branch and jump instructions)
  - L1 and L2 256B 4-way set-associative cache
  - M Extension (for multiplication, division, and remainder instruction support)
  - Prefetching
  - Evicition Write Buffer
