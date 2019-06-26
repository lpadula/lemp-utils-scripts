# Broobe Utils Scripts

"Broobe Utils Scripts" is a **BASH** script which can be used to backup files and databases.
It's written in BASH scripting language.

## Features

* File backups
* Database backups (MySQL or MariaDB)
* Cross platform
* Support for the official Dropbox API v2
* Simple step-by-step configuration wizard

## Getting started

Give the execution permission to the script and run it:

```bash
 $chmod +x runner.sh
```

The first time you run `runner.sh`, you'll be guided through a wizard in order to configure it. This configuration will be stored in `~/.broobe-utils-script`.

## Running as cron job
This script relies on a different configuration file for each system user. The default configuration file location is `$HOME/.broobe-utils-script`.
This means that if you setup the script with your user and then you try to run a cron job as root, it won't work.
So, when running this script using cron, please keep in mind the following:
* Remember to setup the script with the user used to run the cron job
* Always specify the full script path when running it (e.g.  /path/to/dropbox_uploader.sh)
