IDENTIFICATION DIVISION.
PROGRAM-ID. RecvPacket-LoginAcknowledged.

DATA DIVISION.
WORKING-STORAGE SECTION.
    COPY DD-CLIENTS.
    COPY DD-CLIENT-STATES.
LINKAGE SECTION.
    01 LK-CLIENT                BINARY-LONG UNSIGNED.
    01 LK-BUFFER                PIC X ANY LENGTH.
    01 LK-OFFSET                BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-CLIENT LK-BUFFER LK-OFFSET.
    *> Must not happen before login start
    IF CLIENT-PLAYER(LK-CLIENT) = 0
        DISPLAY "[state=" CLIENT-STATE(LK-CLIENT) "] Client sent unexpected login acknowledge"
        CALL "Server-DisconnectClient" USING LK-CLIENT
        GOBACK
    END-IF
    MOVE CLIENT-STATE-CONFIGURATION TO CLIENT-STATE(LK-CLIENT)
    GOBACK.

END PROGRAM RecvPacket-LoginAcknowledged.
