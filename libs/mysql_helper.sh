#!/bin/bash
#
# Autor: broobe. web + mobile development - https://broobe.com
# Script Name: Broobe Utils Scripts
# Version: 3.0
################################################################################
#
# Ref: https://github.com/nelson6e65/bash-mysql-helper/blob/master/src/main.sh
#

source ${SFOLDER}/libs/commons.sh

################################################################################

count_dabases() {

    # $1 = ${DBS}

    DBS=$1

    TOTAL_DBS=0
    for db in ${DBS}; do
        if [[ $DB_BL != *"${db}"* ]]; then
            TOTAL_DBS=$((TOTAL_DBS + 1))
        fi
    done

    # return
    echo $TOTAL_DBS
}

#mysql_user_create() {
#
#    # TODO: Checkear si el usuario ya existe
#    # TODO: el GRANT USAGE debería ser otro método
#
#    # $1 = USER (${PROJECT_NAME}_user)
#
#    DB_USER=$1
#
#    SQL1="CREATE USER '${DB_USER}'@'localhost';"
#    SQL2="GRANT USAGE on *.* to '${DB_USER}'@'localhost';"
#    SQL3="FLUSH PRIVILEGES;"
#
#    echo "Creating ${DB_USER} user in MySQL ..." >>$LOG
#    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}${SQL2}${SQL3}" >>$LOG
#
#    if [ $? -eq 0 ]; then
#        echo " > DONE!" >>$LOG
#        echo -e ${GREN}" > DONE!"${ENDCOLOR}
#    else
#        echo " > Something went wrong!" >>$LOG
#        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
#        exit 1
#    fi
#
#}

mysql_user_create() {

    # $1 = ${DB_USER}
    # $2 = ${DB_PASS}

    DB_USER=$1
    DB_PASS=$2

    if [[ -z ${DB_PASS} || ${DB_PASS} == "" ]]; then
        SQL1="CREATE USER '${DB_USER}'@'localhost';"

    else
        SQL1="CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"

    fi

    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}" >>$LOG

    if [ $? -eq 0 ]; then
        #return o if done
        return 0

    else
        #return 1 if something went wrong
        return 1

    fi

}

mysql_user_delete() {

    # $1 = ${USER_DB}

    USER_DB=$1

    SQL1="DROP USER '${USER_DB}'@'localhost';"
    SQL2="FLUSH PRIVILEGES;"

    echo "Deleting ${USER_DB} user in MySQL ..." >>$LOG
    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}${SQL2}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > DONE!" >>$LOG
        echo -e ${GREN}" > DONE!"${ENDCOLOR}
    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
        exit 1
    fi

}

mysql_user_psw_change() {

    # $1 = ${USER_DB}
    # $2 = ${USER_DB_PSW}

    USER_DB=$1
    USER_DB_PSW=$2

    SQL1="ALTER USER '${USER_DB}'@'localhost' IDENTIFIED BY '${USER_DB_PSW}';"
    SQL2="FLUSH PRIVILEGES;"

    echo "Deleting ${USER_DB} user in MySQL ..." >>$LOG
    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}${SQL2}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > DONE!" >>$LOG
        echo -e ${GREN}" > DONE!"${ENDCOLOR}
    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
        exit 1
    fi

}

mysql_user_grant_privileges() {

    # $1 = ${USER}
    # $2 = ${DB}

    DB_USER=$1
    DB_TARGET=$2

    SQL1="GRANT ALL PRIVILEGES ON ${DB_TARGET}.* TO '${DB_USER}'@'localhost';"
    SQL2="FLUSH PRIVILEGES;"

    echo "Granting privileges to ${DB_USER} on ${DB_TARGET} database in MySQL ..." >>$LOG
    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}${SQL2}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > DONE!" >>$LOG
        echo -e ${GREN}" > DONE!"${ENDCOLOR}

        return 0

    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}

        return 1

    fi

}

mysql_user_exists() {

    # $1 = ${DB_USER}
    # $2 = ${DB_PASS}

    DB_USER=$1
    DB_PASS=$2

    if ! echo "SELECT COUNT(*) FROM mysql.user WHERE user = '${DB_USER}';" | mysql -u ${MUSER} --password=${MPASS} | grep 1 &>/dev/null; then

        #return 0 if user don't exists
        return 0

    else

        #return 1 if user already exists
        return 1

    fi

}

mysql_database_create() {

    # $1 = ${DB}

    DB=$1

    SQL1="CREATE DATABASE IF NOT EXISTS ${DB};"

    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > DONE!" >>$LOG
        echo -e ${GREN}" > DONE!"${ENDCOLOR}
    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
        exit 1
    fi

}

mysql_database_drop() {

    # $1 = ${DB}

    DB=$1

    SQL1="DROP DATABASE ${DB};"

    echo "Droping database ${DB} ..." >>$LOG
    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > Database ${DB} deleted!" >>$LOG
        echo -e ${GREEN}" > Database ${DB} deleted!"${ENDCOLOR}
    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
        exit 1
    fi

}

mysql_database_import() {

    # $1 = ${DATABASE}
    # $2 = ${DUMP_FILE}

    DB_NAME=$1
    DUMP_FILE=$2

    echo -e ${YELLOW}" > Importing dump file ${DUMP_FILE} into database: ${DB_NAME} ..."${ENDCOLOR}
    echo " > Importing dump file ${DUMP_FILE} into database: ${DB_NAME} ..." >>$LOG

    pv ${DUMP_FILE} | mysql -f -u ${MUSER} -p ${MPASS} -f -D ${DB_NAME}

    if [ $? -eq 0 ]; then
        echo " > Import database ${DB_NAME} OK!" >>$LOG
        echo -e ${GREEN}" > Import database ${DB_NAME} OK!"${ENDCOLOR}

    else
        echo " > Import database ${DB_NAME} failed!" >>$LOG
        echo -e ${RED}" > Import database ${DB_NAME} failed!"${ENDCOLOR}

        exit 1

    fi

}

#mysql_database_check() {
#
#    # $1 = ${DATABASE}
#
#    # TODO: check if database exists
#
#}

mysql_database_export() {

    # $1 = ${DATABASE}
    # $2 = ${DUMP_FILE}

    DATABASE=$1
    DUMP_FILE=$2

    echo -e ${YELLOW}" > Exporting database ${DATABASE} into dump file ${DUMP_FILE} ..."${ENDCOLOR}
    echo " > Exporting database ${DATABASE} into dump file ${DUMP_FILE} ..." >>$LOG
    mysqldump -u ${MUSER} -p${MPASS} ${DATABASE} >${DUMP_FILE}

    if [ $? -eq 0 ]; then
        echo " > DB ${DATABASE} exported successfully!" >>$LOG
        echo -e ${GREEN}" > DB ${DATABASE} exported successfully!"${ENDCOLOR}
    else
        echo " > DB ${DATABASE} export failed!" >>$LOG
        echo -e ${RED}" > DB ${DATABASE} export failed!"${ENDCOLOR}
        exit 1
    fi

}

# TODO: PROBAR ESTO Y RETORNAR VARIABLE
mysql_get_disk_usage() {

    SQL1="SELECT SUM( data_length + index_length ) / 1024 / 1024 'Size'
        FROM information_schema.TABLES WHERE table_schema='$1'"

    mysql -u ${MUSER} -p${MPASS} -e "${SQL1}" >>$LOG

    if [ $? -eq 0 ]; then
        echo " > DONE!" >>$LOG
        echo -e ${GREN}" > DONE!"${ENDCOLOR}
    else
        echo " > Something went wrong!" >>$LOG
        echo -e ${RED}" > Something went wrong!"${ENDCOLOR}
        exit 1
    fi

}