#include <assert.h>
#include <stdio.h>
#include <math.h>
#include "ttest.h"

double tTestPairedT(const TTest * tTest);
double tTestUnpairedT(const TTest * tTest);

bool tTestHasData(const TTest * tTest)
{
    return (bool) tTest->data;
}

double tTestT(const TTest * tTest)
{
    switch (tTest->type) {
        case PairedT:
            return tTestPairedT(tTest);

        case UnpairedT:
            return tTestUnpairedT(tTest);
    }

    fprintf(stderr, "invalid t-test type");
    assert(false);
}

double tTestPairedT(const TTest * tTest)
{
    /* the number of pairs of observations */
    int n = dataFileColumnItemCount(tTest->data, 0);

    /* sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2) */
    double sumDiffs = 0.0;

    /* sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2) */
    double sumDiffs2 = 0.0;

    for(int i = 0; i < n; ++i) {
        double diff = dataFileItem(tTest->data, i, 0) - dataFileItem(tTest->data, i, 1);
        sumDiffs += diff;
        sumDiffs2 += pow(diff, 2.0);
    }

    return sumDiffs / pow((((((double) n) * sumDiffs2) - (sumDiffs * sumDiffs)) / (double)(n - 1)), 0.5);
}

double tTestUnpairedT(const TTest * tTest)
{
    /* observation counts for each condition */
    double n1 = (double) dataFileColumnItemCount(tTest->data, 0);
    double n2 = (double) dataFileColumnItemCount(tTest->data, 1);

    /* sums for each condition */
    double sum1 = dataFileColumnSum(tTest->data, 0, 1.0);
    double sum2 = dataFileColumnSum(tTest->data, 1, 1.0);

    /* means for each condition */
    double mean1 = sum1 / n1;
    double mean2 = sum2 / n2;

    /* sum of differences between items and the mean for each condition */
    double sumMeanDiffs1 = 0.0;
    double sumMeanDiffs2 = 0.0;

    for(int i = dataFileRowCount(tTest->data) - 1; i >= 0; --i) {
        double x = dataFileItem(tTest->data, i, 0);

        if(!isnan(x)) {
            x -= mean1;
            sumMeanDiffs1 += (x * x);
        }

        x = dataFileItem(tTest->data, i, 1);

        if(!isnan(x)) {
            x -= mean2;
            sumMeanDiffs2 += (x * x);
        }
    }

    sumMeanDiffs1 /= n1;
    sumMeanDiffs2 /= n2;

    /* calculate the statistic */
    double t = (mean1 - mean2) / pow(((sumMeanDiffs1 / (n1 - 1.0)) + (sumMeanDiffs2 / (n2 - 1.0))), 0.5);

    /* always return +ve t */
    if (0.0 > t) {
        t = -t;
    }

    return t;
}
