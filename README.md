<p align="center">
  <h1 align="center">🤖 MCP + LangChain Agent — Docker Edition</h1>
  <p align="center">
    <strong>A Dockerised AI DevOps assistant powered by MCP servers and LangChain</strong>
  </p>
  <p align="center">
    <a href="#-quick-start"><img src="https://img.shields.io/badge/Quick_Start-blue?style=for-the-badge" alt="Quick Start"></a>
    <a href="#-architecture"><img src="https://img.shields.io/badge/Architecture-purple?style=for-the-badge" alt="Architecture"></a>
    <a href="#-try-these-prompts"><img src="https://img.shields.io/badge/Try_It-green?style=for-the-badge" alt="Try It"></a>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/python-3.12-blue?logo=python&logoColor=white" alt="Python 3.12">
    <img src="https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white" alt="Docker Compose">
    <img src="https://img.shields.io/badge/MCP-Protocol-orange" alt="MCP">
    <img src="https://img.shields.io/badge/LangChain-🦜-green" alt="LangChain">
    <img src="https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazonaws&logoColor=white" alt="AWS EC2">
    <img src="https://img.shields.io/badge/Jira-Cloud-0052CC?logo=jira&logoColor=white" alt="Jira Cloud">
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="MIT License">
  </p>
</p>

---

An AI-powered DevOps assistant that connects **Weather**, **Jira**, and **AWS EC2** APIs through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) with a [LangChain](https://www.langchain.com/) agent. Each MCP server runs in its own **Docker container**, providing isolation, reproducibility, and one-command deployment on any EC2 instance.

> **Built at Cloud Soft Solutions — APEX / NEXUS Lab**

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🌤 **Weather Tools** | Current weather and multi-day forecasts via [Open-Meteo](https://open-meteo.com) (free, no API key) |
| 🎫 **Jira Tools** | List projects, search with JQL, read/create issues, add comments via Jira Cloud API |
| 🖥 **EC2 Tools** | List, describe, summarize instances; optionally start/stop with safety guard |
| 🐳 **Fully Dockerised** | One image, multiple containers — each MCP server runs independently |
| 🔒 **Security First** | Non-root containers, secrets via `.env` (never baked into images), IAM roles for AWS |
| 🏥 **Health Checks** | Built-in Docker health checks with automatic agent dependency management |
| ⚡ **One-Script Setup** | From a fresh Ubuntu EC2 instance to running in ~10 minutes |
| 🤖 **Multi-LLM Support** | Works with Anthropic Claude and OpenAI GPT models |

## 🏗 Architecture

```
┌──────────────────────────── EC2 instance (Ubuntu 24.04 + Docker) ────────────────────────────┐
│                                                                                              │
│   Docker network: mcp-net                                                                    │
│   ┌──────────────┐        ┌────────────────────┐                                             │
│   │  mcp-agent   │──────▶ │ mcp-weather :8001  │──▶ Open-Meteo API                           │
│   │ (run --rm)   │──────▶ │ mcp-jira    :8002  │──▶ Jira Cloud API                           │
│   │ LangChain    │──────▶ │ mcp-ec2     :8003  │──▶ AWS EC2 API (via instance IAM role)      │
│   └──────────────┘        └────────────────────┘                                             │
│          ▲  the agent reaches servers by NAME:  http://weather:8001/mcp                      │
│          │  ports also published on 127.0.0.1 only (debugging) — never public                │
└──────────┼───────────────────────────────────────────────────────────────────────────────────┘
       You (SSH)
```

**How it works:**
1. You type a question (e.g., *"What's the weather in Hyderabad?"*)
2. The **LangChain agent** picks the right MCP tool based on the question
3. The tool calls the appropriate **MCP server** running in its Docker container
4. The server calls the **real API** (Open-Meteo / Jira Cloud / AWS EC2)
5. The result flows back through the chain to you

## 📁 Project Structure

```
mcp-langchain-docker/
├── docker-setup.sh          # ⭐ ONE script: install Docker → configure → build → run → test
├── mcp.sh                   # ⭐ daily commands: up / down / agent / ask / logs / test ...
├── Dockerfile               # one image for all services (python:3.12-slim, non-root)
├── docker-compose.yml       # weather, jira, ec2 (+ agent on demand)
├── .dockerignore            # keeps .env OUT of the image
├── .env.example             # template for secrets and config
├── requirements.txt         # Python dependencies
├── agent/
│   └── agent.py             # LangChain agent (interactive + one-shot mode)
├── servers/
│   ├── weather_server.py    # MCP server: Open-Meteo weather API
│   ├── jira_server.py       # MCP server: Jira Cloud REST API v3
│   └── ec2_server.py        # MCP server: AWS EC2 via boto3
├── scripts/
│   └── test_servers.py      # smoke test — no LLM key needed
└── deploy/
    ├── fix_imds_hop_limit.sh
    └── iam/
        ├── create_role.sh
        ├── ec2-readonly-policy.json
        ├── ec2-startstop-policy.json
        └── ec2-trust-policy.json
```

## 🚀 Quick Start

### Prerequisites

- An **AWS EC2 instance** running Ubuntu 24.04 LTS (t3.small or larger)
- An **LLM API key** (Anthropic or OpenAI)
- (Optional) **Jira Cloud** credentials for Jira integration
- (Optional) **IAM role** attached to the instance for EC2 tools

### Step 1: Create the IAM Role (Optional — for EC2 tools)

From your laptop or AWS CloudShell:

```bash
bash deploy/iam/create_role.sh                 # read-only EC2 access
# or: bash deploy/iam/create_role.sh --with-write   # includes start/stop
```

### Step 2: Launch the EC2 Instance

| Setting | Value |
|---------|-------|
| AMI | Ubuntu Server 24.04 LTS |
| Type | `t3.small` or larger (2 GB RAM) |
| Storage | 20 GB |
| Security group | **SSH (22) from My IP only** |
| IAM instance profile | `mcp-ec2-agent-role` |
| Metadata (Advanced details) | **Metadata response hop limit = 2** |

> **Why hop limit 2?** Docker's bridge network adds one network hop. With the default limit of 1, containers cannot reach the EC2 instance metadata service (IMDSv2) for AWS credentials.

### Step 3: Copy, Setup, and Run

```bash
# From your laptop
scp -i mykey.pem mcp-langchain-docker.zip ubuntu@<EC2_PUBLIC_IP>:~
ssh -i mykey.pem ubuntu@<EC2_PUBLIC_IP>

# On the EC2 instance
sudo apt-get update && sudo apt-get install -y unzip
unzip mcp-langchain-docker.zip && cd mcp-langchain-docker
bash docker-setup.sh
```

The setup script will:
1. ✅ Install Docker Engine + Compose plugin
2. ✅ Create `.env` from template (interactive prompts for API keys)
3. ✅ Build the Docker image
4. ✅ Start the 3 MCP server containers
5. ✅ Wait for health checks and run smoke tests
6. ✅ Verify IAM role access from containers

### Step 4: Start Chatting 🎉

```bash
./mcp.sh agent
```

## 🛠 Daily Commands

The `mcp.sh` wrapper provides convenient commands for day-to-day usage:

| Command | Description |
|---------|-------------|
| `./mcp.sh up` | Build (if needed) and start the servers |
| `./mcp.sh status` | Container status and health |
| `./mcp.sh agent` | Interactive chat session |
| `./mcp.sh ask "list running instances"` | Ask one question, then exit |
| `./mcp.sh test` | Smoke-test all servers (no LLM needed) |
| `./mcp.sh logs jira` | Follow a server's logs (`weather` / `jira` / `ec2`) |
| `./mcp.sh restart` | Recreate containers after editing `.env` |
| `./mcp.sh rebuild` | Rebuild image after editing code |
| `./mcp.sh shell ec2` | Open a bash shell inside a container |
| `./mcp.sh down` | Stop everything |
| `./mcp.sh clean` | Remove containers, network, and image |

> **Tip:** After running `docker-setup.sh`, log out and back in so you can run Docker without `sudo`.

### Docker Compose Equivalents

```bash
docker compose up -d --build        # start servers
docker compose ps                   # status
docker compose run --rm agent       # chat
docker compose logs -f ec2          # logs
docker compose down                 # stop
```

## 💬 Try These Prompts

```
What's the weather in Hyderabad right now?
Give me a 5-day forecast for Chennai.
List my Jira projects.
Show open bugs in project DEMO.
Create a Task in DEMO titled "Rotate IAM keys" with description "Quarterly rotation".
How many EC2 instances do I have in ap-south-1, by type?
Describe my running instances.
If it will rain in Mumbai tomorrow, create a Jira task in DEMO to move the outdoor drill.
```

## 🔧 Configuration

### Environment Variables

Copy the example and fill in your values:

```bash
cp .env.example .env && nano .env
```

| Variable | Required | Description |
|----------|----------|-------------|
| `LLM_MODEL` | Yes | Model identifier, e.g., `anthropic:claude-haiku-4-5-20251001` or `openai:gpt-4o-mini` |
| `ANTHROPIC_API_KEY` | If using Anthropic | Your Anthropic API key |
| `OPENAI_API_KEY` | If using OpenAI | Your OpenAI API key |
| `JIRA_URL` | For Jira tools | e.g., `https://your-domain.atlassian.net` |
| `JIRA_EMAIL` | For Jira tools | Your Atlassian email |
| `JIRA_API_TOKEN` | For Jira tools | [Create one here](https://id.atlassian.com/manage-profile/security/api-tokens) |
| `AWS_REGION` | For EC2 tools | Default: `ap-south-1` |
| `EC2_ALLOW_WRITE` | Optional | Set to `true` to enable start/stop instance tools |

## 🐳 How the Docker Setup Works

| Concept | Where to see it |
|---------|-----------------|
| **One image, many containers.** The same image runs every service; only `command:` changes. | `docker-compose.yml` → `x-app` anchor |
| **Service discovery.** Containers find each other by service name (`weather`, `jira`, `ec2`). | `agent` → `environment:` |
| **Bind address.** Inside a container the server must listen on `0.0.0.0`, or other containers can't reach it. | `MCP_HOST: 0.0.0.0` |
| **Port publishing.** `127.0.0.1:8001:8001` reaches the host only, not the internet. | `ports:` |
| **Healthchecks.** The agent waits until the servers are healthy. | `healthcheck:` + `depends_on` |
| **Secrets at runtime.** `.env` is injected by `env_file` and never copied into the image. | `.dockerignore` |
| **Non-root container.** The image runs as `appuser`. | `Dockerfile` |
| **Profiles.** `up -d` doesn't start the interactive agent. | `profiles: ["cli"]` |

## 🔍 Troubleshooting

| Problem | Fix |
|---------|-----|
| `permission denied ... docker.sock` | Log out and back in (docker group), or use `sudo` |
| Container `unhealthy` / restarting | `./mcp.sh logs <name>` — usually a Python error or a bad `.env` value |
| `No AWS credentials found` | Attach the IAM role **and** set hop limit to 2 (`deploy/fix_imds_hop_limit.sh`), then `./mcp.sh restart` |
| `.env` changes ignored | Use `./mcp.sh restart` (recreates containers). `docker restart` does **not** reload `env_file` |
| Code changes ignored | `./mcp.sh rebuild` — code is baked into the image |
| `Jira API error 401` | Wrong email or API token pair |
| Build fails with no space left | `docker system prune -af` and/or grow the EBS volume |
| Agent says a server is `not reachable` | `./mcp.sh status`, then `./mcp.sh up` |

## 🗺 Roadmap

- [ ] Push the image to **Amazon ECR** and run the servers on **ECS Fargate**
- [ ] Add an HTTP UI container (FastAPI or Streamlit) in front of the agent
- [ ] Deploy the same compose services to **EKS** as Deployments and Services
- [ ] Add more MCP servers (S3, CloudWatch, GitHub, Slack)
- [ ] CI/CD pipeline with GitHub Actions

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/Mokshith-9391">Mokshith Reddy</a> at Cloud Soft Solutions
</p>
