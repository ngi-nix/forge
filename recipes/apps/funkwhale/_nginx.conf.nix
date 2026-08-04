{ frontendPath, backendUrl }:
let
  securityHeaders = ''
    add_header Content-Security-Policy "default-src 'self'; connect-src https: wss: http: ws: 'self' 'unsafe-eval'; script-src 'self' 'wasm-unsafe-eval'; style-src https: http: 'self' 'unsafe-inline'; img-src https: http: 'self' data:; font-src https: http: 'self' data:; media-src https: http: 'self' data:; object-src 'none'";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Service-Worker-Allowed "/";
  '';
in
''
  client_max_body_size 100M;
  root ${frontendPath};
  sendfile off;
  charset utf-8;

  # Compression
  gzip on;
  gzip_types application/javascript application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

  # Security Headers
  ${securityHeaders}

  location / {
    try_files $uri $uri/ @backend;
  }

  location @backend {
    ${securityHeaders}
    proxy_pass ${backendUrl};
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # Subsonic support
  location /rest/ {
    ${securityHeaders}
    proxy_pass ${backendUrl}/api/subsonic/rest/;
  }

  # Support for Vite development paths
  location ~ ^/@(vite-plugin-pwa|vite|id)/ {
    ${securityHeaders}
    alias ${frontendPath};
    try_files $uri $uri/ /index.html;
  }

  # Explicitly proxy API and other backend paths
  location ~ ^/(api|federation|auth|.well-known)/ {
    ${securityHeaders}
    proxy_pass ${backendUrl};
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /staticfiles/ {
    ${securityHeaders}
    alias /var/lib/funkwhale/static/;
    expires 30d;
    add_header Cache-Control "public";
  }

  location /media/ {
    ${securityHeaders}
    alias /var/lib/funkwhale/media/;
  }

  # Allow direct access to only specific subdirectories in /media
  location /media/__sized__/ {
    ${securityHeaders}
    alias /var/lib/funkwhale/media/__sized__/;
    add_header Access-Control-Allow-Origin '*';
  }

  location /media/attachments/ {
    ${securityHeaders}
    alias /var/lib/funkwhale/media/attachments/;
    add_header Access-Control-Allow-Origin '*';
  }

  location /media/dynamic_preferences/ {
    ${securityHeaders}
    alias /var/lib/funkwhale/media/dynamic_preferences/;
    add_header Access-Control-Allow-Origin '*';
  }

  # X-Accel-Redirect support for high-performance file serving
  location ~ /_protected/media/(.+) {
    ${securityHeaders}
    internal;
    alias /var/lib/funkwhale/media/$1;
    add_header Access-Control-Allow-Origin '*';
  }

  location /_protected/music/ {
    ${securityHeaders}
    internal;
    alias /var/lib/funkwhale/music/;
    add_header Access-Control-Allow-Origin '*';
  }

  location /manifest.json {
    return 302 http://$host:5000/api/v2/instance/spa-manifest.json;
  }
''
