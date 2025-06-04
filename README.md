# ⚙️ Parameterized ALU in Verilog with Self-Checking Testbench

This project showcases a fully parameterized Arithmetic Logic Unit (ALU) designed using Verilog, developed during my internship at [Company Name]. The ALU is capable of performing a wide range of arithmetic and logical operations and is accompanied by a self-checking testbench that automates the verification process.

---

## 🚀 Features

- ✅ Parameterized input width (default: 8-bit; scalable)
- ➕ Arithmetic operations: Addition, Subtraction, Increment, Decrement
- 🔣 Logical operations: AND, OR, XOR, NOT, NAND, NOR, XNOR
- 📁 Test vectors loaded from external text file
- 🤖 Self-checking testbench with automated scoreboard
- 📊 100% functional and code coverage achieved
- 🧪 120+ test cases covering edge cases and all operations

---

## 🛠️ Tech Stack

- Verilog (RTL design)
- ModelSim / Vivado Simulator
- Text-based test stimulus generation
- Scoreboard-based PASS/FAIL mechanism

---

## 📂 Repository Structure

```
├── src/
│   └── alu.v                    # ALU module (parameterized)
├── tb/
│   ├── alu_tb.v                 # Self-checking testbench
│   └── input_vectors.txt        # External input stimuli for simulation
├── results/
│   └── simulation_log.txt       # Example simulation output
├── coverage/
│   └──                          # Code coverage summary
├── Design Document/
│   └──                          # Code coverage summary
├── Test Plan/
│   └──              
└── README.md                    # Project documentation
```

---

## 🎯 Objective

To design a reusable and configurable ALU with robust testbench methodology that mimics real-world design verification workflows.

---

## 🔄 How to Run

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/parameterized-alu-verilog.git
   cd parameterized-alu-verilog
   ```

2. Open the project in your preferred simulator (ModelSim, Vivado, etc.)

3. Run the testbench (`alu_tb.v`) and observe the output in the console/log

4. Review coverage reports and simulation logs under the `results/` and `coverage/` directories

---

## 📸 Screenshots (Optional)

Include waveform captures, scoreboard output, or coverage summary here.

---

## 🙌 Acknowledgments

Grateful to my mentors and team at [Company Name] for the guidance and support during this internship project.

---

## 🏷️ Tags

`#Verilog` `#DigitalDesign` `#ALU` `#RTLDesign` `#VLSI` `#Testbench` `#CodeCoverage` `#Internship`
