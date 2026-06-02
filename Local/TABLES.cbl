       IDENTIFICATION DIVISION.
           PROGRAM-ID. TABLES.
           AUTHOR. UMUT-YURDUGUL.


       DATA DIVISION.
       FILE SECTION.
       WORKING-STORAGE SECTION.
       01  TUR-ACENTA.
           05 TUR-PAKET OCCURS 3 TIMES 
                       ASCENDING KEY IS TUR-ID
                       INDEXED BY TUR-IDX.
              10 TUR-ID      PIC 9(3).
              10 TUR-ADI     PIC X(10).
              10 TUR-FIYAT   PIC 9(4).
       01  ARANAN-ID         PIC 9(3).
       01  BULUNDU           PIC X VALUE 'H'.    

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
      *    TABLOYA KODUN ICINDE VERI YUKLEME 

           SET TUR-IDX    TO 1.
           MOVE 100       TO TUR-ID(TUR-IDX).
           MOVE "EGE"     TO TUR-ADI(TUR-IDX).
           MOVE 1000      TO TUR-FIYAT(TUR-IDX).


           SET TUR-IDX    TO 2.
           MOVE 200       TO TUR-ID(TUR-IDX).
           MOVE "ANADOLU" TO TUR-ADI(TUR-IDX).
           MOVE 1500      TO TUR-FIYAT(TUR-IDX).


           SET TUR-IDX    TO 3.
           MOVE 300       TO TUR-ID(TUR-IDX).
           MOVE "DOGU"    TO TUR-ADI(TUR-IDX).
           MOVE 2000      TO TUR-FIYAT(TUR-IDX).




      *    TABLODAKI VERILERI EKRANA BASTIRMA 
           
           DISPLAY "MEVCUT TURLAR".
      *    FOR DONGUSU 
           PERFORM VARYING TUR-IDX FROM 1 BY 1 UNTIL TUR-IDX > 3
                 DISPLAY "ID : " TUR-ID(TUR-IDX)
                         "AD : " TUR-ADI(TUR-IDX)
                      "FIYAT : " TUR-FIYAT(TUR-IDX)
           END-PERFORM.
           DISPLAY SPACE.       
           


           DISPLAY " ARANAN TUR ID : ".
           ACCEPT ARANAN-ID.
      *         SET TUR-IDX TO 1.
           SEARCH ALL TUR-PAKET
              AT END 
                 DISPLAY "ARANAN TUR BULUNAMADI"
              WHEN TUR-ID(TUR-IDX) = ARANAN-ID
                 MOVE 'E' TO BULUNDU
                 DISPLAY "ADI   :   " TUR-ADI(TUR-IDX)
                 DISPLAY "FIYAT :   " TUR-FIYAT(TUR-IDX)
           END-SEARCH.
           STOP RUN.
