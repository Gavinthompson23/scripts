#version=RHEL9
# Download packages
%packages
docker.io
%end

#sudo apt install docker.io -y 
#sudo systemctl start docker
#sudo systemctl enable docker
## Curl command to run the docker compose file for wordpress and mariadb. simple and unedited version of wordpress
curl -sSL https://raw.githubusercontent.com/bitnami/containers/main/bitnami/wordpress/docker-compose.yml > docker-compose.yml
docker-compose up -d
