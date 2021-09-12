import XCTest;
import Statistics;

// TODO use temp file to store test data - Swift access specifiers differ from most other languages and it's not possible to
// set a property such that it can be written to in subclasses but not from outside the class hierarchy
class DataFileTest : XCTestCase
{
    public typealias ValueType = Double;
    public typealias TestDataFile = DataFile<ValueType>;

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
    let TestDataRowCount: UInt64 = 12;
    let TestDataColumnCount: UInt64 = 2;

    public func testRowCount()
    {
        let testData = dataFile;
        XCTAssertEqual(testData.rowCount, TestDataRowCount, "Row count should be \(TestDataRowCount)");
    }

    public func testColumnCount()
    {
        let testData = dataFile;
        XCTAssertEqual(testData.columnCount, TestDataColumnCount, "Column count should be \(TestDataColumnCount)");
    }

	private var dataFile: TestDataFile
    {
        class MockTestDataFile : TestDataFile
        {
            init()
            {
                super.init();
            }

            public override func item(row: UInt64, column: UInt64) -> ValueType
            {
                assert(0 <= row && rowCount > row);
                assert(0 <= column && columnCount > column);
                return DataFileTest.TestData[Int(row)][Int(column)];
            }
        }

        return MockTestDataFile();
    }
}
