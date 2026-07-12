       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAINRPT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Alt programa gönderilecek ve alınacak parametreler
       01  WS-CALL-PARAMS.
           05 WS-REQ-ID            PIC X(8)  VALUE '09012017'.
           05 WS-RET-DATA          PIC X(79).
           05 WS-RET-CODE          PIC X(2).

      * Alt programdan dönen 79 karakterlik veriyi kolonlara ayırmak için
       01  WS-FORMATTED-REPORT.
           05 RPT-ID               PIC X(8).
           05 RPT-DATE             PIC X(10).
           05 RPT-INA              PIC X(5).
           05 RPT-UNDER-22         PIC X(7).
           05 RPT-22-TO-24         PIC X(7).
           05 RPT-25-TO-34         PIC X(7).
           05 RPT-35-TO-44         PIC X(7).
           05 RPT-45-TO-54         PIC X(7).
           05 RPT-55-TO-59         PIC X(7).
           05 RPT-60-TO-64         PIC X(7).
           05 RPT-OVER-65          PIC X(7).

       PROCEDURE DIVISION.
       0000-MAIN.
           
           