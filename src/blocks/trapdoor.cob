*> --- RegisterBlock-Trapdoor ---
IDENTIFICATION DIVISION.
PROGRAM-ID. RegisterBlock-Trapdoor.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 BLOCK-REGISTRY           BINARY-LONG.
    01 INTERACT-PTR             PROGRAM-POINTER.
    01 FACE-PTR                 PROGRAM-POINTER.
    01 BLOCK-COUNT              BINARY-LONG UNSIGNED.
    01 BLOCK-ID                 BINARY-LONG UNSIGNED.
    01 BLOCK-TYPE               PIC X(64).
    01 BLOCK-MINIMUM-STATE-ID   BINARY-LONG.
    01 BLOCK-MAXIMUM-STATE-ID   BINARY-LONG.
    01 STATE-ID                 BINARY-LONG.

PROCEDURE DIVISION.
    CALL "Registries-LookupRegistry" USING "minecraft:block" BLOCK-REGISTRY

    SET INTERACT-PTR TO ENTRY "Callback-Interact"
    SET FACE-PTR TO ENTRY "Callback-Face"

    *> Loop over all blocks and register the callback for each matching block type
    CALL "Registries-EntryCount" USING BLOCK-REGISTRY BLOCK-COUNT
    PERFORM VARYING BLOCK-ID FROM 0 BY 1 UNTIL BLOCK-ID >= BLOCK-COUNT
        CALL "Blocks-GetType" USING BLOCK-ID BLOCK-TYPE
        *> TODO check for trapdoor block type (e.g., iron trapdoors cannot be opened by clicking)
        IF BLOCK-TYPE = "minecraft:trapdoor"
            CALL "Blocks-GetStateIds" USING BLOCK-ID BLOCK-MINIMUM-STATE-ID BLOCK-MAXIMUM-STATE-ID
            PERFORM VARYING STATE-ID FROM BLOCK-MINIMUM-STATE-ID BY 1 UNTIL STATE-ID > BLOCK-MAXIMUM-STATE-ID
                CALL "SetCallback-BlockInteract" USING STATE-ID INTERACT-PTR
                CALL "SetCallback-BlockFace" USING STATE-ID FACE-PTR
            END-PERFORM
            *> TODO set metadata
        END-IF
    END-PERFORM

    GOBACK.

    *> --- Callback-Interact ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Interact.

    DATA DIVISION.
    WORKING-STORAGE SECTION.
        COPY DD-PLAYERS.
        01 BLOCK-STATE              BINARY-LONG.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==CURRENT==.
        01 OPEN-VALUE               PIC X(16).
    LINKAGE SECTION.
        COPY DD-CALLBACK-BLOCK-INTERACT.

    PROCEDURE DIVISION USING LK-PLAYER LK-ITEM-NAME LK-POSITION LK-FACE LK-CURSOR.
        *> Obtain the current block state description
        CALL "World-GetBlock" USING LK-POSITION BLOCK-STATE
        CALL "Blocks-ToDescription" USING BLOCK-STATE CURRENT-DESCRIPTION

        *> Toggle the "open" property
        CALL "Blocks-Description-GetValue" USING CURRENT-DESCRIPTION "open" OPEN-VALUE
        IF OPEN-VALUE = "true"
            MOVE "false" TO OPEN-VALUE
        ELSE
            MOVE "true" TO OPEN-VALUE
        END-IF
        CALL "Blocks-Description-SetValue" USING CURRENT-DESCRIPTION "open" OPEN-VALUE

        *> Set the new block state
        CALL "Blocks-FromDescription" USING CURRENT-DESCRIPTION BLOCK-STATE
        CALL "World-SetBlock" USING PLAYER-CLIENT(LK-PLAYER) LK-POSITION BLOCK-STATE

        GOBACK.

    END PROGRAM Callback-Interact.

    *> --- Callback-Face ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Face.

    DATA DIVISION.
    WORKING-STORAGE SECTION.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==BLOCK==.
        01 PROPERTY-VALUE           PIC X(16).
    LINKAGE SECTION.
        COPY DD-CALLBACK-BLOCK-FACE.

    PROCEDURE DIVISION USING LK-BLOCK-STATE LK-FACE LK-RESULT.
        *> Contrary to doors, trapdoors have solid faces that depend on the orientation and open state.
        CALL "Blocks-ToDescription" USING LK-BLOCK-STATE BLOCK-DESCRIPTION

        *> Open trapdoors have no solid face
        CALL "Blocks-Description-GetValue" USING BLOCK-DESCRIPTION "open" PROPERTY-VALUE
        IF PROPERTY-VALUE = "true"
            MOVE 0 TO LK-RESULT
            GOBACK
        END-IF

        *> Closed trapdoors have a solid face depending on whether they are placed on the top or bottom of a block
        CALL "Blocks-Description-GetValue" USING BLOCK-DESCRIPTION "half" PROPERTY-VALUE
        EVALUATE PROPERTY-VALUE ALSO LK-FACE
            WHEN "top" ALSO "up"
                MOVE 1 TO LK-RESULT
            WHEN "bottom" ALSO "down"
                MOVE 1 TO LK-RESULT
            WHEN OTHER
                MOVE 0 TO LK-RESULT
        END-EVALUATE

        GOBACK.

    END PROGRAM Callback-Face.

END PROGRAM RegisterBlock-Trapdoor.
