       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROGRA1.


       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NUM-1          PIC 9(3) VALUE 0.
       01  NUM-2          PIC 9(3) VALUE 0.
       01  TOTAL          PIC 9(4) VALUE 0.

       PROCEDURE DIVISION.
           PERFORM MAIN-WORK.


       


       MAIN-WORK.

           DISPLAY "NUM 1 : "
           ACCEPT NUM-1
           END-ACCEPT
           DISPLAY "NUM 2 :"
           ACCEPT   NUM-2
           END-ACCEPT
           DISPLAY "CALL THE PROGRA2"
           CALL 'PROGRA2' USING NUM-1,NUM-2,TOTAL
           DISPLAY "TOTAL IS : " TOTAL
           STOP RUN.    
       