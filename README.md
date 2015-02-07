This project is an investigation into the effectiveness and shortcomings of the memory hierarchy on processor architectures.

The specification of the project is as follows:

Component | Description
--------- | -----------
CPU | Multi-Cycle, 32 Bit Von Neumann Architecture.
Memory Controller | Receives signals from CPU controller to read and write, takes appropriate action by sending read/write signals to hierarchy components.
Memory Management Unit | Takes as input the 32 bit virtual address from the CPU and, using the TLB or Main Memory page table, translates the virtual address to a physical address to be used by the memory controller.
Translation Lookaside Buffer | Works in conjunction with the Memory Management Unit to translate virtual addresses to physical addresses. 
L2 Cache | Closest to CPU, storage capacity of 512 Bytes (16 x 8 words).
Main Memory | Consists of word storage and page table, storage capacity of 4096 Bytes (128 x 8 words).
I/O Buffer | Reduces lost CPU cycles waiting for Magnetic Disk to finish reading/writing. Storage capacity of 4096 Bytes (128 x 8 words).
Magnetic Disk | Utilizes the Advanced Format standard with 4K sectors. Storage capacity of 4 Gigabytes (1048576 x 8 words).

- [X] Implementation
  - [X] Memory Controller
  - [X] Memory Management Unit
  - [X] Translation Lookaside Buffer
  - [X] L2 Cache
  - [X] Main Memory
  - [X] I/O Buffer
  - [X] Magnetic Disk
- [X] Testing and Verification
  - [X] Memory Controller
  - [X] Memory Management Unit
  - [X] Translation Lookaside Buffer
  - [X] L2 Cache
  - [X] Main Memory
  - [X] I/O Buffer
  - [X] Magnetic Disk
 - [ ] Integration
   - [ ] Single VHDL File Connecting CPU and Memory Hierarchy
   - [ ] Von Neumann Architecture to Harvard Architecture Conversion
   - [ ] Final Testing and Clean-up
