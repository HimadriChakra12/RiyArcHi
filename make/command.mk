CTL         = sudo systemctl
GG          = git clone
URL         = https://github.com/HimadriChakra12
MAKE        = make && sudo make install

PKG         = $(HOMEDIR)/pkg
CLONE       = -@$(GG) $(URL)/$@ $(PKG)/$@
CD          = @cd $(PKG)/$@
MK          = $(CD) && $(MAKE) 

