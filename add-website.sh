#!/bin/bash

function restart_nginx() {
    nginx -t > /dev/null
    if [ $? -ne 0 ]; then
        echo "Problem with generating nginx config. Quitting."
        nginx -t
        exit 1
    fi
    nginx -s reload
}

function enable_ssl() {
    domain="$1"
    config_file="$2"

    # Check DNS
    dns=$(host "$domain")
    if [ $? -ne 0 ]; then
        echo "DNS record for $domain does not exist"
        exit 1
    fi

    # Optain certificate
    certbot certonly --nginx -d "$domain"

    # Replace nginx config with SSL version
    if [ $? -eq 0 ]; then
        # Enable https config
        sed -i 's/listen 80;/listen 443 ssl http2;/g' "$config_file"
        sed -i 's/listen \[::\]:80;/listen [::]:443 ssl http2;/g' "$config_file"
        sed -i 's/# include/include/g' "$config_file"
        sed -i 's/# ssl_certificate/ssl_certificate/g' "$config_file"
        sed -i 's/# ssl_certificate_key/ssl_certificate_key/g' "$config_file"

        # Append HTTP -> HTTPS redirection
cat >> "$config_file" <<EOF

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;

    server_name $domain;

    if (\$host = $domain) {
        return 301 https://\$host\$request_uri;
    }

    return 404;
}

EOF
fi

restart_nginx
}

read -r -p "Domain: " domain
config_file="/etc/nginx/conf.d/$domain.conf"


# If config file exists, ask to remove site
if [ -f "$config_file" ]; then
    if [[ -d "/etc/letsencrypt/live/$domain" ]]; then
        read -r -p "$config_file already exists. What would you like to do? [r(emove) / Q(uit)]: " remove
    else
        read -r -p "$config_file already exists. What would you like to do? [r(emove) / c(ertificate) / Q(uit)]: " remove
    fi

    if [[ $remove == "r" || $remove == "r" ]]; then
        dns=$(host "$domain")
        if [[ $? == 0 && -d "/etc/letsencrypt/live/$domain" ]]; then
            certbot revoke --delete-after-revoke --cert-name "$domain"
        fi

        if [ -d "/var/www/$domain" ]; then
            rm -r "/var/www/$domain"
        fi

        rm -r "/etc/nginx/conf.d/$domain.conf"

        restart_nginx
    elif [[ $remove == "c" || $remove == "C" ]]; then
        enable_ssl "$domain" "$config_file"
    else
        echo "Quitting"
    fi
    exit 1
fi


# Ask to, and set up reverse proxy nginx config
read -r -p "Proxy? [y/N]: " proxy
if [[ $proxy == "y" || $proxy == "Y" ]];
then

read -r -p "Proxy to port: " port
read -r -p "Get Let's Encrypt certificate? [y/N]: " get_cert

# Create nginc config file
cat > "$config_file" <<EOF
server {
    listen [::]:80;
    listen 80;

    server_name $domain;

    location / {
        proxy_pass http://localhost:$port;
        proxy_set_header X-Forwarded-For ]\$remote_addr;
    }

    # include /etc/nginx/options.conf;

    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;

    # ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
}

EOF


# If not proxy, set up normal site with a /var/www folder
else


read -r -p "Matrix well-known? [y/N]: " wellknown
if [[ "$wellknown" == "y" || "$wellknown" == "Y" ]]; then read -r -p "Delegated URL: " host; fi

read -r -p "Set CORS headers? [y/N]: " cors
read -r -p "Space separated list of indexes. Leave empty for index.html: " indexes
if [[ "$indexes" == "" ]]; then indexes="index.html"; fi
# read -r -p "Use PHP? [y/N]: " use_php
read -r -p "Get Let's Encrypt certificate? [y/N]: " get_cert

# Create nginx config file
cat > "$config_file" <<EOF
server {
    listen [::]:80;
    listen 80;

    server_name $domain;

    root /var/www/$domain/html;
    index $indexes;

EOF

# Create well-known "files"
if [[ "$wellknown" == "y" || "$wellknown" == "Y" ]];
then

cat >> "$config_file" <<EOF
    # well-known files for Matrix server
    location /.well-known/matrix/client {
        return 200 '{"m.homeserver": {"base_url": "https://$host"},"m.identity_server": {"base_url": "https://vector.im"}}';
        add_header Content-Type application/json;
        add_header 'Access-Control-Allow-Origin' '*';
    }
    location /.well-known/matrix/server {
        return 200 '{"m.server": "$host:443"}';
        add_header Content-Type application/json;
    }

EOF

fi # Ending if $wellknown

cat >> "$config_file" <<EOF
    location / {
        try_files \$uri \$uri/ =404;
EOF

# Add CORS headers if selected
if [[ "$cors" == "y" || "$cors" == "Y" ]];
then

cat >> "$config_file" <<EOF

        # Enable CORS headers
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        if (\$request_method = 'POST') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }
        if (\$request_method = 'GET') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }
EOF

fi # Ending if $cors

# Ending block location / {
cat >> "$config_file" <<EOF
    }

    location ~ /\.ht {
        deny all;
    }
EOF

# if [[ "$use_php" == "y" || "$use_php" == "Y" ]];
# then

# cat >> "$config_file" <<EOF

#     location ~ \.php$ {
#         include snippets/fastcgi-php.conf;
#         fastcgi_pass unix:/run/php/php7.2-fpm.sock;
#     }
# EOF

# fi # Ending if $use_php


# Ending block "server {"
cat >> "$config_file" << EOF

    # include /etc/nginx/options.conf;

    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;

    # ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
}
EOF

# Create /var/www stuff
mkdir -p "/var/www/$domain/html"
cat > "/var/www/$domain/html/index.html" <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>Welcome to nginx!</title>
        <style>
            body {
                width: 35em;
                margin: 0 auto;
                font-family: Tahoma, Verdana, Arial, sans-serif;
            }
        </style>
    </head>

    <body>
        <h1>Welcome to nginx for $domain!</h1>
        <p>
            If you see this page, the nginx web server is successfully installed and
            working. Further configuration is required.
        </p>
        <p>
            For online documentation and support please refer to <a href="https://nginx.org/">nginx.org</a>.<br/>
            Commercial support is available at <a href="https://nginx.com/">nginx.com</a>.
        </p>
        <p><em>Thank you for using nginx.</em></p>
    </body>
</html>
EOF

fi # Ending the "else" on "if $proxy"

restart_nginx

if [[ $get_cert == "y" || $get_cert == "Y" ]]; then
    enable_ssl "$domain" "$config_file"
fi
