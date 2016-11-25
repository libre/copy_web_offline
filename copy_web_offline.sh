#!/bin/bash
#
#    Program : copy_web_offline.sh
#            :
#    Author :  github.com/libre
#    Purpose : Script Bash for copy all public content of website (offline mode). 
#					 : Check all inventory of links and dowload all page and content CSS, JS, images ... 
#          
#    Parameters : --help
#                        :  --version
#    Licence        : GPL
#
#      Notes : See --help for details
#============:==============================================================

PROGNAME=`basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo '$Revision: version : 1.0.0 $' | sed -e 's/[^0-9.]//g'`

print_usage() {
        echo "Usage: $PROGNAME [-url www.mywebsite.org] [-ssl no] [-dest /var/www/]"
		echo "		-url	www.mywebsite.org"
		echo "		-ssl no (default no)"
		echo "		-dest /var/www/ (default /var/backups/)"
		echo "      So, check is directory access for current user !"
	echo ""
        echo "Usage: $PROGNAME --help"
        echo "Usage: $PROGNAME --version"
}

print_help() {
        echo $PROGNAME $REVISION
        echo ""
        echo "Copy all public content of website (offline mode)."
        echo ""
        print_usage
        echo ""
        echo "copy_web_offline.sh - http://github.com/libre"
        echo ""
        exit 0
}

while test -n "$1"; do
        case "$1" in
                --help)
                        print_help
                        exit 0
                        ;;
                -h)
                        print_help
                        exit 0
                        ;;
                --version)
                        print_revision $PROGNAME $REVISION
                        exit 0
                        ;;
                -V)
                        print_revision $PROGNAME $REVISION
                        exit 0
                        ;;
                -url)
                    URL=$2;
                    shift;
                    ;;
                -dest)
                    DEST=$2
                    shift;
                ;;
                *)
                        echo "Unknown argument: $1"
                        print_usage
                        exit 1
                        ;;
        esac
        shift
done

# Test vide
if [ "${URL}" = "" ]; then
	echo "UNKNOWN: Please check URL for copy"
	echo "Use --help for help !"
	exit 1
fi
if [ ${URL:0:8} == "https://" ]; then
	echo "Not supported now .... sorry"
	echo "Testing copy on HTTP"
	URL=${URL:8}
fi
if [ ${URL:0:7} == "http://" ] ; then
	URL=${URL:7}
fi
# Test path specifique config file
if [ -e /usr/bin/lynx ]; then
	echo "Lynx not found please install !" 1>&2
	echo "apt-get install lynx or yum install lynx" 1>&2
	exit 1
fi 
if [ -e /usr/bin/wget ]; then
	echo "wget not found please install !" 1>&2
	echo "apt-get install wget or yum install wget" 1>&2
	exit 1
fi
# Test right of dest. directory
if [ "${DEST}" = "" ]; then
	DEST="$HOME"
else
	# Test directory exist : 
	if [ ! -d $DEST ]; then
			echo "Error Not exit directory, please check !"
			exit 1		
	fi
	touch $DEST/test_rw.tmp 1&>2 /dev/null
	RTEST=`echo $?`
	if [ "${RTEST}" == "0" ]; then
		rm -rf $DEST/test_rw.tmp
	else
		echo "Error Not acces write is directory, please check !"
		exit 1		
	fi
fi
# Test directory exist : 
if [ ! -d "${DEST}/copyoffline" ]; then
	mkdir $DEST/copyoffline
	cd $DEST/copyoffline
else 
	cd $DEST/copyoffline
fi
# Test running temp rep exist : 
if [ ! -d jobs ]; then
	mkdir jobs
else 
	rm -rf jobs
	mkdir jobs
fi
subdom=`echo ${URL} | cut -d "." -f1 | grep -iEx "www" | wc -l`
if [ $subdom == "1" ]; then
	DOMAIN=${URL#*.}
else 
	DOMAIN=${URL}
fi 
echo "Listing job URL			[Wait]"
# UUID=$(cat /proc/sys/kernel/random/uuid)
lynx -stderr -dump -listonly http://$URL | grep -E "/$" | grep "http://$URL" | grep -ve "http://$URL/$"  > jobs/url_index.tmp
cat jobs/url_index.tmp | awk '{ print $2 }' > jobs/url_index.txt
### Multidownload integration
echo "#!/bin/bash" > url_index.sh
cat jobs/url_index.txt | while read LINE
do
	echo "echo \"Download content link $LINE 	[Wait]\"" >>  url_index.sh
	echo "sh wget -q -nv --accept pdf,jpg,js,css,doc,docx,bmp,png,gif,pptx --mirror --header=\"Accept: text/html\" --user-agent=\"Mozilla/5.0 Firefox/21.0\" -F -B -nc -x -r -k -m --domains  $DOMAIN --wait=3 $LINE" >> url_index.sh
	echo "echo \"Download content link $LINE        [Wait]\"" >>  url_index.sh
done    
rm -rf jobs/url_index.tmp
chmod +x url_index.sh
sh url_index.sh
rm -rf url_index.sh
echo "Listing index link		[OK]"
OCINDEX=`cat jobs/url_index.txt | wc -l`
echo "Index link occurence index = ${OCINDEX}"
echo "Listing job parent URL		[Wait]"
cat jobs/url_index.txt | while read LINE2
do
		echo "#!/bin/bash" > url_$UUID.sh
        UUID=$(cat /proc/sys/kernel/random/uuid)
        lynx -stderr -dump -listonly $LINE2 | grep -E "/$" | grep "http://$URL" | grep -ve "http://$URL/$" > jobs/url_$UUID.job
        cat jobs/url_$UUID.job | awk '{ print $2 }' > jobs/url_$UUID.txt
        cat jobs/url_$UUID.txt | while read LINE3
		do
			echo "echo \"Download content link $LINE3 	[Wait]\"" >>  url_$UUID.sh
			echo "wget -q -nv --accept pdf,jpg,js,css,doc,docx,bmp,png,gif,pptx --mirror --header=\"Accept: text/html\" --user-agent=\"Mozilla/5.0 Firefox/21.0\" -F -B -nc -x -r -k -m --domains  $DOMAIN --wait=3 $LINE3" >> url_$UUID.sh
			echo "echo \"Download content link $LINE3 	[OK]\"" >>  url_$UUID.sh		 
		done
		chmod +x url_$UUID.sh
		sh url_$UUID.sh
		rm -rf url_$UUID.sh
        rm -rf jobs/url_$UUID.job
done
echo "Processing Cleanning			[OK]"	
rm -rf jobs
echo ""
echo "Copyoffline for website $URL is OK"
echo "Copy of your offline website  location is :"
echo "            ${DEST}/copyoffline/$URL"
echo ""
exit 0
