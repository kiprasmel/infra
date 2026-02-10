# managed via $INFRA_REPO_URL

server {
	server_name $DOMAIN $DOMAIN_SECONDARY;

	# increase max request size for GitHub webhooks
	client_max_body_size              0;
	client_header_buffer_size     1024K;
	large_client_header_buffers 4 1024K;

	location /github-app {
		return 301 "https://github.com/apps/pr-versions";
	}
	location /app {
		return 301 "https://github.com/apps/pr-versions";
	}

	location / {
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_cache_bypass $http_upgrade;

		proxy_intercept_errors  on;
		proxy_redirect	 off;

		proxy_set_header 	Host $host;
		proxy_set_header 	X-Real-IP $remote_addr;
		proxy_set_header 	X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header 	X-Forwarded-Proto $scheme;

		proxy_pass http://localhost:$PORT;
	}
}
