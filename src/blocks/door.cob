*> --- RegisterBlock-Door ---
IDENTIFICATION DIVISION.
PROGRAM-ID. RegisterBlock-Door.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 BLOCK-REGISTRY           BINARY-LONG.
    01 DESTROY-PTR              PROGRAM-POINTER.
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

    SET DESTROY-PTR TO ENTRY "Callback-Destroy"
    SET INTERACT-PTR TO ENTRY "Callback-Interact"
    SET FACE-PTR TO ENTRY "Callback-Face"

    *> Loop over all blocks and register the callback for each matching block type
    CALL "Registries-EntryCount" USING BLOCK-REGISTRY BLOCK-COUNT
    PERFORM VARYING BLOCK-ID FROM 0 BY 1 UNTIL BLOCK-ID >= BLOCK-COUNT
        CALL "Blocks-GetType" USING BLOCK-ID BLOCK-TYPE
        *> TODO check for door block type (e.g., iron doors cannot be opened by clicking)
        IF BLOCK-TYPE = "minecraft:door"
            CALL "Blocks-GetStateIds" USING BLOCK-ID BLOCK-MINIMUM-STATE-ID BLOCK-MAXIMUM-STATE-ID
            PERFORM VARYING STATE-ID FROM BLOCK-MINIMUM-STATE-ID BY 1 UNTIL STATE-ID > BLOCK-MAXIMUM-STATE-ID
                CALL "SetCallback-BlockDestroy" USING STATE-ID DESTROY-PTR
                CALL "SetCallback-BlockInteract" USING STATE-ID INTERACT-PTR
                CALL "SetCallback-BlockFace" USING STATE-ID FACE-PTR
            END-PERFORM
            *> TODO set metadata
        END-IF
    END-PERFORM

    GOBACK.

    *> --- Callback-Destroy ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Destroy.

    DATA DIVISION.
    WORKING-STORAGE SECTION.
        COPY DD-PLAYERS.
        01 AIR-BLOCK-STATE          BINARY-LONG             VALUE 0.
        01 BLOCK-STATE              BINARY-LONG.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==CLICKED==.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==OTHER-HALF==.
        01 HALF-VALUE-CLICKED       PIC X(16).
        01 HALF-VALUE-OTHER         PIC X(16).
        01 OPEN-VALUE               PIC X(16).
        01 BLOCK-POSITION.
            02 BLOCK-X              BINARY-LONG.
            02 BLOCK-Y              BINARY-LONG.
            02 BLOCK-Z              BINARY-LONG.
        01 DROPPED-ITEM-SLOT.
            COPY DD-INVENTORY-SLOT REPLACING LEADING ==PREFIX== BY ==DROPPED-ITEM==.
    LINKAGE SECTION.
        COPY DD-CALLBACK-BLOCK-DESTROY.

    PROCEDURE DIVISION USING LK-PLAYER LK-POSITION LK-FACE.
        *> Obtain the clicked block state description
        CALL "World-GetBlock" USING LK-POSITION BLOCK-STATE
        CALL "Blocks-ToDescription" USING BLOCK-STATE CLICKED-DESCRIPTION

        *> Set the clicked block to air
        CALL "World-SetBlock" USING PLAYER-CLIENT(LK-PLAYER) LK-POSITION AIR-BLOCK-STATE

        *> Drop the item
        IF PLAYER-GAMEMODE(LK-PLAYER) = 0 OR 2
            CALL "Registries-Lookup" USING "minecraft:item" CLICKED-NAME DROPPED-ITEM-SLOT-ID
            IF DROPPED-ITEM-SLOT-ID >= 0
                MOVE 1 TO DROPPED-ITEM-SLOT-COUNT
                *> TODO data components
                MOVE 2 TO DROPPED-ITEM-SLOT-NBT-LENGTH
                MOVE X"0000" TO DROPPED-ITEM-SLOT-NBT-DATA(1:2)

                CALL "World-DropItem-FromBlock" USING DROPPED-ITEM-SLOT LK-POSITION
            END-IF
        END-IF

        *> Find the other half
        CALL "Blocks-Description-GetValue" USING CLICKED-DESCRIPTION "half" HALF-VALUE-CLICKED
        MOVE LK-POSITION TO BLOCK-POSITION
        IF HALF-VALUE-CLICKED = "upper"
            SUBTRACT 1 FROM BLOCK-Y
        ELSE
            ADD 1 TO BLOCK-Y
        END-IF
        CALL "World-GetBlock" USING BLOCK-POSITION BLOCK-STATE
        CALL "Blocks-ToDescription" USING BLOCK-STATE OTHER-HALF-DESCRIPTION

        *> Check if the block matches (normally there shouldn't be single-block doors, but just in case)
        IF OTHER-HALF-NAME NOT = CLICKED-NAME
            GOBACK
        END-IF
        CALL "Blocks-Description-GetValue" USING OTHER-HALF-DESCRIPTION "half" HALF-VALUE-OTHER
        IF HALF-VALUE-CLICKED = HALF-VALUE-OTHER
            GOBACK
        END-IF

        *> Set the other half to air
        *> Note: We don't pass the player client here because they should receive the particle and sound effects, too.
        *>       For the clicked block, the client has already predicted the removal and played the effects.
        CALL "World-SetBlock" USING OMITTED BLOCK-POSITION AIR-BLOCK-STATE

        GOBACK.

    END PROGRAM Callback-Destroy.

    *> --- Callback-Interact ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Interact.

    DATA DIVISION.
    WORKING-STORAGE SECTION.
        01 BLOCK-STATE              BINARY-LONG.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==CLICKED==.
        COPY DD-BLOCK-STATE REPLACING LEADING ==PREFIX== BY ==OTHER-HALF==.
        01 HALF-VALUE-CLICKED       PIC X(16).
        01 HALF-VALUE-OTHER         PIC X(16).
        01 OPEN-VALUE               PIC X(16).
        01 BLOCK-POSITION.
            02 BLOCK-X              BINARY-LONG.
            02 BLOCK-Y              BINARY-LONG.
            02 BLOCK-Z              BINARY-LONG.
        COPY DD-PLAYERS.
    LINKAGE SECTION.
        COPY DD-CALLBACK-BLOCK-INTERACT.

    PROCEDURE DIVISION USING LK-PLAYER LK-ITEM-NAME LK-POSITION LK-FACE LK-CURSOR.
        *> Obtain the current block state description
        CALL "World-GetBlock" USING LK-POSITION BLOCK-STATE
        CALL "Blocks-ToDescription" USING BLOCK-STATE CLICKED-DESCRIPTION

        *> Toggle the "open" property for the clicked half
        CALL "Blocks-Description-GetValue" USING CLICKED-DESCRIPTION "open" OPEN-VALUE
        IF OPEN-VALUE = "true"
            MOVE "false" TO OPEN-VALUE
        ELSE
            MOVE "true" TO OPEN-VALUE
        END-IF
        CALL "Blocks-Description-SetValue" USING CLICKED-DESCRIPTION "open" OPEN-VALUE
        CALL "Blocks-FromDescription" USING CLICKED-DESCRIPTION BLOCK-STATE
        CALL "World-SetBlock" USING PLAYER-CLIENT(LK-PLAYER) LK-POSITION BLOCK-STATE

        *> Find the other half
        CALL "Blocks-Description-GetValue" USING CLICKED-DESCRIPTION "half" HALF-VALUE-CLICKED
        MOVE LK-POSITION TO BLOCK-POSITION
        IF HALF-VALUE-CLICKED = "upper"
            SUBTRACT 1 FROM BLOCK-Y
        ELSE
            ADD 1 TO BLOCK-Y
        END-IF
        CALL "World-GetBlock" USING BLOCK-POSITION BLOCK-STATE
        CALL "Blocks-ToDescription" USING BLOCK-STATE OTHER-HALF-DESCRIPTION

        *> Check if the block matches (normally there shouldn't be single-block doors, but just in case)
        IF OTHER-HALF-NAME NOT = CLICKED-NAME
            GOBACK
        END-IF
        CALL "Blocks-Description-GetValue" USING OTHER-HALF-DESCRIPTION "half" HALF-VALUE-OTHER
        IF HALF-VALUE-CLICKED = HALF-VALUE-OTHER
            GOBACK
        END-IF

        *> Toggle the "open" property for the other half
        CALL "Blocks-Description-SetValue" USING OTHER-HALF-DESCRIPTION "open" OPEN-VALUE
        CALL "Blocks-FromDescription" USING OTHER-HALF-DESCRIPTION BLOCK-STATE
        CALL "World-SetBlock" USING PLAYER-CLIENT(LK-PLAYER) BLOCK-POSITION BLOCK-STATE

        GOBACK.

    END PROGRAM Callback-Interact.

    *> --- Callback-Face ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Face.

    DATA DIVISION.
    LINKAGE SECTION.
        COPY DD-CALLBACK-BLOCK-FACE.

    PROCEDURE DIVISION USING LK-BLOCK-STATE LK-FACE LK-RESULT.
        *> Doors have no solid faces.
        MOVE 0 TO LK-RESULT
        GOBACK.

    END PROGRAM Callback-Face.

END PROGRAM RegisterBlock-Door.
