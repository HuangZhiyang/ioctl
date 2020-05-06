#!/bin/bash
# vim: set sw=4 expandtab:
#
# Licence: GPL
# Created: 2015-12-17 14:19:58+01:00
# Main authors:
#     - Jérôme Pouiller <jezz@sysmic.org>
#

CC=$1
SYSROOT=$($CC -print-sysroot)
ARCH=$($CC -print-multiarch)
# These subdirectories come from the include/uapi of the linux kernel. If
# ioctls appears outside of these directories, it means either it come from
# staging (and it is not stable), or it is architecture dependent or it some
# from a third-aprty (valgrind for exemple)
# Also exclude "drm" directory since it is not exported on most of distibutions
SUBDIRS=" linux misc mtd rdma scsi sound video xen asm-generic $ARCH/asm"
INCDIRS="$(for s in $SUBDIRS; do echo " $SYSROOT/usr/include/$s"; done)"

EXCLUDE_FILES+=" --exclude kfd_ioctl.h"         # Need drm/drm.h
EXCLUDE_FILES+=" --exclude kvm.h"               # Too many architecture dependent ioctls
EXCLUDE_FILES+=" --exclude coda.h"              # Include time.h
EXCLUDE_FILES+=" --exclude ioctl.h"             # Does not contains any ioctl in fact
EXCLUDE_IOCTLS+=" -e AUTOFS_IOC_SETTIMEOUT32"   # Lack type size
EXCLUDE_IOCTLS+=" -e USBDEVFS_CONTROL32"        # Lack type size
EXCLUDE_IOCTLS+=" -e USBDEVFS_BULK32"           # Lack type size
EXCLUDE_IOCTLS+=" -e USBDEVFS_SUBMITURB32"      # Lack type size
EXCLUDE_IOCTLS+=" -e USBDEVFS_DISCSIGNAL32"     # Lack type size
EXCLUDE_IOCTLS+=" -e USBDEVFS_IOCTL32"          # Lack type size
EXCLUDE_IOCTLS+=" -e BLKTRACESETUP"             # Lack type size
EXCLUDE_IOCTLS+=" -e FS_IOC_FIEMAP"             # Lack type size
EXCLUDE_IOCTLS+=" -e BTRFS_IOC_SET_FSLABEL"     # Lack type size
EXCLUDE_IOCTLS+=" -e BTRFS_IOC_GET_FSLABEL"     # Lack type size
EXCLUDE_IOCTLS+=" -e BTRFS_IOC_DEFRAG_RANGE"    # Lack type size
EXCLUDE_IOCTLS+=" -e XSDFEC_IS_ACTIVE"          # Lack type size
EXCLUDE_IOCTLS+=" -e XSDFEC_SET_BYPASS"         # Lack type size
EXCLUDE_IOCTLS+=" -e TIOCGISO7816"              # Lack type size
EXCLUDE_IOCTLS+=" -e TIOCSISO7816"              # Lack type size
EXCLUDE_IOCTLS+=" -e COMPAT_ATM_ADDPARTY"       # Parsing error
EXCLUDE_IOCTLS+=" -e MMC_IOC_MULTI_CMD"         # Missing include
EXCLUDE_IOCTLS+=" -e MMC_IOC_CMD"               # Missing include
EXCLUDE_IOCTLS+=" -e BLKELVGET"                 # Inside #if 0
EXCLUDE_IOCTLS+=" -e BLKELVSET"                 # Inside #if 0

# There are multiple problems:
#  - some delaration does not match regular expression -> Not yet supported
#    (possibility to add them manually to list, but there are problem with
#    foreign platforms)
#  - Sometime, ioctls disappear and it break compilation
#  - Sometime, header are renamed or disapear and it brreak compilation


echo '/* File generated by gen_ioctls_list.sh      */'
echo '/* In case of problem, please read README.md */'
echo '#include "ioctls_list.h"'
echo '#include <asm/termbits.h>' # struct termios2
echo '#include <linux/types.h>'  # other types
# Place here your extra headers
echo
grep -lr $EXCLUDE_FILES '^#define[^(].*[ 	]_IO[RW]*(' $INCDIRS |
    sed -e "s|$SYSROOT/usr/include/\($ARCH/\)\?\(.*\)|#include <\2>|" | sort

echo
echo "const struct ioctl_entry ioctls_list[] = {"
grep -nr $EXCLUDE_FILES '^#define[^(]*[ 	]_IO[RW]*(' $INCDIRS |
    grep -v $EXCLUDE_IOCTLS |
    sed -e "s|$SYSROOT/usr/include/\(.*\):.*:#define[ 	]*\([A-Z0-9x_]*\).*|    { \"\2\", \2, -1, -1 }, // \1|" |
    sort
# Place here you extra entries
echo "    { NULL, 0 },"
echo "};"
