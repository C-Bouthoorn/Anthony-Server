#!/bin/bash

getPermissions() {
  if [ "$(id -u)" != "0" ]; then
    sudo -n true &> /dev/null

    if [ $? != 0 ]; then
      # Requires password for sudo
      echo "Getting permissions"

      sudo echo "Got permissions"
    fi
  fi
}


# Get current node version
mynode=$(nodejs --version)
if [ $? = 127 ]; then
  echo "No version of NodeJS installed!"

  echo "Installing repo version of NodeJS for libraries"
  getPermissions
  sudo apt-get -y install nodejs npm

  mynode=$(nodejs --version)
fi

# Get latest version of node from site
latestnode=$( curl "https://nodejs.org/en/download/stable/" 2>/dev/null | grep "Current stable version" | grep -Eo "v([0-9]+\.?)+" )

arch=""
if [ "$(uname -m)" = "x86_64" ]; then
 arch="x64"
else
 arch="x86"
fi


# Check for latest version
if [ "$mynode" != "$latestnode" ]; then
  echo "Your NodeJS version ($mynode) is not the latest version ($latestnode)."

  echo "Updating NodeJS"

  echo -e "\nCreating temporary directory to save files"
  mkdir nodejstmp
  cd nodejstmp

  echo -e "\nDownloading latest version..."
  wget "https://nodejs.org/dist/$latestnode/node-$latestnode-linux-$arch.tar.xz"

  echo -e "\nExtracting package"
  tar -xf "node-$latestnode-linux-$arch.tar.xz"

  echo -e "\nTesting version"
  cd "node-$latestnode-linux-$arch"

  newversion=$(./bin/node --version)
  echo "Found version $newversion"

  if [ "$newversion" = "$latestnode" ]; then
    echo "New version found!"

    getPermissions

    echo -e "\nCopying new version"
    sudo cp -R . "/usr/local/bin/node-$latestnode"

    echo -e "\nRemoving old backup links"
    sudo rm -f /usr/local/bin/node.bak &>/dev/null
    # sudo rm -f /usr/local/bin/npm.bak &>/dev/null

    echo -e "\nMoving old links to backup file"
    sudo mv /usr/local/bin/node /usr/local/bin/node.bak &>/dev/null
    # sudo mv /usr/local/bin/npm /usr/local/bin/npm.bak &>/dev/null

    echo -e "\nCreating new links"
    sudo ln -s "/usr/local/bin/node-$latestnode/bin/node" "/usr/local/bin/node"
    # sudo ln -s "/usr/local/bin/node-$latestnode/bin/npm" "/usr/local/bin/npm"

    echo -e "\nChecking link"
    if [ ! -f "/usr/local/bin/nodejs" ]; then
      echo "Creating link"
      sudo ln "/usr/local/bin/node" "/usr/local/bin/nodejs"
    fi
  else
    echo -e "\nFailed to get new version. Is your connection still working?"
  fi
else
  echo "Your NodeJS version ($mynode) is up-to-date!"
fi

