
class TTest
    # available types of t-test
    PairedType = 0;
    UnpairedType = 2;

   ## A class representing a t-test on a given dataset.
   ##
   ## The class can perform both paired and unpaired analyses. It assumes that:
   ## - the data is organised with conditions represented by columns and observations represented by rows
   ## - the data to analyse has has at least two columns
   ## - the data to analyse is in the first two columns
   ##
   ## For paired tests it further assumes that:
   ## - each row contains valid values in both of the first two columns
   ##
   ## The data provided is not validated against these assumptions - that is the caller's responsibility.
   def initialize(data, type)
        if UnpairedType != type && PairedType != type
            raise "Invalid test type";
        end

        @data = data;
        @type = type;
    end

    ## Check whether the test has some data set.
    ##
    ## true if the test has data, false otherwise.
    def hasData
        return nil != @data
    end

    def data
        return @data
    end

    def data=(data)
        @data = data
    end

    ## Fetch the type of test.
    ##
    ## Guaranteed to be one of the test type constants.
    def type
        return @type
    end

    ## Set the type of test.
    ##
    ## Raises an error if typeis not one of the test type constants.
    def type=(type)
        if UnpairedType != type && PairedType != type
            raise "Invalid test type";
        end

        @type = type
    end

    ## Calculate and return t.
    ##
    ## Do not call unless you are certain that the t-test has data. See hasData().
    ##
    ## If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
    ##
    ## Guaranteed to be a Float.
    def t
        if PairedType == type
            return pairedT;
        end

        return unpairedT;
    end

    protected

    ## Helper to calculate t for paired data.
    ##
    ## Do not call unless you are certain that the t-test has data. See hasData().
    ##
    ## Guaranteed to be a Float.
    def pairedT
        # the number of pairs of observations
        n = data.columnItemCount(0);

        # differences between pairs of observations: (x1 - x2)
        diffs = [];

        # squared differences between pairs of observations: (x1 - x2) ^ 2
        diffs2 = [];

        # sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
        sumDiffs = 0.0;

        # sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
        sumDiffs2 = 0.0;

        (0 .. n - 1).each {
            |row|
            diffs.append(@data.item(row, 0) - @data.item(row, 1));
            diffs2.append(diffs.last ** 2);
            sumDiffs += diffs.last;
            sumDiffs2 += diffs2.last;
        }

        return sumDiffs / ((((n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ** 0.5);
    end

    ## Helper to calculate t for unpaired data.
    ##
    ## Do not call unless you are certain that the t-test has data. See hasData().
    ##
    ## Guaranteed to be a Float.
    def unpairedT
        # observation counts for each condition
        n1 = data.columnItemCount(0);
        n2 = data.columnItemCount(1);

        # means for each condition
        mean1 = data.columnMean(0);
        mean2 = data.columnMean(1);

        # sum of differences between items and the mean for each condition
        sumMeanDiffs1 = 0.0;
        sumMeanDiffs2 = 0.0;

        (0 .. data.rowCount - 1).each {
            |row|
            x = data.item(row, 0);

            if !x.nan?
                x -= mean1;
                sumMeanDiffs1 += (x ** 2);
            end

            x = data.item(row, 1);

            if !x.nan?
                x -= mean2;
                sumMeanDiffs2 += (x ** 2);
            end
        }

        sumMeanDiffs1 /= n1;
        sumMeanDiffs2 /= n2;

        # calculate the statistic
        t = (mean1 - mean2) / (((sumMeanDiffs1 / (n1 - 1.0)) + (sumMeanDiffs2 / (n2 - 1.0))) ** 0.5);

        # always return +ve t
        if 0.0 > t
            t = -t;
        end

        return t;
    end
end
