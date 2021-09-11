module Statistics
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
    class TTest
        ## Initialise a new t-test.
        ##
        ## The t-test object shares ownership of the provided data with the provider. The
        ## data is intended to be available to modify externally (e.g. an app could
        ## implement a store of data files and an editor for data files), with the t-test
        ## automatically keeping up-to-date with external changes.
        ##
        ## The default test type is a paired test.
        ##
        ## @param data The data to process.
        ## @param type The type of test. Must be one of the symbols :UnpairedTTest or :PairedTTest.
        def initialize(data, type)
            if :UnpairedTTest != type && :PairedTTest != type
                raise "Invalid test type";
            end

            @data = data;
            @type = type;
        end

        ## Check whether the test has some data set.
        ##
        ## true if the test has data, false otherwise.
        def hasData?
            return nil != @data
        end

        ## Fetch a reference to the t-test's data.
        ##
        ## The data will be nil if none has been set (see hasData).
        def data
            return @data
        end

        ## Set the data for the t-test.
        ##
        ## The data provided can be nil to unset the test's data. The test object keeps a reference to the provided data -
        ## changes made to the referenced data outside the class will be reflected in the data used by the test.
        def data=(data)
            @data = data
        end

        ## Fetch the type of test.
        ##
        ## Guaranteed to be one of the test type symbols :PairedTTest or :UnpairedTTest.
        def type
            return @type
        end

        ## Set the type of test.
        ##
        ## Raises an error if typeis not one of the test type symbols.
        def type=(type)
            if :UnpairedTTest != type && :PairedTTest != type
                raise "Invalid test type";
            end

            @type = type
        end

        ## Calculate and return t.
        ##
        ## Do not call unless you are certain that the t-test has data. See hasData.
        ##
        ## If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
        ##
        ## Guaranteed to be a Float.
        def t
            if :PairedTTest == type
                return pairedT;
            end

            return unpairedT;
        end

        protected

        ## Helper to calculate t for paired data.
        ##
        ## Do not call unless you are certain that the t-test has data. See hasData.
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
                diffs.append(@data.item(row: row, col: 0) - @data.item(row: row, col: 1));
                diffs2.append(diffs.last ** 2);
                sumDiffs += diffs.last;
                sumDiffs2 += diffs2.last;
            }

            return sumDiffs / ((((n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ** 0.5);
        end

        ## Helper to calculate t for unpaired data.
        ##
        ## Do not call unless you are certain that the t-test has data. See hasData.
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
                x = data.item(row: row, col: 0);

                if !x.nan?
                    x -= mean1;
                    sumMeanDiffs1 += (x ** 2);
                end

                x = data.item(row: row, col: 1);

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
end
