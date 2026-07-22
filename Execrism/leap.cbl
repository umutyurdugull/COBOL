       IDENTIFICATION DIVISION.
       PROGRAM-ID. LEAP.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-YEAR     PIC 9(4).
       01  WS-X        PIC 9(4).
       01  WS-RESULT   PIC 9(1).
       PROCEDURE DIVISION.
       LEAP.
           COMPUTE WS-X = FUNCTION REM(WS-YEAR 100)
           IF WS-X IS EQUAL TO 0
      * 400              
              MOVE 0 TO WS-X
              COMPUTE WS-X = FUNCTION REM(WS-YEAR,400)
              IF WS-X IS EQUAL TO ZERO
                 MOVE 1 TO WS-RESULT
               ELSE
                 MOVE 0 TO WS-RESULT
              END-IF
           ELSE
              MOVE 0 TO WS-X
              COMPUTE WS-X = FUNCTION REM(WS-YEAR,4)
                 IF WS-X IS EQUAL TO ZERO
                    MOVE 1 TO WS-RESULT
                 ELSE 
                    MOVE 0 TO WS-RESULT
                 END-IF
           END-IF.

           CONTINUE.
       LEAP-EXIT.
           EXIT.
