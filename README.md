# SystemVerilog Template

A flexible and modular template for SystemVerilog projects with built-in support for:

* Simulation: [Verilator](https://verilator.org/) + [Cocotb](https://cocotb.org/)
* Test Automation: via `Makefile`
* Waveform Viewing: [GTKWave](http://gtkwave.sourceforge.net/)
* Synthesis: [sv2v](https://github.com/zachjs/sv2v) + [Yosys](https://yosyshq.net/yosys/)
* Code Coverage: via [lcov](https://lcov.readthedocs.io/)
* Netlist Browsing: using a custom `json2stems` toolchain

---

# Project Structure

```
.
├── src/              # SystemVerilog source files (.sv)
│   ├── top.sv
│   └── counter.sv
│
├── tb/               # Cocotb testbenches (.py)
│   ├── top_tb.py
│   └── counter_tb.py
│
├── synth_out/        # synthesis outputs (optional)
├── sim_build/        # simulation artifacts (auto-generated)
├── json2stems/       # RTL visualization tool (optional)
│
├── config.mk         # Test configuration (defines top modules and sources)
├── Makefile          # Main automation file
└── .last_test.meta   # Last simulation metadata (used by `make view`)
```

---

# Requirements

Install the following tools (via `apt`, `brew`, `pip`, etc.):

* Verilator
* Cocotb
* GTKWave
* Python
* Make
* GCC
* sv2v
* Yosys
* lcov

## Optional: Virtualenv for Cocotb

```bash
python3 -m venv venv
source venv/bin/activate
pip install cocotb
```

---

# Usage

All test definitions are configured in `config.mk`. You do not need to modify the `Makefile`.

### Example `config.mk` test entry:

```make
TEST_DEFS := \
	counter_tb counter counter.sv \
	top_tb     top     top.sv;counter.sv
```

This defines two testbenches:

* `counter_tb` → top module `counter`, file: `counter.sv`
* `top_tb` → top module `top`, files: `top.sv`, `counter.sv`

## Simulation & Tests

| Command         | Description                          |
| --------------- | ------------------------------------ |
| `make <name>`   | Run a testbench (e.g. `make top_tb`) |
| `make test_all` | Run all defined testbenches          |

## Waveform Viewing

```bash
make view
```

Opens GTKWave using `.last_test.meta` to load the correct `.fst` and `.stems` files.

If no `.gtkw` file is found, a new one will be created automatically.

To specify a custom waveform save file:

```bash
make view SAVE_FILE=custom.gtkw
```

## RTL Visualization

Hierarchical RTL browsing in GTKWave can be toggled with the `VIEW_RTL` variable in `config.mk`:

```make
VIEW_RTL = 1   # Enables stem (hierarchical) view
VIEW_RTL = 0   # Disables RTL tree view
```

## Synthesis

```bash
make synth_<test_bench_name>
```

This command uses `sv2v` and `yosys` to convert and synthesize the design associated with `top_tb`.

To synthesize the first test entry in `config.mk`:

```bash
make synth
```

## Coverage

Generate an HTML report using Verilator's coverage tools:

```bash
make coverage
```

Open the coverage report in your browser:

```bash
make open-coverage
```

## Cleanup

Remove intermediate build artifacts:

```bash
make clean
```

Perform a full cleanup of all generated files:

```bash
make clean-all
```

## Clean (Shell script)

A standalone cleanup script is provided for fully removing environment-specific artifacts.
Use this only after deactivating the Python virtual environment by typing:

```bash
deactivate
```

> **Note:** After running the shell script, the environment must be re-created by following the instructions in the *Optional: Virtualenv for Cocotb* section.

---

# How to Add a New Test

1. Create a testbench in `tb/`, e.g. `myunit_tb.py`.
2. Create the matching SystemVerilog source file in `src/`, e.g. `myunit.sv`.
3. Add your new entry to `config.mk`:

```make
TEST_DEFS := \
	... \
	myunit_tb myunit myunit.sv
```

4. Run your testbench:

```bash
make myunit_tb
```

There is no need for `test_` prefixes or Makefile edits.

---

# Example Testbench (Cocotb)

```python
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test_counter(dut):
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())
    dut.rst_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.rst_i.value = 0

    dut.en_i.value = 1
    await RisingEdge(dut.clk_i)
    val = dut.count_o.value.integer

    for _ in range(5):
        await RisingEdge(dut.clk_i)

    assert dut.count_o.value.integer > val
```

---

# Tips

* `.last_test.meta` tracks the last test run and is used by `make view`, `json`, and `stems`.
* Use semicolons (`;`) in `config.mk` to specify multiple `.sv` files.
* `VIEW_RTL` toggles GTKWave’s hierarchical stem view.
* Use `SAVE_FILE=filename.gtkw` with `make view` to save or load a specific waveform layout.
* Override default tools and paths in `config.mk` as needed.

---

# License

MIT License — © Leon Wandruschka

