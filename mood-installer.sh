#!/bin/bash
APT_PACKAGES=(sqlite3 libsqlite3-dev neovim xclip python3-pip)
NPM_PACKAGES=(neovim diagnostic-languageserver)
RUBY_VERSIONS=(2.7.1 2.7.3 3.1.1 3.0.3)
GEMS=(solargraph neovim bundler)
MOOD_GIT=(git@github.com:otavioschwanck/mood-nvim.git)
PACKER_GIT=(https://github.com/wbthomason/packer.nvim)
export LAZY_VER="0.31.4" # LAZYGIT VERSION

get_machine_type () {
  unameOut="$(uname -s)"
  case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
  esac
  echo "Proceeding instalation for OS ${machine}"
}

ask_question () {
  echo "Do you wish to install $1?"
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) echo "Installing $1";$2;break;;
      No ) echo "Not installing $1";break;;
    esac
  done
}

# Install base packages
install_packages_linux () {
  echo "================= INSTALLING PACKAGES ================="
  sudo apt-get -qq update
  sudo apt-get -qq install ${APT_PACKAGES[*]} -y
  sudo npm install -s -g ${NPM_PACKAGES[*]} -y
}

install_packages_mac () {
  echo "================= INSTALLING PACKAGES ================="
  brew install readline openssl zlib pg sqlite rben rbenv
}

install_ruby_linux () {
  echo "================= INSTALLING RUBY ================="
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
  git clone https://github.com/rbenv/ruby-build.git
  cat ruby-build/install.sh
  PREFIX=/usr/local sudo ./ruby-build/install.sh
  echo "gem: --no-document" > ~/.gemrc
  for i in $RUBY_VERSIONS; do rbenv install $i -s; echo "Installed ruby version $i"; done
}

install_ruby_mac () {
  echo "================= INSTALLING RUBY ON MAC ================="
  echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.zshrc
  source ~/.zshrc
}

install_fonts () {
  echo "================= INSTALLING FONTES ================="
  mkdir ~/.fonts
  cd; wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip
  unzip -q -o JetBrainsMono.zip -d ~/.fonts
  cd; rm JetBrainsMono.zip
}

install_pip_with_python () {
  if [ "$(which python3)" = "" ]
  then
    echo "Python3 not found, will look for Python"
    python -m pip install neovim-remote pynvim --quiet
  else
    echo "Python3 found, began installing pip"
    python3 -m pip install neovim-remote pynvim --quiet
  fi
}

check_for_previous_nvim () {
  NVIM_DIR=".config/nvim"
  if [ -d "$NVIM_DIR" ]; then
    echo "We found an already installed nvim on your computer!"
    mv ~/.config/nvim ~/.config/nvim-mood-backup
    echo "The files were moved to .config/nvim-mood-backup"
    echo "Now installing mood nvim from main branch."
  fi
}

clone_nvim_repositories () {
  git clone --quiet $MOOD_GIT ~/.config/nvim
  git config --global push.default current
  git clone --quiet --depth 1 $PACKER_GIT ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  cd ~/.local/share/nvim/site/pack/packer/start/packer.nvim; git reset --quiet --hard HEAD; git pull; cd
}

install_nvim () {
  echo "================= INSTALLING NVIM ================="
  install_pip_with_python
  check_for_previous_nvim
  clone_nvim_repositories
  nvim +PackerSync
}

install_gems () {
  echo "================= INSTALLING GEMS ================="
  for i in $GEMS; do gem install i --silent; done
}

install_lazygit_linux () {
  echo "================= INSTALLING LAZY GIT ================="
  wget -q -O lazygit.tgz https://github.com/jesseduffield/lazygit/releases/download/v${LAZY_VER}/lazygit_${LAZY_VER}_Linux_x86_64.tar.gz
  tar xf lazygit.tgz
  sudo mv lazygit /usr/local/bin/
}

install_lazygit_mac () {
  echo "================= INSTALLING LAZY GIT ================="
  brew install jesseduffield/lazygit/lazygit
  brew install lazygit
}

linux_workflow () {
  ask_question "base packages for neovim" install_packages_linux
  ask_question "Ruby on Rails with Rbenv" install_ruby_linux
  ask_question "LazyGit" install_lazygit_linux
}

mac_workflow () {
  ask_question "base packages for neovim" install_packages_mac
  ask_question "Ruby on Rails with Rbenv" install_ruby_mac
  ask_question "LazyGit" install_lazygit_mac
}

# SCRIPT QUESTIONAIRE
get_machine_type
case "${machine}" in
  Linux)     linux_workflow;;
  Darwin)    mac_workflow;;
  *)         echo "OS not recognized"
esac

install_fonts
install_gems
install_nvim

echo "Script finished!"