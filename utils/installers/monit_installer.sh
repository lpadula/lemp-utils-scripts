#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.0.46
################################################################################

function monit_installer() {

  log_subsection "Monit Installer"

  log_event "info" "Updating packages before installation ..."
  apt-get --yes update -qq >/dev/null

  # Installing packages
  log_event "info" "Installing monit ..."
  apt-get --yes install monit -qq >/dev/null

}

function monit_purge() {

  log_subsection "Monit Installer"

  # Uninstalling packages
  log_event "info" "Uninstalling monit ..."
  apt-get --yes purge monit -qq >/dev/null

}

function monit_configure() {

  if [[ ! -x "${PHP_V}" ]]; then
    PHP_V=$(php -r "echo PHP_VERSION;" | grep --only-matching --perl-regexp "7.\d+")

  fi

  # Configuring monit
  log_event "info" "Configuring monit ..."

  # Using script template
  cat "${SFOLDER}/config/monit/lemp-services" >/etc/monit/conf.d/lemp-services
  cat "${SFOLDER}/config/monit/monitrc" >/etc/monit/monitrc
  display --indent 6 --text "- Copying monit config" --result "DONE" --color GREEN

  # Set Hostname
  sed -i "s#HOSTNAME#${VPSNAME}#" /etc/monit/conf.d/lemp-services

  # Set PHP_V
  php_set_version_on_config "${PHP_V}" "/etc/monit/conf.d/lemp-services"
  display --indent 6 --text "- Setting PHP version" --result "DONE" --color GREEN

  # Set SMTP vars
  sed -i "s#SMTP_SERVER#${SMTP_SERVER}#" /etc/monit/conf.d/lemp-services
  sed -i "s#SMTP_PORT#${SMTP_PORT}#" /etc/monit/conf.d/lemp-services

  # Run two times to cober all var appearance
  sed -i "s#SMTP_U#${SMTP_U}#" /etc/monit/conf.d/lemp-services
  sed -i "s#SMTP_U#${SMTP_U}#" /etc/monit/conf.d/lemp-services

  sed -i "s#SMTP_P#${SMTP_P}#" /etc/monit/conf.d/lemp-services
  sed -i "s#MAILA#${MAILA}#" /etc/monit/conf.d/lemp-services
  display --indent 6 --text "- Configuring SMTP" --result "DONE" --color GREEN

  log_event "info" "Restarting services ..."

  # Service restart
  systemctl restart "php${PHP_V}-fpm"
  systemctl restart nginx.service
  service monit restart

  # Log
  display --indent 6 --text "- Restarting services" --result "DONE" --color GREEN

  log_event "info" "Monit configured"
  display --indent 6 --text "- Monit configuration" --result "DONE" --color GREEN

}

function monit_installer_menu() {

  ### Checking if Monit is installed
  MONIT="$(command -v monit)"

  if [[ ! -x "${MONIT}" ]]; then

    monit_installer
    monit_configure

  else

    while true; do

      echo -e "${YELLOW}${ITALIC} > Monit is already installed. Do you want to reconfigure monit?${ENDCOLOR}"
      read -p "Please type 'y' or 'n'" yn

      case $yn in

      [Yy]*)

        log_subsection "Monit Configurator"

        monit_configure

        break
        ;;

      [Nn]*)

        log_event "warning" "Aborting monit configuration script ..."

        break
        ;;

      *) echo " > Please answer yes or no." ;;

      esac

    done

    # Called twice to remove last messages
    clear_last_line
    clear_last_line

  fi

}
