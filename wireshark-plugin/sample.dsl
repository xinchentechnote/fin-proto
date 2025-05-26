//[ uint16 msgType ][ uint16 bodyLen ][ bytes[bodyLen] containing a JSON string ]
root packet Sample {
     uInt16 MsgType `消息类型`,
     string Body `消息体，长度前缀uInt16`,
}