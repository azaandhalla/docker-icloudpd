#!/bin/ash

if [ -f "/tmp/icloudpd/check_exit_code}" ] || [ -f "/tmp/icloudpd/download_exit_code}" ]; then
   if [ -f "/tmp/icloudpd/download_exit_code}" ]; then
      download_exit_code="$(cat /tmp/icloudpd/download_exit_code)"
      if [ "${download_exit_code}" -ne 0 ]; then
         echo "File download error: ${download_exit_code}"
         exit 1
      fi
   fi
   if [ -f "/tmp/icloudpd/check_exit_code}" ]; then
      check_exit_code="$(cat /tmp/icloudpd/check_exit_code)"
      if [ "${check_exit_code}" -ne 0 ]; then
         echo "File check error: ${check_exit_code}"
         exit 1
      fi
   fi
fi
cookie="$(echo -n "${apple_id//[^a-zA-Z0-9]}" | tr '[:upper:]' '[:lower:]')"
if [ ! -f "${config_dir}/${cookie}" ]; then
	echo "Error: Cookie does not exist. Please generate new cookie"
	exit 1
fi
if [ "${authentication_type:=2FA}" = "2FA" ]; then
   twofa_expire_date="$(grep "X-APPLE-WEBAUTH-HSA-TRUST" "${config_dir}/${cookie}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   twofa_expire_seconds="$(date -d "${twofa_expire_date}" '+%s')"
   days_remaining="$(($((twofa_expire_seconds - $(date '+%s'))) / 86400))"
   if [ -z "${notification_days}" ]; then notification_days=7; fi
   if [ "${days_remaining}" -lt "${notification_days}" ]; then
      echo "Error: Two-factor authentication cookie has expired"
      exit 1
   fi
elif [ "${authentication_type}" = "Web" ]; then
   web_cookie_expire_date="$(grep "X_APPLE_WEB_KB" "${config_dir}/${cookie}" | sed -e 's#.*expires="\(.*\)Z"; HttpOnly.*#\1#')"
   web_cookie_expire_seconds="$(date -d "${web_cookie_expire_date}" '+%s')"
   days_remaining="$(($((web_cookie_expire_seconds - $(date '+%s'))) / 86400))"
else
   echo "Error: Authentication type not recognised"
   exit 1
fi
echo "iCloud Photos Downloader successful and ${authentication_type} cookie valid for ${days_remaining} day(s)"
exit 0