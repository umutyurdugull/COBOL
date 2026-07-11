       IDENTIFICATION DIVISION.
       PROGRAM-ID. GETDATA.


       ENVIRONMENT DIVISION.
         INPUT-OUTPUT SECTION.
         FILE-CONTROL.
           SELECT VSAM-FILE ASSIGN TO VSAM-FILE
             ORGANIZATION IS INDEXED
             ACCESS MODE IS RANDOM
             RECORD KEY IS VS-RECORD-ID
             FILE STATUS IS WS-VSAM-STATUS.


       DATA DIVISION.
       FILE SECTION.
       FD  VSAM-FILE.
       01  VS-RECORD.
           05 VS-RECORD-ID         PIC X(8).
           05 VS-DATE              PIC X(10).
           05 VS-INA               PIC X(5).
           05 VS-UNDER-22          PIC X(7).
           05 VS-22-TO-24          PIC X(7).
           05 VS-25-TO-34          PIC X(7).
           05 VS-35-TO-44          PIC X(7).
           05 VS-45-TO-54          PIC X(7).
           05 VS-55-TO-59          PIC X(7).
           05 VS-60-TO-64          PIC X(7).
           05 VS-OVER-65           PIC X(7).

       WORKING-STORAGE SECTION.
       01  WS-VSAM-STATUS          PIC X(2).

       LINKAGE SECTION.
       01  LS-REQUEST-ID           PIC X(8).
       01  LS-RETURN-DATA          PIC X(79).
       01  LS-RETURN-CODE          PIC X(2).


       PROCEDURE DIVISION USING LS-REQUEST-ID, 
                                LS-RETURN-DATA, 
                                LS-RETURN-CODE.
      
       0000-MAIN.
           OPEN INPUT VSAM-FILE
           IF WS-VSAM-STATUS NOT = '00'
               MOVE '01' TO LS-RETURN-CODE
               GOBACK
           END-IF

           MOVE LS-REQUEST-ID TO VS-RECORD-ID
           READ VSAM-FILE
              INVALID KEY 
                 MOVE '99' TO LS-RETURN-CODE
              NOT INVALID KEY 
                 MOVE '00' TO LS-RETURN-CODE
                 MOVE VS-RECORD TO LS-RETURN-DATA
           END-READ
           CLOSE VSAM-FILE
           GOBACK.