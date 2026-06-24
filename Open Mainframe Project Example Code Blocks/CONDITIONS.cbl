       IDENTIFICATION DIVISION.
       PROGRAM-ID. CONDITIONS.
       AUTHOR.     UMUT-YURDUGUL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      
       01  AGE             PIC 9(3)      VALUE ZERO.
       
       
       01  VOTE-FLAG       PIC X(1)      VALUE 'N'.
           88 CAN-VOTE                   VALUE 'Y'.

       01  VOTE-AGE        PIC 9(2)      VALUE 21.
       01  YEARS-REMANING  PIC 9(2)      VALUE ZERO.
       01  NEW-VARIABLE    PIC 9(2)      VALUE 99.
       01  WS-NAME         PIC X(20)     VALUE SPACES.

       PROCEDURE DIVISION.
  
           PERFORM SOMETHING-THAT-CHANGED.
           PERFORM 100-CHEAT-SHEET.
           PERFORM 200-CHEAT-SHEET.
           STOP RUN. 

       SOMETHING-THAT-CHANGED.
           DISPLAY "ENTER AGE : "
           ACCEPT AGE
           
           IF AGE > ZERO
              DISPLAY AGE
              
              IF AGE < VOTE-AGE
                 COMPUTE YEARS-REMANING = VOTE-AGE - AGE
                 DISPLAY "YEARS REMAINING TO VOTE " YEARS-REMANING
                 DISPLAY VOTE-FLAG
              ELSE 
                 IF AGE = VOTE-AGE
                    DISPLAY "YOU CAN VOTE THIS YEAR"
                    
                    SET CAN-VOTE TO TRUE
                    DISPLAY VOTE-FLAG
                 ELSE
                    DISPLAY "YOU'RE ALREADY VOTING"
                    SET CAN-VOTE TO TRUE
                    DISPLAY VOTE-FLAG
                 END-IF 
              END-IF    
           END-IF.      

       100-CHEAT-SHEET.
           DISPLAY AGE.
           
           IF AGE > NEW-VARIABLE
              DISPLAY "AGE IS GREATER THAN NEW-VARIABLE"
           ELSE
              DISPLAY "IDK SOMETHING LIKE THAT "
           END-IF.
           

       200-CHEAT-SHEET.
           MOVE "UMUT" TO WS-NAME
           
           IF WS-NAME IS NOT NUMERIC
              DISPLAY "WS-NAME IS NOT NUMERIC"
           END-IF.
           
           IF WS-NAME IS ALPHABETIC 
              DISPLAY "WS-NAME IS ALPHABETIC"
           END-IF.
           
           IF WS-NAME IS ALPHABETIC-UPPER
              DISPLAY "WS-NAME IS ALPHABETIC-UPPER"
           END-IF.
