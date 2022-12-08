       PROCESS TEST
      *****************************************************************
      * Program name:    PGM017                               
      * Original author: DEFAY E.                                
      *
      * Maintenence Log                                              
      * Date      Author        Maintenance Requirement               
      * --------- ------------  --------------------------------------- 
      * 07/12/22  IBMUSER       Created for COBOL class         
      *                                                               
      *****************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    PGM017.
       AUTHOR.        DEFAY E. 
       INSTALLATION.  COBOL DEVELOPMENT CENTER. 
       DATE-WRITTEN.  07/12/22. 
       DATE-COMPILED. 07/12/22. 
       SECURITY.      NON-CONFIDENTIAL.
      *****************************************************************
       ENVIRONMENT DIVISION. 
       INPUT-OUTPUT SECTION. 
       FILE-CONTROL. 
           SELECT FILEIN ASSIGN TO FILEIN
           FILE STATUS IS FS-FILEIN.
      *****************************************************************
       DATA DIVISION.
      *****************************************************************
       FILE SECTION.
       FD  FILEIN RECORDING MODE F
           RECORD CONTAINS 80 CHARACTERS.
       01  FICOPER-ENREG. 
          05  FM-COMPTE  PIC S9(09) COMP.       
          05  FM-ROPER   PIC X(10).            
          05  FM-COPER   PIC X(03).            
          05  FM-MTOPER  PIC 9(13)V9(2) COMP-3.
          05  FM-CDEV    PIC X(03).            
          05  FM-DTOPER  PIC X(10).            
          05  FILLER     PIC X(29).            

      *****************************************************************
       WORKING-STORAGE SECTION.
      / FILES STATUS
       01 FS-FILEIN      PIC X(02).
           88 END-FILEIN VALUE '10'.
       
       01 WS-FILE.
           05  WS-COMPTE PIC S9(09) COMP.       
           05  WS-ROPER  PIC X(10).            
           05  WS-COPER  PIC X(03).            
           05  WS-MTOPER PIC S9(13)V9(2) COMP-3.
           05  WS-CDEV   PIC X(03).            
           05  WS-DTOPER PIC X(10).            
           05  FILLER    PIC X(32).            

      / IMPORT SQLCA
           EXEC SQL INCLUDE SQLCA 
           END-EXEC.

      / DECLARATIONS DCLGEN(PGM017)
           EXEC SQL INCLUDE CCOMPTE  END-EXEC.
           EXEC SQL INCLUDE DCHISTO  END-EXEC.
           EXEC SQL INCLUDE DCDEVISE END-EXEC.

      /
      *****************************************************************
      *  Program : Setup, run main routine and exit.
      *    
      *    Main purpose
      *    - 0xx : Input/Output section
      *    - 1xx : Main element
      *    - 2xx : Verifications   
      *    - 3xx : SQL Handling
      *    - 9xx : Close files
      *
      *    Input/Output managment
      *    - x1x : Perform a READ
      *    - x2x : Perform a WRITE
      *    - x3x : Perform a FETCH
      *    - x5x : Perform Comparisons
      *    - x7x : Perform a UPDATE
      *    - x9x : Perform a CLOSE
      *
      *    Specials
      *    -  xxx : OTHERS
      *    - Dxxx : Displays
      *****************************************************************
       
       PROCEDURE DIVISION.
           PERFORM 000-OFILES.
           PERFORM 100-Main.
           PERFORM 999-CFILES.
           GOBACK.

       000-OFILES.
           OPEN INPUT FILEIN
           .

       100-Main.
      **********************************************************
      *  Main routine, getting values from filein
      *  Then fetch SQL
      *  Then update value
           PERFORM 210-Read-File
           
           PERFORM UNTIL (END-FILEIN)
               PERFORM 330-Access-Table-Devise
               PERFORM 331-Access-Table-Compte
               PERFORM 331-Operation-Defined
               PERFORM 321-Histo-update
               PERFORM 210-Read-File
           END-PERFORM
           .

       210-Read-File.
      **********************************************************
      *  This routine should read file line by line
           READ FILEIN
           MOVE FICOPER-ENREG TO WS-FILE
           .
      
       321-Histo-update.
      **********************************************************
      *  This routine should update mtachat, mtvente of cursor
           EXEC SQL
              INSERT INTO TBHISTO
              (
                COMPTE,
                COPER,
                ROPER,
                MTOPPER,
                DDMAJ,
                HDMAJ
              )
              VALUES 
              (
                :DGC-COMPTE,
                :WS-COPER,
                :WS-ROPER,
                :WS-MTOPER,
                 CURRENT DATE,
                 CURRENT TIME
              )
           END-EXEC

           PERFORM D550-CHECKSQL
           .

       330-Access-Table-Devise.
      **********************************************************
      *  This routine should update mtachat, mtvente of cursor
      *
           EXEC SQL
              SELECT *
              INTO   :DCLTBDEVISE
              FROM   TBDEVISE 
              WHERE CDEV=:WS-CDEV
           END-EXEC

           PERFORM D550-CHECKSQL
           .

       331-Access-Table-Compte.
      **********************************************************
      *  This routine should update mtachat, mtvente of cursor
      *
           EXEC SQL
              SELECT *
              INTO :DCLTBCOMPTE
              FROM TBCOMPTE 
              WHERE COMPTE=:WS-COMPTE
           END-EXEC

           PERFORM D550-CHECKSQL
           .

       331-Operation-Defined.
      **********************************************************
      *  This routine should close file(s)
           DISPLAY WS-MTOPER
           COMPUTE WS-MTOPER = WS-MTOPER * DGD-MTACHAT
           EVALUATE TRUE 
              WHEN WS-COPER = 'VIR'
                 COMPUTE DGC-SOLDE = DGC-SOLDE + WS-MTOPER
              WHEN WS-COPER = 'RMB'
                 COMPUTE DGC-SOLDE = DGC-SOLDE + WS-MTOPER
              WHEN WS-COPER = 'PRL'
                 COMPUTE DGC-SOLDE = DGC-SOLDE - WS-MTOPER
              WHEN WS-COPER = 'RET'
                 COMPUTE DGC-SOLDE = DGC-SOLDE - WS-MTOPER    
              WHEN OTHER
                 PERFORM D020-ERROR
           END-EVALUATE
           PERFORM 370-Update-Table-Compte 
           .

       370-Update-Table-Compte.
      **********************************************************
      *  This routine should close file(s)
           EXEC SQL
              UPDATE TBCOMPTE
              SET SOLDE=:DGC-SOLDE,
                  DDMVT=:DGC-DDMVT,
                  DDMAJ=CURRENT DATE,
                  HDMAJ=CURRENT TIME
              WHERE COMPTE=:WS-COMPTE
           END-EXEC

           PERFORM D550-CHECKSQL
           .

       999-CFILES.
      **********************************************************
      *  This routine should close file(s)
           CLOSE FILEIN
           .

       D550-CHECKSQL.
      **********************************************************
      *  Check SQLCODE
           EVALUATE SQLCODE
              WHEN ZERO
                 CONTINUE
              WHEN +100
                 DISPLAY 'END QUERY'
              WHEN OTHER
                 PERFORM D320-DBERROR
           END-EVALUATE
           .
   
       D320-DBERROR.
      **********************************************************
      *  DB2 Error Handling Routine
           DISPLAY '*************************************************'
           DISPLAY '****       E R R O R M E S S A G E S         ****'
           DISPLAY '*************************************************'
           DISPLAY '* Problem in paragraph: ' SQLERRML 
           DISPLAY '* Problem-msg: ' SQLERRMC 
           DISPLAY '*'
           DISPLAY '* SQLCODE: ' SQLCODE
           DISPLAY '*************************************************'
           STOP RUN
           .

       D020-ERROR.
      **********************************************************
      *  File Error
           DISPLAY '*************************************************'
           DISPLAY '****       E R R O R M E S S A G E S         ****'
           DISPLAY '*************************************************'
           DISPLAY '* Problem in File data.                          '
           DISPLAY '*************************************************'
           STOP RUN
           .