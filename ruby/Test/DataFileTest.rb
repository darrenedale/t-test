require_relative "../Statistics/DataFile";
require "test/unit";

module Test
    class DataFileTest < Test::Unit::TestCase
        TestFilePath = "/tmp/TTest-DataFileTest-TestFile-#{Time::now.strftime("%Y%m%d%H%M%S%L")}.csv";

        TestData = [
            [12.000000, 14.000000,],
            [12.000000, 14.000000,],
            [12.000000, 14.000000,],
            [15.000000, 14.000000,],
            [13.000000, 16.000000,],
            [12.000000, 15.000000,],
            [13.000000, 18.000000,],
            [14.000000, 17.000000,],
            [15.000000, 14.000000,],
            [15.000000, 13.000000,],
            [14.000000, 15.000000,],
            [13.000000, 14.000000,],
        ];

        # meta-information about the test data
        #
        # this is used to guide the tests and to provided expected data for calculations (sums, counts, means, etc.)
        # if the data in the above array changes, this meta-information must be checked and updated otherwise the test is
        # not valid
        TestDataRowCount = 12;
        TestDataColumnCount = 2;
    
        # items (total, by-row and by-column
        TestDataItemCount = 24;
        TestDataRowItemCount = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,];
        TestDataColumnItemCount = [12, 12,];
    
        # sums (total, by-row and by-column
        TestDataSum = 338;
        TestDataRowSum = [26, 26, 26, 29, 29, 27, 31, 31, 29, 28, 29, 27,];
        TestDataColumnSum = [160, 178,];
    
        # means (total, by-row and by-column
        TestDataArithmeticMean = 14.0833333;
        TestDataRowArithmeticMean = [13, 13, 13, 14.5, 14.5, 13.5, 15.5, 15.5, 14.5, 14, 14.5, 13.5,];
        TestDataColumnArithmeticMean = [13.33333333, 14.83333333,];
    
        # whether the data contains identical #s of items in each row/column
        TestDataHasUniformRows = true;
        TestDataHasUniformColumns = true;
    
        # if the data contains identical #s of items in each row/column, how many per row/column
        TestDataUniformRowItemCount = 2;
        TestDataUniformColumnItemCount = 12;
    
        def setup()
            if File.writable?(TestFilePath)
                File::delete(TestFilePath);
            end

            print ("Writing test data to #{TestFilePath}\n")
            outFile = File.open(TestFilePath, "w");

            TestData.each_with_index {
                | row, rowIndex |
                if 0 < rowIndex
                    outFile.write("\n");
                end

                row.each_with_index {
                    | value, columnIndex |
                    if 0 < columnIndex
                        outFile.write(",");
                    end

                    outFile.write("%0.6f" % value);
                }
            }

            outFile.close();
        end

        def teardown()
            if File.writable?(TestFilePath)
                File::delete(TestFilePath);
            end
        end

        def testRowCount()
            testData = dataFile();
            assert_kind_of(Integer, testData.rowCount, "Row count is not an integer")
            assert_equal(TestDataRowCount, testData.rowCount, "Row count is not correct");
        end

        def testColumnCount()
            testData = dataFile();
            assert_kind_of(Integer, testData.columnCount, "Column count is not an integer")
            assert_equal(TestDataColumnCount, testData.columnCount, "Column count is not correct");
        end

        private

        def dataFile
            return Statistics::DataFile.new(TestFilePath);
        end
    end
end
