IDENTIFICATION DIVISION.
PROGRAM-ID. SendPacket-SystemChat.

DATA DIVISION.
WORKING-STORAGE SECTION.
    COPY DD-PACKET REPLACING IDENTIFIER BY "play/clientbound/minecraft:system_chat".
    *> temporary data used during encoding
    01 UINT16           BINARY-SHORT UNSIGNED.
    *> buffer used to store the packet data
    01 PAYLOAD          PIC X(64000).
    01 PAYLOADPOS       BINARY-LONG UNSIGNED.
    01 PAYLOADLEN       BINARY-LONG UNSIGNED.
LINKAGE SECTION.
    01 LK-CLIENT        BINARY-LONG UNSIGNED.
    01 LK-MESSAGE       PIC X ANY LENGTH.
    01 LK-MESSAGE-LEN   BINARY-LONG UNSIGNED.
    01 LK-COLOR         PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-CLIENT LK-MESSAGE LK-MESSAGE-LEN LK-COLOR.
    COPY PROC-PACKET-INIT.

    MOVE 1 TO PAYLOADPOS

    *> NBT compound tag
    MOVE X"0A" TO PAYLOAD(PAYLOADPOS:1)
    ADD 1 TO PAYLOADPOS

    *> "text" key
    MOVE X"08" TO PAYLOAD(PAYLOADPOS:1)
    ADD 1 TO PAYLOADPOS
    MOVE 4 TO UINT16
    CALL "Encode-UnsignedShort" USING UINT16 PAYLOAD PAYLOADPOS
    MOVE "text" TO PAYLOAD(PAYLOADPOS:4)
    ADD 4 TO PAYLOADPOS

    *> text
    MOVE LK-MESSAGE-LEN TO UINT16
    CALL "Encode-UnsignedShort" USING UINT16 PAYLOAD PAYLOADPOS
    *> TODO: implement modified UTF-8: https://docs.oracle.com/javase/8/docs/api/java/io/DataInput.html#modified-utf-8
    MOVE LK-MESSAGE(1:LK-MESSAGE-LEN) TO PAYLOAD(PAYLOADPOS:LK-MESSAGE-LEN)
    ADD LK-MESSAGE-LEN TO PAYLOADPOS

    IF LK-COLOR NOT = SPACES
       *> "color" key
       MOVE X"08" TO PAYLOAD(PAYLOADPOS:1)
       ADD 1 TO PAYLOADPOS
       MOVE 5 TO UINT16
       CALL "Encode-UnsignedShort" USING UINT16 PAYLOAD PAYLOADPOS
       MOVE "color" TO PAYLOAD(PAYLOADPOS:5)
       ADD 5 TO PAYLOADPOS

       *> color
       MOVE FUNCTION STORED-CHAR-LENGTH(LK-COLOR) TO UINT16
       CALL "Encode-UnsignedShort" USING UINT16 PAYLOAD PAYLOADPOS
       MOVE LK-COLOR(1:UINT16) TO PAYLOAD(PAYLOADPOS:UINT16)
       ADD UINT16 TO PAYLOADPOS
    END-IF

    *> NBT end tag
    MOVE X"00" TO PAYLOAD(PAYLOADPOS:1)
    ADD 1 TO PAYLOADPOS

    *> "overlay" flag
    MOVE X"00" TO PAYLOAD(PAYLOADPOS:1)
    ADD 1 TO PAYLOADPOS

    *> Send the packet
    COMPUTE PAYLOADLEN = PAYLOADPOS - 1
    CALL "SendPacket" USING LK-CLIENT PACKET-ID PAYLOAD PAYLOADLEN
    GOBACK.

END PROGRAM SendPacket-SystemChat.
