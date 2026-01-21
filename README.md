# Embedder

![](https://img.shields.io/badge/Node.js-18%2B-brightgreen?style=flat-square) [![npm]](https://www.npmjs.com/package/@embedder/embedder)

[npm]: https://img.shields.io/npm/v/@embedder/embedder.svg?style=flat-square

Embedder is an AI coding tool that lives in your terminal, specializing in embedded software development. It understands your hardware, indexes datasheets and reference manuals, and helps you write and test firmware faster by executing routine tasks, debugging on real hardware, and handling complex peripheral configurations.

**Learn more in the [official documentation](https://docs.embedder.dev)**.

## Get started

1. Install Embedder:

```sh
curl -fsSL https://embedder.com/install | bash
```

2. Navigate to your project directory and run `embedder`.

## What Makes Embedder Different

Embedder is built specifically for embedded systems:

- **Hardware-Aware**: Understands microcontroller peripherals (GPIO, SPI, I²C, UART, ADC, DMA, timers, interrupts), memory constraints, and real-time requirements
- **Documentation Intelligence**: Indexes datasheets, reference manuals, and schematics to generate code based on your actual hardware specs
- **Real Hardware Integration**: Connects with serial ports, debuggers, logic analyzers, and oscilloscopes to validate and debug on physical devices
- **Embedded Expertise**: Deep knowledge of RTOS systems, low-level driver development, and MISRA-C/C++ compliance

## Supported Platforms

Works with any embedded platform including ESP32, STM32, nRF, Raspberry Pi Pico, Arduino, and more. Compatible with all major toolchains including GCC, IAR, Keil, and vendor-specific compilers.

## Connect on Discord

Join the [Embedder Discord](https://discord.com/invite/NMT5ndEyxk) to connect with other embedded developers. Get help, share feedback, and discuss your projects with the community.

## Data collection, usage, and retention

When you use Embedder, we collect feedback, which includes usage data.

### How we use your data

We use your data to:
- Provide and maintain our services
- Improve our services and develop new features
- Provide customer support and technical assistance

All codebase indexing happens locally on your machine. For cloud features, we offer enterprise agreements with strict data isolation and compliance with ITAR, ISO 27001, and other standards.

### Privacy safeguards

We have implemented several safeguards to protect your data, including limited retention periods for sensitive information, restricted access to user session data, and clear policies against using feedback for model training without consent.

For full details, please review our [Terms of Service](https://embedder.dev/terms-of-service) and [Privacy Policy](https://embedder.dev/privacy-policy).
