#!/usr/bin/env python3
import sys
import os
import glob

def patch_file(filepath):
    print(f"Patching {filepath}...")
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Normalize line endings to LF
    content = content.replace('\r\n', '\n')

    # Patch 1: set_wiphy_params
    target1 = "static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, u32 changed)"
    replacement1 = """#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 1, 0))
static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, int changed_param, u32 changed)
#else
static int cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, u32 changed)
#endif"""
    if target1 in content:
        content = content.replace(target1, replacement1)
        print("  - Applied set_wiphy_params patch")

    # Patch 2: set_txpower
    target2 = """static int cfg80211_rtw_set_txpower(struct wiphy *wiphy,
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct wireless_dev *wdev,
#endif
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 36)) || defined(COMPAT_KERNEL_RELEASE)
	enum nl80211_tx_power_setting type, int mbm)"""

    replacement2 = """static int cfg80211_rtw_set_txpower(struct wiphy *wiphy,
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct wireless_dev *wdev,
#endif
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 1, 0))
	int link_id,
#endif
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 36)) || defined(COMPAT_KERNEL_RELEASE)
	enum nl80211_tx_power_setting type, int mbm)"""

    if target2 in content:
        content = content.replace(target2, replacement2)
        print("  - Applied set_txpower patch")
    else:
        # Try variation with different indentation
        target2_var = target2.replace('\t', '    ')
        if target2_var in content:
            content = content.replace(target2_var, replacement2)
            print("  - Applied set_txpower patch (spaces variant)")

    # Patch 3: get_txpower
    target3 = """static int cfg80211_rtw_get_txpower(struct wiphy *wiphy,
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct wireless_dev *wdev,
#endif
	int *dbm)
{
	_adapter *padapter = wiphy_to_adapter(wiphy);
	HAL_DATA_TYPE *pHalData = GET_HAL_DATA(padapter);

	RTW_INFO("%s\\n", __func__);

	// *dbm = (12);
	*dbm = pHalData->CurrentTxPwrIdx;

	return 0;
}"""

    replacement3 = """static int cfg80211_rtw_get_txpower(struct wiphy *wiphy,
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct wireless_dev *wdev,
#endif
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 1, 0))
	int link_id, unsigned int type,
#endif
	int *dbm)
{
	_adapter *padapter = wiphy_to_adapter(wiphy);
	HAL_DATA_TYPE *pHalData = GET_HAL_DATA(padapter);

	RTW_INFO("%s\\n", __func__);

	// *dbm = (12);
	*dbm = pHalData->CurrentTxPwrIdx;

	return 0;
}"""

    if target3 in content:
        content = content.replace(target3, replacement3)
        print("  - Applied get_txpower patch")
    else:
        target3_var = target3.replace('\t', '    ')
        if target3_var in content:
            content = content.replace(target3_var, replacement3)
            print("  - Applied get_txpower patch (spaces variant)")

    # Patch 4: set_monitor_channel
    target4 = """static int cfg80211_rtw_set_monitor_channel(struct wiphy *wiphy
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	, struct cfg80211_chan_def *chandef
#else
	, struct ieee80211_channel *chan
	, enum nl80211_channel_type channel_type
#endif
)
{
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct ieee80211_channel *chan = chandef->chan;
#endif"""

    replacement4 = """static int cfg80211_rtw_set_monitor_channel(struct wiphy *wiphy
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 3, 0))
	, struct net_device *ndev
	, struct cfg80211_chan_def *chandef
#elif (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	, struct cfg80211_chan_def *chandef
#else
	, struct ieee80211_channel *chan
	, enum nl80211_channel_type channel_type
#endif
)
{
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 3, 0))
	struct ieee80211_channel *chan = chandef->chan;
#elif (LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0))
	struct ieee80211_channel *chan = chandef->chan;
#endif"""

    if target4 in content:
        content = content.replace(target4, replacement4)
        print("  - Applied set_monitor_channel patch")
    else:
        target4_var = target4.replace('\t', '    ')
        if target4_var in content:
            content = content.replace(target4_var, replacement4)
            print("  - Applied set_monitor_channel patch (spaces variant)")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patching completed.")

def patch_makefile(makefile_path):
    print(f"Patching {makefile_path}...")
    with open(makefile_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Add header search paths to ccflags-y/EXTRA_CFLAGS to resolve relative includes on newer kernels
    target_inc_c = "ccflags-y += -I$(src)/include -I$(src) -I$(srctree)/$(src)/include"
    target_inc_e = "EXTRA_CFLAGS += -I$(src)/include -I$(src) -I$(srctree)/$(src)/include"
    addition = " -I$(srctree)/include/linux -I$(srctree)/arch/x86/include/uapi/asm -I$(srctree)/include/net -I$(src)/include/cmn_info"

    if target_inc_e in content:
        content = content.replace(target_inc_e, target_inc_e + addition)
        print("  - Added additional header search paths to EXTRA_CFLAGS")
    elif target_inc_c in content:
        content = content.replace(target_inc_c, target_inc_c + addition)
        print("  - Added additional header search paths to ccflags-y")

    # Replace EXTRA_CFLAGS with ccflags-y
    if "EXTRA_CFLAGS" in content:
        content = content.replace("EXTRA_CFLAGS", "ccflags-y")
        print("  - Replaced EXTRA_CFLAGS with ccflags-y")

    with open(makefile_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Makefile patching completed.")

def patch_version_h(target_dir):
    print("Patching version.h includes and timer compatibility...")
    # 1. Patch osdep_service_linux.h with timer compatibility
    osdep_path = os.path.join(target_dir, "include", "osdep_service_linux.h")
    if os.path.exists(osdep_path):
        print(f"  - Patching {osdep_path}...")
        with open(osdep_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        if '#include "version.h"' in content:
            replacement = """#include <linux/version.h>
#include <linux/timer.h>

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 15, 0))
#ifndef del_timer_sync
#define del_timer_sync timer_delete_sync
#endif
#ifndef del_timer
#define del_timer timer_delete
#endif
#endif

#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 16, 0))
#ifndef from_timer
#define from_timer timer_container_of
#endif
#endif"""
            content = content.replace('#include "version.h"', replacement)
            print("    - Replaced #include \"version.h\" with <linux/version.h> and timer compatibility definitions")
        with open(osdep_path, 'w', encoding='utf-8') as f:
            f.write(content)

    # 2. Patch platform_aml_s905_sdio.h
    platform_path = os.path.join(target_dir, "platform", "platform_aml_s905_sdio.h")
    if os.path.exists(platform_path):
        print(f"  - Patching {platform_path}...")
        with open(platform_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        if '#include "version.h"' in content:
            content = content.replace('#include "version.h"', '#include <linux/version.h>')
            print("    - Replaced #include \"version.h\" with <linux/version.h>")
        with open(platform_path, 'w', encoding='utf-8') as f:
            f.write(content)
    print("version.h patching completed.")

def main():
    if len(sys.argv) > 1:
        target_dir = sys.argv[1]
    else:
        # Search in /usr/src
        src_dirs = glob.glob('/usr/src/8188eu-*')
        if not src_dirs:
            print("No driver directory found in /usr/src/8188eu-*")
            sys.exit(1)
        target_dir = src_dirs[0]

    file_to_patch = os.path.join(target_dir, "os_dep", "linux", "ioctl_cfg80211.c")
    if not os.path.exists(file_to_patch):
        print(f"File not found: {file_to_patch}")
        sys.exit(1)

    patch_file(file_to_patch)

    makefile_to_patch = os.path.join(target_dir, "Makefile")
    if os.path.exists(makefile_to_patch):
        patch_makefile(makefile_to_patch)

    patch_version_h(target_dir)

if __name__ == "__main__":
    main()
