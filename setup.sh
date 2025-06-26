#!/bin/bash

CURRENT_DIR=$(pwd)

function check_docker_version {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed."
        # Install docker & docker compose
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce
        sudo usermod -aG docker $USER

        # Create monitoring network
        sudo docker network create monitoring

        echo "log out and back in to use docker without sudo"

        return 1
    fi
}
check_docker_version

# Install Functions
install_portainer(){
    echo "Installing Portainer..."
    sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.27.1
}

install_grafana(){
    echo "installing Grafana"
    cd "${CURRENT_DIR}/grafana"
    sudo docker compose up --build --force-recreate -d
}

install_prometheus(){
    echo "installing Prometheus"
    cd "${CURRENT_DIR}/prometheus"
    sudo docker compose up --build --force-recreate -d
}

install_alloy(){
    echo "installing Alloy"
    cd "${CURRENT_DIR}/alloy"
    sudo docker compose up --build --force-recreate -d
}

install_loki(){
    echo "installing Loki"
    cd "${CURRENT_DIR}/loki"
    sudo docker compose up --build --force-recreate -d
}

install_tempo(){
    echo "installing Tempo"
    cd "${CURRENT_DIR}/tempo"
    sudo docker compose up --build --force-recreate -d
}

# Define software list and their install commands
software_list=(
    "Portainer - Docker WebUI"
    "Grafana - Data Visualization Interface"
    "Prometheus - Metrics Database"
    "Alloy - Collector Agent"
    "Loki - Logs Database"
    "Tempo - Traces Database"
)
install_commands=(
    "install_portainer"
    "install_grafana"
    "install_prometheus"
    "install_alloy"
    "install_loki"
    "install_tempo"
)
selected=()
for ((i=0; i<${#software_list[@]}; i++)); do
    selected[i]="false"
done
current_index=0

while true; do
    clear
    
    echo "Software Installer"
    echo "               
                       _ _             _                   _             _    
 _ __ ___   ___  _ __ (_) |_ ___  _ __(_)_ __   __ _   ___| |_ __ _  ___| | __
| '_ \` _ \\ / _ \\| '_ \\| | __/ _ \\| '__| | '_ \\ / _\` | / __| __/ _\` |/ __| |/ /
| | | | | | (_) | | | | | || (_) | |  | | | | | (_| | \__ \\ || (_| | (__|   < 
|_| |_| |_|\\___/|_| |_|_|\\__\\___/|_|  |_|_| |_|\\__, | |___/\\__\\__,_|\\___|_|\\_\\
                                               |___/                          

"
    echo "Navigate with Up/Down arrow keys, press x to select/deselect, and 'q' to finish."
    
    for ((i=0; i<${#software_list[@]}; i++)); do
        if [ $i -eq $current_index ]; then
            printf "\033[32m>> \033[0m"  # Highlight current line
        else
            printf "    "
        fi
        
        if [ "${selected[i]}" = "true" ]; then
            echo "[X] ${software_list[i]}"
        else
            echo "[ ] ${software_list[i]}"
        fi
    done
    
    # Read input without echoing it
read -s -n1 key

case $key in
    # Up arrow
    A)
        if [ $current_index -gt 0 ]; then
            ((current_index--))
        fi
        ;;
    
    # Down arrow
    B)
        if [ $current_index -lt $((${#software_list[@]} - 1)) ]; then
            ((current_index++))
        fi
        ;;
    
    # 'x' to toggle selection
    x)
        if [ "${selected[$current_index]}" = "true" ]; then
            selected[$current_index]="false"
        else
            selected[$current_index]="true"
        fi
        ;;
    
    # 'q' to quit
    q)
        break
        ;;
esac
done

# Confirmation prompt
clear
echo -e "\nSelected software:"
for i in "${!software_list[@]}"; do
    if [ "${selected[$i]}" == "true" ]; then
        echo -e "\033[32m✓ \033[0m${software_list[$i]}"
    fi
done

read -p $'\nAre you sure you want to install these packages? (yes/no): ' confirm
if [[ ! "$confirm" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Installation aborted."
    exit 1
fi

# Proceed with installation
echo -e "\nStarting installation..."

for i in "${!software_list[@]}"; do
    if [ "${selected[$i]}" == "true" ]; then
        command="${install_commands[$i]}"
        if type -t "$command" > /dev/null; then
            # It's a function, execute it
            $command
        else
            # Assume it's an install command, execute in shell
            eval "$command"
        fi
    fi
done
sudo docker restart portainer

echo "Monitoring Stack Installation Complete"