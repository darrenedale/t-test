#ifndef STATISTICS_TTEST_H
#define STATISTICS_TTEST_H

#include <stdbool.h>
#include "datafile.h"

typedef enum ttesttype_t
{
    PairedT = 0,
    UnpairedT
} TTestType;

typedef struct ttest_t
{
    TTestType type;
    const DataFile * data;
} TTest;

bool tTestHasData(const TTest *);
double tTestT(const TTest *);

#endif
