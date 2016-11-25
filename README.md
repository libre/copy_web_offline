# copy_web_offline

### Purpose : Script Bash for copy all public content of website (offline mode). 

Check all inventory of links and dowload all page and content CSS, JS, images ... 
Actualy not directly compatible for https. 

### Depents :
=========
- lynx
- wget

### Usage: $PROGNAME [-url www.mywebsite.org] [-dest /var/www/]
-url	www.mywebsite.org
-dest /var/www/ (default /var/backups/)
So, check is directory access for current user !
