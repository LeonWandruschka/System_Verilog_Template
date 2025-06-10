# SystemVerilog Template

A flexible and modular template for SystemVerilog projects with built-in support for:

- **Simulation:** [Verilator](https://verilator.org/) + [Cocotb](https://cocotb.org/)
- **Test Automation:** via `Makefile`
- **Waveform Viewing:** [GTKWave](http://gtkwave.sourceforge.net/)
- **Synthesis:** [sv2v](https://github.com/zachjs/sv2v) + [Yosys](https://yosyshq.net/yosys/)
- **Code Coverage:** via [lcov](https://lcov.readthedocs.io/)
- **Netlist Browsing:** using a custom `json2stems` toolchain

---

## 📁 Project Structure

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
├── synth_out/        # (optional) synthesis outputs
├── sim_build/        # auto-generated simulation artifacts
├── json2stems/       # optional tool for RTL browsing (Verilator JSON → stems)
│
├── Makefile
├── README.md
└── .last_test.meta   # automatically created (used by `make view`)
```

---

## 🧰 Requirements

Install the following tools (e.g., via `apt`, `brew`, `pip`, etc.):

- [Verilator](https://verilator.org/)
- [Cocotb](https://cocotb.org/)
- [cocotb-test](https://github.com/themperek/cocotb-test)
- [GTKWave](http://gtkwave.sourceforge.net/)
- [Python](https://www.python.org/)
- [Make](https://www.gnu.org/software/make/)
- [GCC](https://gcc.gnu.org/)
- [sv2v](https://github.com/zachjs/sv2v)
- [Yosys](https://yosyshq.net/yosys/)
- [lcov](https://lcov.readthedocs.io/)

### Example: Setup Cocotb in a Python venv

```bash
python3 -m venv venv
source venv/bin/activate
pip install cocotb cocotb-test
```

---

## 🚀 Usage

### Simulation & Tests

| Command                 | Description                                                  |
|------------------------|--------------------------------------------------------------|
| `make test_<name>`     | Run a specific testbench (`tb/<name>.py`)                    |
| `make test_counter_tb` | Example: Runs the `tb/counter_tb.py` test                    |
| `make test_all`        | Run **all defined testbenches**                              |

### Waveform Viewing

```bash
make view
```

Displays the waveform of the last run simulation in GTKWave, using `.stems` and `.fst`.

> ℹ️ This uses `.last_test.meta` automatically — no need to configure manually.

### RTL Visualization

```bash
make json
make stems
make view
```

Uses Verilator's `--json-only` mode and the `json2stems` tool to visualize module hierarchy.

### Synthesis

```bash
make synth
```

Uses `sv2v` + `yosys` to convert and synthesize your RTL source files.

### Coverage

```bash
make coverage
make open-coverage
```

Generates and opens HTML coverage reports via `lcov` and `verilator_coverage`.

### Cleanup

```bash
make clean-all
```

Removes all generated files including waveforms, coverage data, and build directories.

---

## 🧪 How to Add a New Test

1. Create a new Python testbench in `tb/`, e.g. `myunit_tb.py`
2. Write your test in Cocotb (see example below)
3. Add this line to your **Makefile**:

```make
$(eval $(call TEST_template,myunit_tb,myunit,myunit.sv))
```

Where:
- `myunit_tb` is the Python file (`tb/myunit_tb.py`)
- `myunit` is the SystemVerilog top module name
- `myunit.sv` is your source file located in `src/`

4. Run it:

```bash
make test_myunit_tb
```

---

## 🧩 Example Test (Cocotb)

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

## 🧠 Tips

- Always ensure the right `TOPLEVEL`, `MODULE`, and `.sv` files match.
- Run `make test_*` before `make view` so `.last_test.meta` exists.
- `.last_test.meta` is managed automatically — no manual editing needed.

---

## 📜 License

MIT License – © Leon Wandruschka

