#! /bin/bash

##################################################################################
## Our main bash script file:
## 
## to use: ./setup_vm-NEW.sh
## 
##################################################################################

## Some basic varibles:
timeofday=$(date)
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

export GREEN
export RED
export BLUE
export YELLOW
export MAGENTA
export CYAN
export WHITE
export NC

##################################################################################
## Create the Banner to be used everywhere:
##################################################################################
function banner(){
echo "░  ░░░░  ░░░      ░░░░      ░░░  ░░░░  ░░       ░░░░      ░░░░      ░░░   ░░░  ░░░░░░░░░      ░░░        ░░        ░";
echo "▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒  ▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒    ▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒▒";
echo "▓        ▓▓  ▓▓▓▓  ▓▓  ▓▓▓▓▓▓▓▓     ▓▓▓▓▓       ▓▓▓  ▓▓▓▓▓▓▓▓  ▓▓▓▓  ▓▓  ▓  ▓  ▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓      ▓▓▓";
echo "█  ████  ██        ██  ████  ██  ███  ███  ███  ███  ████  ██  ████  ██  ██    ████████  ████  █████  █████  ███████";
echo "█  ████  ██  ████  ███      ███  ████  ██  ████  ███      ████      ███  ███   █████████      ██████  █████  ███████";
echo "                                                                                                                    ";
}
##################################################################################

##################################################################################
## Setting up CLI Logging:
##################################################################################
function cli-logging(){

    # Change the kali user's shell to BASH
    chsh -s /bin/bash

    # Update the apt cache:
    echo "Updating the APT Cache:"
    sudo apt update
    echo "Done."
    echo

    # Install rsyslog and other tools:
    echo "Installing rsyslog and some tools:"
    sudo apt install -y rsyslog golang terminator cherrytree tmux screen libpcap-dev massdns flatpak python3-venv
    echo "Done."
    
    # Set up the logging of our commands:
    echo "Adding the logging info to the /etc/rsyslog.d directory:"
    echo "Working Directory: $(pwd)"
    sudo cp configs/bash.conf /etc/rsyslog.d/
    echo
    echo

    # Add the logging information into the current logged in user's .zshrc file:
    echo "Adding the logging info to the current user's account:"
    echo "Working Directory: $(pwd)"
    sudo cat configs/zshrc_update.conf >> ~/.zshrc
    sudo cat configs/bashrc_update.conf >> ~/.bashrc
    #source ~/.zshrc
    echo "Done."
    echo
    echo

    # Add the config information into the /etc/skel .zshrc and .bashrc files:
    echo "Updating the /etc/skel files:"
    echo "Working Directory: $(pwd)"
    sudo cp configs/zshrc_updates.dist /etc/skel/.zshrc
    sudo cp configs/bashrc_updates.dist /etc/skel/.bashrc
    echo "Done."
    
    # Restart the rsyslog service:
    sudo systemctl restart rsyslog
    
    # Finished.
    echo "Finished setting up the CLI Logging. Now, let's set up the default directories."
    
    # Let's make some default directories:
    # First, the scripts directory.  Test to make sure the directory isn't already there:
    if [ -d "~/scripts" ]; then
        echo "~/scripts Directory exists. Skipping."
    else
        echo "Creating the ~/scripts directory."
        mkdir ~/scripts
    fi

    # Next, add to the Downloads directory.  Test to make sure the directory isn't already there:
    if [ -d "~/Downloads/Software" ]; then
        echo "~/Downloads/Software Directory exists. Skipping."
    else
        echo "Creating the ~/Downloads/Software directory."
        mkdir -p ~/Downloads/Software
    fi

    # Next, the tools directory.  Test to make sure the directory isn't already there:
    if [ -d "~/tools" ]; then
        echo "~/tools Directory exists. Skipping."
    else
        echo "Creating the ~/tools directory."
        mkdir ~/tools
    fi
    
    # Add the update script to the ~/scripts directory:
    echo -e "#! /bin/bash\n\n\nsudo apt update\nsudo apt upgrade -y\nsudo apt dist-upgrade -y\nsudo apt auto-remove -y" > ~/scripts/update.sh && chmod u+x ~/scripts/update.sh
    echo -e "#! /bin/bash\n\n\nwhoami" > ~/scripts/whoamiscript.sh && chmod u+x ~/scripts/whoamiscript.sh
    echo
    echo
    
    # Let the user know you are finished:
    echo
    echo "Done. Will now reboot."
    sleep 5
    sudo reboot
}

##################################################################################
## Update VM:
##################################################################################
function update-vm(){
    echo "Starting the update script"
    ~/scripts/update.sh
    
    # Reboot the VM:
    echo "Done. Will now reboot."
    sleep 5
    sudo reboot
}

##################################################################################
## Install Docker:
##################################################################################
function install-docker(){
   # Remove Podman:
   #sudo apt remove podman -y && sudo apt purge podman -y
   
   # Test to make sure Docker isn't already on the system:
   if command -v docker &> /dev/null; then
       echo "Docker is already installed, skipping installation."
   else
      echo "Docker is not installed, installing it now."
      
      # Add the docker apt source
      printf '%s\n' "deb https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker-ce.list

	  # Next, let's download and import the gpg key
      curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-ce-archive-keyring.gpg

      # Update the APT Cache:
      sudo apt-get update
    
      # Install docker and docker-compose components:
      #sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin
      sudo apt install docker-ce docker-ce-cli containerd.io -y
      
      # Start Docker:
      sudo service docker start
   fi

    # Set the current user to run docker with root previlages:
    echo "Adding the current user to the docker group."
    sudo adduser $USER docker
    echo "$USER has been added to the docker group.  You will need to log out and back in again or restart the VM."
    echo -e "\n# Setting the docker socket:\nexport DOCKER_HOST=unix:///var/run/docker.sock" >> ~/.bashrc
    
    # Reboot the VM:
    echo "Done. Will now reboot."
    sleep 5
    sudo reboot
}

##################################################################################
## Install Netbird client:
##################################################################################
function install-netbird(){
    echo "This is where we install netbird client."
    #curl -fsSL https://pkgs.netbird.io/install.sh | sh
    
    # Add the repository:
    sudo apt-get update
    sudo apt install ca-certificates curl gnupg -y
    curl -sSL https://pkgs.netbird.io/debian/public.key | sudo gpg --dearmor --output /usr/share/keyrings/netbird-archive-keyring.gpg
    echo 'deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main' | sudo tee /etc/apt/sources.list.d/netbird.list

    # Update first:
    sudo apt-get update

    # Install the Clientl
    sudo apt-get install netbird netbird-ui

    # Reboot the VM:
    echo "Done. Netbird is installed.  Will now reboot."
    sleep 5
    sudo reboot
}

##################################################################################
## Set up SecureWV 15 CTF:
##################################################################################

##################################################################################
## Install Project Discovery tools via PDTM:
##################################################################################
function install-pdtm(){
    echo "Installing PDTM:"
    go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest
    echo
    echo
    echo "Finished install PDTM, Installing all Project Discovery Tools:"
    pdtm -ia
    
echo -e "\n\
# Fix for Project Discovery's HTTPX:\n\
alias httpx=\"~/.pdtm/go/bin/httpx\"\n\
alias otherhttpx=\"/usr/bin/httpx\""\
>> ~/.bash_aliases

    echo
    echo
    echo "PDTM and Project Discovery tools are installed."
    
    # Reboot the VM:
    echo "Done. Will now reboot."
    sleep 5
    sudo reboot
}

##################################################################################
## Start WhileLoop for Menu:
##################################################################################
while true
do
    clear
    banner
    echo
    echo " Today is: $timeofday"
    echo " What can I do for you today?"
    echo
    echo " 1) Setup CLI logging and default directories.  Will require a reboot."
    echo " 2) Update VM.  Will reboot after update."
    echo " 3) Install Docker.  Will reboot after install."
    echo " 4) Install netbird client.  Will reboot after install."
    echo " 5) Install Project Discovery Tools.(Optional)  Will reboot after install."
    echo
    #echo " (R)eboot"
    echo " (Q)uit"
    read choice
    
    case $choice in
    	[1])
    	    cli-logging
    	    ;;
	[2])
            update-vm
            ;;
	[3])
            install-docker
            ;;
	[4])
            install-netbird
            ;;
	[5])
            install-pdtm
            ;;
        [Rr])
            sudo reboot
            ;;
    	[Qq])
  	    echo
    	    echo "Have a nice day."
    	    echo 
    	    exit;;
    	*)
    	    echo "Incorrect Choice.  Please try again."
    	    ;;
    esac
    echo
    #echo -e "Enter return to continue...."
    read answer
done
