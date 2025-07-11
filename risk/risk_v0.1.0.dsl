//简化版风控内部协议

options {
    StringPreFixLenType = u32;
    RepeatPreFixSizeType = u32;
    LittleEndian = false;
    JavaPackage = "com.finproto.risk.bin.messages";
    GoPackage = "risk_bin"
    GoMoudle = "github.com/xinchentechnote/fin-proto-go/risk-bin/messages"
}

root packet RcBinary {
    uint32 MsgType `消息类型`,
    uint32 Version `协议版本`,
    uint32 MsgBodyLen = lengthof(Body) `消息体长度`,
    match MsgType as Body {
        100101 : NewOrder,
        200102 : OrderConfirm,
        200115 : ExecutionReport,
        190007 : OrderCancel,
        290008 : CancelReject,
    },
}
// 委托消息

packet NewOrder {
    string ClOrdID `会员订单编号`,
    string SecurityID `证券代码`,
    char[1] Side `买卖方向 1=买 2=卖`,
    uint64 Price `申报价格`,
    uint64 OrderQty `申报数量`,
    char[1] OrdType `订单类型 1=市价 2=限价`,
    string Account `证券账户`,
}
// 委托确认

packet OrderConfirm {
    string ClOrdID `会员订单编号`,
    char[1] ExecType `执行类型 0=接受 8=拒绝`,
    uint32 OrdRejReason `拒绝原因码（仅拒绝时有效）`,
    string OrdCnfmID `交易所订单编号（仅接受时有效）`,
}
// 成交回报

packet ExecutionReport {
    string ClOrdID `会员订单编号`,
    string OrdCnfmID `交易所订单编号`,
    uint64 LastPx `成交价格`,
    uint64 LastQty `成交数量`,
    char[1] OrdStatus `订单状态 1=部分成交 2=全部成交`,
}
// 撤单请求

packet OrderCancel {
    string ClOrdID `会员订单编号`,
    string OrigClOrdID `原订单编号`,
    string SecurityID `证券代码`,
}
// 撤单拒绝

packet CancelReject {
    string ClOrdID `会员订单编号`,
    string OrigClOrdID `原订单编号`,
    uint32 CxlRejReason `撤单拒绝码`,
}