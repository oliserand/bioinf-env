# This was written for xenial, but may work for later distros as well (with some tweaking)
read -p "Enter your username: " username
# Check username correctness
[[ $(grep "^${username}:" /etc/passwd) ]] || (read -p "Invalid user name. Exiting" && exit)

sourcedir="/home/${username}/bin/source"
bindir="/home/${username}/bin"
#Enter MODELLER installation key. You only have to register and replace "xxx" with it. 
read -p "Enter your MODELLER key: " modeller_key

#Directory for downloaded sources
mkdir -p ${sourcedir}

#Set up vim profile for python (code highlighting & indentation)
cd /home/${username}
if [ -f .vimrc ];then cp .vimrc ".vimrc$(date +%s)";fi
echo "syntax on" > /home/${username}/.vimrc
echo "filetype indent plugin on" >> /home/${username}/.vimrc

#Add R repo to xenial sources
distro=$(lsb_release -c | sed 's/Codename:\s*//')
line="http://cran.mirror.ac.za/bin/linux/ubuntu"
grep -q $line /etc/apt/sources.list || echo "deb $line ${distro}/">> /etc/apt/sources.list && \
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

#Add wxMacMolPlt to sources
#From https://brettbode.github.io/wxmacmolplt/downloads.html
echo "deb [trusted=yes] https://dl.bintray.com/brettbode/Xenial xenial main" >> /etc/apt/sources.list

#Generic installations
apt-get update
apt-get install cmake libjpeg62 python3-pip idle-python3.* vim git openbabel muscle jalview \
     autodock autogrid autodock-vina icedtea-*-plugin libjpeg62 exfat-utils flashplugin-installer \
     exfat-fuse gimp  plink emboss grace r-base-core r-base-dev gfortran libx11-dev wxmacmolplt \
     liblzma-dev csh libxml2 figtree labyrinth dia pdb2pqr libxml2-dev libopenblas-dev cython \
     avogadro build-essential python-dev libpng-dev

#Python 3 libraries
pip3 install --upgrade pip && pip3 install numpy scipy matplotlib biopython python-igraph cython tensorflow\
     Theano keras joblib pandas jupyter ipywidgets sierrapy
pip3 install mdtraj

#R libraries
apt-get install r-cran-rgl r-cran-ggplot2 r-cran-caret r-cran-seqinr 
apt-get install libgstreamer-plugins-base0.10-0 libgstreamer0.10-0

#Install MODELLER
cd ${sourcedir}
wget "https://salilab.org/modeller/9.19/modeller_9.19-1_amd64.deb"
dpkg -i modeller_9.19-1_amd64.deb 
sed -i 's/xxx/${modeller_key}/' /usr/lib/modeller9.19/modlib/modeller/config.py

#Install Open-Source PyMOL
#From https://pymolwiki.org/index.php/Linux_Install
cd ${sourcedir}
apt-get install python-pmw libglew-dev freeglut3-dev libfreetype6-dev libmsgpack-dev \
python-pyqt5.qtopengl libglm-dev
git clone https://github.com/schrodinger/pymol-open-source.git
cd pymol-open-source
prefix=${bindir}/bin/pymol-open-source-build
python2 setup.py build install --no-glut --home=$prefix
ln -s ${bindir}/bin/pymol-open-source-build/bin/pymol /home/${username}/bin/pymol

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

#Installing GROMACS 2018.4
cd ${sourcedir}
wget "ftp://ftp.gromacs.org/pub/gromacs/gromacs-2018.4.tar.gz"
tar xfz gromacs-2018.4.tar.gz
cd gromacs-2018.4
mkdir build
cd build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON -DGMX_USE_TNG=off
make >> gromacs_make.log
make check >> gromacs_make_check.log
make install
echo ". /usr/local/gromacs/bin/GMXRC" >> /home/${username}/.bashrc

#Installing g_mmpbsa
cd ${sourcedir}
wget http://rashmikumari.github.io/g_mmpbsa/package/GMX51x_extrn_APBS/g_mmpbsa.tar.gz
wget http://rashmikumari.github.io/g_mmpbsa/package/scripts.tar.gz
tar zxvf g_mmpbsa.tar.gz
tar zxvf scripts.tar.gz
ln -s ${sourcedir}/g_mmpbsa/bin/g_mmpbsa ${bindir}/g_mmpbsa
ln -s ${sourcedir}/g_mmpbsa/bin/energy2bfac ${bindir}/energy2bfac
ln -s ${sourcedir}/scripts/MmPbSaDecomp.py ${bindir}/MmPbSaDecomp.py
ln -s ${sourcedir}/scripts/MmPbSaStat_correlation.py ${bindir}/MmPbSaStat_correlation.py
ln -s ${sourcedir}/scripts/MmPbSaStat.py ${bindir}/MmPbSaStat.py
echo "#APBS for g_mmpbsa" >> /home/${username}/.bashrc
echo "export APBS=$(which apbs)" >> /home/${username}/.bashrc

#Installing RStudio
cd ${sourcedir}
wget "https://download1.rstudio.org/rstudio-0.99.902-amd64.deb"
dpkg -i rstudio-0.99.902-amd64.deb
 
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
echo "Finished execution."
