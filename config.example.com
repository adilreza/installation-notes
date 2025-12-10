server {
    listen 80;
    listen [::]:80;

    server_name api.kakraa.com;

    access_log /var/log/nginx/proxy-access.log;
    error_log  /var/log/nginx/proxy-error.log warn;

    client_max_body_size 50M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        proxy_pass http://172.16.2.137:8000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Connection "";

        proxy_connect_timeout 5s;
        proxy_send_timeout 30s;
        proxy_read_timeout 90s;

        proxy_buffer_size 16k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 64k;
    }

    location = /nginx-health {
        return 200 'ok';
        add_header Content-Type text/plain;
    }
}
