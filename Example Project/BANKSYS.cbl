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
           


           MAIN-PROGRAM.
           




           LOAD-ACCOUNTS.




           DISPLAY-MENU.

           


           SEARCH-ACCOUNT.


           FIND-ACCOUNT.


           DEPOSIT-MONEY.


           WITHDRAW-MONEY.



           SHOW-BALANCE.



           UPDATE-DEPOSIT-STATS.



           UPDATE-WITHDRAW-STATS.



           END-DAY-REPORT.
