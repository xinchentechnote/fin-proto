--[[ 
   sample.lua © 2025 xinchen@af83f787e8911dea9b3bf677746ebac9

   A simple Wireshark Lua dissector for a custom protocol whose payload is:
     [ uint16 msgType ][ uint16 bodyLen ][ bytes[bodyLen] containing a JSON string ]

   To use:
   1. Save this file as “sample.lua” (or any name ending in .lua).
   2. Place it into your Wireshark plugins directory (e.g., on Windows: 
      C:\Program Files\Wireshark\plugins\<version>\ or under ~/.config/wireshark/plugins/ for Linux/Mac).
   3. Restart Wireshark.
   4. If your protocol runs over TCP on port 12345, it will now decode automatically.
      (Adjust the port number in the last lines below to match your actual port.)
--]]

-- 1. Define the protocol
local sample = Proto("sample", "My JSON‐Over‐Binary Protocol")

-- 2. Define the fields we want to extract:
--    - msgType:   uint16
--    - bodyLen:   uint16
--    - jsonStr:   the JSON text (bytes interpreted as string)
local f_msgType = ProtoField.uint16("sample.msgType", "Message Type", base.DEC)
local f_bodyLen = ProtoField.uint16("sample.bodyLen", "Body Length", base.DEC)
local f_jsonStr = ProtoField.string("sample.json", "JSON Payload", base.ASCII)

sample.fields = { f_msgType, f_bodyLen, f_jsonStr }

-- 3. The dissector function
function sample.dissector(buffer, pinfo, tree)
    -- buffer:            the entire packet’s raw bytes
    -- pinfo:             packet metadata (e.g. columns, protocol)
    -- tree:              the protocol tree to which we add our parsed fields

    -- First, ensure we have at least 4 bytes for msgType + bodyLen
    if buffer:len() < 4 then
        return 0
    end

    -- Tell Wireshark which protocol column to display
    pinfo.cols.protocol = sample.name

    -- Add a subtree “My JSON‐Over‐Binary Protocol”
    local subtree = tree:add(sample, buffer(), "My JSON‐Over‐Binary Protocol Data")

    local offset = 0

    -- 3.1 Parse msgType (2 bytes)
    local msgType_field = buffer(offset, 2)
    local msgType_val = msgType_field:uint()
    subtree:add(f_msgType, msgType_field)
    offset = offset + 2

    -- 3.2 Parse bodyLen (2 bytes)
    local bodyLen_field = buffer(offset, 2)
    local bodyLen_val = bodyLen_field:uint()
    subtree:add(f_bodyLen, bodyLen_field)
    offset = offset + 2

    -- 3.3 Check if full JSON payload is available
    if buffer:len() < offset + bodyLen_val then
        -- If not enough bytes, mark it as malformed/truncated
        subtree:add_expert_info(PI_MALFORMED, PI_ERROR, "Packet too short for advertised bodyLen")
        return
    end

    -- 3.4 Extract the JSON string bytes, interpret as ASCII/UTF-8
    local json_field = buffer(offset, bodyLen_val)
    -- We use :string() so that Wireshark will display it as text
    subtree:add(f_jsonStr, json_field)
    offset = offset + bodyLen_val

    -- (Optional) If you want to pretty-print or validate JSON,
    -- you could attempt to parse it here or use a heuristic.
    -- But for most purposes, displaying the raw string is enough.
end

-- 4. Register the dissector on a specific TCP port (e.g. 12345).
--    Change “12345” to whatever port your protocol actually uses, or
--    alternatively hook into a heuristic/UDP/etc. as desired.
local tcp_port = DissectorTable.get("tcp.port")
tcp_port:add(12345, sample)

-- If your protocol is over UDP, swap the last two lines with:
-- local udp_port = DissectorTable.get("udp.port")
-- udp_port:add(12345, sample)
