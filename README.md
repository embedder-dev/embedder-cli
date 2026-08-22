# Embedder
[![npm version](https://img.shields.io/npm/v/@embedder/embedder.svg?style=flat-square)](https://www.npmjs.com/package/@embedder/embedder)
[![npm downloads](https://img.shields.io/npm/dt/@embedder/embedder.svg)](https://www.npmjs.com/package/@embedder/embedder)

Embedder is the enterprise AI platform for embedded software. It combines your
repository, hardware documentation, board design, and bench tools so agents can
plan changes, write code, build, flash, test, and debug against real hardware.

[Read Documentation](https://docs.embedder.com)

### VS Code

The [VS Code extension](https://marketplace.visualstudio.com/items?itemName=embedder.embedder-vscode)
is the primary interface. It includes editor-aware chat, project setup,
schematics, conversation history, and the Embedder Monitor for serial,
debuggers, lab instruments, traces, and dashboards.

### Terminal

Run the same agent from a terminal or over SSH:

```bash
curl -fsSL https://embedder.com/install | bash
cd /path/to/firmware
embedder
```

An npm install is also available:

```bash
npm install --global @embedder/embedder
```

### Automation

Use the headless server for custom clients, the daemon for GitHub and Slack
workflows, or a remote bridge when the toolchain or hardware lives on another
machine.

## Community

[X/Twitter](https://x.com/embedder_dev) · [LinkedIn](https://www.linkedin.com/company/embedder-dev) · [YouTube](https://www.youtube.com/@embedder-dev) · [Discord](https://discord.gg/NMT5ndEyxk)