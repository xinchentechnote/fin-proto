# fin-proto DSL 语法缺口清单

依据 reference 仓库 8 份新增协议 pdsl 的编写实践(nasdaq/ouch、nasdaq/rashport、bist/bist_itch、
nyse/nyse_pillar、nyse/nyse_pillar_options、lse/turquoise/tq301、its/its_native、szse/step)整理,
并涵盖既有文件暴露的问题(hke/hkex_cccg、lse/lseg、sse/step)。

标注说明:
- **阻塞**:已导致对应协议的某段报文无法建模或模型不完整;
- **改进**:当前可绕行,但存在更优表达;
- 每条给出:需求描述 / 来源(协议与消息)/ 建议语法 / 现行绕行方式。

---

## 一、编译器缺陷(建议优先修复)

### 1. 未定义裸字段名导致 panic(阻塞,属 bug)
- **现象**:packet 内出现未在任何 MetaData 定义的裸字段名时,编译器空指针崩溃,
  不给出可定位的语法错误。现有 `lse/lseg/lseg_native_bin_v17.0.2.pdsl` 即触发:
  `panic: nil pointer dereference at internal/parser/packet_dsl_parser.go:71 metaDataDeclarationToMetaData`。
- **建议**:解析期校验标识符引用,未定义时报 `unknown field/type reference` 语法错误。
- **顺带**:修复后需复核 lseg 文件本身是否确有拼写遗漏。

---

## 二、阻塞本批协议的表达缺口

### 2. 位域类型 bitfield
- **需求**:多个协议用打包位域字段,需要按位声明含义并可选地按位取值。
- **来源**:
  - NYSE Pillar(Equities/Options):`BitfieldOrderInstructions`(u64/u128)、
    `BitfieldFlowIndicator`(u8);
  - Turquoise TQ301:`MiFIDFlags`、`PartyRoleQualifiers`(每 2 位一个枚举)、
    `WaiverFlags`/`WaiverFlags2`;
  - BISTech ITCH:Add Order 的 Order Attributes 位图(如 0x2000);
  - ITS:AddReport/CancelReport 的 `flags i64`(0x1=eUserLastRec … 0x800000=eRFQ)。
- **建议语法**:
  ```
  bitfield<uint16> OrderInstructions {
      0  = DepthBook,
      12 = IntermarketSweep,
      ...
  }
  ```
- **现行绕行**:按 `uint8/16/32/64` 建模,位含义写入反引号描述;取值不可校验、展示不友好。

### 3. 条件可选字段 / 可选附加段(optional)
- **需求**:字段或子结构仅在特定条件下出现(由位指示、方向、另一字段取值决定)。
- **来源**:
  - NYSE Pillar:NewOrder 尾部按 `BitfieldOrderInstructions` 位追加
    `OptionalOrderAddOn`(0x0241)/`OptionalRoutingStrategyAddOn`(0x0261),
    AddOn 自带 4 字节 MsgHeader;
  - NASDAQ OUCH 5.0:多数 Inbound 消息尾部可选 Optional Appendage
    (由 `AppendageLength u16` 引导,内容为 TagValue 元素链)。
- **建议语法**:`optional <packet引用> if <表达式>` 或 presence 引用
  (`optional OptionalOrderAddOn when Instructions.AddOnPresent`)。
- **现行绕行**:整段不建模(Pillar AddOn 作为独立消息由根表分发,消息体尾部附加段缺位);
  OUCH 保留 AppendageLength 字段、内容缺位。

### 4. "重复到消息尾"的重复组(repeat until end)
- **需求**:重复组没有计数字段,条目数 = (消息总长 − 定长部分) / 条目长。
- **来源**:
  - NASDAQ OUCH:尾部 TagValue 元素链(Length u8 + OptionTag u8 + 变长 value);
  - NYSE Pillar Options:`0x0357 NewComplexSeriesRequest` 尾部腿组(7 字节/腿,最多 12 腿)、
    `0x0358 ComplexSeriesRequestAcknowledgement` 尾部腿组;
  - NYSE Pillar Equities:`0x0231 MPVLevelReferenceData` 尾部 `MPVLevelDefinition`(50 字节/条)。
- **建议语法**:
  ```
  repeat until end {
      uint8  Length,
      uint8  OptionTag,
      char[] OptionValue,
  }
  ```
- **现行绕行**:仅建模定长部分,重复段在文件头注释与语法缺口中说明。

### 5. 以命名字段作为重复组计数(repeat count=<field>)
- **需求**:重复组个数由一个已建模的命名字段给出,条目前**没有**独立的计数前缀。
- **来源**:
  - NYSE Pillar Options:`0x0294/0x0308 Bulk Quote Acknowledgment`,
    `RepeatingGroups u8@44` 之后直接跟 QuoteAck 条目(21/29 字节,无前缀);
  - ITS(Native Gateway):重复组件前是 `offset u16 + count u16` 两个字段,
    count 之外还多一个 offset 字段(当前以普通 u16 字段 + repeat 自带前缀近似)。
- **建议语法**:`repeat QuoteAck count=RepeatingGroups { ... }`
  (当 count 字段宽度与 ArrayPrefixLenType 不一致时以字段类型为准)。
- **现行绕行**:Options 仅建模计数前的定长部分(1 组示意未展开);
  ITS 恰好可用 ArrayPrefixLenType=u16 兼容 count,offset 用普通字段,特例成立。

### 6. @lengthOf 语义扩展(长度=总长 / 带偏移)
- **需求**:`@lengthOf` 目前只能表达"值 = match 命中的包体长度"。实际协议还有:
  - 长度字段值 = 包体长度 + 常数(含自身头部);
  - 长度字段值 = 整条消息总长(含 Length 字段与 MsgType)。
- **来源**:
  - NYSE Pillar(两份):`MsgHeader = u16 type + u16 length`,length = 含头总长(体长+4);
  - Turquoise TQ301:`MessageLength u16` = 从 MsgType 起的长度(体长 +1);
  - 对比:ITS 与 LSEG MIT203 的 length 恰为体长,现有语义可用。
- **建议语法**:`@lengthOf(Body, delta=4)` / `@lengthOf(Total)`。
- **现行绕行**:长度字段按普通整数建模(不挂 @lengthOf),生成的解码器不据此截断,
  编码侧长度需调用方自行填写,存在出错面。

### 7. STEP/FIX 模式(message / @tag / ProtocolType)
- **需求**:FIX over STEP 类协议(字段为 `tag=value<SOH>`)与二进制打包完全不同,
  需要:
  - 顶层 `message` 结构(区别于二进制 `packet`);
  - MetaData 内使用 `@tag(N)` 标注 FIX tag(grammar 的 `tagAttribute` 目前只允许
    出现在 packet 字段上,且无 message 顶层结构);
  - 字段引用可携带 tag 字面量,如 `ApplID(1180)`;
  - `options { ProtocolType = "step"; }` 驱动代码生成器走 FIX 编解码路径。
- **来源**:`sse/step/sse_step_v0.57.pdsl` 与 `szse/step/szse_step_v1.29.pdsl`
  两份草稿均按该未来语法编写,当前编译器无法解析(草稿状态)。
- **建议**:按上述 sse/szse 两份草稿所用语法定稿 grammar,先支持
  message + @tag + 裸字段名引用,再支持 `Name(tag)` 内联写法。

### 8. 位图存在性映射类型(bitmap)
- **需求**:消息体前部的 presence bitmap,每个 bit 指示后续某字段/重复块是否存在,
  需要与"条件可选字段"(见第 3 条)联动。
- **来源**:HKEx CCCG v1.4 —— `BodyFieldsPresenceMap`;现有
  `hke/hkex_cccg_v1.4.pdsl` 使用的 `Bitmap` / `Bitmap[n]` 类型与 `Bitmap[…]` 语法
  均不在 grammar 中,该文件当前无法编译。
- **建议语法**:`bitmap[n]` 定长位图类型 + `optional Field when PresenceMap.Bit0`。

---

## 三、非阻塞的通用改进

### 9. 非 2^n 整数宽度与带刻度十进制
- **来源**:NASDAQ 系 6 字节纳秒时间戳(ITCH 家族常用);ITS `decn`(8 字节整数 +
  1 字节小数位,共 9 字节)。
- **现行绕行**:6 字节暂未涉及;decn 拆为 `u64 + u8` 内联对象。
- **建议**:`int48`/`bytes[n]` + 数值解释属性,或 `decimal(width=9, scaleAt=end)`。

### 10. 逐字段字节序覆盖
- **来源**:混合端序协议(本批 8 份均为单一端序,未阻塞;NYSE/NASDAQ 混布场景常见)。
- **现行绕行**:全局 `LittleEndian` 开关。
- **建议**:字段属性 `@bigEndian` / `@littleEndian`。

### 11. ASCII 数值字段的展示转换
- **来源**:NASDAQ RASHport 全部数值字段为 ASCII 数字串(右对齐左补 0)。
- **现行绕行**:按 `char[n]` 建模——线格式正确,解码展示为字符串而非数值。
- **建议**:`ascii-numeric` 属性或显示类型,供 Wireshark/Lua 生成器做进制转换展示。

### 12. 传输层帧建模
- **需求**:一条物理连接/UDP 包内承载多个消息(SoupBinTCP、MoldUDP64、Pillar Stream),
  外层有 长度前缀/消息条数/序号 等帧结构。
- **来源**:NASDAQ OUCH/RASH(SoupBinTCP)、BISTech ITCH(MoldUDP64)、NYSE Pillar(流协议)。
- **现状**:消息层已全部建模;帧封装不属于单消息模型,未表达。
- **建议**:`framed by <packet>` 声明或独立的 transport 定义块,供生成器做粘包/拆包。

### 13. 枚举与值集展示(增强)
- **需求**:几乎所有协议的取值语义(如 Side: 1=买 2=卖)目前写入字段描述。
- **建议**:`enum` 声明 + 字段引用,生成器可输出值映射表(可选改进,不阻塞)。

---

## 附:缺口与文件对照

| 缺口 | 受影响文件 | 受影响消息(示例) |
|---|---|---|
| 1 panic | lse/lseg/lseg_native_bin_v17.0.2.pdsl | 全文件 |
| 2 bitfield | nyse/nyse_pillar_bin_v5.15.pdsl、nyse/nyse_pillar_options_bin_v3.24.pdsl、lse/turquoise/tq301_native_v5.0.1.pdsl、bist/bist_itch_v2112.pdsl、its/its_native_v1.1.2.pdsl | NewOrderSingle.BitfieldOrderInstructions、NewOrder.MiFIDFlags、AddOrder.OrderAttributes、*.flags |
| 3 optional | nyse 两份、nasdaq/ouch_v5.0.pdsl | NewOrder 尾部 AddOn、OUCH 各 Inbound 尾部 appendage |
| 4 repeat until end | nasdaq/ouch_v5.0.pdsl、nyse/nyse_pillar_options_bin_v3.24.pdsl、nyse/nyse_pillar_bin_v5.15.pdsl | OUCH TagValue 链、0x0357/0x0358 腿组、0x0231 MPVLevelDefinition |
| 5 repeat count=field | nyse/nyse_pillar_options_bin_v3.24.pdsl | 0x0294/0x0308 Bulk Quote Ack |
| 6 @lengthOf delta | nyse 两份、lse/turquoise/tq301_native_v5.0.1.pdsl | MsgHeader.Length、TQ301 MessageLength |
| 7 STEP 模式 | sse/step/sse_step_v0.57.pdsl、szse/step/szse_step_v1.29.pdsl | 全文件 |
| 8 bitmap | hke/hkex_cccg_v1.4.pdsl | 全文件 |
| 9 宽度/十进制 | its/its_native_v1.1.2.pdsl(decn) | price 组件 |
| 11 ascii 数值 | nasdaq/rashport_v1.1.pdsl | 全部数量/价格字段 |
| 12 帧封装 | nasdaq 两份、bist/bist_itch_v2112.pdsl、nyse 两份 | 传输层 |
