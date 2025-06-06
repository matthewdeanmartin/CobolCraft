IDENTIFICATION DIVISION.
PROGRAM-ID. SendPacket-LoginSuccess.

DATA DIVISION.
WORKING-STORAGE SECTION.
    COPY DD-PACKET REPLACING IDENTIFIER BY "login/clientbound/minecraft:login_finished".
    *> buffer used to store the packet data
    01 PAYLOAD          PIC X(64000).
    01 PAYLOADPOS       BINARY-LONG UNSIGNED.
    01 PAYLOADLEN       BINARY-LONG UNSIGNED.
    01 INT32            BINARY-LONG.
LINKAGE SECTION.
    01 LK-CLIENT        BINARY-LONG UNSIGNED.
    01 LK-PLAYER-UUID   PIC X(16).
    01 LK-USERNAME      PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-CLIENT LK-PLAYER-UUID LK-USERNAME.
    COPY PROC-PACKET-INIT.

    MOVE 1 TO PAYLOADPOS

    *> player UUID
    MOVE LK-PLAYER-UUID(1:16) TO PAYLOAD(PAYLOADPOS:16)
    ADD 16 TO PAYLOADPOS

    *> username
    MOVE FUNCTION STORED-CHAR-LENGTH(LK-USERNAME) TO INT32
    CALL "Encode-String" USING LK-USERNAME INT32 PAYLOAD PAYLOADPOS

    *> properties count=0
    MOVE X"00" TO PAYLOAD(PAYLOADPOS:1)
    ADD 1 TO PAYLOADPOS

    *> properties (omitted)

    *> Send the packet
    COMPUTE PAYLOADLEN = PAYLOADPOS - 1
    CALL "SendPacket" USING LK-CLIENT PACKET-ID PAYLOAD PAYLOADLEN
    GOBACK.

END PROGRAM SendPacket-LoginSuccess.
