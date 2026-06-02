#### ENVIRONMENT DIVISION
The ENVIRONMENT DIVISION describes the aspects of your
program that depend on the computing environment, such as the computer configuration and the computer inputs and outputs.



#### NUMERIC DATA TYPES
PIC 9 ---> Tek bir rakam tutabilen uzunluğu bir hane olan değişkendir. 
PIC 9(N) ->N basamaklı bir sayı 


#### ALPHANUMERIC DATA TYPES   PIC X 
Tek karakter tutar

PIC X(4) --> 4 karakter tutar


77 Seviyesi (Bağımsız Değişkenler): Hiçbir hiyerarşiye (struct'a) ait olmayan, tek başına duran basit değişkenlerdir (örneğin basit bir i sayacı). Sadece Working-Storage içinde kullanılır.

88 Seviyesi (Condition Names - Mantıksal Değerler / Enumlar): Bir değişkenin alabileceği spesifik bir değeri isimlendirmek için kullanılır. Modern dillerdeki boolean (True/False) veya Enum yapılarına çok benzer.