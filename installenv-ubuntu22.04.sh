#!/bin/env bash
# This was written for Ubuntu 20.04 LTS
# The script is to be executed as the superuser ("sudo su")
# Some inputs are expected while the script is being run

read -p "Enter your username: " username
# Check username correctness
[[ $(grep "^${username}:" /etc/passwd) ]] || (read -p "Invalid user name. Exiting" && exit)

sourcedir="/home/${username}/bin/source"
bindir="/home/${username}/bin"
#Enter MODELLER installation key. You only have to register and replace "xxx" with it. 
read -p "Enter your MODELLER key: " modeller_key

#Directory for downloaded sources
mkdir -p ${sourcedir}
mkdir -p ${bindir}

# Dowload binaries ahead of time
cd ${sourcedir} 
wget https://download1.rstudio.org/electron/jammy/amd64/rstudio-2022.12.0-353-amd64.deb &
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh &
wget https://ccsb.scripps.edu/mgltools/download/491/ -O mgltools.tar.gz &
wget https://www.ks.uiuc.edu/Research/vmd/vmd-1.9.3/files/final/vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz &
wget https://az764295.vo.msecnd.net/stable/441438abd1ac652551dbe4d408dfcec8a499b8bf/code_1.75.1-1675893397_amd64.deb &

apt update

# Microsoft fonts and other restricted extras
apt install -y ttf-mscorefonts-installer ubuntu-restricted-extras

#Generic installations
apt install -y vim git muscle autodock autogrid autodock-vina libcanberra-gtk-module grace cmake g++


#Set up vim profile for python (code highlighting & indentation)
cd /home/${username}
if [ -f .vimrc ];then cp .vimrc ".vimrc$(date +%s)";fi
echo "syntax on" > /home/${username}/.vimrc
echo "filetype indent plugin on" >> /home/${username}/.vimrc

# Display paging info in less
echo "LESS+='-M'" >> /home/${username}/.bashrc

# Install R
apt update -qq
apt install --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt install --no-install-recommends r-base
add-apt-repository ppa:c2d4u.team/c2d4u4.0+

# Install RStudio
cd $sourcedir 
#wget https://download1.rstudio.org/electron/jammy/amd64/rstudio-2022.12.0-353-amd64.deb
[[ -f rstudio-2022.12.0-353-amd64.deb ]] && dpkg -i rstudio-2022.12.0-353-amd64.deb;apt -f install

#Get miniconda
#wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
[[ -f Miniconda3-latest-Linux-x86_64.sh ]] && bash Miniconda3-latest-Linux-x86_64.sh -b -p $bindir/miniconda &&. ${bindir}/miniconda/bin/activate && conda init

# Fix color representation in git
echo "export LESS=-R" >> /home/${username}/.bashrc

# Jalview
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda install -y jalview==2.10.5

# Openbabel
conda install -y -c openbabel openbabel

# ACPYPE
conda install -y -c conda-forge acpype

#MODELLER
conda config --add channels salilab
conda install -y modeller
sed -i "s/XXXX/${modeller_key}/" ${bindir}/miniconda/lib/modeller-*.*/modlib/modeller/config.py

#Install Open-Source PyMOL
# Simple method
#conda install -c tpeulen pymol-open-source
# Or from source
#From https://pymolwiki.org/index.php/Linux_Install
cd ${sourcedir}
apt-get install -y python-pmw git build-essential python3-dev libglew-dev libpng-dev libfreetype6-dev libxml2-dev libmsgpack-dev python3-pyqt5.qtopengl libglm-dev libnetcdf-dev
conda install -y -c anaconda pyqt 
git clone https://github.com/schrodinger/pymol-open-source.git
cd pymol-open-source
prefix=${bindir}/pymol-open-source-build
python3 setup.py build install --home=$prefix
ln -s ${bindir}/pymol-open-source-build/bin/pymol /home/${username}/bin/pymol

#Installing GROMACS
cd ${sourcedir}
gmxver="2022"
wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-${gmxver}.tar.gz
tar xfz gromacs-${gmxver}.tar.gz
cd gromacs-${gmxver}
mkdir build && cd build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON
make -j4
make -j4 check
make install
echo "#GROMACS" >> /home/${username}/.bashrc

#Installing MGLTools
cd ${sourcedir}
#wget https://ccsb.scripps.edu/mgltools/download/491/ -O mgltools.tar.gz
[[ -f mgltools.tar.gz ]] && tar -zxvf mgltools.tar.gz
mgltools_ver=`ls -d mgltools_x86_64Linux2*/ | tr -d /`
cd ${mgltools_ver}
./install.sh
echo "#MGLTools setup">> /home/${username}/.bashrc
echo ". ${sourcedir}/${mgltools_ver}/initMGLtools.sh" >> /home/${username}/.bashrc
sed -i "/usr.bin.env python/ c \#\!/usr/bin/env ${sourcedir}/${mgltools_ver}/bin/pythonsh" ${sourcedir}/${mgltools_ver}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py
sed -i "/usr.bin.env python/ c \#\!/usr/bin/env ${sourcedir}/${mgltools_ver}/bin/pythonsh" ${sourcedir}/${mgltools_ver}/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py
echo 'export PATH=$PATH:'"${sourcedir}/${mgltools_ver}/MGLToolsPckgs/AutoDockTools/Utilities24" >> /home/${username}/.bashrc

#PROPKA and PDB2PQR
cd ${sourcedir} && git clone https://github.com/jensengroup/propka && cd propka && pip install .
cd ${sourcedir} && git clone https://github.com/Electrostatics/pdb2pqr && cd pdb2pqr && pip install .

# Vina alternatives 
cd ${sourcedir}
git clone https://github.com/QVina/qvina && chmod +x ${sourcedir}/qvina/bin/qvina*
git clone https://github.com/sirimullalab/vinaXB
conda install -y -c bioconda smina
ln -s ${sourcedir}/vinaXB/linux/vinaXB ${bindir}/vinaXB
ln -s ${sourcedir}/qvina/bin/qvina02 ${bindir}/qvina02
ln -s ${sourcedir}/qvina/bin/qvina-w ${bindir}/qvina-w

#VMD
cd ${sourcedir}
apt install -y rlwrap
#wget https://www.ks.uiuc.edu/Research/vmd/vmd-1.9.3/files/final/vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz
[[ -f vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz ]] && tar zxvf vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz
cd vmd-1.9.3
./configure && cd src
make install
sed -i 's/-b(){}\[\],\&\^%#;|\\\\//' /usr/local/bin/vmd

#VS Code
cd ${sourcedir}
#wget https://az764295.vo.msecnd.net/stable/441438abd1ac652551dbe4d408dfcec8a499b8bf/code_1.75.1-1675893397_amd64.deb
[[ -f code_1.75.1-1675893397_amd64.deb ]] && dpkg -i code_1.75.1-1675893397_amd64.deb

echo ". /usr/local/gromacs/bin/GMXRC" >> /home/${username}/.bashrc
echo "export PATH=${bindir}:"'${PATH}' >> /home/${username}/.bashrc
echo "unset MANPATH" >> /home/${username}/.bashrc
echo "MANDATORY_MANPATH /usr/local/gromacs/share/man" >> /home/${username}/.manpath

echo "Installations done"
