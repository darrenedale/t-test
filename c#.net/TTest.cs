namespace Statistics
{
    using System;
    using System.Collections.Generic;

    public enum TTestType
    {
        Paired = 0,
        Unpaired
    }


    public class TTest
    {
        public TTest(DataFile data, TTestType type)
        {
            this.type = type;
            this.data = data;
        }

        public double t
        {
            get
            {
                switch (type) {
                    case TTestType.Paired:
                        return pairedT;

                    case TTestType.Unpaired:
                        return unpairedT;

                    default:
                        throw new Exception($"Unhandled test type: {type}");
                }
            }
        }

        protected double pairedT
        {
            get
            {
                int n = data.columnItemCount(0);
                List<double> diffs = new List<double>();
                List<double> diffs2 = new List<double>();
                double sumDiffs = 0.0;
                double sumDiffs2 = 0.0;

                for(int i = 0; i < n; ++i) {
                    diffs.Add(data.item(i, 0) - data.item(i, 1));
                    diffs2.Add(diffs[i] * diffs[i]);
                    sumDiffs += diffs[i];
                    sumDiffs2 += diffs2[i];
                }

                return sumDiffs / Math.Pow(((((double) n * sumDiffs2) - (sumDiffs * sumDiffs)) / (double)(n - 1)), 0.5);
            }
        }

        protected double unpairedT
        {
            get
            {
                var n1 = data.columnItemCount(0);
                var n2 = data.columnItemCount(1);
                var sum1 = data.columnSum(0);
                var sum2 = data.columnSum(1);
                var mean1 = sum1 / n1;
                var mean2 = sum2 / n2;
                var sumMDiff1 = 0.0;
                var sumMDiff2 = 0.0;

                for(int i = data.rowCount - 1; i >= 0; --i) {
                    var x = data.item(i, 0);

                    if(!Double.IsNaN(x)) {
                        x -= mean1;
                        sumMDiff1 += (x * x);
                    }

                    x = data.item(i, 1);

                    if(!Double.IsNaN(x)) {
                        x -= mean2;
                        sumMDiff2 += (x * x);
                    }
                }

                sumMDiff1 /= n1;
                sumMDiff2 /= n2;

                double t = (mean1 - mean2) / Math.Pow(((sumMDiff1 / (n1 - 1)) + (sumMDiff2 / (n2 - 1))), 0.5);

                if (0 > t) {
                    t = -t;
                }

                return t;
            }
        }

        public TTestType type;
        public DataFile data;

    }
}