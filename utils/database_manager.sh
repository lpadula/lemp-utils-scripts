#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.0.46
#############################################################################

function database_manager_menu() {

  local database_manager_options
  local chosen_database_manager_option
  local database_list_options
  local chosen_database_list_option

  database_manager_options=(
    "01)" "LIST DATABASES"
    "02)" "CREATE DATABASE"
    "03)" "DELETE DATABASE"
    "04)" "RENAME DATABASE"
    "05)" "LIST USERS"
    "06)" "CREATE USER"
    "07)" "DELETE USER"
    "08)" "CHANGE USER PASSWORD"
  )
  chosen_database_manager_option="$(whiptail --title "DATABASE MANAGER" --menu " " 20 78 10 "${database_manager_options[@]}" 3>&1 1>&2 2>&3)"
  exitstatus=$?

  if [[ ${exitstatus} -eq 0 ]]; then

    if [[ ${chosen_database_manager_option} == *"01"* ]]; then

      # LIST DATABASES

      database_list_options=(
        "01)" "all"
        "02)" "prod"
        "03)" "stage"
        "04)" "test"
        "05)" "dev"
      )
      chosen_database_list_option="$(whiptail --title "DATABASE MANAGER" --menu " " 20 78 10 "${database_list_options[@]}" 3>&1 1>&2 2>&3)"
      exitstatus=$?

      if [[ ${exitstatus} = 0 ]]; then

        mysql_list_databases "${chosen_database_list_option}"

      fi

    fi

    if [[ ${chosen_database_manager_option} == *"02"* ]]; then

      # CREATE DATABASE

      chosen_database_name="$(whiptail --title "DATABASE MANAGER" --inputbox "Insert the database name you want to create, example: my_domain_prod" 10 60 3>&1 1>&2 2>&3)"
      exitstatus=$?

      if [[ ${exitstatus} = 0 ]]; then

        mysql_database_create "${chosen_database_name}"

      fi

    fi

    if [[ ${chosen_database_manager_option} == *"03"* ]]; then

      # DELETE DATABASE

      # List databases
      databases="$(mysql_list_databases "all")"
      chosen_database="$(whiptail --title "DATABASE MANAGER" --menu "Choose a database to delete" 20 78 10 $(for x in ${databases}; do echo "$x [DB]"; done) --default-item "${database}" 3>&1 1>&2 2>&3)"

      exitstatus=$?
      if [[ ${exitstatus} = 0 ]]; then

        mysql_database_drop "${chosen_database}"

      fi

    fi

    if [[ ${chosen_database_manager_option} == *"04"* ]]; then

      # RENAME DATABASE

      # List databases
      databases="$(mysql_list_databases "all")"
      chosen_database="$(whiptail --title "DATABASE MANAGER" --menu "Choose a database to delete" 20 78 10 $(for x in ${databases}; do echo "$x [DB]"; done) --default-item "${database}" 3>&1 1>&2 2>&3)"

      exitstatus=$?
      if [[ ${exitstatus} = 0 ]]; then

        chosen_database_name="$(whiptail --title "DATABASE MANAGER" --inputbox "Insert the database name you want to create, example: my_domain_prod" 10 60 3>&1 1>&2 2>&3)"
        exitstatus=$?

        if [[ ${exitstatus} = 0 ]]; then
          mysql_database_rename "${chosen_database}" "${chosen_database_name}"
        fi

      fi

    fi

    prompt_return_or_finish
    database_manager_menu

  fi

  menu_main_options

}

################################################################################
# Task handler for database functions
#
# Arguments:
#   $1 = ${arguments_count}
#   $2 = ${arguments}
#
# Outputs:
#   global vars
################################################################################

function database_tasks_handler() {

  local subtask=$1

  log_subsection "Database Manager"

  case ${subtask} in

  list_db)

    mysql_list_databases "${DBSTAGE}"

    exit
    ;;

  create_db)

    mysql_create_db "${DBNAME}"

    exit
    ;;

  delete_db)

    mysql_database_drop "${DBNAME}"

    exit
    ;;

  rename_db)

    mysql_database_rename "${DBNAME}" "${DBNAME_N}"

    exit
    ;;

  list_db_user)

    mysql_list_users

    exit
    ;;

  create_db_user)

    mysql_user_create "${DBUSER}"

    exit
    ;;

  delete_db_user)

    mysql_user_delete "${DBUSER}"

    exit
    ;;

  change_db_user_psw)

    mysql_user_psw_change "${DBUSER}" "${DBUSERPSW}"

    exit
    ;;

  *)

    log_event "error" "INVALID DATABASE TASK: ${subtask}" "true"

    exit
    ;;

  esac

}
