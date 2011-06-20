mcbackup
========
mcbackup is a backup script for Minecraft. It is intended to be run via cron(8),
but may be run manually aswell. It requires mcbackup.pl and minecraft.sh to be
configured so that it will work properly (where minecraft is, where backups are
stored, etc.). It also has the ability to send emails to administrators if the
backup encountered any errors.

Setup
-----
1. Edit mcbackup.pl and minecraft.sh to reflect your configuration
2. Add the appropriate line in your crontab (crontab -e) file (e.g. @daily perl
/path/to/mcbackup.pl)
3. Run Minecraft with minecraft.sh