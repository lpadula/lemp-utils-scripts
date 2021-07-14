#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.0.44
################################################################################
#
# Notification Controller: Send notification to configured apps.
#
################################################################################

################################################################################
# Send Notification: send notification to configured apps.
#
# Arguments:
#   $1 = {notification_title}
#   $2 = {notification_content}
#   $3 = {notification_type}
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function send_notification() {

    local notification_title=$1
    local notification_content=$2
    local notification_type=$3

    if [[ ${TELEGRAM_NOTIF} == "true" ]]; then

        telegram_send_notification "${notification_title}" "${notification_content}" "${notification_type}"

    fi
    #if [[ ${MAIL_NOTIF} == "true" ]]; then
    #
    #    mail_send_notification "${notification_title}" "${notification_content}" "${notification_type}"
    #
    #fi

}
