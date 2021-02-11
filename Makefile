include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-xray-bleeding-edge
PKG_VERSION:=573b7807c099dc268a0d3a3d011539bb44f2f314
PKG_RELEASE:=1

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yichya <mail@yichya.dev>

PKG_SOURCE:=Xray-core-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/XTLS/Xray-core/tar.gz/${PKG_VERSION}?
PKG_HASH:=1290ad35b0877e5c0636427b926ab13a74e081af8b0cc676ff5fc78600d7844b

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1

GO_PKG:=github.com/XTLS/Xray-core

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/../feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=Xray-core (pre-release version)
	DEPENDS:=$(GO_ARCH_DEPENDS)
	PROVIDES:=xray-core
endef

define Package/$(PKG_NAME)/description
	Xray-core bare bones binary and optional geoip / geosite data files
endef

define Package/$(PKG_NAME)/config
menu "Xray Configuration"
	depends on PACKAGE_$(PKG_NAME)

config PACKAGE_XRAY_BLEEDING_EDGE_FETCH_VIA_PROXYCHAINS
	bool "Fetch data files using proxychains (not recommended)"
	default n

config PACKAGE_XRAY_BLEEDING_EDGE_INCLUDE_GEOIP
	bool "Include Loyalsoldier geoip.dat"
	default n

config PACKAGE_XRAY_BLEEDING_EDGE_INCLUDE_GEOSITE
	bool "Include Loyalsoldier geosite.dat"
	default n

endmenu
endef

PROXYCHAINS:=

ifdef CONFIG_PACKAGE_XRAY_BLEEDING_EDGE_FETCH_VIA_PROXYCHAINS
	PROXYCHAINS:=proxychains
endif

MAKE_PATH:=$(GO_PKG_WORK_DIR_NAME)/build/src/$(GO_PKG)
MAKE_VARS += $(GO_PKG_VARS)

define Build/Patch
	$(CP) $(PKG_BUILD_DIR)/../Xray-core-$(PKG_VERSION)/* $(PKG_BUILD_DIR)
	$(Build/Patch/Default)
endef

define Build/Compile
	cd $(PKG_BUILD_DIR); $(GO_PKG_VARS) GOPROXY=https://goproxy.io,direct CGO_ENABLED=0 go build -trimpath -o $(PKG_INSTALL_DIR)/bin/xray -ldflags "-s -w" ./main; 
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/xray $(1)/usr/bin/xray
	$(INSTALL_DIR) $(1)/usr/share/xray
ifdef CONFIG_PACKAGE_XRAY_BLEEDING_EDGE_INCLUDE_GEOIP
	$(PROXYCHAINS) wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O $(PKG_BUILD_DIR)/geoip.dat
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geoip.dat $(1)/usr/share/xray/
endif
ifdef CONFIG_PACKAGE_XRAY_BLEEDING_EDGE_INCLUDE_GEOSITE
	$(PROXYCHAINS) wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O $(PKG_BUILD_DIR)/geosite.dat
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geosite.dat $(1)/usr/share/xray/
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
