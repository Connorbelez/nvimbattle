# Instructions to Build 

If using a package manager other than packer which can install lua rocks packages, you will need the nvim rocks plugin. After installing the plugin and using it to install lua socket proceed to next step. 

locate the directory where luarocks sources its lua include file. Take note of the path. 

clone the luasocket repository and change the LUAINC_<PLAT>_base? in src/makefile to point towards the nvim_rocks lua include directory. This will allow the compiler to build against the correct version of lua (5.1 or luajit). 

```make   
LUAINC_linux_base?=/home/cbizy/.local/share/nvim/lazy/nvim_rocks
LUAINC_linux?=$(LUAINC_linux_base)/lua/$(LUAV) $(LUAINC_linux_base)/lua$(LUAV)
LUAPREFIX_linux?=/usr/local
CDIR_linux?=lib/lua/$(LUAV)
LDIR_linux?=share/lua/$(LUAV)
```

after that go to the parent luasocket directory and run sudo make PLAT=linux LUAV=5.1

Then run sudo make install PLAT=linux prefix=../out LUAV=5.1 or whereever you want the build files to end up. 
This
this will create a lib and a share folder move down through the directory to /5.1/ of each of lib and share and copy the contents to your nvim_rocks/lua/ 
directory ~/.local/share/nvim/lazy/nvim_rocks/lua
merge the folders and overwrite that was there. 

I know theres a better way of doing this, there has to be, but this is the only way I've been able to get it to work cross platform. 

If you are using MACOSX ARM you need to go to the buildscripts directory and run build-osx64, 

as building from from the luasocket repo results in an unrecognized symbol. 


