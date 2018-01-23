# This was written for xenial, but may work for later distros as well (with some tweaking)
read -p "Enter your username: " username
# Check username correctness
[[ $(grep "^${username}:" /etc/passwd) ]] || (read -p "Invalid user name. Exiting" && exit)

sourcedir="/home/${username}/bin/source"
#Enter MODELLER installation key. You only have to register and replace "xxx" with it. 
read -p "Enter your MODELLER key: " modeller_key

#Directory for downloaded sources
mkdir -p ${sourcedir}

#Set up vim profile for python (code highlighting & indentation)
cd /home/${username}
if [ -f .vimrc ];then cp .vimrc ".vimrc$(date +%s)";fi
echo "syntax on" > /home/${username}/.vimrc
echo "filetype indent plugin on" >> /home/${username}/.vimrc

#Add R repo to trusty sources (sudo)
distro=$(lsb_release -c | sed 's/Codename:\s*//')
line="http://cran.mirror.ac.za/bin/linux/ubuntu"
grep -q $line /etc/apt/sources.list || echo "deb $line ${distro}/">> /etc/apt/sources.list && \
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

#Generic installations (sudo)
apt-get update
apt-get install cmake libjpeg62 python3-pip python2-pip idle-python3.* pymol vim git openbabel muscle jalview \
     autodock autogrid autodock-vina icedtea-*-plugin libjpeg62 exfat-utils flashplugin-installer \
     exfat-fuse gimp  plink emboss octave octave-info grace r-base-core r-base-dev gfortran libx11-dev \
     liblzma-dev csh libxml2 figtree labyrinth dia pdb2pqr libxml2-dev libopenblas-dev cython

#Python (2&3) libraries

pip3 install --upgrade pip && pip3 install numpy scipy matplotlib biopython python-igraph cython tensorflow\
     Theano keras joblib pandas jupyter ipywidgets
pip3 install mdtraj

pip install --upgrade pip
pip install numpy scipy matplotlib cython mdtraj tensorflow sierrapy

#R libraries
sudo apt-get install r-cran-rgl r-cran-ggplot2 r-cran-nnet r-cran-amore r-cran-caret r-cran-seqinr

#Install MODELLER (sudo)
cd ${sourcedir}
wget "https://salilab.org/modeller/9.19/modeller_9.19-1_amd64.deb"
sudo dpkg -i modeller_9.19-1_amd64.deb 
sudo sed -i 's/xxx/${modeller_key}/' /usr/lib/modeller9.19/modlib/modeller/config.py

#ACPYPE (Preliminary; requires AmberTools to be installed & sourced)
cd ${sourcedir}
git clone https://github.com/t-/acpype acpype
ln -s ${sourcedir}/acpype/acpype.py /home/${username}/bin/acpype

###AmberTools#######
#firefox http://ambermd.org/cgi-bin/AmberTools16-get.pl
#tar jxvf AmberTools15.tar.bz2
#cd amber14
#export AMBERHOME=`pwd`
#./configure gnu
     # We recommend you say "yes" when asked to apply updates
#source amber.sh # Use amber.csh if you use tcsh or csh
#sudo make install
#echo "source $AMBERHOME/amber.sh" >> ~/.bashrc  # Add Amber to your environment

####################

#Installing GROMACS 2016.4
cd ${sourcedir}
wget "ftp://ftp.gromacs.org/pub/gromacs/gromacs-2016.4.tar.gz"
tar xfz gromacs-2016.4.tar.gz
cd gromacs-2016.4
mkdir build
cd build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON
make >> gromacs_make.log
make check >> gromacs_make_check.log
sudo make install
echo ". /usr/local/gromacs/bin/GMXRC" >> /home/${username}/.bashrc

#Installing RStudio
cd ${sourcedir}
wget "https://download1.rstudio.org/rstudio-0.99.902-amd64.deb"
sudo dpkg -i rstudio-0.99.902-amd64.deb
 
#Installing MGLTools
cd ${sourcedir}
wget "http://mgltools.scripps.edu/downloads/downloads/tars/releases/REL1.5.6/mgltools_x86_64Linux2_1.5.6.tar.gz"
tar -zxvf mgltools_x86_64Linux2_1.5.6.tar.gz
cd mgltools_x86_64Linux2_1.5.6
./install.sh
echo "#MGLTools setup">> /home/${username}/.bashrc
echo "alias pmv='${sourcedir}/mgltools_x86_64Linux2_1.5.6/bin/pmv'" >> /home/${username}/.bashrc
echo "alias adt='${sourcedir}/mgltools_x86_64Linux2_1.5.6/bin/adt'" >> /home/${username}/.bashrc
echo "alias vision='${sourcedir}/mgltools_x86_64Linux2_1.5.6/bin/vision'" >> /home/${username}/.bashrc
echo "alias pythonsh='${sourcedir}/mgltools_x86_64Linux2_1.5.6/bin/pythonsh'" >> /home/${username}/.bashrc
echo "export PYTHONPATH=$PYTHONPATH:${sourcedir}/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs" >> /home/${username}/.bashrc

#DiscoveryStudio
echo "Get DS from 'http://accelrys.com/products/collaborative-science/biovia-discovery-studio/visualization-download.php'" 
echo "Then Run ./activateDiscoveryStudio.sh"

#Gephi
cd ${sourcedir}
wget https://github.com/gephi/gephi/releases/download/v0.9.1/gephi-0.9.1-linux.tar.gz
tar zxvf gephi-0.9.1-linux.tar.gz

#MS fonts
#sudo apt-get install ttf-mscorefonts-installer
