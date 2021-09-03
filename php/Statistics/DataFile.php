<?php

namespace Statistics;

/**
 * A data file for use with a statistical test.
 */
class DataFile
{
	/**
	 * The parsed data.
	 */
	private array $m_data = [];

	/**
	 * The path to the file containing the data.
	 */
	private string $m_file;

	/**
	 * @var callable | \Closure The parser for cell content from the CSV file.
	 */
	private mixed $m_parser;

	/**
	 * Initialise a new data file.
	 *
	 * The CSV parser is very simple. It loads successive lines from the provided file and splits it at each comma (,). Each element in the resulting
	 * array of strings is parsed to the float. If this fails, the value for that cell is considered missing (NaN); otherwise, the parsed value is
	 * used for the cell.
	 *
	 * @param ?string $path The path to a local CSV file to load.
	 * @param callable|\Closure|null $parser The parser to use to parse cells from the CSV. Defaults to the class's
	 * default parser.
	 */
	public function __construct(string $path = null, callable | \Closure $parser = null)
	{
		$this->m_parser = $parser ?? function (string $str): float {
			return self::defaultParser($str);
		};

		$this->m_file = $path;
		$this->reload();
	}

	/**
	 * Default parser for values in the CSV.
	 *
	 * @param string $str The cell value to parse.
	 *
	 * @return float The parsed value.
	 */
	protected static function defaultParser(string $str): float
	{
		$value = filter_var($str, FILTER_VALIDATE_FLOAT);
		return (false === $value ? NAN : $value);
	}

	/**
	 * The number of rows in the DataFile.
	 * @return int The row count.
	 */
	public function rowCount(): int
	{
		return count($this->m_data);
	}

	/**
	 * The number of columns in the DataFile.
	 *
	 * Currently the count naively assumes the first row contains all the columns that exist in the data.
	 * @return int The column count.
	 */
	public function columnCount(): int
	{
		if(!empty($this->m_data)) {
			return count($this->m_data[0]);
		}

		return 0;
	}

	/**
	 * Check whether the data file contains any data.
	 * 
	 * @return true if the data file contains zero rows, false otherwise.
	 */
	public function isEmpty(): bool
	{
		return empty($this->m_data);
	}
	
	/**
	 * Count the number of items in a given range in the data file.
	 *
	 * If no arguments are given, the whole data file is included in the count. If at least one argument is given, all
	 * must be given.
	 *
	 * Note that some cells in the data file can be empty, so the count is not simply the product of the range dimensions.
	 *
	 * @param ?int $r1 The topmost row to include in the count.
	 * @param ?int $c1 The leftmost column to include in the count.
	 * @param ?int $r2 The bottom-most row to include in the count.
	 * @param ?int $c2 The rightmost column to include in the count.
	 *
	 * @return int The number of data items in the range.
	 */
	public function itemCount(int $r1 = null, int $c1 = null, int $r2 = null, int $c2 = null): int
	{
		if (!isset($r1)) {
			$r1 = 0;
			$r2 = $this->rowCount() - 1;
			$c1 = 0;
			$c2 = $this->columnCount() - 1;
		}

		$count = 0;

		for ($r = $r1; $r <= $r2; ++$r) {
			for($c = $c1; $c <= $c2; ++$c) {
				if(!is_nan($this->m_data[$r][$c])) {
					++$count;
				}
			}
		}

		return $count;
	}

	/**
	 * Count the number of values in a row in the DataFile.
	 *
	 * @param int row The row to count. Defaults to 0 so that it can be called without a row index when it is
	 * known that all rows contain an identical number of items.
	 *
	 * @return int The number of values.
	 */
	public function rowItemCount(int $row = 0): int
	{
		return $this->itemCount($row, 0, $row, $this->columnCount() - 1);
	}

	/**
	 * Count the number of values in a column in the DataFile.
	 *
	 * @param int col The column to count. Defaults to 0 so that it can be called without a column index when it is known that all columns contain an
	 * identical number of items.
	 *
	 * @return int The number of values.
	 */
	public function columnItemCount(int $col = 0): int
	{
		return $this->itemCount(0, $col, $this->rowCount() - 1, $col);
	}

	/**
	 * Calculate the mean of the items in a given range.
	 *
	 * If no arguments are given, the whole data file is included in the calculation of the mean. If at least one
	 * argument is given, all must be given, except $meanNumber which is always optional.
	 *
	 * The arithmetic mean, which is often referred to as the average, is meanNumber 1; the quadratic is 2; the geometric is -1.
	 *
	 * @param ?int $r1 The topmost row to include in the mean.
	 * @param ?int $c1 leftmost column to include in the mean.
	 * @param ?int $r2 The bottom-most row to include in the mean.
	 * @param ?int $c2 The rightmost column to include in the mean.
	 * @param float $meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
	 *
	 * @return float The mean.
	 */
	public function mean(int $r1 = null, int $c1 = null, int $r2 = null, int $c2 = null, float $meanNumber = 1.0): float
	{
		if (!isset($r1)) {
			$r1 = 0;
			$r2 = $this->rowCount() - 1;
			$c1 = 0;
			$c2 = $this->columnCount() - 1;
		}

		$mean = 0.0;
		$n = 0;

		for ($r = $r1; $r <= $r2; ++$r) {
			for ($c = $c1; $c <= $c2; ++$c) {
				$itemValue = $this->m_data[$r][$c];

				if(!is_nan($itemValue)) {
					++$n;
					$mean += pow($itemValue, $meanNumber);
				}
			}
		}

		return pow($mean / $n, 1.0 / $meanNumber);
	}

	/**
	 * Calculate the mean of the values in a row in the DataFile.
	 *
	 * @return float The mean.
	 */
	public function rowMean(int $row, float $meanNumber = 1.0): float
	{
		return $this->mean($row, 0, $row, $this->columnCount() - 1, $meanNumber);
	}

	/**
	 * Calculate the mean of the values in a column in the DataFile.
	 *
	 * @return float The mean.
	 */
	public function columnMean(int $col, float $meanNumber = 1.0): float
	{
		return $this->mean(0, $col, $this->rowCount() - 1, $col, $meanNumber);
	}

	/**
	 * Sum the items in a given range.
	 *
	 * If no arguments are given, the whole data file is included in the sum. If at least one argument is given, all
	 * must be given except $pow, which is always optional.
	 *
	 * @param ?int $r1 The topmost row to include in the sum.
	 * @param ?int $c1 The leftmost column to include in the sum.
	 * @param ?int $r2 The bottom-most row to include in the sum.
	 * @param ?int $c2 The rightmost column to include in the sum.
	 * @param float $pow An optional power to which to raise each value before it is added to the sum.
	 *
	 * @return float The sum.
	 */
	public function sum(int $r1 = null, int $c1 = null, int $r2 = null, int $c2 = null, float $pow = 1.0): float
	{
		if (!isset($r1)) {
			$r1 = 0;
			$r2 = $this->rowCount() - 1;
			$c1 = 0;
			$c2 = $this->columnCount() - 1;
		}

		$sum = 0.0;

		for($r = $r1; $r <= $r2; ++$r) {
			for($c = $c1; $c <= $c2; ++$c) {
				$itemValue = $this->m_data[$r][$c];

				if(!is_nan($itemValue)) {
					$sum += pow($itemValue, $pow);
				}
			}
		}

		return $sum;
	}

	/**
	 * Calculate the sum of the values in a row in the DataFile.
	 *
	 * @return float The sum.
	 */
	public function rowSum(int $row, float $pow = 1.0): float
	{
		return $this->sum($row, 0, $row, $this->columnCount() - 1, $pow);
	}

	/**
	 * Calculate the sum of the values in a column in the DataFile.
	 *
	 * @return float The sum.
	 */
	public function columnSum(int $col, float $pow = 1.0): float
	{
		return $this->sum(0, $col, $this->rowCount() - 1, $col, $pow);
	}

	/**
	 * Fetch an item from the DataFile.
	 *
	 * @param int $row The index of the row from which the value is sought.
	 * @param int $col The index of the column from which the value is sought.
	 *
	 * @return float The value. This will be NaN if the cell is empty.
	 * @throws \InvalidArgumentException if row or col is OOB
	 */
	public function item(int $row, int $col): float
	{
		if(0 > $row || $this->rowCount() <= $row) {
			throw new \InvalidArgumentException("row out of bounds");
		}

		if(0 > $col || $this->columnCount() <= $col) {
			throw new \InvalidArgumentException("column out of bounds");
		}

		return $this->m_data[$row][$col];
	}

	/**
	 * Helper to reload the data from the file.
	 * @return true on success, false on failure.
	 */
	private function reload(): bool
	{
		if (empty($this->m_file)) {
			fprintf(STDERR, "no file to read\n");
			return false;
		}

		if (!is_callable($this->m_parser)) {
			fprintf(STDERR, "the data file value parser is not callable\n");
			return false;
		}

		if (!is_readable($this->m_file)) {
			fprintf(STDERR, "the data file does not exist or is not readable\n");
			return false;
		}
		
		$in = fopen($this->m_file, "r");

		if (!$in) {
			fprintf(STDERR, "could not open file\n");
			return false;
		}

		$this->m_data = [];

		while (!feof($in)) {
			$this->m_data[] = array_map($this->m_parser, fgetcsv($in));
		}

		return true;
	}
}