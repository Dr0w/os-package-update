#!/bin/bash

# Function to detect the operating system
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
  else
    OS=$(uname -s)
    VER=$(uname -r)
  fi
}

# Function to update packages and handle logging
update_packages() {
  LOGFILE="$HOME/update.log"

  case "$OS" in
    centos)
      if [ "$VER" == "7" ]; then
        sudo yum -y update 2>&1 | tee -a $LOGFILE
        sudo yum -y clean all 2>&1 | tee -a $LOGFILE
      elif [ "$VER" == "8" ]; then
        sudo dnf -y update 2>&1 | tee -a $LOGFILE
        sudo dnf -y clean all 2>&1 | tee -a $LOGFILE
      fi
      ;;
    rhel)
      if [ "$VER" == "8" ]; then
        sudo dnf -y update 2>&1 | tee -a $LOGFILE
        sudo dnf -y clean all 2>&1 | tee -a $LOGFILE
      fi
      ;;
    ubuntu)
    #  if [ "$VER" == "22" ] || [ "$VER" == "24" ]; then
        sudo apt-get update 2>&1 | tee -a $LOGFILE
        sudo apt-get -y upgrade 2>&1 | tee -a $LOGFILE
        sudo apt-get -y autoremove 2>&1 | tee -a $LOGFILE
        sudo apt-get clean 2>&1 | tee -a $LOGFILE
    #  fi
      ;;
    Darwin)
      brew update 2>&1 | tee -a $LOGFILE
      brew upgrade 2>&1 | tee -a $LOGFILE
      brew cleanup 2>&1 | tee -a $LOGFILE
      ;;
    *)
      echo "Unsupported OS: $OS $VER" | tee -a $LOGFILE
      exit 1
      ;;
  esac

  # Check for warnings or errors in the log
  if grep -i "warning\|error" $LOGFILE; then
    echo "Warnings or errors found during update. Check $LOGFILE for details."
  else
    echo "Update completed successfully with no warnings or errors."
    rm $LOGFILE
  fi
}

# Main script execution
detect_os
update_packages