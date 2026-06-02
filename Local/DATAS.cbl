       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATASCBL.
       AUTHOR. UMUT-YURDUGUL.



       DATA DIVISION.
      
       FILE SECTION.
      * I didn't added anything here for now. 
       
       WORKING-STORAGE SECTION.
       01  MUSTERI-KAYDI.
      * 01 STRUCT NAME
      
             05  MUSTERI-NO        PIC 9(5)       VALUE ZEROES.
             05  MUSTERI-AD        PIC X(20)      VALUE SPACES.
             05  MUSTERI-BAKIYE    PIC S9(5)V99   VALUE +00000.00.
      * CUSTOMER MAY HAVE A NEGATIVE BALANCE (DEBT)
             05  DURUM-KODU        PIC X(1).
                 88 AKTIF-MUSTERI                 VALUE 'A'.
                 88 PASIF-MUSTERI                 VALUE 'P'.
                 88 YASAKLI-MUSTERI               VALUE 'Y'.
      
       77  DONGU-SAYACI            PIC 9(3)       VALUE 0.
       77  TOPLAM-TUTAR            PIC 9(7)V99    VALUE ZEROES.
       77  GECICI-MESAJ            PIC X(50)      VALUE "BASARILI".       
           


       LINKAGE SECTION.





       PROCEDURE DIVISION.
       
       


       MAIN-PARAGRAPH.
           MOVE 12345 TO MUSTERI-NO.
           MOVE "UMUT YURDUGUL" TO MUSTERI-AD.
           MOVE 12345.99 TO MUSTERI-BAKIYE.
           SET AKTIF-MUSTERI TO TRUE.
           
           DISPLAY "---MUSTERI BILGILIERI---".
           DISPLAY "MUSTERI ADI    :           "     MUSTERI-AD.
           DISPLAY "MUSTERI BAKIYE :           "     MUSTERI-BAKIYE.
           DISPLAY "DURUM KODU     :           "     DURUM-KODU.
           DISPLAY "SISTEM MESAJ   :           "     GECICI-MESAJ.

           STOP RUN.
       