       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILEHND.
       AUTHOR      UMUT-YURDUGUL.
      *****************************
      *    IN THIS PROGRAM I LEARNED HOW FILE READING WORKS 
      *    AND I ALSO USED TABLES THAT I LEARNED IN LAST LESSON
      *****************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-DATA ASSIGN TO "NOTLAR.TXT"
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUTPUT-FILE ASSIGN TO "NOTLAR.TXT"
                  ORGANIZATION IS LINE SEQUENTIAL.  

           SELECT OGRENCI-DOSYASI ASSIGN TO "NOTLAR.DAT"
                 ORGANIZATION IS INDEXED
                 ACCESS MODE IS DYNAMIC
                 RECORD KEY IS I-OGR-ID
                 FILE STATUS IS WS-DURUM.
            
       DATA DIVISION.
       FILE SECTION.
       FD  OGRENCI-DOSYASI.
       01  INDEXLI-SATIR.
           05 I-OGR-ID    PIC 9(3).
           05 I-OGR-AD    PIC X(15).
           05 I-OGR-NOT   PIC 9(3).
       FD OUTPUT-FILE.
       01  OUTPUT-SATIR.
           05 O-OGR-ID    PIC 9(3).
           05 O-OGR-AD    PIC X(15).
           05 O-OGR-NOT   PIC 9(3).
       FD   INPUT-DATA.
       01  SATIR.
           05 D-OGR-ID    PIC 9(3).
           05 D-OGR-AD    PIC X(15).
           05 D-OGR-NOT   PIC 9(3).
       WORKING-STORAGE SECTION.
       01  WS-DURUM       PIC XX.
      *DOSYA SONU BAYRAK
       01  DOSYA-DURUMU   PIC X VALUE 'H'.
           88 DOSYA-BITTI VALUE 'E'.       
      *TABLO
       01  SINIF-TABLOSU.
           05 OGRENCILER OCCURS 3 TIMES INDEXED BY O-IDX.
              10 T-OGR-ID    PIC 9(3).
              10 T-OGR-AD    PIC X(15).
              10 T-OGR-NOT   PIC 9(3).
       PROCEDURE DIVISION.
           PERFORM 000-MAIN-CONTROL.
       
       000-MAIN-CONTROL.
           
           PERFORM 100-OPEN-FILE.           
           PERFORM 200-WRITE-DATA.
           PERFORM 300-DISPLAY-DATA.
           PERFORM 400-ADD-DATA-HARD.
           PERFORM 500-INPUT-DATA.


       100-OPEN-FILE.
           OPEN INPUT  INPUT-DATA.
           SET O-IDX TO 1.
           READ  INPUT-DATA
              AT END MOVE 'E' TO DOSYA-DURUMU
           END-READ.
           
       200-WRITE-DATA.
           PERFORM UNTIL DOSYA-DURUMU = 'E' OR O-IDX > 3
              MOVE D-OGR-ID TO T-OGR-ID(O-IDX)
              MOVE D-OGR-AD TO T-OGR-AD(O-IDX)
              MOVE D-OGR-NOT TO T-OGR-NOT(O-IDX)
              SET O-IDX UP BY 1
              READ  INPUT-DATA  
                 AT END MOVE 'E' TO DOSYA-DURUMU
              END-READ
           END-PERFORM.
              CLOSE  INPUT-DATA.
       
       300-DISPLAY-DATA.
           PERFORM VARYING O-IDX FROM 1 BY 1
              UNTIL T-OGR-ID(O-IDX) = 0 OR O-IDX > 3
                 DISPLAY "ID : "   T-OGR-ID(O-IDX)
                         " AD : "  T-OGR-AD(O-IDX)
                         " NOT : " T-OGR-NOT(O-IDX)
           END-PERFORM.
           STOP RUN.

       400-ADD-DATA-HARD.
           OPEN EXTEND OUTPUT-FILE.
           MOVE 105 TO O-OGR-ID.
           MOVE "UMUT YURDUGUL" TO O-OGR-AD.
           MOVE 100             TO O-OGR-NOT.
           WRITE OUTPUT-SATIR.
           CLOSE OUTPUT-FILE.
       500-INPUT-DATA.
           OPEN EXTEND OUTPUT-FILE.
           DISPLAY "ID : ".
           ACCEPT O-OGR-ID.
           DISPLAY "AD : ".
           ACCEPT O-OGR-AD.
           DISPLAY "NOT : ".
           ACCEPT O-OGR-NOT.
           WRITE OUTPUT-SATIR.
           CLOSE OUTPUT-FILE.
       600-DELETE-DATA.
           OPEN I-O OGRENCI-DOSYASI.
           DISPLAY "SILINECEK ID GIRIN: ".
           ACCEPT I-OGR-ID.

           DELETE OGRENCI-DOSYASI RECORD
              INVALID KEY 
                 DISPLAY "HATA KODU : " WS-DURUM
              NOT INVALID KEY 
                 DISPLAY "OGRENCI SILINDI"
           END-DELETE.

           CLO   SE OGRENCI-DOSYASI.
              