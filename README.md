# fin-proto

## Overview

**fin-proto** provides a Domain Specific Language (DSL) for describing binary message formats used in financial exchanges, along with Lua Based Wireshark dissectors for network analysis.
The DSL grammar is based on **ANTLR4**, enabling the definition of data structures, metadata types, and matching rules for complex financial protocols.
Grammar details are available at:
🔗 [https://github.com/xinchentechnote/fin-protoc/blob/main/grammar/PacketDsl.g4](https://github.com/xinchentechnote/fin-protoc/blob/main/grammar/PacketDsl.g4)

## Key Features

- **Protocol Definition Language** - Specialized DSL for binary packet structures and message formats
- **Code Generation Pipeline** - Compile protocol definitions into Wireshark dissectors automatically
- **Financial Domain Focus** - Built-in support for financial trading patterns
- **Multi-Exchange Support** - Implementations for SSE, SZSE, with future plans for BJSE, HKE, LSE, NYSE, and NASDAQ

## Repository Structure

```bash
fin-proto/
├── README.md
├── Makefile                     # Build system for compiling protocols to Lua-based Wireshark dissectors
├── reference/                   # Source protocol documentation
├── sample/
│   ├── sample.pdsl              # Tutorial DSL example
│   └── root_packet.lua          # Sample root packet Lua dissector
├── risk/
│   ├── risk_v0.1.0.dsl          # Risk control protocol DSL
│   └── rc_binary.lua            # Risk control Lua dissector
├── sse/binary/
│   ├── sse_bin_v0.57.pdsl       # SSE binary protocol DSL
│   └── sse_binary.lua           # SSE Lua dissector
├── szse/binary/
│   ├── szse_bin_v1.29.pdsl      # SZSE binary protocol DSL
│   └── szse_binary.lua          # SZSE Lua dissector
```

## DSL Syntax Overview

### Basic Structure

fin-proto DSL supports several constructs for defining binary protocols:

```dsl
root packet PacketName {
  fieldDefinitions
}

MetaData DataTypeName {
  type fieldName `description`,
}
```

### Data Types

| Type     | Alias | Description                  |
| -------- | ----- | ---------------------------- |
| uint8    | u8    | 8-bit unsigned integer       |
| uint16   | u16   | 16-bit unsigned integer      |
| uint32   | u32   | 32-bit unsigned integer      |
| uint64   | u64   | 64-bit unsigned integer      |
| int8     | i8    | 8-bit signed integer         |
| int16    | i16   | 16-bit signed integer        |
| int32    | i32   | 32-bit signed integer        |
| int64    | i64   | 64-bit signed integer        |
| float32  | f32   | 32-bit floating point number |
| float64  | f64   | 64-bit floating point number |
| char     |       | Single character             |
| char\[n] |       | Fixed-length character array |
| char\[]  |       | Variable-length string       |
| string   |       | Variable-length string       |

### Protocol Configuration

Each DSL file can define protocol-wide options:

```dsl
options {
  	StringPreFixLenType = u16;
	RepeatPreFixSizeType = u16;
	LittleEndian = false;
	JavaPackage = "com.finproto.sse.bin.messages";
    GoPackage = "sse_bin"
    GoModule = "github.com/xinchentechnote/fin-proto-go/sse-bin/messages"
}
```

## Contributing

When adding new protocols:

1. Follow the DSL syntax guidelines described in this README
2. Define appropriate metadata types for financial data
3. Use descriptive field names and include documentation comments
4. Test the generated dissectors in Wireshark

## Notes

fin-proto is tailored for financial trading environments. It includes robust support for major stock exchange protocols and generates Lua dissectors that enable real-time traffic inspection in Wireshark. This is useful for debugging, monitoring, and regulatory compliance.

The SZSE protocol implementation showcases the DSL’s flexibility in modeling complex and extensible message formats.

## Related Repositories

- [`fin-proto-vscode`](https://github.com/xinchentechnote/fin-proto-vscode)
  VS Code extension for fin-proto DSL development
  Features: syntax highlighting, code completion, formatting, and linting

- [`fin-protoc`](https://github.com/xinchentechnote/fin-protoc)
  ANTLR-based compiler backend for fin-proto DSL

  - Supports transformations using visitor pattern
  - DSL formatter
  - Multi-language code generation (Java, Rust, Lua, Go, Python, C++)

- [`fin-proto-rs`](https://github.com/xinchentechnote/fin-proto-rs)

  - High-performance binary codec in Rust
  - Zero-copy serialization/deserialization
  - Supports SSE, SZSE, and risk protocols
  - Includes unit testing infrastructure

- [`fin-proto-go`](https://github.com/xinchentechnote/fin-proto-go)

  - Native Go implementation of the protocols
  - Standardized codec interface
  - Modular, exchange-specific architecture

- [`fin-proto-cpp`](https://github.com/xinchentechnote/fin-proto-cpp)

  - Efficient C++ implementation
  - Protocol support for SSE, SZSE, risk
  - Optimized serialization logic

- [`fin-proto-java`](https://github.com/xinchentechnote/fin-proto-java)

  - Binary protocol codec for Java
  - Netty ByteBuf integration
  - Gradle build system
  - Java 17+ compatible

- [`fin-proto-py`](https://github.com/xinchentechnote/fin-proto-py)

  - Python implementation for financial protocols
  - SSE, SZSE, and risk protocol support
  - Easy-to-use parsing and serialization API

---

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xinchentechnote/fin-proto)
