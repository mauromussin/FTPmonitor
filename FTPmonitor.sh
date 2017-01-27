#!/bin/bash
#
## monitoraggio dei siti FTP per ritardo dati
## MM giugno 2016, ripreso gennaio 2017
## lo script elenca i file nel sito ftp di arpa, controlla quanti sono presenti nelle directory attese, logga il risultato
## pensato per girare su base oraria, al minuto 59 sarebbe meglio
## codici di log:
##    -> se ho 0 file : ERR (non posso non avere file!)
##    -> se ho 6 file : NOTICE (si presume che sia la configurazione standard, un pacchetto ogni 10')
##    -> se ho un numero diverso : WARNING (la considero una anomalia)
## prerequisiti rsyslog configurato in maniera corretta (vd. /etc/rsyslog.conf) 
##              file elenco_staz in data con l'elenco stazioni
## output in due file separati per GPRS e Supervisore. I file vengono distrutti prima di ogni run
#
### variabili
FTP_CAE_ID='remcae'
FTP_CAE_pwd='usr2010cae'
MYDIR='/home/meteo/script/FTPmonitor/'
#lftp -f data/FTP_command_file_CAE
#lftp -f data/FTP_command_file_Adda
#
## inizializzazioni
# data di oggi
DATAOGGI=$(date +"%Y%m%d")
ORAOGGI=$(date +"%H")
readarray STAZIONI < ${MYDIR}data/elenco_staz
N=${STAZIONI[@]}
if ! rm ${MYDIR}myOutputFile_*;then exit 1;fi
#apro la connessione e listo in un unico passaggio
for i in ${STAZIONI[@]}; do
    lftp -c "open -u $FTP_CAE_ID,$FTP_CAE_pwd ftp.arpalombardia.it;ls -l Supervisore/$i/$DATAOGGI/SP*_$DATAOGGI_$ORAOGGI*.txt" >> ${MYDIR}myOutputFile_Supervisore
    lftp -c "open -u $FTP_CAE_ID,$FTP_CAE_pwd ftp.arpalombardia.it;ls -l GPRS/$i/$DATAOGGI/SP*_$DATAOGGI_$ORAOGGI*.txt" >> ${MYDIR}myOutputFile_GPRS
done
for i in ${STAZIONI[@]}; do
 QUANTI=$(grep -c $i ${MYDIR}myOutputFile_GPRS)
 QUANTI_SUP=$(grep -c $i ${MYDIR}myOutputFile_Supervisore)
 echo "Stazione $i ora $ORAOGGI con $QUANTI file"
 case $QUANTI in
  0)  ERRORE="err"
  ;;
  6)  ERRORE="notice"
  ;;
  *)
  ERRORE="warning"
 esac
 logger -is -p user.$ERRORE "Stazione $i ora $ORAOGGI con $QUANTI file in GPRS" -t "FTPmonitor"
 case $QUANTI_SUP in
  0)  ERRORE="err"
  ;;
  6)  ERRORE="notice"
  ;;
  *)
  ERRORE="warning"
 esac
 logger -is -p user.$ERRORE "Stazione $i ora $ORAOGGI con $QUANTI_SUP file in Supervisore" -t "FTPmonitor"
 if [ "$QUANTI" -eq 0 ] && [ "$QUANTI_SUP" -eq 0 ]
    then logger -is -p user.crit "STAZIONE $i in data $DATAOGGI e ora $ORAOGGI senza dati!" -t "FTPmonitor"
 fi
done
exit 0
