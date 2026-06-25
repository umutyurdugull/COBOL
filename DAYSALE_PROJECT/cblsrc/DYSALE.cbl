        IDENTIFICATION DIVISION.
        PROGRAM-ID. DYSALE.
        AUTHOR. UMUT-YURDUGUL.

        ENVIRONMENT DIVISION.
        INPUT-OUTPUT SECTION.
        FILE-CONTROL.
            SELECT SALES-FILE ASSIGN TO SALES
                ORGANIZATION IS SEQUENTIAL.
                
            SELECT VALID-SALES-FILE ASSIGN TO VALIDSAL
                ORGANIZATION IS SEQUENTIAL.
        
            SELECT ERROR-FILE ASSIGN TO ERRORS
                ORGANIZATION IS SEQUENTIAL.
                
            SELECT REPORT-FILE ASSIGN TO REPOUT
                ORGANIZATION IS SEQUENTIAL.
      
            SELECT SORT-FILE ASSIGN TO SORTWRK.
            

        DATA DIVISION.
        FILE SECTION.
        FD  SALES-FILE
            RECORDING MODE F.
        01  SALES-RECORD.           
            05    IN-CUST-ID              PIC X(5).
            05    IN-CATEGORY             PIC X(10).
            05    IN-QUANTITY             PIC 9(3).
            05    IN-UNIT-PRICE           PIC 9(4)V99.

        FD  VALID-SALES-FILE
            RECORDING MODE F.
        01  VALID-RECORD. 
            05    VAL-CUST-ID             PIC X(5).
            05    VAL-CATEGORY            PIC X(10).
            05    VAL-DISC-PRICE          PIC 9(6)V99.
       
        FD  ERROR-FILE
            RECORDING MODE F.
        01  ERROR-RECORD.
            05  ERR-DATA                  PIC X(24).
            05  ERR-REASON                PIC X(20).

        FD  REPORT-FILE
            RECORDING MODE F.
        01  REPORT-RECORD                 PIC X(80).

        SD  SORT-FILE.
        01  SORT-RECORD.
            05  SRT-CUST-ID               PIC X(5).
            05  SRT-CATEGORY              PIC X(10).
            05  SRT-DISC-PRICE            PIC 9(6)V99.

        WORKING-STORAGE SECTION.
        01  WS-EOF-FLAG                   PIC X(1) VALUE 'N'.
        01  WS-TOTAL-PRICE                PIC 9(6)V99.
        01  WS-REPORT-COUNTERS            PIC 9(4) VALUE ZERO.
        01  WS-FINAL-TOTAL                PIC 9(7)V99 VALUE ZERO.

        01  WS-HEADER-1                   PIC X(55) VALUE 
            "=======================================================".
        01  WS-HEADER-2                   PIC X(55) VALUE 
            "                 DAILY SALES REPORT                    ".
        01  WS-HEADER-3                   PIC X(55) VALUE 
            "CUST ID   CATEGORY      PAID AMOUNT   STATUS           ".
        01  WS-HEADER-4                   PIC X(55) VALUE 
            "-------   ----------    -----------   -------          ".

        01  WS-DETAIL-LINE.
            05  DET-CUST-ID               PIC X(5).
            05  FILLER                    PIC X(5) VALUE SPACES.
            05  DET-CATEGORY              PIC X(10).
            05  FILLER                    PIC X(4) VALUE SPACES.
            05  DET-PRICE                 PIC $ZZZ,ZZ9.99.
            05  FILLER                    PIC X(4) VALUE SPACES.
            05  DET-STATUS                PIC X(10).

        01  WS-FOOTER-1.
            05  FILLER                    PIC X(25) VALUE 
                "TOTAL RECORDS PROCESSED: ".
            05  FOOT-TOTAL-REC            PIC Z,ZZ9.
        01  WS-FOOTER-2.
            05  FILLER                    PIC X(25) VALUE 
                "TOTAL SALES AMOUNT     : ".
            05  FOOT-FINAL-TOTAL          PIC $$$,$$$,$$9.99.

        PROCEDURE DIVISION.
        0000-MAIN-PROCESS.
            PERFORM 1000-INIT.
            PERFORM 2000-PROCESS-SALES-DATA UNTIL WS-EOF-FLAG = 'Y'.
            PERFORM 3000-SORT-SALES.
            PERFORM 4000-GENERATE-REPORT.
            PERFORM 9000-TERMINATION.
            STOP RUN.

        1000-INIT.
            OPEN INPUT SALES-FILE.
            OPEN OUTPUT VALID-SALES-FILE.
            OPEN OUTPUT ERROR-FILE
                        REPORT-FILE.
            READ SALES-FILE
               AT END MOVE 'Y' TO WS-EOF-FLAG
            END-READ.

        2000-PROCESS-SALES-DATA.
            PERFORM 2100-VALIDATE-AND-CALCULATE.
            READ SALES-FILE
                 AT END MOVE 'Y' TO WS-EOF-FLAG
            END-READ.

        2100-VALIDATE-AND-CALCULATE.
             IF IN-QUANTITY IS NOT NUMERIC
                MOVE "NOT NUMERIC"  TO ERR-REASON
                PERFORM 2200-WRITE-ERROR
             ELSE
                IF IN-QUANTITY EQUAL TO ZERO
                   MOVE "ZERO QUANTITY" TO ERR-REASON
                   PERFORM 2200-WRITE-ERROR
                ELSE
                   IF IN-CUST-ID = SPACES
                      MOVE "MISSING CUST ID" TO ERR-REASON
                      PERFORM 2200-WRITE-ERROR
                   ELSE
                      IF IN-CATEGORY IS NOT ALPHABETIC
                         MOVE "INVALID CATEGORY" TO ERR-REASON
                         PERFORM 2200-WRITE-ERROR
                      ELSE
                         IF IN-UNIT-PRICE IS NOT NUMERIC
                            MOVE "PRICE NOT NUMERIC" TO ERR-REASON
                            PERFORM 2200-WRITE-ERROR
                         ELSE
                            PERFORM 2150-CALCULATE-DISCOUNT
                            PERFORM 2300-WRITE-VALID   
                         END-IF
                      END-IF
                   END-IF
                END-IF
             END-IF.

        2150-CALCULATE-DISCOUNT.
            COMPUTE WS-TOTAL-PRICE = IN-QUANTITY * IN-UNIT-PRICE
               ON SIZE ERROR
                  DISPLAY "ID : " IN-CUST-ID " SIZE ERROR"
                  MOVE 999999.99 TO WS-TOTAL-PRICE
            END-COMPUTE.

            EVALUATE IN-CATEGORY
                     WHEN "ELECTRONIC"
                        COMPUTE VAL-DISC-PRICE = WS-TOTAL-PRICE * 0.90
                     WHEN "CLOTHING  "
                        COMPUTE VAL-DISC-PRICE = WS-TOTAL-PRICE * 0.80
                     WHEN OTHER
                        COMPUTE VAL-DISC-PRICE = WS-TOTAL-PRICE
            END-EVALUATE.

        2200-WRITE-ERROR.
            MOVE SALES-RECORD TO ERR-DATA.
            DISPLAY "CUSTOMER ID  " IN-CUST-ID.
            DISPLAY "ERROR REASON " ERR-REASON.
            DISPLAY "ERROR DATA   " ERR-DATA.
            WRITE ERROR-RECORD.

        2300-WRITE-VALID.
            MOVE IN-CUST-ID TO VAL-CUST-ID.
            MOVE IN-CATEGORY TO VAL-CATEGORY.
            WRITE VALID-RECORD.

        3000-SORT-SALES.
            CLOSE VALID-SALES-FILE.
            SORT SORT-FILE
               ON DESCENDING KEY SRT-DISC-PRICE
               USING VALID-SALES-FILE
               GIVING VALID-SALES-FILE.

        4000-GENERATE-REPORT.
            OPEN INPUT VALID-SALES-FILE.
            MOVE 'N' TO WS-EOF-FLAG.
            
            WRITE REPORT-RECORD FROM WS-HEADER-1.
            WRITE REPORT-RECORD FROM WS-HEADER-2.
            WRITE REPORT-RECORD FROM WS-HEADER-1.
            WRITE REPORT-RECORD FROM WS-HEADER-3.
            WRITE REPORT-RECORD FROM WS-HEADER-4.

            READ VALID-SALES-FILE
                AT END MOVE 'Y' TO WS-EOF-FLAG
            END-READ.

            PERFORM 4100-PROCESS-REPORT UNTIL WS-EOF-FLAG = 'Y'.

            MOVE WS-REPORT-COUNTERS TO FOOT-TOTAL-REC.
            MOVE WS-FINAL-TOTAL     TO FOOT-FINAL-TOTAL.

            WRITE REPORT-RECORD FROM WS-HEADER-1.
            WRITE REPORT-RECORD FROM WS-FOOTER-1.
            WRITE REPORT-RECORD FROM WS-FOOTER-2.
            WRITE REPORT-RECORD FROM WS-HEADER-1.

        4100-PROCESS-REPORT.
            MOVE VAL-CUST-ID   TO DET-CUST-ID.
            MOVE VAL-CATEGORY  TO DET-CATEGORY.
            MOVE VAL-DISC-PRICE TO DET-PRICE.

            IF VAL-DISC-PRICE > 1000.00
                MOVE "VIP SALE" TO DET-STATUS
            ELSE
                MOVE "STANDARD" TO DET-STATUS
            END-IF.

            WRITE REPORT-RECORD FROM WS-DETAIL-LINE.

            ADD 1 TO WS-REPORT-COUNTERS.
            ADD VAL-DISC-PRICE TO WS-FINAL-TOTAL.

            READ VALID-SALES-FILE
                AT END MOVE 'Y' TO WS-EOF-FLAG
            END-READ.

        9000-TERMINATION.
            CLOSE SALES-FILE
                  VALID-SALES-FILE
                  ERROR-FILE
                  REPORT-FILE.