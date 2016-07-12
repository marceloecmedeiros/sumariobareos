#!/bin/bash

#E-mail de destino
admin="meuemail@minhaempresa.com.br"

#Altere se necessário
mysqlbin="/usr/bin/mysql"
bcbin="/usr/sbin/bconsole"
bcconfig="/etc/bareos/bconsole.conf"
db="bareos"

# Não retire o '-u' e o '-p' do usuário e senha. Os exemplos abaixo são para usuário: bareos e senha: bareos.
dbuser="-ubareos"
dbpass="-pbareos"

#Pode utilizar hostname ou IP
server="hostname_servidor"

# --------------------------------------------------
# Não modifique nada nas linhas abaixo
# --------------------------------------------------

hist=${1}
if [ -z ${hist} ]; then
        echo "SINTAXE:"
        echo "mailbareos.sh <intervalo em horas>"
        echo "Exemplo:"
        echo "mailbareos.sh 24"
        exit
fi

subject="[BAREOS BACKUP]: Resumo dos Backups das ultimas ${1} horas"

header="
<html><head><title>Relatorio de Backup das ultimas ${1} horas</title></head><body style=\"font-size:12px\"><pre>
Relatorio de Backup das ultimas ${1} horas
--------------------------------------

JobId        Name                  Start Time            Stop Time       Level  Status   Files       Bytes
-----   ---------------------  -------------------  -------------------  -----  ------  --------  -----------
"

msg=`echo "SELECT JobId, Name, StartTime, EndTime, Level, JobStatus, JobFiles, JobBytes \
                FROM Job \
                WHERE Type='B' \
                AND RealEndTime >=  DATE_ADD(NOW(), INTERVAL -${hist} HOUR) \
                ORDER BY JobId;" \
| ${mysqlbin} ${dbuser} ${dbpass} ${db} \
| sed '/^JobId/d' \
| awk '{ printf("%-7s %-22s %s %-9s %s %-9s %5s %7s %9d %9.2f GB\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10/(1024*1024*1024));}'`
footer="</pre></body></html>"
/etc/bareos/zmail.sdx "${admin}" "${subject}" "${header}${msg}${footer}"

