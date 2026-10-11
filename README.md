# fin-proto

简体中文 | [English](README_EN.md)

## 概述

**fin-proto** 提供一门领域特定语言(DSL),用于描述金融交易所的二进制消息格式,并配套基于
Lua 的 Wireshark 解码器生成。DSL 语法基于 **ANTLR4**,可定义复杂数据结构、元数据类型与
分发规则。语法定义见:
🔗 [fin-protoc/grammar/PacketDsl.g4](https://github.com/xinchentechnote/fin-protoc/blob/main/grammar/PacketDsl.g4)

## 特性

- **协议定义语言** —— 专为二进制报文结构与消息格式设计的 DSL
- **代码生成流水线** —— 编译 DSL 自动生成 Lua(Wireshark)/Java/Go/Rust/C++/Python 解码代码
- **金融领域专注** —— 内置金融交易常用模式(消息分发、重复组、变长串、校验和等)
- **多交易所覆盖** —— 上交所、深交所、北交所/股转、NASDAQ、NYSE、Borsa Istanbul、
  港交所、伦交所/Turquoise、ITS 等(见下方清单)

## 目录结构

```bash
fin-proto/
├── README.md                     # 中文说明(本文件)
├── README_EN.md                  # 英文说明
├── Makefile                      # 编译全部协议
├── docs.md                       # DSL 语法说明(中文)
├── syntax-gaps.md                # DSL 语法缺口清单
├── sample/                       # 教学示例
├── risk/                         # 风控协议
├── sse/binary/                   # 上交所 二进制交易
├── sse/step/                     # 上交所 STEP(草稿)
├── szse/binary/                  # 深交所 Binary 交易
├── szse/step/                    # 深交所 STEP(草稿)
├── bse/                          # 北交所/股转 交易 + 行情
├── bist/                         # Borsa Istanbul ITCH
├── nasdaq/                       # NASDAQ OUCH / RASHport
├── nyse/                         # NYSE Pillar 股票 / 期权
├── hke/                          # 港交所 CCCG
├── lse/lseg/                     # 伦交所 MIT203
├── lse/turquoise/                # Turquoise TQ301
└── its/                          # ITS 原生交易网关
```

## pdsl 清单与支持程度

图例:

| 标记 | 含义 |
|---|---|
| ✅ | 已核对 —— 与官方 PDF 逐字段比对过,编译通过 |
| 🧪 | 初版 —— 编译通过,按规范建模;部分段受语法限制未建模,或待第二轮复核/真实报文验证 |
| 📝 | 草稿 —— 依赖尚未实现的 STEP 语法(`message`/`@tag`),暂不可编译 |
| ❌ | 待修复 —— 现有文件无法编译(语法缺口或编译器缺陷) |

| pdsl 文件 | 协议 / 规范 | 包/消息数 | 支持 | 备注 |
|---|---|---:|:-:|---|
| `sse/binary/sse_bin_v0.57.pdsl` | 上交所 二进制交易 V0.57 | 17 | ✅ | 含网络密码服务 306/308;字段描述已对齐 PDF |
| `szse/binary/szse_bin_v1.29.pdsl` | 深交所 Binary 交易 1.29 | 68 | ✅ | 会话+三大业务族全量;报价/询价/成交申报等族(规范 4.6-4.14)有意未建模 |
| `bse/bse_trade_bin_v0.9.pdsl` | 北交所/股转 Binary 交易(试行版) | 62 | ✅ | 字节序/组前缀/家族码按实测偏离官方 PDF(见 bse/readme),待真实报文终验 |
| `bse/bse_md_bin_v0.9.pdsl` | 北交所/股转 Binary 行情(试行版) | 25 | ✅ | 同上;快照 NumberOfOrders 已按 PDF 补齐 |
| `bist/bist_itch_v2112.pdsl` | Borsa Istanbul BISTech ITCH 2112 | 17 | 🧪 | 写入时逐字段偏移自校验;MoldUDP64 传输帧不建模 |
| `nasdaq/ouch_v5.0.pdsl` | NASDAQ OUCH 5.0 | 27 | 🧪 | 大端;Inbound/Outbound 双分发器;可选 appendage 未建模,**建议逐字段复核** |
| `nasdaq/rashport_v1.1.pdsl` | NASDAQ RASHport 1.1 | 14 | 🧪 | ASCII 数值字段按 char[n] 建模,**建议逐字段复核** |
| `nyse/nyse_pillar_bin_v5.15.pdsl` | NYSE Pillar Binary Gateway v5.15(股票) | 37 | 🧪 | 位域/可选 AddOn/无计数尾重复段受语法限制;PDF 混排表格已交叉验证 |
| `nyse/nyse_pillar_options_bin_v3.24.pdsl` | NYSE Pillar Options Gateway v3.24 | 34 | 🧪 | 同上;BulkQuoteAck 命名计数重复组受限 |
| `lse/turquoise/tq301_native_v5.0.1.pdsl` | Turquoise TQ301(伦交所集团) | 20 | ✅ | 全部消息手工逐字段对照 + 长度验算;MiFID 位域按整数建模 |
| `its/its_native_v1.1.2.pdsl` | ITS 原生交易网关(接口 v22) | 23 | ✅ | 全部消息手工逐字段对照 + 长度验算;重复组 offset+count 前缀已精确表达 |
| `sse/step/sse_step_v0.57.pdsl` | 上交所 STEP V0.57 | 19 | 📝 | 等 STEP 语法(见 syntax-gaps.md #7) |
| `szse/step/szse_step_v1.29.pdsl` | 深交所 STEP 1.29 | 25 | 📝 | 同上;业务/回报管理消息清单已按规范建全 |
| `hke/hkex_cccg_v1.4.pdsl` | 港交所 CCCG v1.4 | 20 | ❌ | 使用未实现的 `Bitmap[n]` 语法(syntax-gaps.md #8) |
| `lse/lseg/lseg_native_bin_v17.0.2.pdsl` | 伦交所 MIT203 v17.0.2 | 26 | ❌ | 触发编译器 panic(未定义裸字段,syntax-gaps.md #1),文件亦标注未完成 |
| `risk/risk_v0.1.0.pdsl` | 风控协议 | 7 | ✅ | 内部协议 |
| `sample/sample.pdsl` | 教学示例 | 6 | ✅ | DSL 用法示例 |

> 各协议的官方规范 PDF 存放于独立仓库
> [fin-proto-reference](https://github.com/xinchentechnote/fin-proto-reference)。

## DSL 语法简介

```dsl
options {
    StringPrefixLenType = u16;   // 变长字符串长度前缀类型
    ArrayPrefixLenType  = u16;   // 重复组计数前缀类型
    LittleEndian = false;        // 字节序
    JavaPackage = "com.finproto.sse.bin.messages";
}

MetaData DataType {            // 命名类型字典
    int64 price `价格`,
    char[12] SecurityID `证券代码`,
}

root packet SseBinary {        // 线上根结构:消息头 + 分发 + 消息尾
    uint32 MsgType `消息类型`,
    @lengthOf(Body)
    uint32 MsgBodyLen `消息体长度`,
    match MsgType as Body {
        40 : Logon,
        58 : NewOrderSingle,
        [206, 207] : ExecRptSyncFamily,
    },
    @calculatedFrom("SSE_BIN")
    uint32 Checksum `校验和`,
}

packet Logon {
    char[32] SenderCompID `发送方代码`,
    char[32] TargetCompID `接收方代码`,
    uint16 HeartBtInt `心跳间隔（秒）`,
}

packet ExecRptSync {
    repeat SubExecRptSync {    // 重复组(计数前缀 = ArrayPrefixLenType)
        char[8] Pbu,
        uint32 SetID,
    },
}
```

完整语法说明见 [docs.md](docs.md);当前语法能力边界与待支持清单见
[syntax-gaps.md](syntax-gaps.md)。

## 快速开始

```bash
git clone https://github.com/xinchentechnote/fin-proto.git
cd fin-proto
make compile     # 需本地 fin-protoc(默认路径 ~/workspace/fin-protoc/bin/)
```

编译产物为各目录下的 Lua Wireshark 解码器;其他语言目标请使用
`fin-protoc -g/-j/-r/-p/-c` 输出参数。

## 相关仓库

- [`fin-proto-vscode`](https://github.com/xinchentechnote/fin-proto-vscode) —— VS Code 插件
  (语法高亮、补全、格式化、校验)
- [`fin-protoc`](https://github.com/xinchentechnote/fin-protoc) —— 基于 ANTLR 的编译器
  (Visitor 转换、格式化、多语言代码生成)
- [`fin-proto-rs`](https://github.com/xinchentechnote/fin-proto-rs) —— Rust 高性能编解码
- [`fin-proto-go`](https://github.com/xinchentechnote/fin-proto-go) —— Go 原生实现
- [`fin-proto-cpp`](https://github.com/xinchentechnote/fin-proto-cpp) —— C++ 实现
- [`fin-proto-java`](https://github.com/xinchentechnote/fin-proto-java) —— Java(Netty ByteBuf)
- [`fin-proto-py`](https://github.com/xinchentechnote/fin-proto-py) —— Python 实现
- [`fin-proto-reference`](https://github.com/xinchentechnote/fin-proto-reference) —— 各交易所
  官方规范 PDF

## 贡献

新增协议时:

1. 将官方规范 PDF 放入 fin-proto-reference 仓库;
2. 参照本 README「pdsl 清单」中的约定创建 `<交易所>/<协议>_v<版本>.pdsl`,
   文件头注明依据的 PDF 文件名与建模取舍;
3. 用 `make compile` 验证,并按 `syntax-gaps.md` 记录无法表达的部分;
4. 更新本清单的支持程度标记(中英两份 README 同步)。

---

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xinchentechnote/fin-proto)
