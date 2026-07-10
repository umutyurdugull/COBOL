       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADER.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CSV-FILE ASSIGN TO CSVFILE
               ORGANIZATION IS SEQUENTIAL.
               
           SELECT VSAM-FILE ASSIGN TO VSAMFILE
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS VS-RECORD-ID
               FILE STATUS IS WS-VSAM-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CSV-FILE
           RECORD CONTAINS 150 CHARACTERS.
       01  CSV-RECORD              PIC X(150).

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
       01  WS-EOF-SWITCH           PIC X(1) VALUE 'N'.
       01  WS-VSAM-STATUS          PIC X(2).

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT CSV-FILE
           OPEN OUTPUT VSAM-FILE

           PERFORM UNTIL WS-EOF-SWITCH = 'Y'
               READ CSV-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF-SWITCH
                   NOT AT END
                       PERFORM 1000-PROCESS-RECORD
               END-READ
           END-PERFORM

           CLOSE CSV-FILE
           CLOSE VSAM-FILE
           STOP RUN.

       1000-PROCESS-RECORD.
           INITIALIZE VS-RECORD
           UNSTRING CSV-RECORD DELIMITED BY ','
              INTO VS-RECORD-ID
                    VS-DATE
                    VS-INA
                    VS-UNDER-22
                    VS-22-TO-24
                    VS-25-TO-34
                    VS-35-TO-44
                    VS-45-TO-54
                    VS-55-TO-59
                    VS-60-TO-64
                    VS-OVER-65
           END-UNSTRING.

           WRITE VS-RECORD 
              INVALID KEY 
                 DISPLAY "INVALID KEY : " VS-RECORD-ID
                    "STATUS : " WS-VSAM-STATUS
               NOT INVALID KEY 
                 DISPLAY "ADDED" VS-RECORD-ID
           END-WRITE. 