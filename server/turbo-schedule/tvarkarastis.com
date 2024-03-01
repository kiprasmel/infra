# managed via $INFRA_REPO_URL

server {
	listen 80;
	server_name tvarkarastis.com www.tvarkarastis.com;

	location = /cfg {
		return 301 $CONFIG_URL;
	}

	location ~ /* {
		proxy_pass http://localhost:$PORT;

		proxy_http_version 	1.1;
		proxy_set_header 	Upgrade $http_upgrade;
		proxy_set_header 	Connection 'upgrade';
		proxy_cache_bypass 	$http_upgrade;

		proxy_set_header 	Host $host;
		proxy_set_header 	X-Real-IP $remote_addr;
		proxy_set_header 	X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header 	X-Forwarded-Proto $scheme;
	}

	gzip            on;
	gzip_min_length 1000;
	gzip_proxied    any;
	gzip_types      "*";

	# increase max request size
	client_max_body_size 		0;
	client_header_buffer_size 	1024K;
	large_client_header_buffers 4 1024K;
}

