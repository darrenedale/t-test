#ifndef STATISTICS_TTEST_H
#define STATISTICS_TTEST_H

#include <stdbool.h>
#include "datafile.h"

typedef enum ttesttype_s
{
    PairedT = 0,
    UnpairedT
} TTestType;

typedef struct ttest_s
{
    TTestType type;
    const DataFile * data;
} TTest;

bool tTestHasData(const TTest *);
double tTestT(const TTest *);

#endif
