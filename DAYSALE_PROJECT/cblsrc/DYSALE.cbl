       IDENTIFICATION DIVISION.
       PROGRAM-ID. DYSALE.
       AUTHOR. UMUT-YURDUGUL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE ASSIGN TO REPOUT
               ORGANIZATION IS SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  REPORT-FILE
           RECORDING MODE F.
       01  REPORT-RECORD                 PIC X(80).

       WORKING-STORAGE SECTION.
      * Include Db2 SQL Communications Area
           EXEC SQL INCLUDE SQLCA END-EXEC.

      * Define host variables inside DECLARE SECTION
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
            
      * Input Sales Host Variables
       01  DB-SALES-RECORD.
           05  DB-IN-CUST-ID         PIC X(5).
           05  DB-IN-CATEGORY        PIC X(10).
           05  DB-IN-QUANTITY        PIC S9(9) COMP.
           05  DB-IN-UNIT-PRICE      PIC S9(4)V99 COMP-3.
                
      * Valid Sales Host Variables
       01  DB-VALID-RECORD.
           05  DB-VAL-CUST-ID        PIC X(5).
           05  DB-VAL-CATEGORY       PIC X(10).
           05  DB-VAL-DISC-PRICE     PIC S9(7)V99 COMP-3.
                
      * Error Log Host Variables
       01  DB-ERROR-RECORD.
           05  DB-ERR-DATA           PIC X(24).
           05  DB-ERR-REASON         PIC X(20).
                
           EXEC SQL END DECLARE SECTION END-EXEC.

      * Program status flags
       01  WS-EOF-FLAG               PIC X(1) VALUE 'N'.
       01  WS-TOTAL-PRICE            PIC 9(7)V99.
       01  WS-REPORT-COUNTERS        PIC 9(4) VALUE ZERO.
       01  WS-FINAL-TOTAL            PIC 9(7)V99 VALUE ZERO.
       01  WS-SQLCODE-DISP           PIC -9(9).

      * Formatting for Error Log raw data construction
       01  WS-FORMAT-FIELDS.
           05  WS-QTY-DISP           PIC 9(3).
           05  WS-PRICE-DISP         PIC 9(6).

       01  WS-HEADER-1               PIC X(55) VALUE
           "=======================================================".
       01  WS-HEADER-2               PIC X(55) VALUE
           "                 DAILY SALES REPORT                    ".
       01  WS-HEADER-3               PIC X(55) VALUE
           "CUST ID   CATEGORY      PAID AMOUNT  STATUS".
       01  WS-HEADER-4               PIC X(55) VALUE 
           "-------   ----------    -----------   -------          ".

       01  WS-DETAIL-LINE.
           05  DET-CUST-ID           PIC X(5).
           05  FILLER                PIC X(5) VALUE SPACES.
           05  DET-CATEGORY          PIC X(10).
           05  FILLER                PIC X(4) VALUE SPACES.
           05  DET-PRICE             PIC $ZZZ,ZZ9.99.
           05  FILLER                PIC X(4) VALUE SPACES.
           05  DET-STATUS            PIC X(10).

       01  WS-FOOTER-1.
           05  FILLER                PIC X(25) VALUE 
               "TOTAL RECORDS PROCESSED: ".
           05  FOOT-TOTAL-REC        PIC Z,ZZ9.
       01  WS-FOOTER-2.
           05  FILLER                PIC X(25) VALUE
               "TOTAL SALES AMOUNT     : ".
           05  FOOT-FINAL-TOTAL      PIC $$$,$$$,$$9.99.

      * Cursor declarations
           EXEC SQL
               DECLARE SALES_CUR CURSOR FOR
               SELECT CUST_ID, CATEGORY, QUANTITY, UNIT_PRICE
               FROM Z88116.SALES_DATA
           END-EXEC.

           EXEC SQL
               DECLARE VALID_SALES_CUR CURSOR FOR
               SELECT CUST_ID, CATEGORY, DISC_PRICE
               FROM Z88116.VALID_SALES
               ORDER BY DISC_PRICE DESC
           END-EXEC.

       PROCEDURE DIVISION.
       0000-MAIN-PROCESS.
           PERFORM 1000-INIT.
           PERFORM 2000-PROCESS-SALES-DATA UNTIL WS-EOF-FLAG = 'Y'.
           EXEC SQL CLOSE SALES_CUR END-EXEC.
           PERFORM 4000-GENERATE-REPORT.
           PERFORM 9000-TERMINATION.
           STOP RUN.

       1000-INIT.
           OPEN OUTPUT REPORT-FILE.
            
      * Empty valid sales and error log tables 
      * (matches OPEN OUTPUT behavior)
           EXEC SQL
               DELETE FROM Z88116.VALID_SALES
           END-EXEC.
           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               PERFORM 9100-SQL-ERROR
           END-IF.
            
           EXEC SQL
               DELETE FROM Z88116.ERROR_LOG
           END-EXEC.
           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               PERFORM 9100-SQL-ERROR
           END-IF.
            
      * Open SQL Cursor for reading sales
           EXEC SQL OPEN SALES_CUR END-EXEC.
           IF SQLCODE NOT = 0
               PERFORM 9100-SQL-ERROR
           END-IF.
            
           PERFORM 1100-FETCH-SALES.

       1100-FETCH-SALES.
           EXEC SQL
               FETCH SALES_CUR 
               INTO :DB-IN-CUST-ID, 
                    :DB-IN-CATEGORY, 
                    :DB-IN-QUANTITY, 
                    :DB-IN-UNIT-PRICE
           END-EXEC.
            
           IF SQLCODE = 100
               MOVE 'Y' TO WS-EOF-FLAG
           ELSE 
               IF SQLCODE NOT = 0
                   PERFORM 9100-SQL-ERROR
               END-IF
           END-IF.

       2000-PROCESS-SALES-DATA.
           PERFORM 2100-VALIDATE-AND-CALCULATE.
           PERFORM 1100-FETCH-SALES.

       2100-VALIDATE-AND-CALCULATE.
      * Note: Since DB2 columns have numerical types, 
      * DB-IN-QUANTITY and DB-IN-UNIT-PRICE are guaranteed 
      * to be numeric by Db2 type checks.
           IF DB-IN-QUANTITY EQUAL TO ZERO
              MOVE "ZERO QUANTITY" TO DB-ERR-REASON
              PERFORM 2200-WRITE-ERROR
           ELSE
              IF DB-IN-CUST-ID = SPACES
                 MOVE "MISSING CUST ID" TO DB-ERR-REASON
                 PERFORM 2200-WRITE-ERROR
              ELSE
                 IF DB-IN-CATEGORY IS NOT ALPHABETIC
                    MOVE "INVALID CATEGORY" TO DB-ERR-REASON
                    PERFORM 2200-WRITE-ERROR
                 ELSE
                    PERFORM 2150-CALCULATE-DISCOUNT
                    PERFORM 2300-WRITE-VALID   
                 END-IF
              END-IF
           END-IF.

       2150-CALCULATE-DISCOUNT.
           COMPUTE WS-TOTAL-PRICE = DB-IN-QUANTITY * DB-IN-UNIT-PRICE
              ON SIZE ERROR
                 DISPLAY "ID : " DB-IN-CUST-ID " SIZE ERROR"
                 MOVE 999999.99 TO WS-TOTAL-PRICE
           END-COMPUTE.

           EVALUATE DB-IN-CATEGORY
                    WHEN "ELECTRONIC"
                       COMPUTE DB-VAL-DISC-PRICE = WS-TOTAL-PRICE * 0.90
                    WHEN "CLOTHING  "
                       COMPUTE DB-VAL-DISC-PRICE = WS-TOTAL-PRICE * 0.80
                    WHEN OTHER
                       COMPUTE DB-VAL-DISC-PRICE = WS-TOTAL-PRICE
           END-EVALUATE.

       2200-WRITE-ERROR.
      * Build 24-character string representation of the raw record
           MOVE DB-IN-QUANTITY TO WS-QTY-DISP.
           COMPUTE WS-PRICE-DISP = DB-IN-UNIT-PRICE * 100.
            
           MOVE SPACES TO DB-ERR-DATA.
           STRING DB-IN-CUST-ID DB-IN-CATEGORY WS-QTY-DISP WS-PRICE-DISP
                  DELIMITED BY SIZE INTO DB-ERR-DATA.
                   
      * DB-ERR-REASON already populated in validation.
            
           EXEC SQL
               INSERT INTO Z88116.ERROR_LOG 
                   (ERR_DATA, ERR_REASON)
               VALUES (:DB-ERR-DATA, 
                       :DB-ERR-REASON)
           END-EXEC.
            
           IF SQLCODE NOT = 0
               PERFORM 9100-SQL-ERROR
           END-IF.

       2300-WRITE-VALID.
           MOVE DB-IN-CUST-ID TO DB-VAL-CUST-ID.
           MOVE DB-IN-CATEGORY TO DB-VAL-CATEGORY.
            
           EXEC SQL
               INSERT INTO Z88116.VALID_SALES 
                   (CUST_ID, CATEGORY, DISC_PRICE)
               VALUES (:DB-VAL-CUST-ID, 
                       :DB-VAL-CATEGORY, 
                       :DB-VAL-DISC-PRICE)
           END-EXEC.
            
           IF SQLCODE NOT = 0
               PERFORM 9100-SQL-ERROR
           END-IF.

       4000-GENERATE-REPORT.
           MOVE 'N' TO WS-EOF-FLAG.
            
           WRITE REPORT-RECORD FROM WS-HEADER-1.
           WRITE REPORT-RECORD FROM WS-HEADER-2.
           WRITE REPORT-RECORD FROM WS-HEADER-1.
           WRITE REPORT-RECORD FROM WS-HEADER-3.
           WRITE REPORT-RECORD FROM WS-HEADER-4.

           EXEC SQL OPEN VALID_SALES_CUR END-EXEC.
           IF SQLCODE NOT = 0
               PERFORM 9100-SQL-ERROR
           END-IF.

           PERFORM 4050-FETCH-REPORT-DATA.
           PERFORM 4100-PROCESS-REPORT UNTIL WS-EOF-FLAG = 'Y'.

           MOVE WS-REPORT-COUNTERS TO FOOT-TOTAL-REC.
           MOVE WS-FINAL-TOTAL     TO FOOT-FINAL-TOTAL.

           WRITE REPORT-RECORD FROM WS-HEADER-1.
           WRITE REPORT-RECORD FROM WS-FOOTER-1.
           WRITE REPORT-RECORD FROM WS-FOOTER-2.
           WRITE REPORT-RECORD FROM WS-HEADER-1.
            
           EXEC SQL CLOSE VALID_SALES_CUR END-EXEC.

       4050-FETCH-REPORT-DATA.
           EXEC SQL
               FETCH VALID_SALES_CUR
               INTO :DB-VAL-CUST-ID, :DB-VAL-CATEGORY,:DB-VAL-DISC-PRICE
           END-EXEC.
            
           IF SQLCODE = 100
               MOVE 'Y' TO WS-EOF-FLAG
           ELSE
               IF SQLCODE NOT = 0
                   PERFORM 9100-SQL-ERROR
               END-IF
           END-IF.

       4100-PROCESS-REPORT.
           MOVE DB-VAL-CUST-ID   TO DET-CUST-ID.
           MOVE DB-VAL-CATEGORY  TO DET-CATEGORY.
           MOVE DB-VAL-DISC-PRICE TO DET-PRICE.

           IF DB-VAL-DISC-PRICE > 1000.00
               MOVE "VIP SALE" TO DET-STATUS
           ELSE
               MOVE "STANDARD" TO DET-STATUS
           END-IF.

           WRITE REPORT-RECORD FROM WS-DETAIL-LINE.

           ADD 1 TO WS-REPORT-COUNTERS.
           ADD DB-VAL-DISC-PRICE TO WS-FINAL-TOTAL.

           PERFORM 4050-FETCH-REPORT-DATA.

       9000-TERMINATION.
           CLOSE REPORT-FILE.

       9100-SQL-ERROR.
           MOVE SQLCODE TO WS-SQLCODE-DISP.
           DISPLAY "DATABASE ERROR OCCURRED! SQLCODE: " WS-SQLCODE-DISP.
           DISPLAY "SQLERRMC: " SQLERRMC.
           EXEC SQL ROLLBACK END-EXEC.
           STOP RUN.