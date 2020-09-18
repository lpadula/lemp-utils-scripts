#!/bin/bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.2
################################################################################

# shellcheck source=${SFOLDER}/libs/mysql_helper.sh
source "${SFOLDER}/libs/mysql_helper.sh"
# shellcheck source=${SFOLDER}/libs/wpcli_helper.sh
source "${SFOLDER}/libs/wpcli_helper.sh"
# shellcheck source=${SFOLDER}/libs/wordpress_helper.sh
source "${SFOLDER}/libs/wordpress_helper.sh"
# shellcheck source=${SFOLDER}/libs/certbot_helper.sh
source "${SFOLDER}/libs/certbot_helper.sh"
# shellcheck source=${SFOLDER}/libs/nginx_helper.sh
source "${SFOLDER}/libs/nginx_helper.sh"
# shellcheck source=${SFOLDER}/libs/cloudflare_helper.sh
source "${SFOLDER}/libs/cloudflare_helper.sh"
# shellcheck source=${SFOLDER}/libs/mail_notification_helper.sh
source "${SFOLDER}/libs/mail_notification_helper.sh"
# shellcheck source=${SFOLDER}/libs/telegram_notification_helper.sh
source "${SFOLDER}/libs/telegram_notification_helper.sh"

################################################################################

restore_menu () {

  local restore_options chosen_restore_options

  restore_options="01) RESTORE-FROM-DROPBOX 02) RESTORE-FROM-URL"
  chosen_restore_options=$(whiptail --title "RESTORE TYPE" --menu " " 20 78 10 $(for x in ${restore_options}; do echo "$x"; done) 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    if [[ ${chosen_restore_options} == *"01"* ]]; then
      server_selection_restore_menu

    elif [[ ${chosen_restore_options} == *"02"* ]]; then
      # shellcheck source=${SFOLDER}/utils/wordpress_restore_from_source.sh
      source "${SFOLDER}/utils/wordpress_restore_from_source.sh"

    fi

  fi

  main_menu

}

server_selection_restore_menu () {

  SITES_F="site"
  CONFIG_F="configs"
  DBS_F="database"

  local dropbox_server_list chosen_server
  
  # Select SERVER
  dropbox_server_list=$(${DROPBOX_UPLOADER} -hq list "/")
  chosen_server=$(whiptail --title "RESTORE BACKUP" --menu "Choose Server to work with" 20 78 10 $(for x in ${dropbox_server_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    dropbox_type_list=$(${DROPBOX_UPLOADER} -hq list "${chosen_server}")
    dropbox_type_list='project '${dropbox_type_list}

    # Select backup type
    select_restore_type_from_dropbox "${chosen_server}" "${dropbox_type_list}"

  else
    restore_menu
    
  fi

restore_menu

}

#This is executed if we want to restore a file backup on directory with the same name
make_temp_files_backup() {

  # $1 = Folder to backup

  local folder_to_backup=$1

  mkdir "${SFOLDER}/tmp/old_backup"
  mv "${folder_to_backup}" "${SFOLDER}/tmp/old_backup"

  log_event "info" "Temp backup completed and stored here: ${SFOLDER}/tmp/old_backup" "false"
  display --indent 2 --text "- Creating backup on temp directory" --result "DONE" --color GREEN

}

restore_database_backup() {

  #$1 = ${project_name}
  #$2 = ${project_state}
  #$3 = ${project_backup}

  local project_name=$1
  local project_state=$2
  local project_backup=$3

  local db_name db_exists user_db_exists db_pass

  log_event "info" "Running restore_database_backup for ${project_backup} DB ${ENDCOLOR}" "false"
  log_subsection "Database Restore"

  db_name="${project_name}_${project_state}"

  # Check if database already exists
  mysql_database_exists "${db_name}"
  
  db_exists=$?
  if [[ ${db_exists} -eq 1 ]]; then  
    
    mysql_database_create "${db_name}"

  else

    log_event "info" "MySQL database ${db_name} already exists" "false"
    mysql_database_export "${db_name}" "${db_name}_bk_before_restore.sql"

  fi

  # Restore database
  project_backup="${project_backup%%.*}.sql"
  mysql_database_import "${project_name}_${project_state}" "${project_backup}"

  log_event "info" "Cleanning temp files ..." "fañse"
  
  rm "${project_backup%%.*}.sql"
  rm "${project_backup%%.*}.tar.bz2"
  rm "${project_backup}"

  display --indent 2 --text "- Cleanning temp files" --result "DONE" --color GREEN

  log_event "success" "restore_database_backup done" "false"

}

download_and_restore_config_files_from_dropbox(){

  #$1 = ${dropbox_chosen_type_path}
  #$2 = ${dropbox_project_list}

  local dropbox_chosen_type_path=$1
  local dropbox_project_list=$2

  local chosen_config_type dropbox_bk_list chosen_config_bk

  # Select config backup type
  chosen_config_type=$(whiptail --title "RESTORE CONFIGS BACKUPS" --menu "Choose a config backup type." 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    #Restore from Dropbox
    dropbox_bk_list=$($DROPBOX_UPLOADER -hq list "${dropbox_chosen_type_path}/${chosen_config_type}")
  fi

  chosen_config_bk=$(whiptail --title "RESTORE CONFIGS BACKUPS" --menu "Choose a config backup file to restore." 20 78 10 $(for x in ${dropbox_bk_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    cd "${SFOLDER}/tmp"

    #echo " > Downloading from Dropbox ${dropbox_chosen_type_path}/${chosen_config_type}/${chosen_config_bk} ..." >>$LOG
    ${DROPBOX_UPLOADER} download "${dropbox_chosen_type_path}/${chosen_config_type}/${chosen_config_bk}"

    # Restore files
    mkdir "${chosen_config_type}"
    mv "${chosen_config_bk}" "${chosen_config_type}"
    cd "${chosen_config_type}"

    log_event "info" "Uncompressing ${chosen_config_bk} ..." "false"
    
    pv "${chosen_config_bk}" | tar xp -C "${SFOLDER}/tmp/${chosen_config_type}" --use-compress-program=lbzip2

    if [[ "${chosen_config_bk}" == *"nginx"* ]]; then

      restore_nginx_site_files ""

    fi
    if [[ "${CHOSEN_CONFIG}" == *"mysql"* ]]; then
      echo -e "${B_RED} > TODO: RESTORE MYSQL CONFIG ...${ENDCOLOR}">&2

    fi
    if [[ "${CHOSEN_CONFIG}" == *"php"* ]]; then
      echo -e "${B_RED} > TODO: RESTORE PHP CONFIG ...${ENDCOLOR}">&2

    fi
    if [[ "${CHOSEN_CONFIG}" == *"letsencrypt"* ]]; then
      echo -e "${B_RED} > TODO: RESTORE LETSENCRYPT CONFIG ...${ENDCOLOR}">&2
      #restore_letsencrypt_site_files "" ""

    fi

    # TODO: ask for remove tmp files
    #echo " > Removing ${SFOLDER}/tmp/${chosen_type} ..." >>$LOG
    #echo -e ${GREEN}" > Removing ${SFOLDER}/tmp/${chosen_type} ..."${ENDCOLOR}
    #rm -R ${SFOLDER}/tmp/${chosen_type}

  fi

}

restore_nginx_site_files() {

  # $1 = ${domain} optional
  # $2 = ${date} optional

  local domain=$1
  local date=$2

  local bk_file bk_to_download filename to_restore dropbox_output

  bk_file="nginx-configs-files-${date}.tar.bz2"
  bk_to_download="${chosen_server}/configs/nginx/${bk_file}"

  log_subsection "Nginx Server Configuration Restore"

  log_event "info" "Running dropbox_uploader.sh download ${bk_to_download} ..." "false"
  dropbox_output=$(${DROPBOX_UPLOADER} download "${bk_to_download}" 1>&2)
  display --indent 2 --text "- Dropbox backup downloaded" --result "DONE" --color GREEN

  # Extract tar.bz2 with lbzip2
  mkdir "${SFOLDER}/tmp/nginx"
  extract "${bk_file}" "${SFOLDER}/tmp/nginx" "lbzip2"

  # TODO: if nginx is installed, ask if nginx.conf must be replace

  # Checking if default nginx folder exists
  if [[ -n "${WSERVER}" ]]; then

    log_event "info" "Folder ${WSERVER} exists ... OK" "false"

    if [[ -z "${domain}" ]]; then

      startdir="${SFOLDER}/tmp/nginx/sites-available"
      file_browser "$menutitle" "$startdir"

      to_restore=${filepath}"/"${filename}
      log_event "info" "File to restore: ${to_restore} ..." "false"

    else

      to_restore="${SFOLDER}/tmp/nginx/sites-available/${domain}"
      filename=${domain}

      log_event "info" "File to restore: ${to_restore} ..." "false"

    fi    

    if [[ -f "${WSERVER}/sites-available/${filename}" ]]; then

      log_event "info" "File ${WSERVER}/sites-available/${filename} already exists. Making a backup file ..." "false"
      mv "${WSERVER}/sites-available/${filename}" "${WSERVER}/sites-available/${filename}_bk"

      display --indent 2 --text "- Making backup of existing config" --result "DONE" --color GREEN

    fi


    log_event "info" "Restoring nginx configuration from backup: ${filename}" "false"
    
    cp "${to_restore}" "${WSERVER}/sites-available/${filename}"

    ln -s "${WSERVER}/sites-available/${filename}" "${WSERVER}/sites-enabled/${filename}"

    display --indent 2 --text "- Restoring Nginx server config" --result "DONE" --color GREEN

    nginx_server_change_phpv "${domain}" ""

    log_event "info" "Reloading webserver ..." "false"
    service nginx reload

    display --indent 2 --text "- Reloading nginx" --result "DONE" --color GREEN

  else

    log_event "error" "/etc/nginx/sites-available NOT exist... Skipping!" "false"
    #echo "ERROR: nginx main dir is not present!"

  fi

}

restore_letsencrypt_site_files() {

  # $1 = ${domain}
  # $2 = ${date}

  local domain=$1
  local date=$2

  local bk_file bk_to_download

  bk_file="letsencrypt-configs-files-${date}.tar.bz2"
  bk_to_download="${chosen_server}/configs/letsencrypt/${bk_file}"

  log_event "info" "Running dropbox_uploader.sh download ${bk_to_download}" "false"
  ${DROPBOX_UPLOADER} download "${bk_to_download}"

  # Extract tar.bz2 with lbzip2
  log_event "info" "Extracting ${bk_file} on ${SFOLDER}/tmp/" "false"

  mkdir "${SFOLDER}/tmp/letsencrypt"
  extract "${bk_file}" "${SFOLDER}/tmp/letsencrypt" "lbzip2"

  # Creating directories
  mkdir "/etc/letsencrypt/archive/"
  mkdir "/etc/letsencrypt/live/"
  mkdir "/etc/letsencrypt/archive/${domain}"
  mkdir "/etc/letsencrypt/live/${domain}"

  # Check if file exist
  if [ ! -f "/etc/letsencrypt/options-ssl-nginx.conf" ]; then
    cp -r "${SFOLDER}/tmp/letsencrypt/options-ssl-nginx.conf" "/etc/letsencrypt/"

  fi
  if [ ! -f "/etc/letsencrypt/ssl-dhparams.pem" ]; then
    cp -r "${SFOLDER}/tmp/letsencrypt/ssl-dhparams.pem" "/etc/letsencrypt/"
    
  fi

  # TODO: check www.${domain} too
  cp -r "${SFOLDER}/tmp/letsencrypt/archive/${domain}" "/etc/letsencrypt/archive/"
  cp -r "${SFOLDER}/tmp/letsencrypt/live/${domain}" "/etc/letsencrypt/live/"

}

restore_site_files() {

  # $1 = ${chosen_domain} Here, should match with PROJECT_DOMAIN

  local domain=$1

  local actual_folder folder_to_install chosen_domain

  chosen_domain=$(whiptail --title "Project Name" --inputbox "Want to change the project's domain? Default:" 10 60 "${domain}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    # Log
    log_subsection "Site Files Restore"
    log_event "info" "Setting chosen_domain=${chosen_domain}" "false"
    display --indent 2 --text "- Selecting project domain" --result "DONE" --color GREEN

    # New tmp folder
    project_tmp_folder="${SFOLDER}/tmp/${chosen_domain}"

    # Renaming
    mv "${SFOLDER}/tmp/${domain}" "${project_tmp_folder}"
      
    # Ask folder to install
    folder_to_install=$(ask_folder_to_install_sites "${SITES}")

    # New destination directory
    actual_folder="${folder_to_install}/${chosen_domain}"

    # Check if destination folder exist
    if [ -d "${actual_folder}" ]; then

      log_event "warning" "${actual_folder} exist. Let's make a Backup ..." "false"

      make_temp_files_backup "${actual_folder}"

    fi

    # Restore files
    log_event "info" "Moving files from ${project_tmp_folder} to ${folder_to_install} ..." "false"

    display --indent 2 --text "- Restoring backup files"
    
    mv "${project_tmp_folder}" "${folder_to_install}"

    clear_last_line
    display --indent 2 --text "- Restoring backup files" --result "DONE" --color GREEN

    install_path=$(search_wp_config "${actual_folder}")

    log_event "info" "install_path=${install_path}" "false"

    if [ -d "${install_path}" ]; then

      log_event "info" "Wordpress intallation found on: ${install_path}" "false"

      wp_change_permissions "${install_path}" 

      log_event "info" "Files backup restored on: ${install_path}" "false"

      # Return
      echo "${install_path}"
    
    fi

  else

    return 1

  fi

}

select_restore_type_from_dropbox() {
  
  # TODO: check project type (WP? Laravel? other?)
  # ask for directory_browser if apply
  # add credentials on external txt and send email

  # $1 = chosen_server
  # $2 = dropbox_type_list

  local chosen_server=$1
  local dropbox_type_list=$2

  local chosen_type dropbox_chosen_type_path dropbox_project_list domain db_project_name bk_to_dowload folder_to_install project_site

  chosen_type=$(whiptail --title "RESTORE FROM BACKUP" --menu "Choose a backup type. You can choose restore an entire project or only site files, database or config." 20 78 10 $(for x in ${dropbox_type_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then

    dropbox_chosen_type_path="${chosen_server}/${chosen_type}"

    if [[ ${chosen_type} == "project" ]]; then

      project_restore "${chosen_server}"

    elif [[ ${chosen_type} != "project" ]]; then

      log_section "Restore ${chosen_type} Backup"

      dropbox_project_list=$(${DROPBOX_UPLOADER} -hq list "${dropbox_chosen_type_path}")
      
      if [[ ${chosen_type} == *"$CONFIG_F"* ]]; then

        download_and_restore_config_files_from_dropbox "${dropbox_chosen_type_path}" "${dropbox_project_list}"

      else # DB or SITE

        # Select Project
        chosen_project=$(whiptail --title "RESTORE BACKUP" --menu "Choose Backup Project" 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
          DROPBOX_CHOSEN_BACKUP_PATH="${dropbox_chosen_type_path}/${chosen_project}"
          DROPBOX_BACKUP_LIST=$(${DROPBOX_UPLOADER} -hq list "${DROPBOX_CHOSEN_BACKUP_PATH}")

        fi
        # Select Backup File
        CHOSEN_BACKUP_TO_RESTORE=$(whiptail --title "RESTORE BACKUP" --menu "Choose Backup to Download" 20 78 10 $(for x in ${DROPBOX_BACKUP_LIST}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then

          cd "${SFOLDER}/tmp"

          bk_to_dowload="${chosen_server}/${chosen_type}/${chosen_project}/${CHOSEN_BACKUP_TO_RESTORE}"

          log_event "info" "Running dropbox_uploader.sh download ${bk_to_dowload}" "false"

          ${DROPBOX_UPLOADER} download "${bk_to_dowload}"

          log_event "info" "Uncompressing ${CHOSEN_BACKUP_TO_RESTORE}" "false"

          pv "${CHOSEN_BACKUP_TO_RESTORE}" | tar xp -C "${SFOLDER}/tmp/" --use-compress-program=lbzip2

          if [[ ${chosen_type} == *"$DBS_F"* ]]; then

            # Asking project state with suggested actual state
            suffix="$(cut -d'_' -f2 <<<"${chosen_project}")"
            project_state=$(ask_project_state "${suffix}")

            # Extract project_name (its removes last part of db name with "_" char)
            project_name=${chosen_project%"_$suffix"}

            project_name=$(whiptail --title "Project Name" --inputbox "Want to change the project name?" 10 60 "${project_name}" 3>&1 1>&2 2>&3)
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
              log_event "info" "Setting project_name=${project_name}" "false"

            else
              return 1

            fi

            # Running mysql_name_sanitize $for project_name
            db_project_name=$(mysql_name_sanitize "${project_name}")
            
            # Restore database
            restore_database_backup "${db_project_name}" "${project_state}" "${CHOSEN_BACKUP_TO_RESTORE}"

            db_user="${db_project_name}_user"

            # Check if user database already exists
            mysql_user_exists "${db_user}"
            
            user_db_exists=$?
            if [[ ${user_db_exists} -eq 0 ]]; then

              # Passw generator
              db_pass=$(openssl rand -hex 12)

              mysql_user_create "${db_user}" "${db_pass}"

            else
              log_event "warning" "MySQL user ${db_user} already exists" "false"
              whiptail_event "WARNING" "MySQL user ${db_user} already exists. Please after the script ends, check project configuration files."

            fi

            # Grant privileges to database user
            mysql_user_grant_privileges "${db_user}" "${db_name}"

            # TODO: ask if want to change project db parameters and make cloudflare changes

            # TODO: check project type (WP, Laravel, etc)

            folder_to_install=$(ask_folder_to_install_sites "${SITES}")

            startdir=${folder_to_install}
            menutitle="Site Selection Menu"
            directory_browser "$menutitle" "$startdir"
            project_site=$filepath"/"$filename

            install_path=$(search_wp_config "${folder_to_install}/${filename}")

            # TODO: search_wp_config could be an array of dir paths, need to check that
            if [ "${install_path}" != "" ]; then

              log_event "info" "WordPress installation found: ${project_site}/${install_path}" "false"

              # Change wp-config.php database parameters
              wp_update_wpconfig "${install_path}" "${project_name}" "${project_state}" "${DB_PASS}"

              # TODO: change the secret encryption keys

            else

              log_event "error" "WordPress installation not found!" "false"

            fi

            #TODO: ask if want to change IP from Cloudflare then ask for Cloudflare Root Domain

            # Asume that project main folder name is the project's domain, removing "/" char
            #domain="${filename::-1}"
            
            # Only for Cloudflare API
            #suggested_root_domain=${domain#[[:alpha:]]*.}
            #suggested_root_domain=${domain}

            #root_domain=$(cloudflare_ask_root_domain "${suggested_root_domain}")

            #cloudflare_change_a_record "${root_domain}" "${domain}"
            
            # HTTPS with Certbot
            #certbot_helper_installer_menu "${MAILA}" "${domain}"

          else # site

            # Here, for convention, chosen_project should be CHOSEN_DOMAIN... 
            # Only for better code reading, i assign this new var:
            chosen_domain=${chosen_project}
            restore_site_files "${chosen_domain}"

          fi
        
        fi

      fi

    fi

  fi

}

project_restore() {

  # $1 = ${chosen_server}

  local chosen_server=$1

  local dropbox_project_list chosen_project dropbox_chosen_backup_path dropbox_backup_list bk_to_dowload chosen_backup_to_restore db_to_download

  log_section "Restore Project Backup"

  dropbox_project_list=$(${DROPBOX_UPLOADER} -hq list "${chosen_server}/site")

  # Select Project
  chosen_project=$(whiptail --title "RESTORE PROJECT BACKUP" --menu "Choose Backup Project" 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    dropbox_chosen_backup_path="${chosen_server}/site/${chosen_project}"
    dropbox_backup_list=$(${DROPBOX_UPLOADER} -hq list "${dropbox_chosen_backup_path}")
  
  else

    display --indent 2 --text "- Restore project backup" --result "SKIPPED" --color YELLOW
    return 1

  fi
  # Select Backup File
  chosen_backup_to_restore=$(whiptail --title "RESTORE PROJECT BACKUP" --menu "Choose Backup to Download" 20 78 10 $(for x in ${dropbox_backup_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ ${exitstatus} -eq 0 ]; then

    display --indent 2 --text "- Selecting project backup" --result "DONE" --color GREEN
    display --indent 4 --text "Backup selected: ${chosen_backup_to_restore}"

    cd "${SFOLDER}/tmp"

    # Download backup
    bk_to_dowload="${chosen_server}/site/${chosen_project}/${chosen_backup_to_restore}"
    log_event "info" "Running dropbox_uploader.sh download ${bk_to_dowload}" "false"
    display --indent 2 --text "- Downloading backup from dropbox"
    dropbox_output=$(${DROPBOX_UPLOADER} download "${bk_to_dowload}" 1>&2)
    clear_last_line
    display --indent 2 --text "- Downloading backup from dropbox" --result "DONE" --color GREEN

    # Uncompress backup file
    log_event "info" "Uncompressing ${chosen_backup_to_restore}" "false"
    pv "${chosen_backup_to_restore}" | ${TAR} xp -C "${SFOLDER}/tmp/" --use-compress-program=lbzip2
    clear_last_line
    display --indent 2 --text "- Uncompressing backup file" --result "DONE" --color GREEN

    # Project Type
    project_type=$(get_project_type "${SFOLDER}/tmp/${chosen_project}")

    log_event "info" "Project Type: ${project_type}" "false"
    log_event "info" "Trying to get database parameters from ${SFOLDER}/tmp/${chosen_project}/wp-config.php" "false"

    case $project_type in

      wordpress)
        db_name=$(cat ${SFOLDER}/tmp/${chosen_project}/wp-config.php | grep DB_NAME | cut -d \' -f 4)
        db_user=$(cat ${SFOLDER}/tmp/${chosen_project}/wp-config.php | grep DB_USER | cut -d \' -f 4)
        db_pass=$(cat ${SFOLDER}/tmp/${chosen_project}/wp-config.php | grep DB_PASSWORD | cut -d \' -f 4)
        ;;

      laravel)
        echo -n "TODO"
        ;;

      yii)
        echo -n "TODO"
        ;;

      *)
        echo -n "Project Type Unknown"
        ;;
    esac

    # Here, for convention, chosen_project should be CHOSEN_DOMAIN... 
    # Only for better code reading, i assign this new var:
    chosen_domain=${chosen_project}

    # Restore site files
    project_path=$(restore_site_files "${chosen_domain}")

    # Database Backup
    backup_date=$(echo "${chosen_backup_to_restore}" |grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}')
    db_to_download="${chosen_server}/database/${db_name}/${db_name}_database_${backup_date}.tar.bz2"

    # Extracting project_state from
    project_state="$(cut -d'_' -f2 <<<"${db_name}")"

    log_event "" "*************** wp-config.php ***************" "true"
    log_event "" "project_path: ${project_path}" "true"
    log_event "" "chosen_project: ${chosen_project}" "true"
    log_event "" "project_state: ${project_state}" "true"
    log_event "" "backup_date: ${backup_date}" "true"
    log_event "" "Old db_name: ${db_name}" "true"
    log_event "" "Old db_user: ${db_user}" "true"
    log_event "" "Old db_pass: ${db_pass}" "true"
    log_event "" "********************************************" "true"

    # Downloading Database Backup
    display --indent 2 --text "- Downloading backup from dropbox"
    dropbox_output=$(${DROPBOX_UPLOADER} download "${db_to_download}" 1>&2)
    clear_last_line
    display --indent 2 --text "- Downloading backup from dropbox" --result "DONE" --color GREEN

    # Uncompress backup file
    log_event "info" "Uncompressing ${db_to_download}" "false"
    pv "${db_name}_database_${backup_date}.tar.bz2" | tar xp -C "${SFOLDER}/tmp/" --use-compress-program=lbzip2
    clear_last_line
    display --indent 2 --text "- Uncompressing backup file" --result "DONE" --color GREEN

    # Trying to extract project name from domain
    chosen_project="$(cut -d'.' -f1 <<<"${chosen_project}")"

    # Asking project state with suggested actual state
    suffix="$(cut -d'_' -f2 <<<"${chosen_project}")"
    project_state=$(ask_project_state "${suffix}")

    # Extract project_name (its removes last part of db name with "_" char)
    project_name=${chosen_project%"_$suffix"}

    # TODO: extract to function
    # Extract reserved substrings
    project_name=$(echo "${project_name}" | sed s/"_org"// | sed s/"_ar"// | sed s/"_com"// | sed s/"_net"// | sed s/"_edu"//)

    project_name=$(whiptail --title "Project Name" --inputbox "Want to change the project name?" 10 60 "${project_name}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      log_event "info" "Setting project_name=${project_name}" "false"

    else
      return 1

    fi

    # Sanitize ${project_name}
    db_project_name=$(mysql_name_sanitize "${project_name}")

    # Restore database function
    restore_database_backup "${db_project_name}" "${project_state}" "${db_name}_database_${backup_date}.tar.bz2"

    db_name="${db_project_name}_${project_state}"
    db_user="${db_project_name}_user"

    # Check if user database already exists
    mysql_user_exists "${db_user}"
    
    user_db_exists=$?
    if [[ ${user_db_exists} -eq 0 ]]; then

      db_pass=$(openssl rand -hex 12)

      log_event "info" "Creating ${db_user} user in MySQL with pass: ${db_pass}" "false"

      mysql_user_create "${db_user}" "${db_pass}"

    else

      log_event "warning" "MySQL user ${db_user} already exists" "false"
      display --indent 2 --text "- Creating ${db_user} user in MySQL" --result "FAIL" --color RED
      display --indent 4 --text "MySQL user ${db_user} already exists."

      whiptail_event "WARNING" "MySQL user ${db_user} already exists. Please after the script ends, check project configuration files."

    fi

    # Grant privileges to database user
    mysql_user_grant_privileges "${db_user}" "${db_name}"

    # Change wp-config.php database parameters
    wp_update_wpconfig "${project_path}" "${db_project_name}" "${project_state}" "${db_pass}"

    #TODO: ask if restore backuped let's encrypt conf or create a new one
    restore_letsencrypt_site_files "${chosen_domain}" "${backup_date}"

    # TODO: ask to choose between regenerate nginx config or restore backup
    # If choose restore config and has https, need to restore letsencrypt config and run cerbot
    restore_nginx_site_files "${chosen_domain}" "${backup_date}"

    #TODO: ask if want to change IP from Cloudflare then ask for Cloudflare Root Domain

    # Only for Cloudflare API
    root_domain=$(cloudflare_ask_root_domain "${chosen_domain}")

    cloudflare_change_a_record "${root_domain}" "${chosen_domain}"
    
    # HTTPS with Certbot
    certbot_helper_installer_menu "${MAILA}" "${chosen_domain}"

    telegram_send_message "✅ ${VPSNAME}: Project ${chosen_domain} restored on ${project_path}"

  fi

}