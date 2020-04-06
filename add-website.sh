#!/bin/bash


# Read variables
read -p "Domain: " domain
read -p "CORS [Y/N]: " cors
read -p "Modular well-known files [Y/N]: " wellknown
if [[ $wellknown -eq "y" && $wellknown -eq "Y" ]]; then
    read -p "Host: " host
fi


# Create nginx config
config_file=/etc/nginx/sites-available/$domain

if [ -f "$config_file" ]; then
    echo "$config_file already exists. Quitting"
    exit 1
fi

echo "server {"> $config_file
echo "        listen 80;">> $config_file
echo "        listen [::]:80;">> $config_file
echo "        root /var/www/$domain/html;">> $config_file
echo "        index index.php index.html index.htm index.nginx-debian.html /_h5ai/public/index.php;">> $config_file
echo "        server_name london.twily.me;">> $config_file
echo "        location / {">> $config_file
echo "            try_files \$uri \$uri/ =404;">> $config_file

if [[ $cors -eq "y" && $cors -eq "Y" ]]; then
    echo "            if (\$request_method = 'OPTIONS') {">> $config_file
    echo "                add_header 'Access-Control-Allow-Origin' '*';">> $config_file
    echo "                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';">> $config_file
    echo "                #">> $config_file
    echo "                # Custom headers and headers various browsers *should* be OK with but aren't">> $config_file
    echo "                #">> $config_file
    echo "                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';">> $config_file
    echo "                #">> $config_file
    echo "                # Tell client that this pre-flight info is valid for 20 days">> $config_file
    echo "                #">> $config_file
    echo "                add_header 'Access-Control-Max-Age' 1728000;">> $config_file
    echo "                add_header 'Content-Type' 'text/plain; charset=utf-8';">> $config_file
    echo "                add_header 'Content-Length' 0;">> $config_file
    echo "                return 204;">> $config_file
    echo "            }">> $config_file
    echo "            if (\$request_method = 'POST') {">> $config_file
    echo "                add_header 'Access-Control-Allow-Origin' '*';">> $config_file
    echo "                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';">> $config_file
    echo "                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';">> $config_file
    echo "                add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';">> $config_file
    echo "            }">> $config_file
    echo "            if (\$request_method = 'GET') {">> $config_file
    echo "                add_header 'Access-Control-Allow-Origin' '*';">> $config_file
    echo "                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';">> $config_file
    echo "                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';">> $config_file
    echo "                add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';">> $config_file
    echo "            }">> $config_file
fi

echo "        }">> $config_file
echo "        location ~ /\.ht {">> $config_file
echo "                deny all;">> $config_file
echo "        }">> $config_file
echo "        location ~ \.php$ {">> $config_file
echo "            include snippets/fastcgi-php.conf;">> $config_file
echo "            fastcgi_pass unix:/run/php/php7.2-fpm.sock;">> $config_file
echo "        }">> $config_file
echo "}">> $config_file


# Enable nginx config
ln -s $config_file /etc/nginx/sites-enabled/


# Test nginx config
nginx -t > /dev/null
if [ $? -ne 0 ]; then
    echo "Problem with generating nginx config. Quitting."
    nginx -t
    rm /etc/nginx/sites-enabled/$domain
    exit 1
fi
systemctl restart nginx


# Create /var stuff
mkdir -p /var/www/$domain/html
echo "<!DOCTYPE html>"> /var/www/$domain/html/index.html
echo "<html>">> /var/www/$domain/html/index.html
echo "<head>">> /var/www/$domain/html/index.html
echo "<title>Welcome to nginx!</title>">> /var/www/$domain/html/index.html
echo "<style>">> /var/www/$domain/html/index.html
echo "    body {">> /var/www/$domain/html/index.html
echo "        width: 35em;">> /var/www/$domain/html/index.html
echo "        margin: 0 auto;">> /var/www/$domain/html/index.html
echo "        font-family: Tahoma, Verdana, Arial, sans-serif;">> /var/www/$domain/html/index.html
echo "    }">> /var/www/$domain/html/index.html
echo "</style>">> /var/www/$domain/html/index.html
echo "</head>">> /var/www/$domain/html/index.html
echo "<body>">> /var/www/$domain/html/index.html
echo "<h1>Welcome to nginx for $domain!</h1>">> /var/www/$domain/html/index.html
echo "<p>If you see this page, the nginx web server is successfully installed and">> /var/www/$domain/html/index.html
echo "working. Further configuration is required.</p>">> /var/www/$domain/html/index.html
echo "<p>For online documentation and support please refer to">> /var/www/$domain/html/index.html
echo "<a href="http://nginx.org/">nginx.org</a>.<br/>">> /var/www/$domain/html/index.html
echo "Commercial support is available at">> /var/www/$domain/html/index.html
echo "<a href="http://nginx.com/">nginx.com</a>.</p>">> /var/www/$domain/html/index.html
echo "<p><em>Thank you for using nginx.</em></p>">> /var/www/$domain/html/index.html
echo "</body>">> /var/www/$domain/html/index.html
echo "</html>">> /var/www/$domain/html/index.html


# Create .well-known
if [[ $wellknown -eq "y" && $wellknown -eq "Y" ]]; then
    mkdir -p /var/www/$domain/html/.well-known/matrix/
    echo "{">> /var/www/$domain/html/.well-known/matrix/client
    echo "    \"m.homeserver\": {">> /var/www/$domain/html/.well-known/matrix/client
    echo "        \"base_url\": \"https://$host.modular.im\"">> /var/www/$domain/html/.well-known/matrix/client
    echo "    },">> /var/www/$domain/html/.well-known/matrix/client
    echo "    \"m.identity_server\": {">> /var/www/$domain/html/.well-known/matrix/client
    echo "        \"base_url\": \"https://vector.im\"">> /var/www/$domain/html/.well-known/matrix/client
    echo "    }">> /var/www/$domain/html/.well-known/matrix/client
    echo "}">> /var/www/$domain/html/.well-known/matrix/client

    echo "{">> /var/www/$domain/html/.well-known/matrix/server
    echo "    \"m.server\": \"$host.modular.im:443\"">> /var/www/$domain/html/.well-known/matrix/server
    echo "}">> /var/www/$domain/html/.well-known/matrix/server
fi

certbot --nginx