# Windows Forensic Triage & Analysis Framework (WFTAF)
**WORK In progress**
## 🚀 Overview
**Status: Active Development (Phase 1: Collection & Normalization)**

This project is a modular Digital Forensics and Incident Response (DFIR) framework designed for rapid triage of Windows endpoints. By leveraging high-performance PowerShell data acquisition and Python-based heuristic analysis, this tool transforms raw system telemetry into actionable intelligence.

The framework is built on a **Pipeline Architecture**:
1. **Acquisition:** PowerShell scripts collect live system state (Persistence, Network, Processes).
2. **Normalization:** Data is streamed as structured **JSON** to ensure machine-readability and forensic integrity.
3. **Analysis:** A Python engine parses the telemetry, applies known-bad heuristics, and utilizes **LLMs (Large Language Models)** to identify sophisticated anomalies that traditional pattern-matching might miss.



## 🛠 Key Features
- **Performance Optimized:** Data collection uses streaming logic to minimize memory overhead and execution time on target systems.
- **Structured Telemetry:** Moves away from flat-text logs to deep-nested JSON, preserving metadata for automated parsing.
- **AI-Augmented Detection:** Integrates LLM logic to analyze process command lines and WMI event consumers for masquerading and C2 behavior.
- **Modular Design:** Independent modules for Network Forensics, Persistence Mechanisms, and C2 Detection.

---

## 📂 Project Structure

| Component | Description | Tech Stack |
| :--- | :--- | :--- |
| **`/Scripts`** | Targeted forensic collectors (Triage, Network, Persistence). | PowerShell (JSON output) |
| **`/Parsers`** | Data normalization, heuristic filtering, and LLM integration. | Python, LangChain, Ollama |
| **`/Evidence`** | Default output directory for collected artifacts. | JSON / Markdown Reports |

---

## 📖 How to Use

### 1. Data Collection
Run the primary triage script on the target Windows machine with Administrative privileges:
# Navigate to the Scripts folder and execute
.\HueristicTriage\
Triage_Collector.ps1

This generates a Triage_[ComputerName].json file containing the system state.

### 2. Analysis & Reporting
Pass the generated JSON to the Python parser to identify IOCs:

# Navigate to the Parsers folder
python main_parser.py --input ../Evidence/Triage_PC01.json --analyze

### Roadmap
- [ ] Phase 1: Standardize JSON schema for all PowerShell collectors.
- [ ] Phase 2: Implement Python heuristic engine (Regex/Signature based).
- [ ] Phase 3: Integrate Local LLM (Llama 3/Ollama) for anomaly deduction.
- [ ] Phase 4: Develop specialized C2 and Network traffic analysis modules.

Author: William Richardson

Date: February 2026