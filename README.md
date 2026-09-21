# PortableAI — Portable Local AI Agent Launcher

**PortableAI** is a fully offline, portable AI agent that runs **100% on your own machine** — no cloud, no API keys, no subscriptions, no data leaving your computer.

It wraps the [llama.cpp](https://github.com/ggml-org/llama.cpp) `llama-server` into a simple launcher — `run-llama.bat` (Windows) or `run-llama.sh` (Linux / macOS) — that gives you:

- 💬 **Normal chat** with any GGUF model
- 🖥️ **Two ways to run** — Server (Web UI + API) or CLI (terminal chat)
- 🧠 **Reasoning / thinking mode** (with effort levels and token budgets)
- 🛠️ **Built-in agent tools** (read/write/edit files, grep, glob, shell commands)
- 🔌 **MCP servers** (Model Context Protocol) — plug in extra tools like **web search**
- 🌐 **Built-in Web UI** — a full ChatGPT-like interface in your browser
- 🔌 **OpenAI-compatible API** on `http://127.0.0.1:8080/v1`
- 🔍 **Automatic free-port detection** and session logging

---

## ⚠️ IMPORTANT — What is NOT in this repository

The following large files are **intentionally NOT pushed to GitHub** (they are excluded by `.gitignore`):

| Excluded | Reason | Where to get it |
|----------|--------|-----------------|
| `models/*.gguf` | Model files are huge (1 GB – 30 GB each) | Download from Hugging Face (see **Step 3**) |
| `llama/*.exe`, `llama/*.dll` | Compiled binaries | Download a llama.cpp release (see **Step 2**) |
| `mcp/mcp.json` | Contains your personal MCP setup | Create it yourself (see **MCP section**) |

**You must download these files yourself before the launcher will run.** The full step-by-step process is below — it takes about 10 minutes.

---

## 📋 Requirements

- **OS:** Windows 10 / 11 (64-bit), **or Linux / macOS** via `run-llama.sh`
- **RAM / VRAM:** depends on the model (see the model table in Step 3)
  - 1B–4B models → 4–8 GB RAM, runs on almost any PC
  - 7B models → 8–12 GB
  - 12B–16B models → 16 GB+
  - FP16 models → 16–32 GB
- **GPU (optional):** any NVIDIA card speeds things up dramatically if you use the CUDA build of llama.cpp. CPU-only works fine too.
- **Node.js (optional):** only needed if you want MCP servers such as web search
- **Git (optional):** only needed to clone the repo — you can also download it as a ZIP

---

## 🚀 Setup — Step by Step

### Step 1 — Get the project

```bash
git clone https://github.com/mohammadhossein-asadi/PortableAi.git
cd PortableAi
```

> Or click **Code → Download ZIP** on GitHub, extract it, and open the folder.

After this step your folder looks like this:

```
PortableAi/
├── llama/        (empty — you add llama.cpp binaries in Step 2)
├── models/       (empty — you add GGUF models in Step 3)
├── mcp/          (empty — optional, for MCP servers)
├── workspace/    (logs are written here automatically)
├── tmp/          (setup downloads land here; cleaned up automatically)
├── run-llama.bat (the launcher — this is the whole app, Windows)
├── run-llama.sh  (the launcher — Linux / macOS)
├── setup.bat     (one-command setup wizard — Windows)
├── setup.sh      (one-command setup wizard — Linux / macOS)
├── .gitignore
├── LICENSE
└── README.md
```

---

#### ⚡ One-command setup (recommended)

Run the setup wizard once and skip the manual steps below:

```bat
setup.bat
```

```bash
./setup.sh
```

The wizard automatically:

1. **Detects your OS and GPU** and downloads the right llama.cpp build into `llama/` — on Windows it offers CPU or CUDA if an NVIDIA card is found; on Linux/macOS it picks the matching official build.
2. **Lets you pick a curated GGUF model** (every URL is verified, sizes shown) — or paste any Hugging Face GGUF URL — and downloads it into `models/`.

Re-run it any time: finished parts are skipped, and **interrupted model downloads resume where they left off** (the finished file is size-verified, so a truncated download is always detected instead of failing later at model load).

Extras: `./setup.sh --list` prints the curated models without downloading anything.

> 💡 Behind the scenes the script reads llama.cpp's release feed (`releases/latest` on GitHub is only a stub — the real binaries live in the rolling `b<N>` releases, which the script handles for you).

---

### Step 2 — Download llama.cpp binaries → put them in `llama/`

> The setup wizard above does all of this automatically — the steps below are the manual equivalent.

1. Go to the llama.cpp releases page: **https://github.com/ggml-org/llama.cpp/releases**
2. Download the **latest build for your OS**:
   - Windows, CPU only: `llama-bXXXX-bin-win-cpu-x64.zip` (works everywhere)
   - Windows, NVIDIA GPU: `llama-bXXXX-bin-win-cuda-12.4-x64.zip` (much faster)
   - Linux (CPU): `llama-bXXXX-bin-ubuntu-x64.zip`
   - macOS (Apple Silicon): `llama-bXXXX-bin-macos-arm64.zip`
3. **Extract ALL files** from the archive directly into the `llama/` folder.

When done, you must have **at least** this file:

```
PortableAi/llama/llama-server.exe   ← required on Windows
PortableAi/llama/llama-server       ← required on Linux / macOS
```

(plus the shared libraries that ship alongside them: `llama.dll` / `ggml.dll` on Windows, `libllama.so` / `libggml*.so` on Linux, etc.)

> ✅ If you can see `llama\llama-server.exe` (Windows) or `llama/llama-server` (Linux/macOS), Step 2 is complete.
> ❌ The launcher will refuse to start without it.
> ⚠️ Do not mix: a Windows `.exe` will not run on Linux/macOS and vice versa.

---

### Step 3 — Download GGUF models → put them in `models/`

> The setup wizard above can also download a model for you (curated list or any Hugging Face URL) — the steps below are the manual equivalent.

1. Go to **https://huggingface.co/models?library=gguf&sort=downloads** (or search "GGUF" + the model name).
2. Download the `.gguf` file of a model you like.
3. **Put the `.gguf` file inside the `models/` folder.**

Popular models that match what this project was built and tested with:

| Model | Hugging Face repo | Approx. size | Min. RAM/VRAM |
|-------|-------------------|--------------|----------------|
| DeepSeek-R1-Distill-Qwen-1.5B (Q5_K_M) | `bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF` | ~1.1 GB | 4 GB |
| Gemma-3-1B-IT (IQ4_NL) | `bartowski/gemma-3-1b-it-GGUF` | ~0.7 GB | 4 GB |
| Qwen3.5-4B (IQ4_NL) | search "Qwen3.5 GGUF" | ~2.5 GB | 6 GB |
| DeepSeek-R1-Distill-Qwen-7B (IQ2_M) | `bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF` | ~3.3 GB | 6 GB |
| DeepSeek-Coder-V2-Lite-Instruct (Q2_K) | `bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF` | ~6 GB | 8 GB |
| Gemma 12B (Q3_K_S) | search "gemma 12b GGUF" | ~6.5 GB | 10 GB |
| Qwen2.5-Coder-7B-Instruct (FP16, 4 parts) | `Qwen/Qwen2.5-Coder-7B-Instruct-GGUF` | ~15 GB | 16 GB |
| Qwen2.5-Coder-14B-Instruct (FP16, 4 parts) | `Qwen/Qwen2.5-Coder-14B-Instruct-GGUF` | ~28 GB | 32 GB |

> 💡 **Quantization guide:** `Q4_K_M` / `IQ4_NL` = best quality/size balance. `Q2`/`IQ2` = small but dumber. `FP16` = full quality but huge. When in doubt, pick Q4.

**Multi-part models (e.g. `...-00001-of-00004.gguf`):** download **all 4 parts**, put them all in `models/`, and when the launcher asks you to select a model, choose the **first part** (`00001-of-00004`). llama.cpp automatically loads the remaining shards.

> ✅ If you can see at least one `.gguf` file in `models/`, Step 3 is complete.

---

### Step 4 — Run the launcher

**Windows:** double-click **`run-llama.bat`** (or run it from a terminal):

```bash
run-llama.bat
```

**Linux / macOS:** run the shell launcher:

```bash
chmod +x run-llama.sh     # only needed the first time
./run-llama.sh
```

Both launchers offer the identical menu and produce identical server flags. If `./run-llama.sh` prints `bad interpreter` or `\r` errors, the file was converted to Windows line endings — run `sed -i 's/\r$//' run-llama.sh` once to fix it (git's `.gitattributes` in this repo normally prevents this).

The launcher will:

1. ✅ Check that `llama\llama-server.exe` exists
2. ✅ Scan `models\` for `.gguf` files and list them
3. ✅ Ask you to **select a model** (auto-selects if there is only one)
4. ✅ Ask for the **Run Type** — Server (Web UI + API) or CLI (terminal chat)
5. ✅ Show the **Agent Mode menu** (see next section)
6. ✅ Find a free port (server run only, starts at `8080`)
7. ✅ Print the final configuration
8. ✅ Open your browser at `http://127.0.0.1:8080` (server run only)
9. ✅ Start `llama-server` or `llama-cli`

---

## 🖥️ Run Types — Server or CLI

After you pick a model, the launcher asks how to run it:

| Run type | What it does |
|----------|--------------|
| **Server** | Starts `llama-server` → Web UI at `http://127.0.0.1:8080` plus the OpenAI-compatible API. Supports all agent modes: built-in tools, MCP, web search, reasoning. |
| **CLI** | Starts `llama-cli` → chat directly in the terminal window. Chat + reasoning work; tools / MCP / web search are server-only features and are skipped (the launcher tells you). |

CLI tips: type your message and press Enter; `/exit` or Ctrl+C quits. The launcher uses `llama-cli`'s conversation mode (`-cnv`), so the model's chat template is applied automatically.

> The CLI option is only available when `llama/` contains `llama-cli` / `llama-cli.exe` — the full llama.cpp release includes it (see Step 2).

---

## 🎛️ Agent Modes (the menu)

When the launcher starts it asks you to pick a mode:

| # | Mode | Tools | MCP | Web Search | Reasoning | Best for |
|---|------|-------|-----|------------|-----------|----------|
| 1 | **Normal Chat** | ❌ | ❌ | ❌ | off | Simple questions, fastest responses |
| 2 | **Chat + Reasoning** | ❌ | ❌ | ❌ | on (medium) | Math, logic, hard problems |
| 3 | **Agent + Built-in Tools** | ✅ | ❌ | ❌ | off | Let the AI read/edit files on your PC |
| 4 | **Agent + Tools + Reasoning** | ✅ | ❌ | ❌ | on (medium) | Agentic coding tasks |
| 5 | **Agent + Tools + MCP** | ✅ | ✅ | ❌ | off | Custom MCP tools |
| 6 | **Full Agent** | ✅ | ✅ | ✅ | on (medium) | Everything: tools + MCP + web + thinking |
| 7 | **Custom** | your choice | your choice | your choice | your choice | Full manual control |

### Built-in tools (modes 3–6)

> Modes 3–6 rely on server-only features. With the **CLI** run type the launcher runs chat + reasoning only and skips tools / MCP / web search.

These llama.cpp server tools are enabled with `--tools all`:

`read_file` · `file_glob_search` · `grep_search` · `write_file` · `edit_file` · `exec_shell_command` · `get_info`

> ⚠️ **SECURITY WARNING:** these tools let the model **read and modify files and run shell commands on your computer**. The server is bound to `127.0.0.1` (localhost only) so nobody on your network can reach it — **never expose this server publicly** and keep an eye on what the model does.

---

## 🌐 Using the Web UI

After the server starts, your browser opens `http://127.0.0.1:8080` automatically (or open it manually).

- Type in the chat box and the model answers locally
- When tools are enabled, the model can call them and you see the tool calls in the UI
- Multi-turn conversations are kept in the browser

---

## 🔌 Using the API (OpenAI-compatible)

Any app that speaks the OpenAI API can use your local server.

**curl (Windows):**

```bash
curl http://127.0.0.1:8080/v1/chat/completions ^
  -H "Content-Type: application/json" ^
  -d "{\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}"
```

**Python (openai package):**

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:8080/v1", api_key="not-needed")

response = client.chat.completions.create(
    model="local",
    messages=[{"role": "user", "content": "Explain quantum computing simply"}],
)
print(response.choices[0].message.content)
```

---

## 🔌 MCP Servers (extra tools, e.g. Web Search)

Modes 5 and 6 load MCP servers from **`mcp/mcp.json`** — copy **`mcp/mcp.json.example`** (included in the repo) to `mcp/mcp.json` to get started.

Example `mcp/mcp.json` with a **web search** server (requires [Node.js](https://nodejs.org)):

```json
{
  "mcpServers": {
    "web-search": {
      "command": "npx",
      "args": ["-y", "duckduckgo-mcp-server"]
    }
  }
}
```

Notes:

- If **Web Search** is enabled but MCP is not, the launcher disables Web Search automatically (web search is delivered through MCP — llama.cpp has no native web-search tool).
- If MCP is enabled but `mcp.json` does not exist, the launcher disables MCP with a warning.
- You can add any MCP-compatible server under `"mcpServers"` (filesystem, fetch, git, etc.).

---

## 🧠 Reasoning / Thinking

| Setting | Values | Meaning |
|---------|--------|---------|
| `REASONING_MODE` | `auto` / `on` / `off` | Whether the model thinks before answering |
| `REASONING_EFFORT` | `minimal` `low` `medium` `high` `xhigh` `max` | How hard the model thinks |
| `REASONING_BUDGET` | `-1` (default) / `0` (off) / `N` tokens | Max tokens spent on thinking |

Defaults live at the top of `run-llama.bat`; mode 7 lets you set them interactively. Reasoning works best with reasoning-capable models (e.g. DeepSeek-R1 distills, Qwen3).

---

## ⚙️ Configuration Reference (top of `run-llama.bat`)

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `127.0.0.1` | Bind address — **keep localhost** for safety |
| `START_PORT` | `8080` | First port tried |
| `PORT_SCAN_LIMIT` | `100` | How many ports to try (8080–8179) |
| `TOOLS_ENABLED` / `TOOLS_LIST` | `0` / `all` | Built-in tool switch and list |
| `MCP_ENABLED` | `0` | Load `mcp/mcp.json` |
| `WEB_SEARCH_ENABLED` | `0` | Web search via MCP |
| `OPEN_BROWSER` | `1` | Auto-open the Web UI |
| `REASONING_MODE` / `EFFORT` / `BUDGET` | `auto` / `default` / `-1` | Reasoning defaults |

---

## 📄 Logs

Every session writes a log to:

```
workspace/logs/session_<random>.log
```

It records the date, model, mode, server URL, all flags, and the exact command line — useful for reproducing a session or reporting issues.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `[ERROR] No llama.cpp asset found` in setup | llama.cpp changed their release layout — grab the zip manually from https://github.com/ggml-org/llama.cpp/releases (Windows CPU: `llama-bNNNN-bin-win-cpu-x64.zip`) |
| `[ERROR] Downloaded file is incomplete` in setup | The connection dropped mid-download — just re-run `setup.bat` / `./setup.sh` and pick the same model; it resumes from where it stopped |
| `[ERROR] llama-server.exe was not found` | You skipped **Step 2** — extract the llama.cpp release ZIP into `llama/` |
| `[ERROR] No GGUF models found` | You skipped **Step 3** — put at least one `.gguf` file in `models/` |
| The window closes instantly | Run `run-llama.bat` from a terminal (`cmd`) to see the error |
| `permission denied: ./run-llama.sh` | Run `chmod +x run-llama.sh` once, then `./run-llama.sh` |
| `bad interpreter` / `\r` errors from `.sh` | Windows line endings got in: `sed -i 's/\r$//' run-llama.sh` |
| Model loads very slowly | Large FP16 models take minutes; use a smaller quant (Q4) or the CUDA build |
| Out-of-memory / crash on load | Pick a smaller model or a lower quant (Q2/IQ2) |
| Very slow generation | Use a smaller model, a Q4 quant, or the CUDA build of llama.cpp |
| Port 8080 busy | The launcher auto-scans the next 100 ports — check the printed URL |
| Web Search disabled | Web search requires MCP: create `mcp/mcp.json` and use mode 5 or 6 |
| `npx` not recognized | Install Node.js from https://nodejs.org (only needed for MCP) |
| CLI run type says *unavailable* | `llama-cli(.exe)` is missing from `llama/` — download the full llama.cpp release (Step 2) |
| Model answers with garbage | Wrong chat template — re-download the GGUF from a trusted source |
| Multi-part model fails | You must keep **all** parts (`00001-of-00004` … `00004-of-00004`) in `models/` and select part 1 |

---

## 📁 Project Structure

```
PortableAi/
├── llama/                  # llama.cpp binaries — DOWNLOAD SEPARATELY (not in repo)
│   └── llama-server.exe    #   ← the main server the launcher runs
├── models/                 # GGUF models — DOWNLOAD SEPARATELY (not in repo)
│   └── *.gguf
├── mcp/                    # MCP server config — created by you (not in repo)
│   ├── mcp.json.example    #   ← template, copy to mcp.json
│   └── mcp.json
├── worktrees/              # worktree sandboxes (created by create-worktree.bat, gitignored)
├── workspace/
│   └── logs/               # session logs (generated at runtime, gitignored)
├── setup.bat               # ⭐ one-command setup wizard (Windows)
├── setup.sh                # ⭐ one-command setup wizard (Linux / macOS)
├── run-llama.bat           # ⭐ the launcher — the whole app (Windows)
├── run-llama.sh            # ⭐ the launcher — the whole app (Linux / macOS)
├── create-worktree.bat     # ⭐ create an isolated agent sandbox (branch + worktree)
├── remove-worktree.bat     # ⭐ remove a sandbox safely (checks for unmerged work)
├── .gitignore              # excludes exe/dll/gguf/bin/dat, llama/, models/, worktrees/
├── LICENSE                 # MIT
└── README.md
```

---

## ❓ FAQ

**Is my data sent anywhere?**
No. The server binds to `127.0.0.1` only. Nothing leaves your machine — unless you enable a web-search MCP server, which (by definition) contacts the internet to search.

**Do I need a GPU?**
No. CPU-only works. A GPU just makes it much faster.

**Server or CLI — which one?**
Server for the Web UI, the OpenAI-compatible API, and agent tools / MCP / web search. CLI for quick terminal chats with no port and no browser.

**Can I use several models at once?**
Run `run-llama.bat` twice — the port scanner gives each instance its own port.

**Can I add more models?**
Just drop more `.gguf` files into `models/`. The launcher lists all of them at startup.

**Linux / macOS?**
Yes — use `./run-llama.sh`. It is a full port of the Windows launcher with the same menu, modes, flags, port scan, and session logs. Download the Linux or macOS llama.cpp build (see Step 2); everything else works the same. Only `create-worktree.bat` / `remove-worktree.bat` are Windows-only (plain `git worktree add` / `git worktree remove` are the equivalent there).

---

## 🌿 Worktree Sandboxes (safe agent workspaces)

Want the AI agent (or yourself) to work on something without risking your main checkout? Create an isolated **worktree sandbox** — a separate folder + git branch.

### Create a sandbox

```bash
create-worktree.bat my-feature        # or run it with no arguments for an interactive prompt
```

This will:

1. Create branch `worktree/my-feature` from your last commit
2. Create folder `worktrees/my-feature/` with the full repo
3. **Link `llama\` and `models\` from the main checkout via directory junctions** — zero extra disk space, and the sandbox can run models immediately
4. Copy `mcp/mcp.json` into the sandbox
5. Add per-worktree git exclusions so linked/copied files never show up in `git status`

### Work inside the sandbox

```bash
cd worktrees/my-feature
run-llama.bat        # the agent now works on the my-feature branch
```

Everything the agent changes happens **only inside the sandbox** — your main checkout stays clean. Your `.gguf` models and llama binaries are shared, not duplicated.

### Keep or discard the results

```bash
git -C worktrees/my-feature status    # inspect what changed
git diff master worktree/my-feature   # review the changes
git merge worktree/my-feature         # keep them (run from the main checkout)
```

### Remove a sandbox

```bash
remove-worktree.bat my-feature
```

It refuses to silently destroy work: it warns about **uncommitted changes** and about **commits not yet merged into master**, and keeps the branch if it still has unmerged commits. The `worktrees/` folder is gitignored, so sandboxes never pollute the repo.

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🙏 Credits

- [llama.cpp](https://github.com/ggml-org/llama.cpp) by Georgi Gerganov & the GGML community — the engine doing all the real work
- [Model Context Protocol](https://modelcontextprotocol.io) — the MCP tool ecosystem
- Model authors: DeepSeek, Google (Gemma), Alibaba (Qwen), Meta (Llama) and the GGUF quantizers on Hugging Face

## 📄 License

MIT — see [LICENSE](LICENSE).
