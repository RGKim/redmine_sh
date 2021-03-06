
#!/bin/bash

cat << EOF > /root/cloudz.sh
#!/bin/sh

CONFIG_FILE="/root/provisioningConfiguration.cfg"
if [ -f "\$CONFIG_FILE" ] ; then
  source \$CONFIG_FILE

  OLD_PASSWORD="admin"
  NEW_PASSWORD=\$OS_PASSWORD
  
  systemctl start mariadb
  
  /usr/bin/mysql -u root -p\$OLD_PASSWORD mysql -e "\
  SET PASSWORD FOR 'root'@'localhost' = PASSWORD('\$NEW_PASSWORD');\
  SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('\$NEW_PASSWORD');\
  SET PASSWORD FOR 'root'@'::1' = PASSWORD('\$NEW_PASSWORD');\
  FLUSH PRIVILEGES;"


  systemctl start postfix
  gitlab-ctl reconfigure
  
  eval "gitlab-rails runner 'puts user = User.find(1); user.password, user.password_confirmation = \"\$NEW_PASSWORD\"; user.save! '"

  systemctl disable cloudz
  rm -f /etc/systemd/system/cloudz.service
  rm -f /root/cloudz.sh
  
else
  echo "provisioningConfiguration file not exist"
fi

EOF

chmod 755 /root/cloudz.sh

cat << EOF > /etc/systemd/system/cloudz.service
[Unit]
Description=CloudZ Install
After=network.target

[Service]
ExecStart=/root/cloudz.sh
Type=oneshot
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cloudz
cat /dev/null > /root/.bash_history && history -c  
