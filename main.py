#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
import shutil
import re
from pathlib import Path
from dotenv import load_dotenv
import requests
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.markdown import Markdown
from rich.table import Table

# Import enhanced testbench generation system
from enhanced_tb_generator import (
    TestbenchLearningSystem,
    analyze_module_complexity,
    extract_module_info,
    build_enhanced_prompt,
    validate_testbench_syntax,
    calculate_quality_score
)

console = Console()
learning_system = TestbenchLearningSystem()

def load_api_key():
    load_dotenv()
    api_key = os.getenv('WATSONX_API_KEY')
    if not api_key:
        console.print("[bold red]Error: WATSONX_API_KEY not found in .env file[/bold red]")
        sys.exit(1)
    return api_key

def call_watsonx(prompt, api_key, max_tokens=2500, temperature=0.7, top_p=0.95, top_k=50):
    """Enhanced function to call IBM Watsonx API with better sampling parameters."""
    try:
        token_response = requests.post(
            "https://iam.cloud.ibm.com/identity/token",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={"grant_type": "urn:ibm:params:oauth:grant-type:apikey", "apikey": api_key}
        )
        if token_response.status_code != 200:
            console.print("[bold red]Error getting IAM token.[/bold red]")
            sys.exit(1)
        
        iam_token = token_response.json()["access_token"]
        url = "https://us-south.ml.cloud.ibm.com/ml/v1/text/generation?version=2023-05-29"
        
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"Bearer {iam_token}"
        }

        payload = {
            "input": prompt,
            "parameters": {
                "decoding_method": "sample",
                "max_new_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
                "top_k": top_k,
                "repetition_penalty": 1.05,
                "stop_sequences": ["endmodule\n\n", "```"]
            },
            "model_id": "ibm/granite-3-8b-instruct",
            "project_id": os.getenv('WATSONX_PROJECT_ID')
        }

        response = requests.post(url, headers=headers, json=payload, timeout=90)
        response.raise_for_status()
        return response.json()['results'][0]['generated_text']
    except Exception as e:
        console.print(f"[bold red]API Error:[/bold red] {e}")
        sys.exit(1)

def generate_verification_report(verilog_content, api_key):
    prompt = f"""You are a Principal VLSI Verification Engineer. 
Perform Static Code Analysis on this Verilog module. 
Output a professional Markdown report with:
# 🔬 AI Verification Report
## 1. Architecture Summary (Focus on pointers and buffer type)
## 2. Critical Bugs & Syntax Errors
## 3. Unhandled Edge Cases (Full/Empty conditions, Reset states)
## 4. Final Verdict

Verilog Module:
{verilog_content}
"""
    return call_watsonx(prompt, api_key, 3000).strip()

def generate_enhanced_testbench(verilog_content, api_key, max_attempts=3):
    """
    Enhanced testbench generation with:
    - Complexity analysis
    - Few-shot learning from successful examples
    - Iterative refinement with syntax validation
    - Quality scoring and learning
    """
    console.print("\n[cyan]🔍 Analyzing module complexity...[/cyan]")
    
    # Step 1: Analyze module
    complexity = analyze_module_complexity(verilog_content)
    module_info = extract_module_info(verilog_content)
    
    # Display analysis
    table = Table(title="Module Analysis", show_header=True, header_style="bold magenta")
    table.add_column("Property", style="cyan")
    table.add_column("Value", style="green")
    table.add_row("Module Name", module_info['module_name'])
    table.add_row("Complexity Level", complexity['level'].upper())
    table.add_row("Complexity Score", f"{complexity['score']}/15")
    table.add_row("Max Bus Width", f"{complexity['max_bus_width']}-bit")
    table.add_row("Has Clock", "✓" if module_info['has_clock'] else "✗")
    table.add_row("Has Reset", "✓" if module_info['has_reset'] else "✗")
    table.add_row("State Machine", "✓" if complexity['has_state_machine'] else "✗")
    console.print(table)
    
    # Step 2: Get examples from learning system
    console.print("\n[cyan]📚 Retrieving best practice examples...[/cyan]")
    examples = learning_system.get_best_examples(module_info['module_name'], n=2)
    if examples:
        console.print(f"[green]✓[/green] Found {len(examples)} relevant examples")
    else:
        console.print("[yellow]ℹ[/yellow] No prior examples found, using base knowledge")
    
    # Step 3: Build enhanced prompt
    console.print("\n[cyan]🎯 Building enhanced prompt with few-shot learning...[/cyan]")
    prompt = build_enhanced_prompt(verilog_content, module_info, complexity, examples)
    
    # Step 4: Iterative generation with refinement
    best_code = None
    best_score = 0
    
    for attempt in range(1, max_attempts + 1):
        console.print(f"\n[cyan]🤖 Generation attempt {attempt}/{max_attempts}...[/cyan]")
        
        # Adjust parameters based on complexity and attempt
        temperature = 0.7 if complexity['level'] == 'simple' else 0.8
        if attempt > 1:
            temperature += 0.1  # Increase creativity on retries
        
        max_tokens = 2000 if complexity['level'] == 'simple' else 3000 if complexity['level'] == 'moderate' else 4000
        
        try:
            raw_output = call_watsonx(prompt, api_key, max_tokens, temperature=temperature)
            
            if not raw_output or len(raw_output.strip()) == 0:
                console.print(f"[yellow]⚠ Empty response from API[/yellow]")
                continue
            
            console.print(f"[dim]Received {len(raw_output)} characters[/dim]")
            
            # Clean output
            clean_code = re.sub(r'```(?:verilog|systemverilog)?', '', raw_output, flags=re.IGNORECASE)
            clean_code = clean_code.replace('```', '')
            
            start_match = re.search(r'(`timescale|module)', clean_code, re.IGNORECASE)
            if not start_match:
                console.print(f"[yellow]⚠ No valid Verilog code found in response[/yellow]")
                continue
                
            code_body = clean_code[start_match.start():]
            end_match = re.search(r'endmodule', code_body, re.IGNORECASE)
            if not end_match:
                console.print(f"[yellow]⚠ Incomplete module (missing endmodule)[/yellow]")
                continue
                
            code_body = code_body[:end_match.end()]
            
            # Validate syntax
            validation = validate_testbench_syntax(code_body)
            quality_score = calculate_quality_score(code_body, module_info, complexity)
            
            console.print(f"[cyan]📊 Quality Score: {quality_score:.1f}/10[/cyan]")
            
            if validation['errors']:
                console.print(f"[yellow]⚠ Syntax errors found:[/yellow]")
                for error in validation['errors']:
                    console.print(f"  • {error}")
            
            if validation['warnings']:
                console.print(f"[yellow]ℹ Warnings:[/yellow]")
                for warning in validation['warnings']:
                    console.print(f"  • {warning}")
            
            # Keep best version
            if quality_score > best_score:
                best_code = code_body
                best_score = quality_score
                console.print(f"[green]✓ New best score: {best_score:.1f}/10[/green]")
            
            # If we got a good score, stop early
            if quality_score >= 8.0 and validation['valid']:
                console.print(f"[bold green]✓ Excellent quality achieved![/bold green]")
                break
            
            # Add feedback for next iteration
            if attempt < max_attempts and not validation['valid']:
                prompt += f"\n\nPREVIOUS ATTEMPT HAD ERRORS:\n"
                for error in validation['errors']:
                    prompt += f"- {error}\n"
                prompt += "\nFix these errors in the next generation.\n"
            
        except Exception as e:
            console.print(f"[red]✗ Attempt {attempt} failed: {str(e)}[/red]")
            import traceback
            console.print(f"[dim]{traceback.format_exc()}[/dim]")
            continue
    
    if best_code:
        # Store successful pattern in learning system
        if best_score >= 7.0:
            learning_system.add_successful_testbench(
                module_info['module_name'],
                best_code,
                best_score
            )
            console.print(f"\n[green]✓ Stored in knowledge base for future reference[/green]")
        
        return best_code
    
    console.print("[red]✗ Failed to generate valid testbench after all attempts[/red]")
    return None

def update_filelist(target_path, list_name="files.f"):
    target_path_str = str(target_path)
    try:
        if Path(list_name).exists():
            with open(list_name, 'r') as f:
                if target_path_str in f.read(): return
        with open(list_name, 'a') as f:
            f.write(f"{target_path_str}\n")
        console.print(f"[green]✓[/green] Added [cyan]{target_path_str}[/cyan] to {list_name}")
    except Exception as e:
        console.print(f"[yellow]Warning: Could not update {list_name}[/yellow]")

def main():
    console.print(Panel.fit("[bold cyan]BobBench: Advanced AI Verification Pipeline[/bold cyan]", border_style="cyan"))
    parser = argparse.ArgumentParser()
    parser.add_argument("verilog_file")
    args = parser.parse_args()
    
    file_path = Path(args.verilog_file)
    if not file_path.exists(): sys.exit(1)
        
    api_key = load_api_key()
    with open(file_path, 'r') as f: verilog_content = f.read()
    
    base_name = file_path.stem
    output_dir = Path("runs") / base_name
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if testbench already exists
    tb_path = output_dir / f"{base_name}_tb.v"
    tb_exists = tb_path.exists()
    
    if tb_exists:
        console.print(f"[yellow]ℹ[/yellow] Testbench already exists at [cyan]{tb_path}[/cyan]")
        console.print("[yellow]→[/yellow] Skipping testbench generation, proceeding with AI verification only")
        
    with Progress(SpinnerColumn(), TextColumn("[progress.description]{task.description}"), console=console) as progress:
        task1 = progress.add_task("[cyan]Step 1: AI Static Analysis...", total=None)
        report_md = generate_verification_report(verilog_content, api_key)
        progress.update(task1, completed=True)
    
    tb_code = None
    if not tb_exists:
        console.print("\n[bold cyan]═══ Step 2: Enhanced Testbench Generation ═══[/bold cyan]")
        tb_code = generate_enhanced_testbench(verilog_content, api_key, max_attempts=3)
        
        if not tb_code:
            console.print("[bold red]✗ Testbench generation failed[/bold red]")
            sys.exit(1)
    else:
        console.print("\n[green]✓[/green] Using existing testbench")
    
    with open(output_dir / f"{base_name}_report.md", 'w') as f: f.write(report_md)
    
    if not tb_exists and tb_code:
        with open(tb_path, 'w') as f: f.write(tb_code)
        console.print(f"\n[green]✓[/green] Testbench saved to [cyan]{tb_path}[/cyan]")
    
    console.print("\n")
    console.print(Panel(Markdown(report_md), title="Static Analysis Report", border_style="blue"))
    
    console.print("\n[bold cyan]═══ Step 3: Simulation Engine ═══[/bold cyan]")
    vvp_file = output_dir / f"{base_name}.vvp"
    
    try:
        shutil.copy(file_path, output_dir / file_path.name)
        # Using -g2012 for SystemVerilog support
        subprocess.run(["iverilog", "-g2012", "-o", str(vvp_file), str(output_dir / file_path.name), str(output_dir / f"{base_name}_tb.v")], check=True, capture_output=True)
        console.print("[green]✓[/green] Compiled Successfully")
        
        subprocess.run(["vvp", vvp_file.name], cwd=output_dir, check=True, capture_output=True)
        console.print("[green]✓[/green] Simulation Complete")
        
        if (output_dir / "dump.vcd").exists():
            subprocess.Popen(["gtkwave", "dump.vcd"], cwd=output_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]Pipeline Failed:[/bold red]\n{e.stderr.decode()}")
        
    update_filelist(output_dir / file_path.name)
    update_filelist(output_dir / f"{base_name}_tb.v")
    
    console.print(f"\n[bold green]Success: Assets isolated in {output_dir}/[/bold green]")

if __name__ == "__main__":
    main()