CTL   = sudo systemctl
GG    = git clone
URL   = https://github.com/HimadriChakra12
MAKE  = make && sudo make install

PKG   = $(HOMEDIR)/pkg
CLONE = -@[ -d $(PKG)/$@ ] || $(GG) $(URL)/$@ $(PKG)/$@
CD    = @cd $(PKG)/$@
MK    = $(CD) && $(MAKE) 

AU    = baph
