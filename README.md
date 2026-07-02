# Embedder
[![npm version](https://img.shields.io/npm/v/@embedder/embedder.svg?style=flat-square)](https://www.npmjs.com/package/@embedder/embedder)
[![npm downloads](https://img.shields.io/npm/dt/@embedder/embedder.svg)](https://www.npmjs.com/package/@embedder/embedder)

**Build firmware with AI agents.**

Embedder is an AI agent for firmware. It reads your datasheets, writes the code, flashes the board, runs the tests, and fixes its own mistakes, autonomously. Every step is grounded in reference manuals, schematics, and errata, with closed-loop validation on real hardware.

[**Request a Pilot →**](https://embedder.com/contact)

---

## Why Embedder?

Generic AI coding tools generate plausible-looking code, and in firmware, *plausible is dangerous*. A hallucinated register address or invented clock tree doesn't fail a lint check. It fails on the bench, or worse, in the field.

Embedder is built differently. It's hardware-aware from the ground up: it knows your exact part, your board's wiring, and what the silicon actually did at runtime.

## Capabilities

| Capability | What it does |
|---|---|
| [Datasheet Intelligence](https://embedder.com/capabilities/datasheet-intelligence) | Every generated value cites the reference manual section it came from. No hallucinated registers, no invented clock trees |
| [Schematic Ingestion](https://embedder.com/capabilities/schematic-ingestion) | Reads Altium, KiCad, Eagle, PADS, and Xpedition schematics so generated code already knows how the board is wired |
| [Hardware Interaction](https://embedder.com/capabilities/hardware-interaction) | Drives debug probes, logic analyzers, scopes, and power profilers, folding real signals back into the loop |
| [Agent Orchestration](https://embedder.com/capabilities/agent-orchestration) | Specialized agents build, flash, test, and repair firmware in a closed loop, turning multi-hour workflows into minutes |
| [Hallucination Detection](https://embedder.com/capabilities/hallucination-detection) | Cross-references every register, bit field, and timing value against the docs. Uncited values are blocked, low-confidence ones flagged for review |

## Solutions

| Use case | What Embedder does |
|---|---|
| [Rapid Bring-Up](https://embedder.com/solutions/rapid-bringup) | From schematic to blinking board, fast |
| [Debugging & RCA](https://embedder.com/solutions/debugging-rca) | Root-cause analysis against the live board |
| [Platform Migrations](https://embedder.com/solutions/platform-migrations) | Move between MCU families without a rewrite from scratch |
| [Automated Testing](https://embedder.com/solutions/automated-testing) | Closed-loop test generation and execution on real hardware |
| [Power Optimization](https://embedder.com/solutions/power-optimization) | Every microamp accounted for, verified on silicon |

## Platform Support

- **MCUs & silicon:** STM32, Nordic, ESP32, Teensy, Arduino, Raspberry Pi, plus Texas Instruments, NXP, Infineon, Microchip, Renesas, and Atmel. Architectures include ARM Cortex-M0/M4/M7, RISC-V, Xtensa, AVR, and PIC32
- **Protocols:** SPI, I2C, UART, CAN/CAN-FD, Ethernet/MAC, USB-PD, BLE 5.4
- **Test equipment:** J-Link, OpenOCD, Saleae and Digilent logic analyzers, Nordic PPK, Joulescope, Siglent and Rigol instruments
- **Compliance standards:** MISRA C:2012, CERT C, ISO 26262, IEC 61508, IEC 62304, DO-178C

## Get Started

Embedder is currently available through pilot programs.

[**Request a Pilot →**](https://embedder.com/contact)

## Resources

- [Documentation](https://docs.embedder.com)
- [Changelog](https://docs.embedder.com/changelog)
- [Product Demos](https://www.youtube.com/@embedder-dev)
- [News](https://embedder.com/news)

## Community

[X/Twitter](https://x.com/embedder_dev) · [LinkedIn](https://www.linkedin.com/company/embedder-dev) · [YouTube](https://www.youtube.com/@embedder-dev) · [Discord](https://discord.gg/NMT5ndEyxk)
