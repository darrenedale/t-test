import XCTest;
import Statistics;

class DataFileTest : XCTestCase
{
    /**
     * The value type to use when testing the DataFile class.
     */
    public typealias ValueType = Double;

    /**
     * Convenience alias for the concrete type of the DataFile being tested.
     */
    public typealias TestDataFile = DataFile<ValueType>;

    /**
     * Amount by which floating-point tests for equality are allowed to vary.
     * 
     * Testing floats for equality is prone to false failures because float representation is inherently imprecise. This
     * is the maximum amount an actual float value is permitted to vary from its expected value in order to pass
     * testing.
     */
    static let FloatEqualityDelta = 0.000001;

    /**
     * The test data.
     *
     * This is the data that appears in the DataFile used for testing.
     */
    static let TestData = [
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

    // meta-information about the test data
    //
    // this is used to guide the tests and to provided expected data for calculations (sums, counts, means, etc.)
    // if the data in the above array changes, this meta-information must be checked and updated otherwise the test is
    // not valid
    static let TestDataRowCount: UInt64 = 12;
    static let TestDataColumnCount: UInt64 = 2;

    // items (total, by-row and by-column
    static let TestDataItemCount: UInt64 = 24;
    static let TestDataRowItemCount: [UInt64] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,];
    static let TestDataColumnItemCount: [UInt64] = [12, 12,];

    // sums (total, by-row and by-column
    static let TestDataSum: ValueType = 338;
    static let TestDataRowSum: [ValueType] = [26, 26, 26, 29, 29, 27, 31, 31, 29, 28, 29, 27,];
    static let TestDataColumnSum: [ValueType] = [160, 178,];

    // means (total, by-row and by-column
    static let TestDataArithmeticMean: ValueType = 14.0833333;
    static let TestDataRowArithmeticMean: [ValueType] = [13, 13, 13, 14.5, 14.5, 13.5, 15.5, 15.5, 14.5, 14, 14.5, 13.5,];
    static let TestDataColumnArithmeticMean: [ValueType] = [13.33333333, 14.83333333,];

    // whether the data contains identical //s of items in each row/column
    static let TestDataHasUniformRows = true;
    static let TestDataHasUniformColumns = true;

    // if the data contains identical //s of items in each row/column, how many per row/column
    static let TestDataUniformRowItemCount: UInt64 = 2;
    static let TestDataUniformColumnItemCount: UInt64 = 12;

    /**
     * Test for Statistics::DataFile.rowCount
     */
    public func testRowCount()
    {
        do {
            let testData = try dataFile();
            XCTAssertEqual(testData.rowCount, DataFileTest.TestDataRowCount, "Row count should be \(DataFileTest.TestDataRowCount)");
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.columnCount
     */
    public func testColumnCount()
    {
        do {
            let testData = try dataFile();
            XCTAssertEqual(testData.columnCount, DataFileTest.TestDataColumnCount, "Column count should be \(DataFileTest.TestDataColumnCount)");
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.itemCount       
     */
    public func testItemCount()
    {
        do {
            let testData = try dataFile();
            XCTAssertEqual(DataFileTest.TestDataItemCount, testData.itemCount);
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.rowItemCount
     */
    public func testRowItemCount()
    {
        do {
            let testData = try dataFile();
            
            for row in (0 ..< DataFileTest.TestDataRowCount) {
                XCTAssertEqual(DataFileTest.TestDataRowItemCount[Int(row)], testData.rowItemCount(row), "Item count for row \(row) is expected to be \(DataFileTest.TestDataRowItemCount[Int(row)])");
            }

            if (DataFileTest.TestDataHasUniformRows) {
                XCTAssertEqual(DataFileTest.TestDataUniformRowItemCount, testData.rowItemCount());
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.columnItemCount
     */
    public func testColumnItemCount()
    {
        do {
            let testData = try dataFile();
            
            for column in (0 ..< DataFileTest.TestDataColumnCount) {
                XCTAssertEqual(DataFileTest.TestDataColumnItemCount[Int(column)], testData.columnItemCount(column), "Item count for column \(column) is expected to be \(DataFileTest.TestDataColumnItemCount[Int(column)])");
            }

            if (DataFileTest.TestDataHasUniformColumns) {
                XCTAssertEqual(DataFileTest.TestDataUniformColumnItemCount, testData.columnItemCount());
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.sum
     */
    public func testSum()
    {
        do {
            let testData = try dataFile();
            XCTAssertEqual(DataFileTest.TestDataSum, testData.sum(), accuracy: DataFileTest.FloatEqualityDelta);
            XCTAssertEqual(DataFileTest.TestDataSum, DataFileTest.TestDataRowSum.reduce(0, { sum, value in sum + value }), accuracy: DataFileTest.FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected row sums do not agree");
            XCTAssertEqual(DataFileTest.TestDataSum, DataFileTest.TestDataColumnSum.reduce(0, { sum, value in sum + value }), accuracy: DataFileTest.FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected COLUMN sums do not agree");
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.rowSum
     */
    public func testRowSum()
    {
        do {
            let testData = try dataFile();
            
            for row in (0 ..< DataFileTest.TestDataRowCount) {
                XCTAssertEqual(DataFileTest.TestDataRowSum[Int(row)], testData.rowSum(row), accuracy: DataFileTest.FloatEqualityDelta, "Sum for row \(row) is expected to be \(DataFileTest.TestDataRowSum[Int(row)])");
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.columnSum
     */
    public func testColumnSum()
    {
        do {
            let testData = try dataFile();

            for column in (0 ..< DataFileTest.TestDataColumnCount) {
                XCTAssertEqual(DataFileTest.TestDataColumnSum[Int(column)], testData.columnSum(column), accuracy: DataFileTest.FloatEqualityDelta, "Sum for column \(column) is expected to be \(DataFileTest.TestDataColumnSum[Int(column)])");
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.mean
     */
    public func testMean()
    {
        do {
            let testData = try dataFile();
            XCTAssertEqual(DataFileTest.TestDataArithmeticMean, testData.mean(), accuracy: DataFileTest.FloatEqualityDelta);
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.rowMean
     */
    public func testRowMean()
    {
        do {
            let testData = try dataFile();

            for row in (0 ..< DataFileTest.TestDataRowCount) {
                XCTAssertEqual(DataFileTest.TestDataRowArithmeticMean[Int(row)], testData.rowMean(row), accuracy: DataFileTest.FloatEqualityDelta, "Mean for row \(row) is expected to be \(DataFileTest.TestDataRowArithmeticMean[Int(row)])");
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.columnMean
     */
    public func testColumnMean()
    {
        do {
            let testData = try dataFile();

            for column in (0 ..< DataFileTest.TestDataColumnCount) {
                XCTAssertEqual(DataFileTest.TestDataColumnArithmeticMean[Int(column)], testData.columnMean(column), accuracy: DataFileTest.FloatEqualityDelta, "Mean for column \(column) is expected to be \(DataFileTest.TestDataColumnArithmeticMean[Int(column)])");
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Test for Statistics::DataFile.item
     */
    public func testItem()
    {
        do {
            let testData = try dataFile();

            for row: UInt64 in (0 ..< UInt64(DataFileTest.TestData.count)) {
                XCTAssertGreaterThan(testData.rowCount, row, "missing row \(row) in data file");

                for column: UInt64 in (0 ..< UInt64(DataFileTest.TestData[Int(row)].count)) {
                    XCTAssertGreaterThan(testData.columnCount, column, "missing column in data file");
                    XCTAssertEqual(DataFileTest.TestData[Int(row)][Int(column)], testData.item(row: row, column: column), accuracy: DataFileTest.FloatEqualityDelta, "Item at R\(row), C\(column) is expected to be \(DataFileTest.TestData[Int(row)][Int(column)])");
                }
            }
        } catch let err {
            XCTFail("No test data available: \(err.localizedDescription)");
        }
    }

    /**
     * Clean up after each test case.
     *
     * The test data is discarded and the temporary CSV file is removed.
     */
    public override func tearDown()
    {
        if (nil != m_testDataUrl) {
            do {
                try FileManager.default.removeItem(at: m_testDataUrl!);
            } catch {
                print("Failed to delete temporary data file \(m_testDataUrl!.path)")
            }

            m_testDataUrl = nil;
        }

        m_tempDataFile = nil;
    }

    /**
     * Fetch the test data file for the current test case.
     */
	private func dataFile() throws -> TestDataFile
    {
        if (nil == m_tempDataFile) {
            let dictionary = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
            let randomString = String((0 ... 20).map{_ in dictionary.randomElement()!;});

            m_testDataUrl = FileManager.default.temporaryDirectory
                .appendingPathComponent("data-file-test-data-\(randomString)")
                .appendingPathExtension("csv");

            try? DataFileTest.TestData.map {
                row in row.map {
                    value in "\(value)";
                }.joined(separator: ",")
            }.joined(separator: "\n").write(to: m_testDataUrl!, atomically: true, encoding: .utf8);

            m_tempDataFile = TestDataFile(fromFile: m_testDataUrl!.path);
        }

        return m_tempDataFile!;
    }

    /**
     * The DataFile with the test data in it.
     */
    private var m_tempDataFile: TestDataFile?;

    /**
     * Where the temporary CSV file with the test data has been stored.
     */
    private var m_testDataUrl: URL?;
}
