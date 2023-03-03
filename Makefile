#.SILENT:

# ---{ BUILD CONFIGURATION }--- #
SIO_DEBUG ?= 1
DS34 ?= 0
SMB ?= 0
TMANIP ?= 1
ETH ?= 1
EXFAT ?= 1
DVRP ?= 0
IOP_RESET ?= 1
XFROM ?= 0
UDPTTY ?= 1
MX4SIO ?= 0
SIO2MAN ?= 1
SIOR ?= 0
# ----------------------------- #

BIN_NAME = BOOT$(HAS_EXFAT)$(HAS_DS34)$(HAS_ETH)$(HAS_IOP_RESET)$(HAS_SMB)$(HAS_DVRP)$(HAS_XFROM)$(HAS_MX4SIO)$(HAS_EESIO)
EE_BIN = UNC-$(BIN_NAME).ELF
EE_BIN_PKD = $(BIN_NAME).ELF
EE_OBJS = main.o config.o elf.o draw.o loader_elf.o filer.o \
	poweroff_irx.o iomanx_irx.o filexio_irx.o ps2atad_irx.o ps2dev9_irx.o\
	ps2hdd_irx.o ps2fs_irx.o usbd_irx.o mcman_irx.o mcserv_irx.o\
	cdvd_irx.o vmc_fs_irx.o ps2kbd_irx.o\
	hdd.o hdl_rpc.o hdl_info_irx.o editor.o timer.o jpgviewer.o icon.o lang.o\
	font_uLE.o makeicon.o chkesr.o allowdvdv_irx.o

EE_INCS := -I$(PS2DEV)/gsKit/include -I$(PS2SDK)/ports/include -Ioldlibs/libcdvd/ee

EE_LDFLAGS := -L$(PS2DEV)/gsKit/lib -L$(PS2SDK)/ports/lib -Loldlibs/libcdvd/lib -s
EE_LIBS = -lgskit -ldmakit -ljpeg -lmc -lhdd -lcdvdfs -lkbd -lmf \
	-lcdvd -lc -lfileXio -lpatches -lpoweroff -ldebug -lc
EE_CFLAGS := -mgpopt -G10240 -G0 -DNEWLIB_PORT_AWARE -D_EE

BIN2S = @bin2s

ifeq ($(SMB),1)
    EE_OBJS += smbman.o
    HAS_SMB = -SMB
    EE_CFLAGS += -DSMB
endif

ifeq ($(XFROM),1)
    HAS_XFROM = -XFROM
    EE_CFLAGS += -DXFROM
endif

ifeq ($(DS34),1)
    EE_OBJS += ds34usb.o libds34usb.a ds34bt.o libds34bt.a pad_ds34.o 
    HAS_DS34 = -DS34
    EE_CFLAGS += -DDS34
else
	EE_OBJS += pad.o
endif

ifeq ($(DVRP),1)
    EE_OBJS += dvrdrv_irx.o dvrfile_irx.o
    EE_CFLAGS += -DDVRP
    HAS_DVRP = -DVRP
endif

ifeq ($(MX4SIO),1)
    EE_OBJS += mx4sio_bd.o
    EE_CFLAGS += -DMX4SIO
    HAS_MX4SIO = -MX4SIO
    SIO2MAN = 1
endif

ifeq ($(SIO2MAN),1)
    EE_OBJS += sio2man.o padman.o
    EE_CFLAGS += -DHOMEBREW_SIO2MAN
    EE_LIBS += -lpadx
else
    EE_LIBS += -lpad
endif

ifeq ($(SIO_DEBUG),1)
    EE_CFLAGS += -DSIO_DEBUG
    EE_OBJS += sior_irx.o
    HAS_EESIO = -SIO_DEBUG
	ifeq ($(SIOR),1)
        EE_LIBS += -lsior
        EE_CFLAGS += -DSIOR
	endif
endif

ifeq ($(IOP_RESET),0)
    EE_CFLAGS += -DNO_IOP_RESET
    HAS_IOP_RESET = -NO_IOP_RESET
endif

ifeq ($(ETH),1)
    EE_OBJS += ps2smap_irx.o ps2ftpd_irx.o ps2host_irx.o ps2netfs_irx.o ps2ip_irx.o
    EE_CFLAGS += -DETH
	ifeq ($(UDPTTY),1)
	  EE_OBJS += udptty.o
	  HAS_UDPTTY = -UDPTTY
	  EE_CFLAGS += -DUDPTTY
	endif
else
    HAS_ETH = -NO_NETWORK
endif

ifeq ($(TMANIP),1)
    EE_CFLAGS += -DTMANIP
endif

ifeq ($(TMANIP),2)
    EE_CFLAGS += -DTMANIP
    EE_CFLAGS += -DTMANIP_MORON
endif

ifeq ($(EXFAT),1)
    EE_OBJS += bdm_irx.o bdmfs_fatfs_irx.o usbmass_bd_irx.o
    EE_CFLAGS += -DEXFAT
    HAS_EXFAT = -EXFAT
else
    EE_OBJS += usbhdfsd_irx.o
endif

ifeq ($(DEFAULT_COLORS),1)
@echo using default colors
else
EE_CFLAGS += -DCUSTOM_COLORS
endif

.PHONY: all run reset clean rebuild

all: githash.h $(EE_BIN_PKD)

$(EE_BIN_PKD): $(EE_BIN)
	ps2-packer $< $@
ifeq ($(IOP_RESET),0)
	@echo "-------------{COMPILATION PERFORMED WITHOUT IOP RESET}-------------"
endif

run: all
	ps2client -h 192.168.0.10 -t 1 execee host:$(EE_BIN)
reset: clean
	ps2client -h 192.168.0.10 reset

githash.h:
	printf '#ifndef ULE_VERDATE\n#define ULE_VERDATE "' > $@ && \
	git show -s --format=%cd --date=local | tr -d "\n" >> $@ && \
	printf '"\n#endif\n' >> $@
	printf '#ifndef GIT_HASH\n#define GIT_HASH "' >> $@ && \
	git rev-parse --short HEAD | tr -d "\n" >> $@ && \
	printf '"\n#endif\n' >> $@

current_flags:
	@echo "SMB: set to 1 to build wLe with smb support"
	@echo "DEFAULT_COLORS - set to 1 to use default uLaunchELF colors, otherwise, custom values will be used"
	@echo "TMANIP: set to 1 to compile with time manipulation function, if set to 2 the function will manipulate the date of a specific folder (to avoid issues caused by noobs) (the specific folder name used is the macro HACK_FOLDER, wich is defined at launchelf.h)"
	@echo "LANG: use a custom language file to compile wLe (by now only SPA and ENG are available)"
	@echo "DVRP: support for PSX DESR encrypted HDD area"

mcman_irx.s: $(PS2SDK)/iop/irx/mcman.irx
	$(BIN2S) $< $@ mcman_irx

mcserv_irx.s: $(PS2SDK)/iop/irx/mcserv.irx
	$(BIN2S) $< $@ mcserv_irx

usbd_irx.s: $(PS2SDK)/iop/irx/usbd.irx
	$(BIN2S) $< $@ usbd_irx

ifeq ($(EXFAT),1)
bdm_irx.s: iop/bdm.irx
	$(BIN2S) $< $@ bdm_irx

bdmfs_fatfs_irx.s: iop/bdmfs_fatfs.irx
	$(BIN2S) $< $@ bdmfs_fatfs_irx

usbmass_bd_irx.s: iop/usbmass_bd.irx
	$(BIN2S) $< $@ usbmass_bd_irx
else
usbhdfsd_irx.s: $(PS2SDK)/iop/irx/usbhdfsd.irx
	$(BIN2S) $< $@ usb_mass_irx
endif

oldlibs/libcdvd/lib/cdvd.irx: oldlibs/libcdvd
	$(MAKE) -C $<

cdvd_irx.s: oldlibs/libcdvd/lib/cdvd.irx
	$(BIN2S) $< $@ cdvd_irx

poweroff_irx.s: $(PS2SDK)/iop/irx/poweroff.irx
	$(BIN2S) $< $@ poweroff_irx

iomanx_irx.s: $(PS2SDK)/iop/irx/iomanX.irx
	$(BIN2S) $< $@ iomanx_irx

filexio_irx.s: $(PS2SDK)/iop/irx/fileXio.irx
	$(BIN2S) $< $@ filexio_irx

ps2dev9_irx.s: $(PS2SDK)/iop/irx/ps2dev9.irx
	$(BIN2S) $< $@ ps2dev9_irx
	
mx4sio_bd.s: iop/mx4sio_bd.irx
	$(BIN2S) $< $@ mx4sio_bd_irx

ifeq ($(ETH),1)
ps2ip_irx.s: $(PS2SDK)/iop/irx/ps2ip.irx
	$(BIN2S) $< $@ ps2ip_irx

udptty.s: $(PS2SDK)/iop/irx/udptty.irx
	$(BIN2S) $< $@ udptty_irx

ps2smap_irx.s: $(PS2DEV)/ps2eth/smap/ps2smap.irx
	$(BIN2S) $< $@ ps2smap_irx

ps2ftpd_irx.s: oldlibs/ps2ftpd/bin/ps2ftpd.irx
	$(BIN2S) $< $@ ps2ftpd_irx

ps2netfs_irx.s: $(PS2SDK)/iop/irx/ps2netfs.irx
	$(BIN2S) $< $@ ps2netfs_irx

ps2host_irx.s: ps2host/ps2host.irx
	$(BIN2S) $< $@ ps2host_irx
endif

oldlibs/ps2ftpd/bin/ps2ftpd.irx: oldlibs/ps2ftpd
	$(MAKE) -C $<

ps2atad_irx.s: $(PS2SDK)/iop/irx/ps2atad.irx
	$(BIN2S) $< $@ ps2atad_irx

ps2hdd_irx.s: $(PS2SDK)/iop/irx/ps2hdd-osd.irx
	$(BIN2S) $< $@ ps2hdd_irx

ps2fs_irx.s: $(PS2SDK)/iop/irx/ps2fs.irx
	$(BIN2S) $< $@ ps2fs_irx
	
ifeq ($(DVRP),1)
dvrdrv_irx.s: iop/dvrdrv.irx
	$(BIN2S) $< $@ dvrdrv_irx

dvrfile_irx.s: iop/dvrfile.irx
	$(BIN2S) $< $@ dvrfile_irx
endif

hdl_info/hdl_info.irx: hdl_info
	$(MAKE) -C $<

hdl_info_irx.s: hdl_info/hdl_info.irx
	$(BIN2S) $< $@ hdl_info_irx

ps2host/ps2host.irx: ps2host
	$(MAKE) -C $<

ds34usb/ee/libds34usb.a: ds34usb/ee
	$(MAKE) -C $<

ds34usb/iop/ds34usb.irx: ds34usb/iop
	$(MAKE) -C $<

ds34bt/ee/libds34bt.a: ds34bt/ee
	$(MAKE) -C $<

ds34bt/iop/ds34bt.irx: ds34bt/iop
	$(MAKE) -C $<

ds34usb.s: ds34usb/iop/ds34usb.irx
	@$(BIN2S) $< $@ ds34usb_irx

libds34usb.a: ds34usb/ee/libds34usb.a
	cp $< $@	

ds34bt.s: ds34bt/iop/ds34bt.irx
	@$(BIN2S) $< $@ ds34bt_irx

libds34bt.a: ds34bt/ee/libds34bt.a
	cp $< $@

padman.s: $(PS2SDK)/iop/irx/padman.irx
	$(BIN2S) $< $@ padman_irx

sio2man.s: $(PS2SDK)/iop/irx/sio2man.irx
	$(BIN2S) $< $@ sio2man_irx

ifeq ($(SMB),1)
smbman_irx.s: $(PS2SDK)/iop/irx/smbman.irx
	$(BIN2S) $< $@ smbman_irx
endif

vmc_fs/vmc_fs.irx: vmc_fs
	$(MAKE) -C $<

vmc_fs_irx.s: vmc_fs/vmc_fs.irx
	$(BIN2S) $< $@ vmc_fs_irx

loader/loader.elf: loader
	$(MAKE) -C $<

loader_elf.s: loader/loader.elf
	$(BIN2S) $< $@ loader_elf

ps2kbd_irx.s: $(PS2SDK)/iop/irx/ps2kbd.irx
	$(BIN2S) $< $@ ps2kbd_irx

sior_irx.s: $(PS2SDK)/iop/irx/sior.irx
	$(BIN2S) $< $@ sior_irx

AllowDVDV/AllowDVDV.irx: AllowDVDV
	$(MAKE) -C $<

allowdvdv_irx.s: AllowDVDV/AllowDVDV.irx
	$(BIN2S) $< $@ allowdvdv_irx

clean:
	$(MAKE) -C hdl_info clean
	$(MAKE) -C ps2host clean
	$(MAKE) -C loader clean
	$(MAKE) -C vmc_fs clean
	$(MAKE) -C AllowDVDV clean
	$(MAKE) -C oldlibs/libcdvd clean
	$(MAKE) -C oldlibs/ps2ftpd clean
	rm -f githash.h *.s $(EE_OBJS) $(EE_BIN) $(EE_BIN_PKD)

rebuild: clean all

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal
