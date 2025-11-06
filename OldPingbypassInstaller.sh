internalip=$( hostname -I | awk '{print $1}' )

#print the credits first
echo $'brought to you by HAV0X of'
echo $'                                                                            
 ▄▄           ▐      ▗              ▗▄▄  ▝          ▐                       
▐▘ ▘ ▄▖ ▗▗▖  ▄▟  ▄▖ ▗▟▄  ▄▖  ▖▄     ▐ ▝▌▗▄  ▗▗▖  ▄▄ ▐▄▖ ▗ ▗ ▗▄▖  ▄▖  ▄▖  ▄▖ 
▝▙▄ ▝ ▐ ▐▘▐ ▐▘▜ ▐ ▝  ▐  ▝ ▐  ▛ ▘    ▐▄▟▘ ▐  ▐▘▐ ▐▘▜ ▐▘▜ ▝▖▞ ▐▘▜ ▝ ▐ ▐ ▝ ▐ ▝ 
  ▝▌▗▀▜ ▐ ▐ ▐ ▐  ▀▚  ▐  ▗▀▜  ▌      ▐    ▐  ▐ ▐ ▐ ▐ ▐ ▐  ▙▌ ▐ ▐ ▗▀▜  ▀▚  ▀▚ 
▝▄▟▘▝▄▜ ▐ ▐ ▝▙█ ▝▄▞  ▝▄ ▝▄▜  ▌      ▐   ▗▟▄ ▐ ▐ ▝▙▜ ▐▙▛  ▜  ▐▙▛ ▝▄▜ ▝▄▞ ▝▄▞ 
                                                 ▖▐      ▞  ▐               
                                                 ▝▘     ▝▘  ▝               
'
echo $'Sandstar Pingbypass can be found at http://discord.gg/5HVsNJrVWM'

#make sure this is being run in the home dir and not anywhere else
if [ $PWD != ~ ]; then
	echo $'This script MUST be run in the home directory!\nThis script will NOT work elsewhere!'
	exit 0
fi

#ask for user input for ip, port, password, and OS type
#if the user is on something NOT ubuntu based, different java-related things will be used
read -p $'Is the VM Ubuntu based? Input only [y/n] for Yes or No.\nIf you are unsure, use n for No.' ubuntu
read -p $'What port would you like to use for Pingbypass? \n' openport
read -p $'What password would you like Pingbypass to use? \n' pass
read -p $'Input the email of the Minecraft account you want on the server.\n' email
read -p $'Input the password of the Minecraft account you want on the server.\n' password

#install dependencies
sudo apt update -y && sudo apt install wget -y
if [ $ubuntu == n ]; then
	wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u345-b01/OpenJDK8U-jdk_x64_linux_hotspot_8u345b01.tar.gz
	tar -xf OpenJDK8U-jdk_x64_linux_hotspot_8u345b01.tar.gz
	sudo update-alternatives --install /usr/bin/java java ~/jdk8u345-b01/bin/java 100
else
	sudo apt install openjdk-8-jdk
fi

#make config files, directories and input relevant configs
mkdir ~/HeadlessMC -p && touch ~/HeadlessMC/config.properties && cat >> ~/HeadlessMC/config.properties<<EOL 
hmc.java.versions=/usr/bin/java
hmc.invert.jndi.flag=true
hmc.invert.lookup.flag=true
hmc.invert.lwjgl.flag=true
hmc.invert.pauls.flag=true
hmc.jvmargs=-Xmx1700M -Dheadlessforge.no.console=true
EOL
mkdir ~/.minecraft/earthhack -p && touch ~/.minecraft/earthhack/pingbypass.properties && cat >> ~/.minecraft/earthhack/pingbypass.properties<<EOL
pb.server=true
pb.ip=$internalip
pb.port=$openport
pb.password=$pass
EOL
mkdir ~/.minecraft/mods -p

#download mods and hmc and move them to the proper places
wget https://github.com/3arthqu4ke/3arthh4ck/releases/download/1.8.3/3arthh4ck-1.8.3-release.jar && mv 3arthh4ck-1.8.3-release.jar ~/.minecraft/mods
wget https://github.com/3arthqu4ke/HMC-Specifics/releases/download/1.0.3/HMC-Specifics-1.12.2-b2-full.jar && mv HMC-Specifics-1.12.2-b2-full.jar ~/.minecraft/mods
wget https://github.com/3arthqu4ke/HeadlessForge/releases/download/1.2.0/headlessforge-1.2.0.jar && mv headlessforge-1.2.0.jar ~/.minecraft/mods
wget https://github.com/3arthqu4ke/HeadlessMc/releases/download/1.5.2/headlessmc-launcher-1.5.2.jar

#setup login and download of minecraft and forge
java -jar headlessmc-launcher-1.5.2.jar --command login $email $password
java -jar headlessmc-launcher-1.5.2.jar --command download 1.12.2
java -jar headlessmc-launcher-1.5.2.jar --command forge 1.12.2

#Download playit.gg
wget https://github.com/playit-cloud/playit-agent/releases/download/v0.9.3/playit-0.9.3 && chmod +x playit-0.9.3

#tell user how to use playit.gg and how to launch server
echo $"To connect to your server, run ./playit-0.9.3. When the browser opens, click where it says 'create a guest account' and then click 'Add tunnel'. For 'Tunnel Type' choose 'Minecraft Java' then click 'Next'. Set Local IPV4 to $internalip and Local Port to $openport Click 'Next' and then 'Create Tunnel'. Click the X in the top right of the box, and keep the browser window open.

Now open another terminal, and run HeadlessMC with 'java -jar headlessmc-launcher-1.5.2.jar' and use 'launch [id number next to the forge install] -id' to launch the Pingbypass server.

On 3arthh4ck in the multiplayer menu, turn Pingbypass ON, and click the book to edit your connection details. For Proxy-IP put the IP of the tunnel from playit.gg, and for Proxy-Port, the port from playit.gg. In the last box, put in your Pingbypass password, which is $pass.

For your reference, your Internal IP is $internalip, your minecraft port $openport, and pingbypass password is $pass"
