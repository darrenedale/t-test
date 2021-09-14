#ifndef TTEST_UTIL_H
#define TTEST_UTIL_H

/**
 * Case-insensitive string comparison.
 * 
 * Basic implementation of the similar function from posix, so that we don't constrain ourselves to posix-compliant platforms.
 */
int strcasecmp(const char * a, const char * b);

#endif
