# Embedder

[![npm version](https://img.shields.io/npm/v/@embedder/embedder.svg?style=flat-square)](https://www.npmjs.com/package/@embedder/embedder)
[![npm downloads](https://img.shields.io/npm/dt/@embedder/embedder.svg)](https://www.npmjs.com/package/@embedder/embedder)

Embedder is an AI coding agent that lives in your terminal, built specifically for embedded software development. It understands your hardware, indexes datasheets and reference manuals, and helps you write and test firmware faster.

![cmkzv96k64bde0i38kjb9oorl](https://github.com/user-attachments/assets/c1cc91d9-74a4-4f55-9e60-cd8d213524cf)



## Get Started

### 1. Install Embedder

MacOS / Linux
```
curl -fsSL https://embedder.com/install | bash
```
Windows (Powershell)
```
irm https://embedder.com/install | iex
```

### 2. Upload Documentation

If your hardware is not supported, visit [app.embedder.com](https://app.embedder.com) and upload:
- Datasheets
- Reference manuals
- Schematics
- Application notes
- Safety standards

Contact [help@embedder.com](mailto:help@embedder.com) to suggest additions to our MCU/peripheral catalog.

### 3. Run Embedder

Navigate to your project directory and run:

```
embedder
```

You'll be prompted to log in with your account on first run.

## What Makes Embedder Different

Embedder is purpose-built for embedded systems:

- **Hardware-Aware**: Understands microcontroller peripherals (GPIO, SPI, I²C, UART, ADC, DMA, timers, interrupts), memory constraints, and real-time requirements.

- **Documentation Intelligence**: Indexes your datasheets, reference manuals, and schematics to generate code grounded in your actual hardware specs.

- **Real Hardware Integration**: Connects directly with serial ports, debuggers, logic analyzers, and oscilloscopes to validate and debug on physical devices without switching tools.

- **Embedded Expertise**: Deep knowledge of RTOS systems (FreeRTOS, Zephyr, ThreadX), low-level driver development, and MISRA-C/C++ compliance.

- **Cited Outputs**: Every code generation includes inline references to specific datasheet sections, register definitions, and application notes.

## Supported Platforms

Works with any embedded platform, including:
- **MCUs**: ESP32, STM32, nRF, Raspberry Pi Pico, Arduino, PIC, MSP430, and more
- **Toolchains**: GCC-ARM, GCC-RISC-V, IAR, Keil, LLVM, and vendor-specific compilers
- **Build systems**: PlatformIO, CMake, Make, Ninja

## Community

Join the [Embedder Discord](https://discord.com/invite/NMT5ndEyxk) to connect with other embedded developers. Get help, share feedback, and discuss your projects.

## Enterprise

For teams requiring air-gapped deployment, on-premises hosting, or compliance with ITAR, ISO 27001, and other standards, contact us at [founders@embedder.com](mailto:founders@embedder.com).
For full details, review our [Terms of Service](https://embedder.com/terms-of-service) and [Privacy Policy](https://embedder.com/privacy-policy).

## License

See [LICENSE](./LICENSE) for details.
