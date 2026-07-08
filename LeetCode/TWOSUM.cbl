       IDENTIFICATION DIVISION.
       PROGRAM-ID. TWOSUM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 NUMBERS.
           05 NUM OCCURS 4 TIMES PIC 99.

       01 TARGET      PIC 999.
       01 I           PIC 9.
       01 J           PIC 9.
       01 START-J     PIC 9.
       01 TEMP-SUM    PIC 999.
       01 FOUND       PIC X VALUE 'N'.

       PROCEDURE DIVISION.

        
           ACCEPT NUM(1)

           ACCEPT NUM(2)

           ACCEPT NUM(3)

           ACCEPT NUM(4)

           ACCEPT TARGET

           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 4

               ADD 1 TO I GIVING START-J

               PERFORM VARYING J FROM START-J BY 1
                   UNTIL J > 4

                   ADD NUM(I) NUM(J) GIVING TEMP-SUM

                   IF TEMP-SUM = TARGET
                       DISPLAY "FOUND:"
                       DISPLAY "INDEX 1 = " I
                       DISPLAY "INDEX 2 = " J
                       MOVE 'Y' TO FOUND
                       STOP RUN
                   END-IF

               END-PERFORM

           END-PERFORM

           IF FOUND = 'N'
               DISPLAY "NO MATCH FOUND"
           END-IF

           STOP RUN.