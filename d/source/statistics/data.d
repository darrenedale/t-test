module statistics.data;

import std.stdio;
import std.math;
import std.file;
import std.string;
import std.array;
import std.conv;
import std.algorithm;

/**
 * Template type alias for parser functions for DataFile values.
 */
alias DataItemParser(T) = T function(string);

/**
 * A data file for use with a statistical test.
 *
 * @tparam T The data type for the data file. Items in the data file are parsed to values of this type. Defaults to real, the longest floating-point type available.
 */
class DataFile(T = real)
{
	/**
	 * The type used to index rows, columns, etc.
	 */
    public alias IndexType = long;
    
	/**
	 * The type of items in the data file.
	 */
    public alias ValueType = T;

	/**
	 * The type for value parsers compatible with the DataFile.
	 */
    public alias ParserType = DataItemParser!ValueType;
    
	/**
	 * Initialise a new data file.
	 *
	 * The CSV parser is very simple. It loads successive lines from the provided file and splits it at each comma (,). Each element in the resulting
	 * array of strings is parsed to the ValueType. If this fails, the value for that cell is considered missing (NaN); otherwise, the parsed value is
	 * used for the cell.
	 *
	 * @param path The path to a local CSV file to load.
	 */
	this(string path = "", ParserType parser = item => to!ValueType(item.strip()))
	{
		m_file = path;
		m_itemParser = parser;
		reload();
	}

	/**
	 * Helper to reload the data from the file.
	 * @return true on success, false on failure.
	 */
	protected bool reload()
	{
		if ("" == m_file) {
			writefln("no file to load");
			return false;
		}

		File inFile;

		try {
			inFile = File(m_file, "r");
		} catch(Exception err) {
			writefln("exception thrown opening file \"%s\": %s", m_file, err.msg);
			return false;
		}

		uint n = 0;
		auto data = appender(&m_data);

		// quick and dirty CSV parser
		// can't use std.csv because that requires each row in the CSV to have the same # of cells, which is not a constraint for our data files
		while(!inFile.eof()) {
			data.put(
				inFile
					.readln()
					.strip()
					.split(',')
					.map!(item => m_itemParser(item))
					.array()
			);
		}

		inFile.close();
		return true;
	}

	/**
	 * The number of rows in the DataFile.
	 * @return The row count.
	 */
	public pure IndexType rowCount() const
	{
		return cast(IndexType) m_data.length;
	}

	/**
	 * The number of columns in the DataFile.
	 * @return The column count.
	 */
	public pure IndexType columnCount() const
	{
		if (0 < m_data.length) {
			return cast(IndexType) m_data[0].length;
		}

		return 0;
	}

	/**
	 * Check whether the data file contains any data.
	 * 
	 * @return true if the data file contains zero rows, false otherwise.
	 */
	public pure bool isEmpty() const
	{
		return 0 == m_data.length;
	}
	
	/**
	 * Count the number of values in the DataFile.
	 * 
	 * The number of values is the product of the row and column count, less the number of empty cells.
	 *
	 * @return The number of items.
	 */
	public pure IndexType itemCount() const
	{
        return itemCount(0, 0, rowCount() - 1, columnCount() - 1);
	}

	/**
	 * Count the number of values in a row in the DataFile.
	 * 
	 * The number of values is the length of the row, less the number of empty cells.
	 *
	 * @return The number of items.
	 */
	public pure IndexType rowItemCount(IndexType row = 0) const
	{
        return itemCount(row, 0, row, columnCount() - 1);
	}
	
	/**
	 * Count the number of values in a column in the DataFile.
	 * 
	 * The number of values is the height of the column, less the number of empty cells.
	 *
	 * @return The number of items.
	 */
	public pure IndexType columnItemCount(IndexType col = 0) const
	{
        return itemCount(0, col, rowCount() - 1, col);
	}

	/**
	 * Calculate the sum of the items in the DataFile.
	 *
	 * @param pow An optional power to which to raise each value before it is added to the sum.
	 *
	 * @return The sum of the values.
	 */
	public pure ValueType sum(ValueType pow = 1.0) const
	{
		return sum(0, 0, rowCount() - 1, columnCount() - 1, pow);
	}

	/**
	 * Calculate the sum of the items in a row in the DataFile.
	 *
	 * @param row The row containing the items to include in the calculation.
	 * @param pow An optional power to which to raise each value before it is added to the sum.
	 *
	 * @return The sum of the values.
	 */
	public pure ValueType rowSum(IndexType row, ValueType pow = 1.0) const
	{
		return sum(row, 0, row, columnCount() - 1, pow);
	}

	/**
	 * Calculate the sum of the items in a column in the DataFile.
	 *
	 * @param col The column containing the items to include in the calculation.
	 * @param pow An optional power to which to raise each value before it is added to the sum.
	 *
	 * @return The sum of the values.
	 */
	public pure ValueType columnSum(IndexType col, ValueType pow = 1.0) const
	{
		return sum(0, col, rowCount() - 1, col, pow);
	}

	/**
	 * Calculate the mean of the items in the DataFile.
	 *
	 * @param meanNumber Which mean to calculate. Defaults to the arithmetic mean.
	 *
	 * @return The mean of the values.
	 */
	public pure ValueType mean(ValueType meanNumber= 1.0) const
	{
		return mean(0, 0, rowCount() - 1, columnCount() - 1, meanNumber);
	}

	/**
	 * Calculate the mean of the items in a row in the DataFile.
	 *
	 * @param row The row containing the items to include in the calculation.
	 * @param meanNumber Which mean to calculate. Defaults to the arithmetic mean.
	 *
	 * @return The mean of the values.
	 */
	public pure ValueType rowMean(IndexType row, ValueType meanNumber = 1.0) const
	{
		return mean(row, 0, row, columnCount() - 1, meanNumber);
	}

	/**
	 * Calculate the mean of the items in a column in the DataFile.
	 *
	 * @param col The column containing the items to include in the calculation.
	 * @param meanNumber Which mean to calculate. Defaults to the arithmetic mean.
	 *
	 * @return The mean of the values.
	 */
	public pure ValueType columnMean(IndexType col, ValueType meanNumber = 1.0) const
	{
		return mean(0, col, rowCount() - 1, col, meanNumber);
	}

	/**
	 * Count the number of values in a range in the DataFile.
	 *
	 * The number of values is the product of the width and height of the range, less the number of empty cells.
	 *
	 * @param r1 The first row to include in the range.
	 * @param c1 The second row to include in the range.
	 * @param r2 The first column to include in the range.
	 * @param c2 The second column to include in the range.
	 *
	 * @return The number of values in the range.
	 */
	protected pure IndexType itemCount(IndexType r1, IndexType c1, IndexType r2, IndexType c2) const
	in
	{
		assert(r1 >= 0);
		assert(r1 < rowCount());
		assert(c1 >= 0);
		assert(c1 < columnCount());
		assert(r2 >= 0);
		assert(r2 < rowCount());
		assert(c2 >= 0);
		assert(c2 < columnCount());
		assert(r2 >= r1);
		assert(c2 >= c1);
	}
	do
	{
		IndexType count = 0;
		
		foreach (IndexType col; c1 .. c2 + 1) {
			foreach (IndexType row; r1 .. r2 + 1) {
				if (isNaN(m_data[row][col])) {
					continue;
				}
				
				++count;
			}
		}
		
		return count;
	}
	
	/**
	 * Calculate the sum of a range of values in the DataFile.
	 *
	 * @param r1 The first row to include in the range.
	 * @param c1 The second row to include in the range.
	 * @param r2 The first column to include in the range.
	 * @param c2 The second column to include in the range.
	 * @param pow An optional power to which to raise each value before it is added to the sum.
	 *
	 * @return The sum of the values in the range.
	 */
	protected pure ValueType sum(IndexType r1, IndexType c1, IndexType r2, IndexType c2, ValueType pow = 1.0) const
	in
	{
		assert(r1 >= 0);
		assert(r1 < rowCount());
		assert(c1 >= 0);
		assert(c1 < columnCount());
		assert(r2 >= 0);
		assert(r2 < rowCount());
		assert(c2 >= 0);
		assert(c2 < columnCount());
		assert(r2 >= r1);
		assert(c2 >= c1);
	}
	do
	{
		ValueType sum = 0.0;

		foreach(IndexType c; c1 .. c2 + 1) {
			foreach(IndexType r; r1 .. r2 + 1) {
				sum += item(r, c) ^^ pow;
			}
		}

		return sum;
	}
	
	/**
	 * Calculate the mean of a range of values in the DataFile.
	 *
	 * @param r1 The first row to include in the range.
	 * @param c1 The second row to include in the range.
	 * @param r2 The first column to include in the range.
	 * @param c2 The second column to include in the range.
	 * @param meanNumber Which mean to calculate. Defaults to the arithmetic mean.
	 *
	 * @return The mean of the values in the range.
	 */
	protected pure ValueType mean(IndexType r1, IndexType c1, IndexType r2, IndexType c2, ValueType meanNumber = 1.0) const
	in
	{
		assert(r1 >= 0);
		assert(r1 < rowCount());
		assert(c1 >= 0);
		assert(c1 < columnCount());
		assert(r2 >= 0);
		assert(r2 < rowCount());
		assert(c2 >= 0);
		assert(c2 < columnCount());
		assert(r2 >= r1);
		assert(c2 >= c1);
	}
	do
	{
		ValueType mean = 0.0L;
		IndexType n = 0;

		foreach (IndexType row; r1 .. r2 + 1) {
			foreach (IndexType col; c1 .. c2 + 1) {
				ValueType itemValue = m_data[row][col];

				if(!isNaN(itemValue)) {
					++n;
					mean += itemValue ^^ meanNumber;
				}
			}
		}

		return mean / n ^^ (1.0L / meanNumber);
	}

	/**
	 * Fetch an item from the DataFile.
	 *
	 * @param row The index of the row from which the value is sought.
	 * @param col The index of the column from which the value is sought.
	 *
	 * @return The value. This will be NaN if the cell is empty.
	 */
	public pure ValueType item(IndexType row, IndexType col) const
	in
	{
		assert(row >= 0);
		assert(row < rowCount());
		assert(col >= 0);
		assert(col < columnCount());
	}
	do
	{
		return m_data[row][col];
	}
    
	/**
	 * Internal type alias for the storage of the values from the data file.
	 */
    private alias DataStorage = ValueType[][];
    
	/**
	 * The parsed data.
	 */
	private DataStorage m_data;
	
	/**
	 * The path to the file containing the data.
	 */
	private string m_file;
	
	/**
	 * The parser used to read values from the file content.
	 */
	private DataItemParser!ValueType m_itemParser;
}

unittest
{
	import testing.unit : TestCase, RunsTests;
	
	/**
	 * Unit test for DataFile class.
	 */
	class DataFileTest : TestCase
	{
		mixin RunsTests!(DataFileTest);

		static const real[][] testData = [
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
		
		static const real floatEqualityDelta = 0.000001;

		static const ulong testDataRowCount = 12;
		static const ulong testDataColumnCount = 2;

		static const ulong testDataItemCount = 24;
		static const ulong[] testDataRowItemCount = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,];
		static const ulong[] testDataColumnItemCount = [12, 12,];

		// sums (total, by-row and by-column
		static const real testDataSum = 338;
		static const real[] testDataRowSum = [26, 26, 26, 29, 29, 27, 31, 31, 29, 28, 29, 27,];
		static const real[] testDataColumnSum = [160, 178,];

		// means (total, by-row and by-column
		static const real testDataArithmeticMean = 14.0833333;
		static const real[] testDataRowArithmeticMean = [13, 13, 13, 14.5, 14.5, 13.5, 15.5, 15.5, 14.5, 14, 14.5, 13.5,];
		static const real[] testDataColumnArithmeticMean = [13.33333333, 14.83333333,];

		// whether the data contains identical #s of items in each row/column
		static const bool testDataHasUniformRows = true;
		static const bool testDataHasUniformColumns = true;

		// if the data contains identical #s of items in each row/column, how many per row/column
		static const ulong testDataUniformRowItemCount = 2;
		static const ulong testDataUniformColumnItemCount = 12;

		private static DataFile!() dataFile()
		{
			import std.ascii : letters;
			import std.random : randomSample;
			import std.path : buildPath;
			import std.file : remove, tempDir;
			import std.utf : byCodeUnit;
			
			string tempFile = tempDir().buildPath("t-test-unit-test-data-" ~ letters.byCodeUnit().randomSample(10).to!string() ~ ".csv");
			
			scope (exit)
			{
				tempFile.remove();
			}
			
			auto outFile = new File(tempFile, "w");
			bool firstRow = true;
			
			foreach(const ref real[] row; testData) {
				if (firstRow) {
					firstRow = false;
				} else {
					outFile.writeln("");
				}
				
				bool firstColumn = true;
				
				foreach(real value; row) {
					if (firstColumn) {
						firstColumn = false;
					} else {
						outFile.write(',');
					}
					
					outFile.writef("%0.3f", value);
				}
			}
			
			outFile.close();
			return new DataFile!()(tempFile);
		}

		public void testRowCount()
		{
			auto dataFile = this.dataFile();
			assertEquals(testDataRowCount, dataFile.rowCount(), "row count expected to be " ~ to!string(testDataRowCount) ~ " found " ~ to!string(dataFile.rowCount()));
		}

		public void testColumnCount()
		{
			auto dataFile = this.dataFile();
			assertEquals(testDataColumnCount, dataFile.columnCount(), "column count expected to be " ~ to!string(testDataColumnCount) ~ " found " ~ to!string(dataFile.columnCount()));
		}

		public void testItemCount()
		{
			auto dataFile = this.dataFile();
			assertEquals(testDataItemCount,  dataFile.itemCount(), "item count expected to be " ~ to!string(testDataItemCount) ~ " found " ~ to!string(dataFile.itemCount()));
		}
			
		public void testRowItemCount()
		{
			auto dataFile = this.dataFile();
			
			for (long row = 0; row < testDataRowCount; ++row) {
				assertEquals(testDataRowItemCount[row], dataFile.rowItemCount(row), "Item count for row " ~ to!string(row) ~ " is expected to be " ~ to!string(testDataRowItemCount[row]));
			}

			if (testDataHasUniformRows) {
				assert(testDataUniformRowItemCount == dataFile.rowItemCount());
			}
		}
			
		public void testColumnItemCount()
		{
			auto dataFile = this.dataFile();
			
			for (long column = 0; column < testDataColumnCount; ++column) {
				assertEquals(testDataColumnItemCount[column], dataFile.columnItemCount(column), "Item count for column " ~ to!string(column) ~ " is expected to be " ~ to!string(testDataColumnItemCount[column]));
			}

			if (testDataHasUniformColumns) {
				assert(testDataUniformColumnItemCount == dataFile.columnItemCount());
			}
		}

		public void testSum()
		{
			auto dataFile = this.dataFile();
			assertIsType!real(dataFile.sum());
			assertEqualsWithDelta(testDataSum, dataFile.sum(), floatEqualityDelta);
		}
			
		public void testRowSum()
		{
			auto dataFile = this.dataFile();
			
			for (long row = 0; row < testDataRowCount; ++row) {
				assertIsType!real(dataFile.rowSum(row), "Sum for row " ~ to!string(row) ~ "is not a floating-point value.");
				assertEqualsWithDelta(testDataRowSum[row], dataFile.rowSum(row), floatEqualityDelta, "Sum for row " ~ to!string(row) ~ "is expected to be " ~ to!string(testDataRowSum[row]));
			}
		}

		public void testColumnSum()
		{
			auto dataFile = this.dataFile();

			for (long column = 0; column < testDataColumnCount; ++column) {
				assertIsType!real(dataFile.columnSum(column), "Sum for column " ~ to!string(column) ~ "is not a floating-point value.");
				assertEqualsWithDelta(testDataColumnSum[column], dataFile.columnSum(column), floatEqualityDelta, "Sum for column " ~ to!string(column) ~ "is expected to be " ~ to!string(testDataColumnSum[column]));
			}
		}

		/**
		* @covers \Statistics\DataFile::mean
		*/
		public void testMean()
		{
			auto dataFile = this.dataFile();
			assertEqualsWithDelta(testDataArithmeticMean, dataFile.mean(), floatEqualityDelta);
		}

		/**
		* @covers \Statistics\DataFile::rowMean
		*/
		public void testRowMean()
		{
			auto dataFile = this.dataFile();

			for (long row = 0; row < testDataRowCount; ++row) {
				assertIsType!real(dataFile.rowMean(row), "Mean for row " ~ to!string(row) ~ "is not a floating-point value.");
				assertEqualsWithDelta(testDataRowArithmeticMean[row], dataFile.rowMean(row), floatEqualityDelta, "Mean for row " ~ to!string(row) ~ "is expected to be " ~ to!string(testDataRowArithmeticMean[row]));
			}
		}

		/**
		* @covers \Statistics\DataFile::columnMean
		*/
		public void testColumnMean()
		{
			auto dataFile = this.dataFile();

			for (long column = 0; column < testDataColumnCount; ++column) {
				assertIsType!real(dataFile.columnMean(column), "Mean for column " ~ to!string(column) ~ "is not a floating-point value.");
				assertEqualsWithDelta(testDataColumnArithmeticMean[column], dataFile.columnMean(column), floatEqualityDelta, "Mean for column " ~ to!string(column) ~ "is expected to be " ~ to!string(testDataColumnArithmeticMean[column]));
			}
		}

		/**
		* @covers \Statistics\DataFile::item
		*/
		public void testItem()
		{
			auto dataFile = this.dataFile();

			for (long row = 0; row < testData.length; ++row) {
				assertLessThan(dataFile.rowCount(), row, "missing row " ~ to!string(row) ~ "in data file");

				for (long column = 0; column < testData[row].length; ++column) {
					assertLessThan(dataFile.columnCount(), column, "missing column in data file");
					assertIsType!real(dataFile.item(row, column), "Item at R" ~ to!string(row) ~ ", C" ~ to!string(column) ~ " is expected to be a floating-point value.");
					assertEqualsWithDelta(testData[row][column], dataFile.item(row, column), floatEqualityDelta, "Item at R{row}, C{column} is expected to be " ~ to!string(testData[row][column]));
				}
			}
		}
	}
	
	new DataFileTest().run();
}
