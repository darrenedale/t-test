
import Foundation;

protocol LineReader
{
	func nextLine() -> String?;
}

class DataFileReader : LineReader
{
	init?(_ fileName: String)
	{
		let fh = FileHandle(forReadingAtPath: fileName);

		if (nil == fh) {
			return nil;
		}

		m_fileHandle = fh!;
	}

	public func nextLine() -> String?
	{
		var eol = m_cursor;

		while (true) {
			if (eol == m_buffer.count) {
				// clear out anything we've already returned to the caller
				eol -= shrinkBuffer();

				// end of file?
				if (!readMore()) {
					// end of file and cursor is already at the end of the buffer, there are no more lines
					// to read
					if (eol == m_cursor) {
						return nil;
					}

					// NOTE the buffer has been shrunk so we know we're returning the whole thing
					let line = String(decoding: m_buffer, as: UTF8.self);
					m_cursor = eol;
					return line;
				}
			}

			if (10 == m_buffer[eol]) {
				let line = String(decoding: m_buffer[m_cursor ..< eol], as: UTF8.self);
				m_cursor = eol + 1;
				return line;
			}

			eol += 1;
		}
	}

	private func readMore(bytes: UInt64 = 1024) -> Bool
	{
		let inData = m_fileHandle.readData(ofLength: 1024);

		guard !inData.isEmpty else {
			return false;
		}

		m_buffer.append(inData);
		return true;
	}

	/**
	 * @returns The number of bytes recovered from the buffer.
	 */
	private func shrinkBuffer() -> Int
	{
		guard 0 < m_cursor else {
			return 0;
		}

		m_buffer.removeFirst(m_cursor);
		let removed = m_cursor;
		m_cursor = 0;
		return removed;
	}

	private var m_fileHandle: FileHandle;
	private var m_buffer: Data = Data();
	private var m_cursor: Int = 0;
}

class DataFile<ValueType : BinaryFloatingPoint & LosslessStringConvertible>
{
    public typealias ValueParser = (String) -> ValueType;

	/**
	 * Initialise a new data file.
	 *
	 * The CSV parser is very simple. It reads successive lines from the provided file and splits each line at every comma (,). Each element in the
	 * resulting array of strings for each line is parsed as a +Float+. If this fails, the value for that cell is considered missing (+Float::NAN+);
	 * otherwise, the parsed value is used for the cell.
	 *
	 * The +parser+ argument is an object (e.g. method, lambda, ...) that can be called with a single +String+ argument and which returns a +Float+
	 * when called.
	 * It will be called once for each string cell read from the CSV file to parse it to a value for the data. The default implementation checks
	 * whether the string is a valid representation of a decimal floating point value and calls <code>to_f()</code> if it is, or returns +Float::NAN+
	 * if it's not. It is guaranteed that it will never be called with anything other than a single +String+ argument.
	 *
	 * @param path The path to a local CSV file to load.
	 * @param parser A custom parser to convert string cells in the CSV file to numeric values.
	 */
	init(fromFile path: String? = nil, parsingValuesWith parser: @escaping ValueParser = DataFile.defaultParser)
	{
		self.m_file = path;
		self.m_parser = parser;
		reload();
	}

	/**
	 * Check whether the data file contains any data.
	 *
	 * @return true if the data file contains zero rows, false otherwise.
	 */
	public var isEmpty: Bool
	{
        return 0 == rowCount;
	}

	/**
     * The number of rows in the DataFile.
     *
     * @return The row count.
	 */
	public var rowCount: UInt64
	{
		return UInt64(m_data?.count ?? 0);
	}

	/**
     * The number of columns in the DataFile.
     *
     * Currently the count naively assumes the first row contains all the columns that exist in the data.
	 *
     * @return The column count.
	 */
	public var columnCount: UInt64
	{
		return 0 == rowCount ? 0 : UInt64(m_data![0].count);
	}

	/**
	 * Count the number of values in the DataFile.
	 *
	 * @return The number of values.
	 */
	public var itemCount: UInt64
	{
		assert(!isEmpty);
		return rangeItemCount(firstRow: 0, firstColumn: 0, lastRow: rowCount - 1, lastColumn: columnCount - 1);
	}

	/**
	 * Count the number of values in a row in in the DataFile.
	 *
	 * @params row The row to count. Defaults to 0 so that it can be called without a row index when it is known that all rows contain an identical
	 * number of items.
	 *
	 * @return The number of values.
	 */
	public func rowItemCount(_ row: UInt64 = 0) -> UInt64
	{
		assert(0 <= row && rowCount > row);
		return rangeItemCount(firstRow: row, firstColumn: 0, lastRow: row, lastColumn: columnCount - 1);
	}

	/**
	 * Count the number of values in a column in in the DataFile.
	 *
	 * @params column The column to count. Defaults to 0 so that it can be called without a column index when it is known that all columns contain an identical
	 * number of items.
	 *
	 * @return The number of values.
	 */
	public func columnItemCount(_ column: UInt64 = 0) -> UInt64
	{
		assert(0 <= column && columnCount > column);
		return rangeItemCount(firstRow: 0, firstColumn: column, lastRow: rowCount - 1, lastColumn: column);
	}

	/**
	 * Calculate the sum of the values in the DataFile.
	 *
	 * @params pow The power to which to raise each value before it is added to the sum. Defaults to 1.0.
	 *
	 * @return The sum.
	 */
	public func sum(_ power: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(!isEmpty);
		return rangeSum(firstRow: 0, firstColumn: 0, lastRow: rowCount - 1, lastColumn: columnCount - 1, power: power);
	}

	/**
	 * Calculate the sum of the values in a row in the DataFile.
	 *
	 * @params row The row whose items are to be summed.
	 * @params pow The power to which to raise each value before it is added to the sum. Defaults to 1.0.
	 *
	 * @return The sum.
	 */
	public func rowSum(_ row: UInt64 = 0, _ power: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(0 <= row && rowCount > row);
		return rangeSum(firstRow: row, firstColumn: 0, lastRow: row, lastColumn: columnCount - 1, power: power);
	}

	/**
	 * Calculate the sum of the values in a column in the DataFile.
	 *
	 * @params column The column whose items are to be summed.
	 * @params pow The power to which to raise each value before it is added to the sum. Defaults to 1.0.
	 *
	 * @return The sum.
	 */
	public func columnSum(_ column: UInt64 = 0, _ power: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(0 <= column && columnCount > column);
		return rangeSum(firstRow: 0, firstColumn: column, lastRow: rowCount - 1, lastColumn: column, power: power);
	}

	/**
	 * Calculate the mean of the values in the DataFile.
	 *
	 * @params meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
	 *
	 * @return The mean.
	 */
	public func mean(_ meanNumber: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(!isEmpty);
		return rangeMean(firstRow: 0, firstColumn: 0, lastRow: rowCount - 1, lastColumn: columnCount - 1, meanNumber: meanNumber);
	}

	/**
	 * Calculate the mean of the values in a row in the DataFile.
	 *
	 * @params row The row whose items are to be included in the calculation.
	 * @params meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
	 *
	 * @return The mean.
	 */
	public func rowMean(_ row: UInt64 = 0, _ meanNumber: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(0 <= row && rowCount > row);
		return rangeMean(firstRow: row, firstColumn: 0, lastRow: row, lastColumn: columnCount - 1, meanNumber: meanNumber);
	}

	/**
	 * Calculate the mean of the values in a column in the DataFile.
	 *
	 * @params column The column whose items are to be included in the calculation.
	 * @params meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
	 *
	 * @return The mean.
	 */
	public func columnMean(_ column: UInt64 = 0, _ meanNumber: ValueType = ValueType(1.0)) -> ValueType
	{
		assert(0 <= column && columnCount > column);
		return rangeMean(firstRow: 0, firstColumn: column, lastRow: rowCount - 1, lastColumn: column, meanNumber: meanNumber);
	}

	/**
	 * Fetch a value from the data file.
	 *
	 * The value will be NaN if the identified cell in the data file is empty.
	 *
	 * For performance reasons, the row and column are not bounds checked - it is the caller's responsibility to check
	 * the provided row and column before attempting to fetch an item.
	 *
	 * @return The value.
	 */
	public func item(row: UInt64, column: UInt64) -> ValueType
	{
		assert(0 <= row && rowCount > row);
		assert(0 <= column && columnCount > column);
		return m_data![Int(row)][Int(column)];
	}

	/**
	 * The default parser for the CSV file content.
	 *
	 * @param str The string from a single cell of the CSV file to parse.
	 *
	 * @return The parsed value (ValueType.nan if the string is not a valid decimal floating-point number).
	 */
	private static func defaultParser(str: String) -> ValueType
	{
        return ValueType(str) ?? ValueType.nan;
	}

	/**
	 * Helper to calculate the number of values in a given range.
	 *
	 * Assumes that the given range is valid for the data in the DataFile object. It is the caller's responsiblity to
	 * ensure this is the case.
	 *
	 * @param firstRow The topmost row to include in the count.
	 * @param firstColumn The leftmost column to include in the count.
	 * @param lastRow The bottom-most row to include in the count.
	 * @param lastColumn The rightmost column to include in the count.
	 *	 
	 * @return The number of non-NaN items.
	 */
	private func rangeItemCount(firstRow: UInt64, firstColumn: UInt64, lastRow: UInt64, lastColumn: UInt64) -> UInt64
	{
		var count: UInt64 = 0;

		for row: UInt64 in (firstRow ... lastRow) {
			for col: UInt64 in (firstColumn ... lastColumn) {
				if (!item(row: row, column: col).isNaN) {
					count += 1;
				}
			}
		}

		return count;
	}

	/**
	 * Helper to Sum the values in a given range.
	 *
	 * @param firstRow The topmost row to include in the sum.
	 * @param firstColumn The leftmost column to include in the sum.
	 * @param lastRow The bottom-most row to include in the sum.
	 * @param lastColumn The rightmost column to include in the sum.
	 * @param power An optional power to which to raise each value before it is added to the sum. Defaults to 1.0.
	 *
	 * @return The sum of the values in the range.
	 */
	private func rangeSum(firstRow: UInt64, firstColumn: UInt64, lastRow: UInt64, lastColumn: UInt64, power: ValueType = 1.0) -> ValueType
	{
		var sum: ValueType = ValueType(0.0);

		for row: UInt64 in (firstRow ... lastRow) {
			for col: UInt64 in (firstColumn ... lastColumn) {
				let value = item(row: row, column: col);

				if (!value.isNaN) {
					sum += ValueType(pow(Double(value), Double(power)));
				}
			}
		}

		return sum;
	}

	/**
	 * Calculate the mean of the items in a given range.
	 *
	 * The arithmetic mean, which is often referred to as the average, is meanNumber 1; the quadratic is 2; the geometric is -1.
	 *
	 * @param firstRow The topmost row to include in the calculation.
	 * @param firstColumn The leftmost column to include in the calculation.
	 * @param lastRow The bottom-most row to include in the calculation.
	 * @param lastColumn The rightmost column to include in the calculation.
	 * @param meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
	 *
	 * @return The mean of the values in the range.
	 */
	private func rangeMean(firstRow: UInt64, firstColumn: UInt64, lastRow: UInt64, lastColumn: UInt64, meanNumber: ValueType = 1.0) -> ValueType
	{
		var sum: ValueType = 0.0;
		var n: UInt64 = 0;

		for row in (firstRow ... lastRow) {
			for col in (firstColumn ... lastColumn) {
				let value = item(row: row, column: col);

				if (!value.isNaN) {
					sum += ValueType(pow(Float80(value), Float80(meanNumber)));
					n += 1;
				}
			}
		}

		return ValueType(pow(Float80(sum / ValueType(n)), Float80(ValueType(1.0) / meanNumber)));
	}

	/**
	 * Helper to reload the data from the file.
	 * 
	 * @return true on success, false on failure.
	 */
	@discardableResult
	private func reload() -> Bool
	{
		if (nil == self.m_file || self.m_file!.isEmpty) {
			print("no file to load\n");
			return false;
		}

		if (!FileManager.default.isReadableFile(atPath: self.m_file!)) {
			print("file " + self.m_file! + " does not exist or is not readable");
			return false;
		}

		let reader = DataFileReader(self.m_file!);

		if (nil == reader) {
			print("file " + self.m_file! + " could not be opened for reading");
			return false;
		}

		m_data = [];
		var row = 0;

		while (true) {
			let line = reader!.nextLine();
			
			guard nil != line else {
				break;
			}

			m_data!.append([]);
			let cells = line!.split(separator: ",");

			for col in (0 ..< cells.count) {
				// trim leading and trailing whitespace
				var start = cells[col].startIndex;
				var end = cells[col].index(before: cells[col].endIndex);
				
				while (start != end && cells[col][start].isWhitespace) {
					start = cells[col].index(after: start);
				}
				
				while (start != end && cells[col][end].isWhitespace) {
					end = cells[col].index(before: end);
				}

				let value = m_parser(String(cells[col][start ... end]));
				m_data![row].append(value);
			}

			row += 1;
		}

		return true;
	}

	private var m_data: [[ValueType]]?;
	private let m_file: String?;
	private let m_parser: ValueParser;
}
