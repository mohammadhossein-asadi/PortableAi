# PortableAI

A collection of lightweight AI utilities and scripts designed to be easily portable across different environments. It includes tools for working with large language models, model management, and various AI-related workflows.

## 📌 Important Note About Model Files

**Model files (`.gguf`, `.bin`, `.dat`) are large and are NOT pushed to GitHub.** They should be downloaded separately as needed. See the "Usage" section for instructions on obtaining and placing model files.

---

## ✨ Features

- Modular design for easy integration
- Supports multiple LLM backends (Llama, Gemma, Qwen, DeepSeek)
- Easily extensible
- Cross-platform compatibility
- Tool capability detection and configuration

---

## 📦 Installation

### Option 1: Clone the repository

```bash
# Clone the repository
git clone https://github.com/your-username/PortableAi.git

# Navigate to the project directory
cd PortableAi
```

### Option 2: Download as ZIP

1. Go to the [GitHub repository](https://github.com/your-username/PortableAi)
2. Click "Code" -> "Download ZIP"
3. Extract the ZIP file to your desired location

### Prerequisites

- Windows 10/11 or compatible OS
- Python 3.8+ (for Python-based scripts)
- [Ollama](https://ollama.com/) or local LLM runtime (optional)

---

## 🚀 Usage

### Running the Portable AI Scripts

#### Using the Batch Script

```bash
# Run the main Llama script
./run-llama.bat
```

#### Using Python

```python
import llama

# Example: Simple inference
result = llama.execute(prompt="Your prompt here")
print(result)
```

### Working with Models

#### Adding a New Model

1. Download a GGUF model file (`.gguf` format)
2. Place it in the `models/` directory
3. Ensure the model filename doesn't contain spaces for best compatibility

#### Available Models

The repository supports various GGUF-format models:

- **DeepSeek models**: Code and reasoning models
- **Gemma models**: Google's efficient models
- **Qwen models**: Qwen series coding and chat models
- **Llama models**: Meta's Llama models

### Tool Capability Detection

PortableAI can detect model capabilities automatically:

```powershell
# Run the tool capability detector
python -m workspace.tool-capability
```

Or via batch script:

```bash
run-llama.bat --detect
```

---

## 🛠️ Project Structure

```
PortableAi/
├── llama/                    # Llama runtime and executables
├── models/                   # GGUF model files (download separately)
├── workspace/                # Workspace for logs and configuration
│   └── logs/                 # Session logs
├── .gitignore                # Git ignore rules
├── README.md                 # This file
├── run-llama.bat           # Main execution script
└── tool-capability.log      # Tool capability detection log
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📬 Contact

**Your Name** - your.email@example.com

**Project Link**: [https://github.com/your-username/PortableAi](https://github.com/your-username/PortableAi)

---

## 🆕 Getting Started - Step by Step

### First Time Setup

Follow these steps to get PortableAI running on your system:

#### Step 1: Clone or Download

```bash
git clone https://github.com/your-username/PortableAi.git
cd PortableAi
```

#### Step 2: Install Git LFS (Optional but Recommended)

If you plan to work with model files, install Git LFS:

```bash
git lfs install
git lfs track "*.gguf"
```

#### Step 3: Place Your Model Files

1. Create an account on [Hugging Face](https://huggingface.co) or [GGUF](https://github.com/ggerganov/llama.cpp/releases)
2. Download your desired GGUF model
3. Place it in the `models/` directory

#### Step 4: Run Your First Model

```bash
# Using the batch script
./run-llama.bat

# Or via Python
python -c "from llama import execute; print(execute('Hello World'))"
```

#### Step 5: Detect Model Capabilities

```powershell
# Detect model capabilities
python -m workspace.tool-capability
```

#### Step 6: Explore More Scripts

Check the `llama/` directory for available scripts and utilities.

### Common Issues

| Issue | Solution |
|-------|----------|
| "Model file not found" | Ensure `.gguf` files are in the `models/` directory |
| Script won't start | Check that you have the required runtime components |
| Performance issues | Verify your hardware meets minimum requirements |
| Template detection failed | Check the model filename follows expected patterns |

### Advanced Usage

- **Batch processing**: Run multiple prompts sequentially
- **Model quantization**: Adjust quantization levels for performance/quality tradeoff
- **Custom templates**: Add your own chat templates in the workspace directory