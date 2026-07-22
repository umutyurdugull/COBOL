       IDENTIFICATION DIVISION.
       PROGRAM-ID. square-root.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NUMBER PIC 9(32).
       01 WS-SQRT PIC 9(32).

       PROCEDURE DIVISION.
       SQUARE-ROOT.
           IF WS-NUMBER < 0 OR WS-NUMBER IS EQUAL TO 0
              GOBACK
           ELSE
           COMPUTE WS-SQRT = WS-NUMBER ** 0.5
           DISPLAY WS-SQRT
           END-IF.