# fin-proto

English | [简体中文](README.md)

## Overview

**fin-proto** provides a Domain Specific Language (DSL) for describing binary message
formats used in financial exchanges, along with Lua-based Wireshark dissector generation.
The DSL grammar is based on **ANTLR4**, enabling the definition of data structures,
metadata types, and matching rules for complex financial protocols. Grammar details:
🔗 [fin-protoc/grammar/PacketDsl.g4](https://github.com/xinchentechnote/fin-protoc/blob/main/grammar/PacketDsl.g4)

## Key Features

- **Protocol Definition Language** — DSL specialized for binary packet structures and message formats
- **Code Generation Pipeline** — Compile protocol definitions into Lua (Wireshark) / Java / Go / Rust / C++ / Python decoders
- **Financial Domain Focus** — Built-in support for financial trading patterns (message dispatch, repeating groups, length-prefixed strings, checksums)
- **Multi-Exchange Support** — SSE, SZSE, BSE/CFFEX-linked NEEQ, NASDAQ, NYSE, Borsa Istanbul, HKEx, LSE/Turquoise, ITS and more (see inventory below)

## Repository Structure

```bash
fin-proto/
├── README.md                     # Chinese readme (default)
├── README_EN.md                  # English readme (this file)
├── Makefile                      # Build all protocols
├── docs.md                       # DSL syntax guide (Chinese)
├── syntax-gaps.md                # DSL syntax gap list
├── sample/                       # Tutorial example
├── risk/                         # Risk control protocol
├── sse/binary/                   # SSE binary trading
├── sse/step/                     # SSE STEP (draft)
├── szse/binary/                  # SZSE binary trading
├── szse/step/                    # SZSE STEP (draft)
├── bse/                          # BSE/NEEQ trading + market data
├── bist/                         # Borsa Istanbul ITCH
├── nasdaq/                       # NASDAQ OUCH / RASHport
├── nyse/                         # NYSE Pillar equities / options
├── hke/                          # HKEx CCCG
├── lse/lseg/                     # LSEG MIT203
├── lse/turquoise/                # Turquoise TQ301
└── its/                          # ITS native trading gateway
```

## pdsl Inventory & Support Status

Legend:

| Mark | Meaning |
|---|---|
| ✅ | Verified — field-by-field checked against the official PDF, compiles |
| 🧪 | Initial — compiles and modeled per spec; some segments not modeled due to syntax limits, or pending second-pass review / real-packet validation |
| 📝 | Draft — depends on the unimplemented STEP syntax (`message`/`@tag`), not compilable yet |
| ❌ | Needs fix — existing file does not compile (syntax gap or compiler defect) |

| pdsl file | Protocol / Spec | Packets | Status | Notes |
|---|---|---:|:-:|---|
| `sse/binary/sse_bin_v0.57.pdsl` | SSE binary trading V0.57 | 17 | ✅ | Includes password-service 306/308; descriptions aligned with PDF |
| `szse/binary/szse_bin_v1.29.pdsl` | SZSE binary trading 1.29 | 68 | ✅ | Session + three business families complete; quote/RFQ/trade-report families (spec 4.6–4.14) intentionally not modeled |
| `bse/bse_trade_bin_v0.9.pdsl` | BSE/NEEQ binary trading (trial) | 62 | ✅ | Endianness/group prefix/family codes intentionally deviate from the official PDF per bse/readme; pending final packet-capture validation |
| `bse/bse_md_bin_v0.9.pdsl` | BSE/NEEQ binary market data (trial) | 25 | ✅ | Same; snapshot NumberOfOrders added per PDF |
| `bist/bist_itch_v2112.pdsl` | Borsa Istanbul BISTech ITCH 2112 | 17 | 🧪 | Per-field offset self-checked; MoldUDP64 transport framing not modeled |
| `nasdaq/ouch_v5.0.pdsl` | NASDAQ OUCH 5.0 | 27 | 🧪 | Big-endian; dual dispatchers for inbound/outbound; optional appendage not modeled — **field-level re-review recommended** |
| `nasdaq/rashport_v1.1.pdsl` | NASDAQ RASHport 1.1 | 14 | 🧪 | ASCII numeric fields modeled as char[n] — **field-level re-review recommended** |
| `nyse/nyse_pillar_bin_v5.15.pdsl` | NYSE Pillar Binary Gateway v5.15 (equities) | 37 | 🧪 | Bitfields/optional add-ons/count-less trailing repeats limited by syntax; mixed-up PDF tables cross-verified |
| `nyse/nyse_pillar_options_bin_v3.24.pdsl` | NYSE Pillar Options Gateway v3.24 | 34 | 🧪 | Same; named-count repeating group of BulkQuoteAck limited |
| `lse/turquoise/tq301_native_v5.0.1.pdsl` | Turquoise TQ301 (LSEG) | 20 | ✅ | All messages manually field-checked + length-verified; MiFID bitfields modeled as integers |
| `its/its_native_v1.1.2.pdsl` | ITS native trading gateway (iface v22) | 23 | ✅ | All messages manually field-checked + length-verified; offset+count repeating groups expressed exactly |
| `sse/step/sse_step_v0.57.pdsl` | SSE STEP V0.57 | 19 | 📝 | Waiting for STEP syntax (see syntax-gaps.md #7) |
| `szse/step/szse_step_v1.29.pdsl` | SZSE STEP 1.29 | 25 | 📝 | Same; business/report-management message list complete per spec |
| `hke/hkex_cccg_v1.4.pdsl` | HKEx CCCG v1.4 | 20 | ❌ | Uses unimplemented `Bitmap[n]` syntax (syntax-gaps.md #8) |
| `lse/lseg/lseg_native_bin_v17.0.2.pdsl` | LSEG MIT203 v17.0.2 | 26 | ❌ | Triggers compiler panic on undefined bare field (syntax-gaps.md #1); file also marked incomplete |
| `risk/risk_v0.1.0.pdsl` | Risk control protocol | 7 | ✅ | Internal protocol |
| `sample/sample.pdsl` | Tutorial example | 6 | ✅ | DSL usage example |

> Official specification PDFs live in a separate repository:
> [fin-proto-reference](https://github.com/xinchentechnote/fin-proto-reference).

## DSL Syntax Overview

```dsl
options {
    StringPrefixLenType = u16;   // length-prefix type for variable strings
    ArrayPrefixLenType  = u16;   // count-prefix type for repeating groups
    LittleEndian = false;        // byte order
    JavaPackage = "com.finproto.sse.bin.messages";
}

MetaData DataType {            // named type dictionary
    int64 price `price`,
    char[12] SecurityID `security id`,
}

root packet SseBinary {        // wire root: header + dispatch + trailer
    uint32 MsgType `message type`,
    @lengthOf(Body)
    uint32 MsgBodyLen `body length`,
    match MsgType as Body {
        40 : Logon,
        58 : NewOrderSingle,
        [206, 207] : ExecRptSyncFamily,
    },
    @calculatedFrom("SSE_BIN")
    uint32 Checksum `checksum`,
}

packet Logon {
    char[32] SenderCompID `sender`,
    char[32] TargetCompID `target`,
    uint16 HeartBtInt `heartbeat interval (sec)`,
}

packet ExecRptSync {
    repeat SubExecRptSync {    // repeating group (count prefix = ArrayPrefixLenType)
        char[8] Pbu,
        uint32 SetID,
    },
}
```

Full syntax guide: [docs.md](docs.md) (Chinese). Current language limits and the
requested-features list: [syntax-gaps.md](syntax-gaps.md).

## Getting Started

```bash
git clone https://github.com/xinchentechnote/fin-proto.git
cd fin-proto
make compile     # requires a local fin-protoc (default ~/workspace/fin-protoc/bin/)
```

Build output is a Lua Wireshark dissector per protocol directory; other language
targets use the `fin-protoc -g/-j/-r/-p/-c` output flags.

## Related Repositories

- [`fin-proto-vscode`](https://github.com/xinchentechnote/fin-proto-vscode) — VS Code extension
  (syntax highlighting, completion, formatting, linting)
- [`fin-protoc`](https://github.com/xinchentechnote/fin-protoc) — ANTLR-based compiler backend
- [`fin-proto-rs`](https://github.com/xinchentechnote/fin-proto-rs) — High-performance Rust codec
- [`fin-proto-go`](https://github.com/xinchentechnote/fin-proto-go) — Native Go implementation
- [`fin-proto-cpp`](https://github.com/xinchentechnote/fin-proto-cpp) — C++ implementation
- [`fin-proto-java`](https://github.com/xinchentechnote/fin-proto-java) — Java (Netty ByteBuf)
- [`fin-proto-py`](https://github.com/xinchentechnote/fin-proto-py) — Python implementation
- [`fin-proto-reference`](https://github.com/xinchentechnote/fin-proto-reference) — Official spec PDFs

## Contributing

When adding a new protocol:

1. Put the official specification PDF into the fin-proto-reference repository;
2. Create `<exchange>/<protocol>_v<version>.pdsl` following the inventory conventions,
   noting the source PDF and modeling decisions in the file header;
3. Validate with `make compile` and record anything inexpressible in `syntax-gaps.md`;
4. Update the support-status inventory in both readmes (Chinese and English).

---

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xinchentechnote/fin-proto)
