#!/usr/bin/env bash
# Fixed version: fixes netlink socket warning by using safer IP detection
# and fixes broken splash/quoting that caused "command not found" and syntax errors.

set -euo pipefail
IFS=$'\n\t'

# variables
internalip=$(ip -4 addr show scope global | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1 || true) # safer than netlink route get
externalip=""
javadir="$HOME/jdk1.8.0_321/bin"
hmcdir="$HOME/HeadlessMC"
modsdir="$HOME/.minecraft/mods"
mcdir="$HOME/.minecraft/versions/1.12.2"
launch="$HOME/launchpb"

# try external ip only if curl exists (avoid hanging)
if command -v curl >/dev/null 2>&1; then
  externalip=$(curl -4 --max-time 8 -s https://ifconfig.me || true)
fi

# ensure this is being run in the home dir and not anywhere else
if [ "${PWD:-}" != "$HOME" ]; then
	echo "**This script MUST be run in the home directory!**"
	echo "**This script will NOT work elsewhere!**"
	exit 1
fi

# check for wget, and require the user to install it
if ! command -v wget >/dev/null 2>&1; then
	echo "wget is not installed. Install it with 'sudo apt install wget' if you are on a Debian/Ubuntu system."
	exit 1
fi

# check for curl, and pester the user if they dont have it (non-fatal)
if ! command -v curl >/dev/null 2>&1; then
	echo
	echo 'curl is not installed. Install it with "sudo apt install curl" if you are on a Debian/Ubuntu based system.'
	echo
	sleep 3
fi

# splash (fixed quoting — use a heredoc to avoid quote problems)
cat <<'SPLASH'
The proper pingbypass installer
Rewrite by NeverForeverX

  NEVRForverX

SPLASH

echo "Sandstar Pingbypass can be found at http://discord.gg/5HVsNJrVWM"
sleep 2
echo "This script will NOT do any network setup for you, nor log in to HeadlessMC."
echo "If any directories already exist, they will not be created/written into."
sleep 1

# ask for user input for ip, port, password, and version
# use plain read prompts (avoid nested $'..' quoting)
read -p "What port would you like to use for Pingbypass? " openport
read -p "What password would you like the Pingbypass server to use? " pass
read -p "What is the latest RELEASE version of 3arthh4ck on Github? (e.g. 1.8.4) " ver

# install java if it hasn't been installed before (basic check)
if [ ! -x "$javadir/java" ]; then
	echo "Java not found at $javadir/java — attempting to download JDK 8u321 (best-effort)."
	# NOTE: URL may change; prefer installing via package manager if possible
	wget -q "https://javadl.oracle.com/webapps/download/GetFile/1.8.0_321-b07/df5ad55fdd604472a86a45a217032c7d/linux-i586/jdk-8u321-linux-x64.tar.gz" -O /tmp/jdk-8u321-linux-x64.tar.gz || true
	if [ -f /tmp/jdk-8u321-linux-x64.tar.gz ]; then
		tar -xf /tmp/jdk-8u321-linux-x64.tar.gz -C "$HOME"
		rm -f /tmp/jdk-8u321-linux-x64.tar.gz
	else
		echo "Could not download JDK automatically. Please install Java and re-run the script."
	fi
fi

# make config files, directories and input relevant configs if they dont exist
if [ ! -d "$hmcdir" ]; then
	mkdir -p "$hmcdir"
	cat > "$hmcdir/config.properties" <<EOL
hmc.java.versions=$javadir/java
hmc.invert.jndi.flag=true
hmc.invert.lookup.flag=true
hmc.invert.lwjgl.flag=true
hmc.invert.pauls.flag=true
hmc.jvmargs=-Xmx1700M -Dheadlessforge.no.console=true
EOL

	mkdir -p "$HOME/.minecraft/earthhack"
	cat > "$HOME/.minecraft/earthhack/pingbypass.properties" <<EOL
pb.server=true
pb.ip=${internalip:-}
pb.port=${openport:-}
pb.password=${pass:-}
EOL
	# restrict permission on the file containing password
	chmod 600 "$HOME/.minecraft/earthhack/pingbypass.properties" || true
fi

# download mods and hmc and move them to the proper places if not already downloaded
mkdir -p "$modsdir"
if [ ! -f "$modsdir/3arthh4ck-$ver-release.jar" ]; then
	wget "https://github.com/3arthh4ckDevelopment/3arthh4ck-Client/releases/download/$ver/3arthh4ck-$ver-release.jar" -O "$modsdir/3arthh4ck-$ver-release.jar" || echo "Failed downloading 3arthh4ck-$ver"
fi
if [ ! -f "$modsdir/HMC-Specifics-1.12.2-b2-full.jar" ]; then
	wget "https://github.com/3arthqu4ke/HMC-Specifics/releases/download/1.0.3/HMC-Specifics-1.12.2-b2-full.jar" -O "$modsdir/HMC-Specifics-1.12.2-b2-full.jar" || true
fi
if [ ! -f "$modsdir/headlessforge-1.2.0.jar" ]; then
	wget "https://github.com/3arthqu4ke/HeadlessForge/releases/download/1.2.0/headlessforge-1.2.0.jar" -O "$modsdir/headlessforge-1.2.0.jar" || true
fi
# headlessmc launcher in home
if [ ! -f "$HOME/headlessmc-launcher-2.6.1.jar" ]; then
	wget "https://github.com/3arthqu4ke/HeadlessMc/releases/download/2.6.1/headlessmc-launcher-2.6.1.jar" -O "$HOME/headlessmc-launcher-2.6.1.jar" || true
fi

# download minecraft and forge if not already done and login
if [ ! -d "$mcdir" ]; then
	if [ -x "$javadir/java" ] && [ -f "$HOME/headlessmc-launcher-2.6.1.jar" ]; then
		"$javadir/java" -jar "$HOME/headlessmc-launcher-2.6.1.jar" --command download 1.12.2 || echo "Download command returned non-zero"
		"$javadir/java" -jar "$HOME/headlessmc-launcher-2.6.1.jar" --command forge 1.12.2 || echo "Forge install command returned non-zero"
	else
		echo "Skipping automatic minecraft/forge download: Java or launcher missing."
	fi
fi

# make launch file for pb server if it hasn't been made already
if [ ! -f "$launch" ]; then
	cat > "$HOME/hmc" <<'EOL'
#!/usr/bin/env bash
JAVA="$HOME/jdk1.8.0_321/bin/java"
exec "$JAVA" -jar "$HOME/headlessmc-launcher-2.6.1.jar" "$@"
EOL
	chmod +x "$HOME/hmc"
fi

# tell user how to use hmc and how to launch server
cat <<EOF

Run HeadlessMC with './hmc' and login to your Minecraft account with 'login [email] and password [password]'.
Use 'launch [id number next to the forge install] -id' to launch the Pingbypass server.

On 3arthh4ck in the multiplayer menu, turn Pingbypass ON, and input these connection details:
IP: ${externalip:-<external-ip-unknown>}
Port: ${openport}
Password: (stored in ~/.minecraft/earthhack/pingbypass.properties; file permission set to 600)

EOF