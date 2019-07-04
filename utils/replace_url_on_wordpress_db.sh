#!/bin/bash
#
# Autor: broobe. web + mobile development - https://broobe.com
# Script Name: Broobe Utils Scripts
# Version: 2.9
#############################################################################

### Checking some things...
if [[ -z "${MUSER}" ]]; then
  MUSER=$(whiptail --title "MySQL user with full Privileges" --inputbox "Please enter a MySQL user with full Privileges" 10 60 3>&1 1>&2 2>&3)
fi

if [[ -z "${MPASS}" ]]; then
  MPASS=$(whiptail --title "MySQL user password" --inputbox "Please insert the MySQL user Password" 10 60 3>&1 1>&2 2>&3)
fi

echo " > Starting replace_url_on_wordpress_db script ...">> $LOG

if [[ -z "${DB_PREFIX}" ]]; then
  DB_PREFIX=$(whiptail --title "WordPress DB Prefix" --inputbox "Please insert the WordPress Database Prefix. Example: wp_" 10 60 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    echo "Setting DB_PREFIX="${DB_PREFIX} >> $LOG
  else
    exit 1
  fi
fi

if [[ -z "${TARGET_DB}" ]]; then
  DBS="$(${MYSQL} -u ${MUSER} -p${MPASS} -Bse 'show databases')"
  CHOSEN_DB=$(whiptail --title "REPLACING URLS ON WP DATABASE" --menu "Chose a Database to work with" 20 78 10 `for x in ${DBS}; do echo "$x [DB]"; done` 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    echo "Setting CHOSEN_DB="${CHOSEN_DB} >> $LOG
  else
    exit 1
  fi

else
  CHOSEN_DB=${TARGET_DB};

fi

if [[ -z "${existing_URL}" ]]; then
  existing_URL=$(whiptail --title "URL TO CHANGE" --inputbox "Insert the URL you want to change, including http:// or https://" 10 60 3>&1 1>&2 2>&3)
  exitstatus=$?

  echo "Setting existing_URL="${existing_URL} >> $LOG

  if [ ${exitstatus} = 0 ]; then

    if [[ -z "${new_URL}" ]]; then
      new_URL=$(whiptail --title "THE NEW URL" --inputbox "Insert the new URL , including http:// or https://" 10 60 3>&1 1>&2 2>&3)
      exitstatus=$?

      if [ ${exitstatus} = 0 ]; then

        echo "Setting new_URL="${new_URL} >> $LOG

        echo "Executing mysqldump of ${CHOSEN_DB} before replace urls ...">> $LOG
        ${MYSQLDUMP} -u ${MUSER} --password=${MPASS} ${CHOSEN_DB} > ${CHOSEN_DB}_bk_before_replace_urls.sql

        echo "Database backup created: ${CHOSEN_DB}_bk_before_replace_urls.sql">> $LOG
        echo -e ${YELLOW}" > Database backup created: ${CHOSEN_DB}_bk_before_replace_urls.sql"${ENDCOLOR}

        # Queries
        SQL0="USE ${CHOSEN_DB};"
        SQL1="UPDATE ${DB_PREFIX}options SET option_value = replace(option_value, '${existing_URL}', '${new_URL}') WHERE option_name = 'home' OR option_name = 'siteurl';"
        SQL2="UPDATE ${DB_PREFIX}posts SET post_content = replace(post_content, '${existing_URL}', '${new_URL}');"
        SQL3="UPDATE ${DB_PREFIX}posts SET guid = replace(guid, '${existing_URL}', '${new_URL}');"
        SQL4="UPDATE ${DB_PREFIX}postmeta SET meta_value = replace(meta_value,'${existing_URL}','${new_URL}');"
        SQL5="UPDATE ${DB_PREFIX}usermeta SET meta_value = replace(meta_value, '${existing_URL}','${new_URL}');"
        SQL6="UPDATE ${DB_PREFIX}links SET link_url = replace(link_url, '${existing_URL}','${new_URL}');"
        SQL7="UPDATE ${DB_PREFIX}comments SET comment_content = replace(comment_content , '${existing_URL}','${new_URL}');"

        echo "Replacing URLs in database ${PROJECT_NAME} ...">> $LOG
        echo -e ${YELLOW}" > Replacing URLs in database ${PROJECT_NAME} ..."${ENDCOLOR}

        ${MYSQL} -u ${MUSER} --password=${MPASS} -e "${SQL0}${SQL1}${SQL2}${SQL3}${SQL4}${SQL5}${SQL6}${SQL7}"

        echo " > DONE">> $LOG
        echo -e ${GREEN}" > DONE"${ENDCOLOR}

      fi

    fi

  fi

fi