# Verilog Testbench Generator

Automatically generate comprehensive Verilog testbenches using IBM watsonx.ai, then compile and simulate with Icarus Verilog and GTKWave.

## Features

- 🤖 **AI-Powered Generation**: Uses IBM watsonx.ai to generate comprehensive testbenches
- 🔍 **Edge Case Testing**: Automatically includes edge cases, overflow testing, and stuck-at fault models
- ⚡ **Automated Workflow**: Compiles with iverilog and opens waveforms in GTKWave
- 🎨 **Rich Terminal UI**: Polished output using the rich library
- 📊 **VCD Generation**: Automatic waveform file generation for analysis

## Prerequisites

1. **Python 3.7+**
2. **Icarus Verilog** (iverilog and vvp)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install iverilog
   
   # macOS
   brew install icarus-verilog
   ```
3. **GTKWave** (optional, for waveform viewing)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install gtkwave
   
   # macOS
   brew install gtkwave
   ```

## Installation

1. Clone or download this repository

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file in the project directory with your IBM watsonx.ai credentials:
   ```env
   WATSONX_API_KEY=your_api_key_here
   WATSONX_PROJECT_ID=your_project_id_here
   ```

## Usage

### Basic Usage

Generate a testbench for a Verilog file:

```bash
python main.py alu.v
```

This will:
1. Read the Verilog file (`alu.v`)
2. Send it to watsonx.ai for testbench generation
3. Save the testbench as `alu_tb.v`
4. Compile both files with iverilog
5. Run the simulation
6. Open the waveform in GTKWave

### Skip Simulation

To generate the testbench without compiling/simulating:

```bash
python main.py alu.v --no-sim
```

### Make Script Executable

```bash
chmod +x main.py
./main.py alu.v
```

## Output Files

For an input file `module.v`, the script generates:

- `module_tb.v` - Generated testbench
- `module_tb.vvp` - Compiled simulation file
- `module_tb.vcd` - Waveform data file

## Example

```bash
$ python main.py alu.v

╭─────────────────────────────────────╮
│  Verilog Testbench Generator        │
│  Powered by IBM watsonx.ai           │
╰─────────────────────────────────────╯

→ Loading API credentials...
✓ API key loaded

→ Reading Verilog file...
✓ Successfully read alu.v

→ Generating testbench...
⠋ Generating testbench with watsonx.ai...
✓ Testbench generated successfully

→ Saving testbench...
✓ Testbench saved to alu_tb.v

═══ Compilation & Simulation ═══

→ Compiling with iverilog...
✓ Compilation successful: alu_tb.vvp
→ Running simulation...

Simulation Output:
╭────────────────────────────────────╮
│ Test results appear here...        │
╰────────────────────────────────────╯

✓ Simulation complete
→ Opening waveform in GTKWave...
✓ GTKWave opened with alu_tb.vcd

═══ Complete ═══

✓ Testbench file: alu_tb.v
```

## Configuration

### API Endpoint

The script uses the US South region by default. To change regions, modify the `url` in the `generate_testbench()` function in [`main.py`](main.py:82):

```python
url = "https://us-south.ml.cloud.ibm.com/ml/v1/text/generation?version=2023-05-29"
```

### Model Selection

The default model is `ibm/granite-13b-chat-v2`. To use a different model, modify the `model_id` in [`main.py`](main.py:99):

```python
"model_id": "ibm/granite-13b-chat-v2",
```

### Generation Parameters

Adjust token limits and other parameters in the `payload` section of [`main.py`](main.py:93-98):

```python
"parameters": {
    "decoding_method": "greedy",
    "max_new_tokens": 2000,
    "min_new_tokens": 0,
    "stop_sequences": [],
    "repetition_penalty": 1.0
}
```

## Troubleshooting

### API Key Issues

If you see "WATSONX_API_KEY not found":
- Ensure `.env` file exists in the same directory as `main.py`
- Check that the key is correctly formatted: `WATSONX_API_KEY=your_key`

### Compilation Errors

If iverilog fails:
- Verify iverilog is installed: `iverilog -v`
- Check that your Verilog file has no syntax errors
- Review the error output for specific issues

### GTKWave Not Opening

If GTKWave doesn't open automatically:
- Install GTKWave if not present
- Manually open the `.vcd` file: `gtkwave module_tb.vcd`
- Use `--no-sim` flag and open files manually

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.