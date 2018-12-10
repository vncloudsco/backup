SERVER_NAME="$(ifconfig | grep broadcast | awk {'print $2'})"
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/root/backup/$TIMESTAMP"
MYSQL_USER="user"
MYSQL_PASSWORD="pass"
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump
SECONDS=0
CHECKSQL="$(ls /usr/bin/ | grep mysql)"
NGINX="$(ls /etc/ | grep nginx)"
NGINX_DIR="$(nginx -V 2>&1 | grep -o '\-\-conf-path=\(.*conf\)' | cut -d '=' -f2 | cut -c1-11)"
HTTPD="$(ls /etc/ | grep -w httpd)"
HTTPD_DIR=/etc/httpd/ # thay bang thu muc cau hinh apache
LOG_DIR=var/log/
mkdir -p "$BACKUP_DIR"
# databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`
# check cai dat mysql
if [[ $CHECKSQL == "mysql" ]];

then
  mkdir -p "$BACKUP_DIR/mysql"
  databases=`$MYSQL --user=$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql)"`

echo "Starting Backup Database";

for db in $databases; do
    $MYSQLDUMP --force --opt --user=$MYSQL_USER -p$MYSQL_PASSWORD --databases $db | gzip > "$BACKUP_DIR/mysql/$db.sql.gz"
done
echo "Finished";
echo '';

else
echo "khong co thu muc"
fi

echo "Starting Backup Website";
# Loop through /home directory
for D in /var/www/*; do
    if [ -d "${D}" ]; then #If a directory
        domain=${D##*/} # Domain name
        echo "- "$domain;
        zip -r $BACKUP_DIR/$domain.zip /var/www/$domain -q -x home/$domain/wp-content/cache/**\* # Không backup cache c?a website
    fi
done
echo "Finished";
echo '';

echo "Starting Backup Server Configuration";
if [ "$NGINX" = "nginx" ] && [ "$HTTPD" = "httpd" ]
then
	echo "Starting Backup nginx proxy, apache backend Configuration";
	cp -r $NGINX_DIR $BACKUP_DIR/nginx
	cp -r $HTTPD_DIR $BACKUP_DIR/httpd
	cp -r $LOG_DIR $BACKUP_DIR/log
	echo "Finished";
	echo '';
elif [ "$NGINX" = "nginx" ];
then
	echo "Starting Backup NGINX Configuration";
	cp -r $NGINX_DIR $BACKUP_DIR/nginx
	cp -r $LOG_DIR $BACKUP_DIR/log
	echo "Finished";
	echo '';

elif [ "$HTTPD" = "httpd" ];
then
	echo "Starting Backup HTTPD (apache) Configuration";
	cp -r $HTTPD_DIR $BACKUP_DIR/httpd
	cp -r $LOG_DIR $BACKUP_DIR/log
	echo "Finished";
	echo '';
else
	echo "2 thu muc can copy khong ton tai";
fi





size=$(du -sh $BACKUP_DIR | awk '{ print $1}')
echo "Starting Uploading Backup";
rclone copy $BACKUP_DIR "backupauto:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
rclone copy $BACKUP_DIR "dropbox:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
rclone copy $BACKUP_DIR "ondrive:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
rclone copy $BACKUP_DIR "yandex:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
rclone move $BACKUP_DIR "jottacloud:$SERVER_NAME/$TIMESTAMP" >> /var/log/rclone.log 2>&1
# Clean up
rclone -q --min-age 365d delete "ondrive:$SERVER_NAME" # xóa backup cu quá 365 ngày
rclone -q --min-age 365d rmdirs "ondrive:$SERVER_NAME" # xóa  thu mu backup cu quá 365 ngày
rclone -q --min-age 10d delete "jottacloud:$SERVER_NAME" # xóa backup cu quá 365 ngày
rclone -q --min-age 10d rmdirs "jottacloud:$SERVER_NAME" # xóa  thu m?c backup cu quá 365 ngày
rclone -q --min-age 20d delete "yandex:$SERVER_NAME" # xóa b?n backup cu quá 365 ngày
rclone -q --min-age 20d rmdirs "yandex:$SERVER_NAME" # xóa  thu  backup cu quá 365 ngày
rm -rf $BACKUP_DIR
echo "Finished";
echo '';

duration=$SECONDS
echo "Total $size, $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."