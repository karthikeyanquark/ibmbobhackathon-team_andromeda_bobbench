#!/usr/bin/env python3
"""
Enhanced Testbench Generator with Self-Learning Capabilities
Implements: Few-shot learning, iterative refinement, quality scoring, and feedback loop
"""

import json
import re
from pathlib import Path
from datetime import datetime

class TestbenchLearningSystem:
    """Manages learning from successful testbenches and quality scoring."""
    
    def __init__(self, db_path="testbench_knowledge.json"):
        self.db_path = Path(db_path)
        self.knowledge_base = self._load_knowledge()
    
    def _load_knowledge(self):
        """Load existing knowledge base or create new one."""
        if self.db_path.exists():
            with open(self.db_path, 'r') as f:
                return json.load(f)
        return {
            "successful_patterns": [],
            "common_errors": [],
            "best_practices": [],
            "module_templates": {}
        }
    
    def save_knowledge(self):
        """Persist knowledge base to disk."""
        with open(self.db_path, 'w') as f:
            json.dump(self.knowledge_base, f, indent=2)
    
    def add_successful_testbench(self, module_type, tb_code, quality_score):
        """Store successful testbench patterns for future reference."""
        pattern = {
            "module_type": module_type,
            "code_snippet": tb_code[:500],  # Store first 500 chars as pattern
            "quality_score": quality_score,
            "timestamp": datetime.now().isoformat()
        }
        self.knowledge_base["successful_patterns"].append(pattern)
        self.save_knowledge()
    
    def get_best_examples(self, module_type, n=3):
        """Retrieve best examples for similar module types."""
        patterns = [p for p in self.knowledge_base["successful_patterns"] 
                   if module_type.lower() in p["module_type"].lower()]
        patterns.sort(key=lambda x: x["quality_score"], reverse=True)
        return patterns[:n]
    
    def record_error(self, error_type, context):
        """Record common errors for future avoidance."""
        error_entry = {
            "type": error_type,
            "context": context,
            "timestamp": datetime.now().isoformat()
        }
        self.knowledge_base["common_errors"].append(error_entry)
        self.save_knowledge()


def analyze_module_complexity(verilog_content):
    """Analyze module complexity to determine generation strategy."""
    complexity_score = 0
    
    # Check for state machines
    if re.search(r'\bcase\b|\bstate\b', verilog_content, re.IGNORECASE):
        complexity_score += 3
    
    # Check for parameters and generics
    if re.search(r'#\s*\(parameter', verilog_content, re.IGNORECASE):
        complexity_score += 2
    
    # Check for wide buses (64-bit or more)
    if re.search(r'\[(\d+):0\]', verilog_content):
        widths = re.findall(r'\[(\d+):0\]', verilog_content)
        max_width = max([int(w) for w in widths])
        if max_width >= 63:
            complexity_score += 4
    
    # Check for multiple always blocks
    always_count = len(re.findall(r'\balways\b', verilog_content, re.IGNORECASE))
    complexity_score += min(always_count, 5)
    
    # Check for memory/arrays
    if re.search(r'\breg\s+\[.*\]\s+\w+\s*\[', verilog_content):
        complexity_score += 3
    
    return {
        "score": complexity_score,
        "level": "simple" if complexity_score < 5 else "moderate" if complexity_score < 10 else "complex",
        "has_state_machine": bool(re.search(r'\bcase\b|\bstate\b', verilog_content, re.IGNORECASE)),
        "has_parameters": bool(re.search(r'#\s*\(parameter', verilog_content, re.IGNORECASE)),
        "max_bus_width": max([int(w) for w in re.findall(r'\[(\d+):0\]', verilog_content)], default=0),
        "always_blocks": len(re.findall(r'\balways\b', verilog_content, re.IGNORECASE))
    }


def extract_module_info(verilog_content):
    """Extract detailed module information for better prompt construction."""
    info = {
        "module_name": "",
        "inputs": [],
        "outputs": [],
        "parameters": [],
        "has_clock": False,
        "has_reset": False
    }
    
    # Extract module name
    module_match = re.search(r'module\s+(\w+)', verilog_content)
    if module_match:
        info["module_name"] = module_match.group(1)
    
    # Extract ports
    port_section = re.search(r'module\s+\w+[^;]*\((.*?)\);', verilog_content, re.DOTALL)
    if port_section:
        ports = port_section.group(1)
        
        # Find inputs
        for match in re.finditer(r'input\s+(?:\[[\d:]+\]\s+)?(\w+)', ports):
            port_name = match.group(1)
            info["inputs"].append(port_name)
            if 'clk' in port_name.lower():
                info["has_clock"] = True
            if 'rst' in port_name.lower() or 'reset' in port_name.lower():
                info["has_reset"] = True
        
        # Find outputs
        for match in re.finditer(r'output\s+(?:reg\s+)?(?:\[[\d:]+\]\s+)?(\w+)', ports):
            info["outputs"].append(match.group(1))
    
    # Extract parameters
    for match in re.finditer(r'parameter\s+(\w+)\s*=', verilog_content):
        info["parameters"].append(match.group(1))
    
    return info


def build_enhanced_prompt(verilog_content, module_info, complexity, examples):
    """Build an enhanced prompt with few-shot learning and detailed instructions."""
    
    prompt = f"""You are an Expert VLSI Verification Engineer with 15+ years of experience writing production-grade testbenches for complex digital designs.

# MISSION
Generate a comprehensive, syntactically correct SystemVerilog testbench for the provided Verilog module.

# MODULE ANALYSIS
- Name: {module_info['module_name']}
- Complexity: {complexity['level'].upper()} (score: {complexity['score']}/15)
- Bus Width: Up to {complexity['max_bus_width']}-bit
- State Machine: {'YES' if complexity['has_state_machine'] else 'NO'}
- Parameters: {', '.join(module_info['parameters']) if module_info['parameters'] else 'None'}
- Clock: {'YES' if module_info['has_clock'] else 'NO'}
- Reset: {'YES' if module_info['has_reset'] else 'NO'}

# CRITICAL SYNTAX RULES (MUST FOLLOW)
1. **DECLARATIONS**: Every DUT input → `reg`, every output → `wire`
2. **NO DOT NOTATION**: Never write `dut.signal = value`
3. **PORT MAPPING**: Explicit mapping: `.port_name(local_signal)`
4. **SYSTEM TASKS**: Always use `$` prefix: `$display`, `$finish`, `$dumpfile`
5. **TIMING**: Use `#10` delays between operations
6. **WAVEFORMS**: MUST include:
   ```verilog
   initial begin
       $dumpfile("dump.vcd");
       $dumpvars(0, tb_{module_info['module_name']});
   end
   ```
7. **CLOCK GENERATION** (if module has clock):
   ```verilog
   reg clk = 0;
   always #5 clk = ~clk;  // 10ns period
   ```
8. **RESET SEQUENCE** (if module has reset):
   ```verilog
   initial begin
       rst_n = 0;
       #20 rst_n = 1;  // Release after 20ns
   end
   ```

# TESTBENCH STRUCTURE (MANDATORY)
```verilog
`timescale 1ns/1ps

module tb_{module_info['module_name']}();
    // 1. Signal declarations
    // 2. DUT instantiation
    // 3. Clock generation (if needed)
    // 4. Waveform dump
    // 5. Test stimulus with comprehensive coverage
    // 6. Self-checking with expected values
endmodule
```

# TEST COVERAGE REQUIREMENTS
"""

    if complexity['level'] == 'simple':
        prompt += """
- Basic functionality: All input combinations
- Edge cases: All 0s, all 1s, alternating patterns
- Boundary values: Min/max values
- At least 50 test vectors
"""
    elif complexity['level'] == 'moderate':
        prompt += """
- Functional scenarios: Normal operation paths
- State transitions: All valid state changes
- Edge cases: Boundary conditions, overflow/underflow
- Corner cases: Simultaneous operations
- At least 100 test vectors with random patterns
"""
    else:  # complex
        prompt += """
- Comprehensive functional coverage: All operation modes
- State machine exhaustive testing: All states and transitions
- Stress testing: Back-to-back operations, pipeline stalls
- Corner cases: Race conditions, metastability scenarios
- Error injection: Invalid inputs, protocol violations
- Performance testing: Maximum throughput scenarios
- At least 200 test vectors with constrained random
"""

    if complexity['max_bus_width'] >= 32:
        prompt += f"""
# WIDE BUS HANDLING ({complexity['max_bus_width']}-bit)
- Use hexadecimal notation: `{complexity['max_bus_width']}'hXXXX`
- Test patterns: Walking 1s, walking 0s, random values
- Boundary testing: 0, MAX_VALUE, MAX_VALUE-1
"""

    if complexity['has_state_machine']:
        prompt += """
# STATE MACHINE TESTING
- Test all state transitions
- Verify illegal state handling
- Test reset from each state
- Verify state outputs for each state
"""

    # Add few-shot examples if available
    if examples:
        prompt += "\n# REFERENCE EXAMPLES (High-Quality Testbenches)\n"
        for i, example in enumerate(examples[:2], 1):
            prompt += f"\n## Example {i} (Quality Score: {example['quality_score']}/10)\n"
            prompt += f"```verilog\n{example['code_snippet']}\n```\n"

    prompt += f"""

# SELF-CHECKING MECHANISM
Include automatic verification:
```verilog
task check_output;
    input expected_value;
    begin
        if (actual_output !== expected_value) begin
            $display("ERROR at time %0t: Expected %h, Got %h", 
                     $time, expected_value, actual_output);
            error_count = error_count + 1;
        end
    end
endtask
```

# OUTPUT FORMAT
- Start with `timescale 1ns/1ps
- End with `endmodule`
- NO markdown code blocks (```)
- NO explanatory text
- ONLY valid Verilog/SystemVerilog code

# VERILOG MODULE TO TEST
{verilog_content}

Generate the complete testbench now:
"""
    
    return prompt


def validate_testbench_syntax(tb_code):
    """Validate testbench for common syntax errors."""
    errors = []
    warnings = []
    
    # Check for timescale
    if not re.search(r'`timescale', tb_code):
        errors.append("Missing `timescale directive")
    
    # Check for module declaration
    if not re.search(r'module\s+\w+', tb_code):
        errors.append("Missing module declaration")
    
    # Check for endmodule
    if not re.search(r'endmodule', tb_code):
        errors.append("Missing endmodule")
    
    # Check for dumpfile
    if not re.search(r'\$dumpfile', tb_code):
        warnings.append("Missing $dumpfile for waveform generation")
    
    # Check for dumpvars
    if not re.search(r'\$dumpvars', tb_code):
        warnings.append("Missing $dumpvars for waveform generation")
    
    # Check for improper dot notation (common error)
    if re.search(r'dut\.\w+\s*=', tb_code):
        errors.append("Illegal dot notation found (dut.signal = value)")
    
    # Check for missing $ in system tasks
    system_tasks = ['display', 'finish', 'monitor', 'time']
    for task in system_tasks:
        if re.search(rf'\b{task}\s*\(', tb_code) and not re.search(rf'\${task}\s*\(', tb_code):
            errors.append(f"Missing $ prefix for system task: {task}")
    
    # Check for balanced begin/end
    begin_count = len(re.findall(r'\bbegin\b', tb_code))
    end_count = len(re.findall(r'\bend\b', tb_code))
    if begin_count != end_count:
        errors.append(f"Unbalanced begin/end blocks: {begin_count} begin, {end_count} end")
    
    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "score": max(0, 10 - len(errors) * 2 - len(warnings) * 0.5)
    }


def calculate_quality_score(tb_code, module_info, complexity):
    """Calculate comprehensive quality score for generated testbench."""
    score = 0
    max_score = 10
    
    # Syntax validation (3 points)
    validation = validate_testbench_syntax(tb_code)
    score += (validation["score"] / 10) * 3
    
    # Coverage indicators (3 points)
    test_count = len(re.findall(r'#\d+', tb_code))  # Count delays as proxy for test steps
    if test_count > 50:
        score += 1
    if test_count > 100:
        score += 1
    if re.search(r'for\s*\(', tb_code):  # Has loops for comprehensive testing
        score += 1
    
    # Self-checking (2 points)
    if re.search(r'if\s*\(.*!==.*\)', tb_code):  # Has comparison checks
        score += 1
    if re.search(r'\$display.*error', tb_code, re.IGNORECASE):  # Reports errors
        score += 1
    
    # Best practices (2 points)
    if re.search(r'task\s+\w+', tb_code):  # Uses tasks for organization
        score += 0.5
    if re.search(r'\$dumpfile.*\$dumpvars', tb_code, re.DOTALL):  # Has waveform dump
        score += 0.5
    if module_info['has_clock'] and re.search(r'always\s+#\d+\s+clk', tb_code):  # Proper clock
        score += 0.5
    if module_info['has_reset'] and re.search(r'rst.*=.*0.*#.*rst.*=.*1', tb_code, re.DOTALL):
        score += 0.5
    
    return min(score, max_score)


# Export functions for use in main.py
__all__ = [
    'TestbenchLearningSystem',
    'analyze_module_complexity',
    'extract_module_info',
    'build_enhanced_prompt',
    'validate_testbench_syntax',
    'calculate_quality_score'
]

# Made with Bob
