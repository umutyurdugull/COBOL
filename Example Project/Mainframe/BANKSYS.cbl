       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKSYS.
       AUTHOR. UMUT-YURDUGUL



       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNTS-IN ASSIGN TO ACCIN
                              ORGANIZATION IS SEQUENTIAL.
           SELECT ACCOUNTS-OUT ASSIGN TO ACCOUT
                               ORGANIZATION IS SEQUENTIAL.
                               
           SELECT TRANS-IN     ASSIGN TO TRANSIN
                               ORGANIZATION IS SEQUENTIAL.
                               
           SELECT REPORT-OUT   ASSIGN TO REPOUT
                               ORGANIZATION IS SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       
       FD  ACCOUNTS-IN.
       01  ACCOUNT-RECORD-IN.
           05 AR-ACC-NO-IN          PIC 9(6).
           05 AR-ACC-NAME-IN        PIC X(20).
           05 AR-ACC-BALANCE-IN     PIC 9(9)V99.
           05 AR-ACC-DEPOSIT-IN     PIC 9(4).
           05 AR-ACC-WITHDRAW-IN    PIC 9(5).

      * 2. GUNCEL HESAP DOSYASI (YAZILACAK) - 46 BYTE
       FD  ACCOUNTS-OUT.
       01  ACCOUNT-RECORD-OUT       PIC X(46).

      * 3. GUNLUK ISLEM DOSYASI (OKUNACAK) - 36 BYTE
       FD  TRANS-IN.
       01  TRANS-RECORD.
           05 TR-CODE               PIC 9.      
      * 2: ADD, 3: DEPOSIT, 4: WITHDRAW
           05 TR-ACC-NO             PIC 9(6).
           05 TR-NAME               PIC X(20).
           05 TR-AMOUNT             PIC 9(7)V99.

      * 4. GUN SONU RAPOR DOSYASI (YAZILACAK) - 80 BYTE
       FD  REPORT-OUT.
       01  REPORT-RECORD            PIC X(80).

       WORKING-STORAGE SECTION.
      * --- DOSYA OKUMA (EOF) KONTROL BAYRAKLARI ---
       01  WS-EOF-ACCIN             PIC X          VALUE 'N'.
       01  WS-EOF-TRANS             PIC X          VALUE 'N'.

      * --- ARAMA VE GECICI DEGISKENLER ---
       01  WS-FOUND-INDEX           PIC 9(4).
       01  WS-ACCOUNT-FOUND         PIC X.

      * --- GUN SONU RAPORU TOPLAMLARI ---
       01  WS-DEPOSIT-TOTAL         PIC 9(9)V99    VALUE ZERO.
       01  WS-WITHDRAW-TOTAL        PIC 9(9)V99    VALUE ZERO.
       01  TOTAL-DEPOSIT-COUNT      PIC 9(5)       VALUE ZERO.
       01  TOTAL-WITHDRAW-COUNT     PIC 9(5)       VALUE ZERO.
       01  WS-NET-FLOW              PIC S9(9)V99   VALUE ZERO.
       01  WS-ACCOUNT-COUNT         PIC 9(4)       VALUE ZERO.

      
       01  ACCOUNT-TABLE.
           05 ACCOUNT-ENTRY OCCURS 100 TIMES
              INDEXED BY ACC-IDX.
              10 ACC-NO             PIC 9(6).
              10 ACC-NAME           PIC X(20).
              10 ACC-BALANCE        PIC 9(9)V99.
              10 ACC-DEPOSIT-COUNT  PIC 9(4).
              10 ACC-WITHDRAW-COUNT PIC 9(4).

      *BURDAN SONRA PARAGRAFLAR YAZILACAK 

      *ÇOĞU YENİDEN YAZILACAĞI İÇİN TEKRARDAN Bİ TASARLAMA YAPIACAK 
      *FIND ACCOUNTU YAZIP YATACAĞIM
       PROCEDURE DIVISION.
           PERFORM MAIN-MENU.     
      

       MAIN-MENU.
           PERFORM FIND-ACCOUNT.



       FIND-ACCOUNT.
           MOVE "N" TO WS-ACCOUNT-FOUND
           MOVE 0   TO WS-FOUND-INDEX
           PERFORM VARYING ACC-IDX FROM 1 BY 1
                 UNTIL ACC-IDX > WS-ACCOUNT-COUNT
                 IF ACC-NO(ACC-IDX) = TR-ACC-NO
                    MOVE "Y" TO WS-ACCOUNT-FOUND
                    MOVE ACC-IDX TO WS-FOUND-INDEX
                    EXIT PERFORM
                 END-IF
           END-PERFORM.