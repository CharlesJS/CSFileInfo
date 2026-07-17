//
//  cshims.h
//  
//
//  Created by Charles Srstka on 3/11/23.
//

#if __APPLE__
#include <membership.h>
#endif

#if __linux__
#include <acl/libacl.h>
#include <fcntl.h>
#include <linux/magic.h>
#include <linux/posix_acl.h>
#include <linux/stat.h>
#include <linux/xattr.h>
#include <mntent.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/acl.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/statfs.h>
#include <sys/syscall.h>
#include <sys/sysmacros.h>
#include <sys/vfs.h>
#include <sys/xattr.h>
#include <unistd.h>
#include <uuid/uuid.h>

__attribute__((swift_name("AT_EMPTY_PATH")))
static const int swift_at_empty_path = 0x1000;

__attribute__((swift_name("O_PATH")))
static const int swift_o_path = 010000000;

__attribute__((swift_name("S_ISDIR(_:)")))
static inline bool swift_S_ISDIR_16(uint16_t mode) {
    return S_ISDIR(mode);
};

__attribute__((swift_name("makedev(_:_:)")))
static inline dev_t swift_makedev(uint32_t major, uint32_t minor) {
    return makedev(major, minor);
};

__attribute__((swift_name("open(_:_:)")))
static inline int swift_open(const char *pathname, int flags) {
    return open(pathname, flags);
};

__attribute__((swift_name("statx(_:_:_:_:_:)")))
static inline int swift_statx(int dirfd, const char *path, int flags, unsigned int mask, struct statx *buf) {
    return syscall(SYS_statx, dirfd, path, flags, mask, buf);
}

#endif
