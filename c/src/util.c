#include <ctype.h>
#include "util.h"

int strcasecmp(const char * a, const char * b)
{
    while (*a && *b) {
        char diff = tolower(*b) - tolower(*a);

        if (0 != diff) {
            return diff;
        }

        ++a;
        ++b;
    }

    if (!*a) {
        /* if b still has chars while a hasn't, b is "greater" */
        if (*b) {
            return 1;
        }
    } else {
        /* if a still has chars while b hasn't, a is "greater" */
        if (!*b) {
            return -1;
        }
    }

    /* they are equal */
    return 0;
}
