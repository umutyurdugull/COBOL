       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANSYS.
       AUTHOR. UMUT-YURDUGUL.



       ENVIRONMENT DIVISION.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNTS-FILE
                  ASSIGN TO "ACCOUNTS.DAT"
                  ORGANIZATION IS LINE SEQUENTIAL.


       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNTS-FILE.
       01  ACCOUNT-RECORD.
           05 AR-ACC-NO      PIC 9(6).
           05 AR-ACC-NAME    PIC X(20).
           05 AR-ACC-BALANCE PIC 9(9)V99.


       WORKING-STORAGE SECTION.
       01  WS-MENU-CHOICE       PIC 9.
       01  WS-EXIT-FLAG         PIC X.
       01  WS-SEARCH-ACC-NO     PIC 9(6).
       01  WS-FOUND-INDEX       PIC 9(4).
       01  WS-ACCOUNT-FOUND     PIC X.
      *    Y N
       01  WS-AMOUNT            PIC 9(7)V99.
       01  WS-WITHDRAW-COUNT    PIC 9(5).
       01 WS-NEW-NAME PIC X(20).
       01  WS-DEPOSIT-TOTAL     PIC 9(9)V99.
       01  WS-WITHDRAW-TOTAL    PIC 9(9)V99.
       01  WS-ACCOUNT-COUNT     PIC 9(4) VALUE ZERO.




       01  ACCOUNT-TABLE.
           05 ACCOUNT-ENTRY OCCURS 100 TIMES
              INDEXED BY ACC-IDX.
              10 ACC-NO         PIC 9(6).
              10 ACC-NAME       PIC X(20).
              10 ACC-BALANCE    PIC 9(9)V99.





       PROCEDURE DIVISION.
           PERFORM MAIN-PROGRAM.






       MAIN-PROGRAM.

           PERFORM LOAD-ACCOUNTS

           MOVE "N" TO WS-EXIT-FLAG

           PERFORM UNTIL WS-EXIT-FLAG = "Y"

               PERFORM DISPLAY-MENU

               ACCEPT WS-MENU-CHOICE
               DISPLAY " SELECTED  OPTION: " WS-MENU-CHOICE 
               EVALUATE WS-MENU-CHOICE

                   WHEN 1
                       PERFORM SEARCH-ACCOUNT

                   WHEN 2
                       PERFORM ADD-ACCOUNT

                   WHEN 3
                       PERFORM DEPOSIT-MONEY

                   WHEN 4
                       PERFORM SAVE-ACCOUNTS
                       MOVE "Y" TO WS-EXIT-FLAG

               END-EVALUATE

           END-PERFORM.


       LOAD-ACCOUNTS.
              OPEN INPUT ACCOUNTS-FILE
              MOVE 0 TO WS-ACCOUNT-COUNT
              PERFORM UNTIL WS-ACCOUNT-COUNT = 100

                  READ ACCOUNTS-FILE
                        AT END
                           EXIT PERFORM
                  END-READ

                  ADD 1 TO WS-ACCOUNT-COUNT
                  MOVE AR-ACC-NO       TO ACC-NO(WS-ACCOUNT-COUNT)
                  MOVE AR-ACC-NAME     TO ACC-NAME(WS-ACCOUNT-COUNT)
                  MOVE AR-ACC-BALANCE  TO ACC-BALANCE(WS-ACCOUNT-COUNT)
              END-PERFORM

              CLOSE ACCOUNTS-FILE.
              DISPLAY " LOADED  ACCOUNTS FROM FILE ".


       DISPLAY-MENU.




       SEARCH-ACCOUNT.


       UPDATE-DEPOSIT-STATS.

      *

       ADD-ACCOUNT.
           ACCEPT WS-SEARCH-ACC-NO
           ACCEPT WS-NEW-NAME
           ACCEPT WS-AMOUNT
           DISPLAY "--- LOG: ATTEMPTING TO ADD: NO=" WS-SEARCH-ACC-NO 
             ", NAME=" WS-NEW-NAME ", BAL=" WS-AMOUNT " ---"

           ADD 1 TO WS-ACCOUNT-COUNT
           IF WS-ACCOUNT-COUNT > 100

               DISPLAY "ACCOUNT TABLE IS FULL"

               SUBTRACT 1 FROM WS-ACCOUNT-COUNT

               EXIT PARAGRAPH

           END-IF



           MOVE WS-SEARCH-ACC-NO TO ACC-NO(WS-ACCOUNT-COUNT)

           MOVE WS-NEW-NAME      TO ACC-NAME(WS-ACCOUNT-COUNT)

           MOVE WS-AMOUNT        TO ACC-BALANCE(WS-ACCOUNT-COUNT)
           MOVE WS-AMOUNT        TO ACC-BALANCE(WS-ACCOUNT-COUNT)

           DISPLAY "ACCOUNT ADDED"
           DISPLAY " TOTAL ACCOUNTS IN MEMORY IS NOW: " WS-ACCOUNT-COUNT 
           EXIT PARAGRAPH.

       FIND-ACCOUNT.
           
           DISPLAY "SEARCHING ARRAY FOR ACCOUNT NO: " WS-SEARCH-ACC-NO 

           MOVE "N" TO WS-ACCOUNT-FOUND.
           MOVE 0 TO WS-FOUND-INDEX.
           PERFORM VARYING ACC-IDX FROM 1 BY 1
                   UNTIL ACC-IDX > WS-ACCOUNT-COUNT
               IF ACC-NO(ACC-IDX) = WS-SEARCH-ACC-NO
                   MOVE "Y" TO WS-ACCOUNT-FOUND
                   MOVE ACC-IDX TO WS-FOUND-INDEX
           EXIT PERFORM
           END-IF

           END-PERFORM.

       DEPOSIT-MONEY.
                 ACCEPT WS-SEARCH-ACC-NO
                 PERFORM FIND-ACCOUNT.

                 IF WS-ACCOUNT-FOUND = "Y"
                    ACCEPT WS-AMOUNT
                    ADD WS-AMOUNT TO ACC-BALANCE(WS-FOUND-INDEX)
                    PERFORM UPDATE-DEPOSIT-STATS
                    DISPLAY "DEPOSIT SUCCES"
                    DISPLAY ACC-BALANCE(WS-FOUND-INDEX)
                 ELSE
                    DISPLAY "ACCOUNT NOT FOUND"
                 END-IF.

       SAVE-ACCOUNTS.
           OPEN OUTPUT ACCOUNTS-FILE
           PERFORM VARYING ACC-IDX FROM 1 BY 1
                   UNTIL ACC-IDX > WS-ACCOUNT-COUNT

               MOVE ACC-NO(ACC-IDX)      TO AR-ACC-NO
               MOVE ACC-NAME(ACC-IDX)    TO AR-ACC-NAME
               MOVE ACC-BALANCE(ACC-IDX) TO AR-ACC-BALANCE

               WRITE ACCOUNT-RECORD
           END-PERFORM
           CLOSE ACCOUNTS-FILE.
           DISPLAY "--- LOG: SUCCESSFULLY WRITTEN ".
