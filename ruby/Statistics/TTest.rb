module Statistics
    ##
    # A class representing a t-test on a given dataset.
    #
    # The class can perform both paired and unpaired analyses. It assumes that:
    # - the data is organised with conditions represented by columns and observations represented by rows
    # - the data to analyse has has at least two columns
    # - the data to analyse is in the first two columns
    #
    # For paired tests it further assumes that:
    # - each row contains valid values in both of the first two columns
    #
    # The data provided is not validated against these assumptions - that is the caller's responsibility.
    class TTest
        ##
        # Default getter for the test's data.
        attr_reader :data;

        ##
        # Default getter for the test's type.
        attr_reader :type;

        ##
        # Initialise a new t-test.
        #
        # The t-test object shares ownership of the provided data with the provider. The
        # data is intended to be available to modify externally (e.g. an app could
        # implement a store of data files and an editor for data files), with the t-test
        # automatically keeping up-to-date with external changes.
        #
        # The default test type is a paired test.
        #
        # [Params]
        # - +data+ The data to process.
        # - +type+ The type of test. Must be one of the symbols :UnpairedTTest or :PairedTTest.
        def initialize(data, type)
            if :UnpairedTTest != type && :PairedTTest != type
                raise "Invalid test type";
            end

            @data = data;
            @type = type;
        end

        ##
        # Check whether the test has some data set.
        #
        # [Return]
        # +true+ if the test has data, +false+ otherwise.
        def hasData?
            return nil != @data
        end

        ##
        # Set the data for the t-test.
        #
        # The data provided can be nil to unset the test's data. The test object keeps a reference to the provided data -
        # changes made to the referenced data outside the class will be reflected in the data used by the test.
        #
        # Params:
        # - +data+ +DataFile+ or +nil+ The data for the test.
        def data=(data)
            if data && !data.instance_of?(DataFile)
                raise "Invalid data file"
            end

            @data = data
        end

        ##
        # Set the type of test.
        #
        # Raises an error if type is not one of the test type symbols.
        #
        # [Params]
        # - +type+ The test type. Must be on of the symbols +:UnpairedTTest+ or +:PairedTTest+.
        def type=(type)
            if :UnpairedTTest != type && :PairedTTest != type
                raise "Invalid test type";
            end

            @type = type
        end

        ##
        # Calculate and return t.
        #
        # Do not call unless you are certain that the t-test has data. See +hasData?+.
        #
        # [Return]
        # `Float` The value of t.
        def t
            if :PairedTTest == type
                return pairedT;
            end

            return unpairedT;
        end

        private

        ##
        # Helper to calculate t for paired data.
        #
        # Do not call unless you are certain that the t-test has data. See hasData.
        #
        # If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
        #
        # [Return]
        # `Float` The value of t.
        def pairedT
            # the number of pairs of observations
            n = data.columnItemCount(0);

            # sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
            sumDiffs = 0.0;

            # sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
            sumDiffs2 = 0.0;

            (0 .. n - 1).each {
                |row|
                diff = data.item(row: row, col: 0) - data.item(row: row, col: 1);
                sumDiffs += diff;
                sumDiffs2 += diff * diff;
            }

            return sumDiffs / ((((n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ** 0.5);
        end

        ##
        # Helper to calculate t for unpaired data.
        #
        # Do not call unless you are certain that the t-test has data. See hasData.
        #
        # If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
        #
        # [Return]
        # `Float` The value of t.
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
