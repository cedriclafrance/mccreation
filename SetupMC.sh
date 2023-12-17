#!/bin/bash
######################################################################################################################################
# Create the required directories
echo "What would you like to name your server??"
read servername
mkdir $servername
chmod 777 $servername
cd $servername
######################################################################################################################################
# Variables
USER=$(whoami)
DATE=$(date +"%y%m%d")
TIME=$(date +"%H%M%S")
LOGDATE=$(date +"%y/%m/%d")
TIMESTAMP=$(date +"%H:%M:%S")
LOGLOCATION=/home/clafr/Logs
WORLDLOCATION=/home/$USER/$servername
######################################################################################################################################
# Verify log directory, create log file
if [ ! -d "$log_directory" ]; then
    mkdir -p "$log_directory"
fi
touch "${LOGLOCATION}/setupmc_${DATE}"
######################################################################################################################################
# Install required tools and SSH
sudo apt install openssh-server -y
echo "{$LOGDATE-$TIMESTAMP} Installed openssh-server" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo systemctl status ssh
echo "{$LOGDATE-$TIMESTAMP} Installed SSH" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo ufw allow ssh
echo "{$LOGDATE-$TIMESTAMP} Allowed SSH" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo apt install nano -y
echo "{$LOGDATE-$TIMESTAMP} Installed nano" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo apt install openjdk-17-jdk -y
sudo apt install openjdk-17-source -y
echo "{$LOGDATE-$TIMESTAMP} Installed OpenJDK 17" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo apt install screen -y
echo "{$LOGDATE-$TIMESTAMP} Installed screen" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo apt install cifs-utils -y
sudo apt-get install jq -
sudo apt-get update -y
sudo apt-get upgrade -y
echo "{$LOGDATE-$TIMESTAMP} Installed Updates" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo apt-get autoclean
######################################################################################################################################
# Function to get the latest PaperMC version from API
get_latest_papermc_version() {
    local latest_version=$(curl -s "https://papermc.io/api/v2/projects/paper" | jq -r '.version.versions[-1]')
    echo "$latest_version"
}

# Function to download the latest PaperMC version
download_papermc() {
    local version=$1
    local download_url="https://papermc.io/api/v2/projects/paper/versions/$version/builds/latest/downloads/paper-$version.jar"
    
    # Download the PaperMC version
    wget -O "paper-$version.jar" "$download_url"
    
    if [ $? -eq 0 ]; then
        echo "PaperMC version $version downloaded successfully."
        
        # Create the start.sh file with the appropriate command
        echo "java -Xms6144M -Xmx6144M -jar paper-$version.jar nogui" > start.sh
        chmod +x start.sh
    else
        echo "Failed to download PaperMC version $version."
        exit 1
    fi
}

# Get the latest PaperMC version
latest_version=$(get_latest_papermc_version)

if [ -z "$latest_version" ]; then
    echo "Failed to fetch the latest PaperMC version. Check your internet connection or the PaperMC API."
    exit 1
fi

# Download the latest PaperMC version and create start.sh
download_papermc "$latest_version"
######################################################################################################################################
# Generate the MC Server files
sudo ./start.sh
#sudo chmod 777 -R ./*
#echo "{$LOGDATE-$TIMESTAMP} Generating server files" >>  "${LOGLOCATION}/setupmc_${DATE}"
######################################################################################################################################
# Agree to EULA terms
sed -i 's/false/true/g' eula.txt
echo "{$LOGDATE-$TIMESTAMP} EULA accepted" >>  "${LOGLOCATION}/setupmc_${DATE}"
######################################################################################################################################
# Modify the server properties
sudo chmod 777 -R ./*
sed -i "s/^motd=.*/port=\u00A76\u00A7l$servername Vanilla Server \n\u00A7b\u00A7o$version/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Banner changed" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i 's/^simulation-distance=.*/simulation-distance=8/' server.properties
sed -i 's/^view-distance=.*/view-distance=10/' server.properties
echo "{$LOGDATE-$TIMESTAMP} Viewing distance set" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i "s/^level-name=.*/level-name==$servername/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Servername set" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i 's/^max-players=.*/max-players=10/' server.properties
echo "{$LOGDATE-$TIMESTAMP} Max player set" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i 's/^spawn-protection=.*/spawn-protection=0/' server.properties
echo "{$LOGDATE-$TIMESTAMP} Spawn protection off" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i 's/^max-tick-time=.*/max-tick-time=-1/' server.properties
echo "{$LOGDATE-$TIMESTAMP} Spawn protection off" >>  "${LOGLOCATION}/setupmc_${DATE}"
sed -i 's/^difficulty=.*/difficulty=hard/' server.properties
echo "{$LOGDATE-$TIMESTAMP} Difficulty set to hard" >>  "${LOGLOCATION}/setupmc_${DATE}"

echo "What port would you like to use?"
read port
sed -i "s/^server-port=.*/server-port=$port/" server.properties
sed -i "s/^query.port=.*/query.port=$port/" server.properties
sed -i "s/^rcon.port=.*/rcon.port=$port/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Network port set to $port" >>  "${LOGLOCATION}/setupmc_${DATE}"
echo "What gamemode would you like (survival, creative, hardcore)?"
read gamemode
sed -i "s/^gamemode=.*/gamemode=$gamemode/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Gamemode set to $port" >>  "${LOGLOCATION}/setupmc_${DATE}"
echo "What see would you like to use (leave empty if random)?"
read seed
sed -i "s/^level-seed=.*/level-seed=$seed/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Using seed $seed" >>  "${LOGLOCATION}/setupmc_${DATE}"
echo "What type of world would you want (default, flat, largebiomes, amplified, buffet)?"
read worldtype
sed -i "s/^level-type=.*/level-type=$worldtype/" server.properties
echo "{$LOGDATE-$TIMESTAMP} Using level-type $worldtype" >>  "${LOGLOCATION}/setupmc_${DATE}"
######################################################################################################################################
# Create, Enable, Start mcserver.service
sudo touch /etc/systemd/system/mcserver.service
sudo nano /etc/systemd/system/mcserver.service
cd /etc/systemd/system/
echo '[Unit]' > /etc/systemd/system/mcserver.service
echo 'Description=Minecraft Server Startup' >> /etc/systemd/system/mcserver.service
echo '# After=network.target' >> /etc/systemd/system/mcserver.service
echo '# After=systemd-user-sessions.service' >> /etc/systemd/system/mcserver.service
echo '# After=network-online.target' >> /etc/systemd/system/mcserver.service
echo '' >> /etc/systemd/system/mcserver.service
echo '[Service]' >> /etc/systemd/system/mcserver.service
echo 'RemainAfterExit=yes' >> /etc/systemd/system/mcserver.service
echo "WorkingDirectory=$WORLDLOCATION" >> /etc/systemd/system/mcserver.service
echo "User=$USER" >> /etc/systemd/system/mcserver.service
echo '# Start Screen, Java, and Minecraft' >> /etc/systemd/system/mcserver.service
echo 'ExecStart=screen -s mc -d -m ./start.sh' >> /etc/systemd/system/mcserver.service
echo '# Tell Minecraft to gracefully stop.' >> /etc/systemd/system/mcserver.service
echo '# Ending Minecraft will terminate Java' >> /etc/systemd/system/mcserver.service
echo '# systemd will kill Screen after the 10-second delay. No explicit kill for Screen needed' >> /etc/systemd/system/mcserver.service
echo 'ExecStop=screen -p 0 -S mc -X eval 'stuff "say SERVER SHUTTING DOWN. Saving map..."\015'' >> /etc/systemd/system/mcserver.service
echo 'ExecStop=screen -p 0 -S mc -X eval 'stuff "save-all"\015'' >> /etc/systemd/system/mcserver.service
echo 'ExecStop=screen -p 0 -S mc -X eval 'stuff "stop"\015'' >> /etc/systemd/system/mcserver.service
echo 'ExecStop=sleep 10' >> /etc/systemd/system/mcserver.service
echo '' >> /etc/systemd/system/mcserver.service
echo '[Install]' >> /etc/systemd/system/mcserver.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/mcserver.service
echo "{$LOGDATE-$TIMESTAMP} Created mcserver.service" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo systemctl enable mcserver
echo "{$LOGDATE-$TIMESTAMP} mcserver.service enabled" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo systemctl start mcserver
echo "{$LOGDATE-$TIMESTAMP} mcserver.service started" >>  "${LOGLOCATION}/setupmc_${DATE}"
sudo systemctl status mcserver
######################################################################################################################################
# Confirm
if systemctl is-active --quiet mcserver.service && systemctl is-enabled --quiet mcserver.service; then
    echo "Server is running"
    echo "Script Completed Successfully. Please open $port for IP address $(hostname -I | awk '{print $1}')"
else
    echo "Server is not running, please check the logs under $LOGLOCATION"
fi
echo "Script Completed Successfully: $(hostname -I | awk '{print $1}')"
######################################################################################################################################
