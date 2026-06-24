       IDENTIFICATION DIVISION.
       
       PROGRAM-ID. EIGHT.
       AUTHOR. UMUT-YURDUGUL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
           
       01  FACIAL-EXP        PIC X(11) VALUE SPACES.
           88 HAPPY          VALUE 'happy'.
       
      
      

       PROCEDURE DIVISION.
          
           PERFORM SAY-SOMETHING-DIFFERENT UNTIL HAPPY.
           STOP RUN.

       SAY-SOMETHING-DIFFERENT.
          
           DISPLAY "ENTER FACIAL EXPRESSION (HAPPY/SAD/RANDOM) : "
           ACCEPT FACIAL-EXP
           INSPECT FACIAL-EXP CONVERTING 
           "ABCDEFGHIJKLMNOPQRSTUVWXYZ" TO "abcdefghijklmnopqrstuvwxyz"
           EVALUATE FACIAL-EXP
            WHEN 'happy'
              DISPLAY "YOU'RE HAPPY"
            WHEN 'sad'
              DISPLAY "YOU'RE SAD"
            WHEN 'random'
              DISPLAY "YOU'RE RANDOM"
            WHEN OTHER
              DISPLAY "I DON'T KNOW THAT FEELING."
           END-EVALUATE.
     
