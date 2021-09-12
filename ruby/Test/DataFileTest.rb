require_relative "../Statistics/DataFile";
require "test/unit";

module Test
    class DataFileTest < Test::Unit::TestCase
        # Amount by which floating-point tests for equality are allowed to vary.
        # 
        # Testing floats for equality is prone to false failures because float representation is inherently imprecise. This
        # is the maximum amount an actual float value is permitted to vary from its expected value in order to pass
        # testing.
        FloatEqualityDelta = 0.000001;
        
        # The test data.
        #
        # This is the data that appears in the DataFile used for testing.
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

        ##
        # Test for Statistics::DataFile.rowCount
        def testRowCount()
            testData = dataFile();
            assert_kind_of(Integer, testData.rowCount, "Row count is not an integer")
            assert_equal(TestDataRowCount, testData.rowCount, "Row count is not correct");
        end

        ##
        # Test for Statistics::DataFile.rowCount
        def testColumnCount()
            testData = dataFile();
            assert_kind_of(Integer, testData.columnCount, "Column count is not an integer")
            assert_equal(TestDataColumnCount, testData.columnCount, "Column count is not correct");
        end

        ##
        # Test for Statistics::DataFile.itemCount       
        def testItemCount()
            testData = dataFile();
            assert_kind_of(Integer, testData.itemCount());
            assert_equal(TestDataItemCount, testData.itemCount());
        end

        ##
        # Test for Statistics::DataFile.rowItemCount
        def testRowItemCount()
            testData = dataFile();
            
            (0 .. TestDataRowCount - 1).each {
                | row |
                assert_kind_of(Integer, testData.rowItemCount(row), "Item count for row #{row} is not an integer.");
                assert_equal(TestDataRowItemCount[row], testData.rowItemCount(row), "Item count for row #{row} is expected to be #{TestDataRowItemCount[row]}");
            }

            if TestDataHasUniformRows
                assert_kind_of(Integer, testData.rowItemCount());
                assert_equal(TestDataUniformRowItemCount, testData.rowItemCount());
            end
        end

        ##
        # Test for Statistics::DataFile.columnItemCount
        def testColumnItemCount()
            testData = dataFile();
            
            (0 .. TestDataColumnCount - 1).each {
                | column |
                assert_kind_of(Integer, testData.columnItemCount(column), "Item count for column #{column} is not an integer.");
                assert_equal(TestDataColumnItemCount[column], testData.columnItemCount(column), "Item count for column #{column} is expected to be #{TestDataColumnItemCount[column]}");
            }


            if TestDataHasUniformColumns
                assert_kind_of(Integer, testData.columnItemCount());
                assert_equal(TestDataUniformColumnItemCount, testData.columnItemCount());
            end
        end

        ##
        # Test for Statistics::DataFile.sum
        def testSum()
            testData = dataFile();
            assert_kind_of(Float, testData.sum());
            assert_in_delta(TestDataSum, testData.sum(), FloatEqualityDelta);
            assert_in_delta(TestDataSum, TestDataRowSum.sum(), FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected row sums do not agree");
            assert_in_delta(TestDataSum, TestDataColumnSum.sum(), FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected COLUMN sums do not agree");
        end

        ##
        # Test for Statistics::DataFile.rowSum
        def testRowSum()
            testData = dataFile();
            
            (0 .. TestDataRowCount - 1).each {
                | row |
                assert_kind_of(Float, testData.rowSum(row), "Sum for row #{row} is not a floating-point value.");
                assert_in_delta(TestDataRowSum[row], testData.rowSum(row), FloatEqualityDelta, "Sum for row #{row} is expected to be #{TestDataRowSum[row]}");
            }
        end

        ##
        # Test for Statistics::DataFile.columnSum
        def testColumnSum()
            testData = dataFile();

            (0 .. TestDataColumnCount - 1).each {
            | column |
                assert_kind_of(Float, testData.columnSum(column), "Sum for column #{column} is not a floating-point value.");
                assert_in_delta(TestDataColumnSum[column], testData.columnSum(column), FloatEqualityDelta, "Sum for column #{column} is expected to be #{TestDataColumnSum[column]}");
            }
        end
   
        ##
        # Test for Statistics::DataFile.mean
        def testMean()
            testData = dataFile();
            assert_kind_of(Float, testData.mean());
            assert_in_delta(TestDataArithmeticMean, testData.mean(), FloatEqualityDelta);
        end
   
        ##
        # Test for Statistics::DataFile.rowMean
        def testRowMean()
            testData = dataFile();

            (0 .. TestDataRowCount - 1).each {
            | row |
                assert_kind_of(Float, testData.rowMean(row), "Mean for row #{row} is not a floating-point value.");
                assert_in_delta(TestDataRowArithmeticMean[row], testData.rowMean(row), FloatEqualityDelta, "Mean for row #{row} is expected to be #{TestDataRowArithmeticMean[row]}");
            }
        end
   
        ##
        # Test for Statistics::DataFile.columnMean
        def testColumnMean()
            testData = dataFile();

            (0 .. TestDataColumnCount - 1).each {
                | column |
                assert_kind_of(Float, testData.columnMean(column), "Mean for column #{column} is not a floating-point value.");
                assert_in_delta(TestDataColumnArithmeticMean[column], testData.columnMean(column), FloatEqualityDelta, "Mean for column #{column} is expected to be #{TestDataColumnArithmeticMean[column]}");
            }
        end
   
        ##
        # Test for Statistics::DataFile.item
        def testItem()
            testData = dataFile();

            (0 .. TestData.length - 1).each {
                | row |
                assert_compare(testData.rowCount(), ">", row, "missing row #{row} in data file");

                (0 .. TestData[row].length - 1).each {
                | column |
                    assert_compare(testData.columnCount(), ">", column, "missing column in data file");
                    assert_kind_of(Float, testData.item(row: row, col: column), "Item at R#{row}, C#{column} is expected to be a floating-point value.");
                    assert_in_delta(TestData[row][column], testData.item(row: row, col: column), FloatEqualityDelta, "Item at R#{row}, C#{column} is expected to be #{TestData[row][column]}");
                }
            }
        end

        private

        ##
        # Fetch a test mock DataFile
        #
        # Returns an instance of an anonymous subclass of DataFile where the data is always the test data.
        def dataFile
            return (Class.new(Statistics::DataFile) {
                def initialize()
                    super(nil);
                    @data = TestData;
                end
            }).new()
        end
    end
end
