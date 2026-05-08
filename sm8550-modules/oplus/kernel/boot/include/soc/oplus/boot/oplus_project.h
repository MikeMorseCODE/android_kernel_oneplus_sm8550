/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * oplus_project.h — stub for GKI 6.1 out-of-tree module builds
 *
 * The real implementation reads SKU/project info from SMEM or DT.
 * This stub lets AW8697 and other OEM drivers compile without the
 * full OnePlus boot framework present in the build tree.
 *
 * Drivers guard OPLUS_FEATURE_* calls with preprocessor checks,
 * so returning 0/"unknown" is safe for non-production builds.
 */
#ifndef __OPLUS_PROJECT_H__
#define __OPLUS_PROJECT_H__

#include <linux/types.h>

static inline unsigned int get_project(void)       { return 0; }
static inline unsigned int get_pcb_version(void)   { return 0; }
static inline unsigned int get_eng_version(void)   { return 0; }
static inline bool         is_project(unsigned int p) { return false; }
static inline unsigned int get_rf_version(void)    { return 0; }
static inline unsigned int get_hw_version_major(void) { return 0; }
static inline unsigned int get_hw_version_minor(void) { return 0; }

#endif /* __OPLUS_PROJECT_H__ */
