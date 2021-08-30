<?php

namespace unit\Statistics;

use Statistics\DataFile;
use PHPUnit\Framework\TestCase;

class DataFileTest extends TestCase
{
	/**
	 * Amount by which floating-point tests for equality are allowed to vary.
	 * 
	 * Testing floats for equality is prone to false failures because float representation is inherently imprecise. This
	 * is the maximum amount an actual float value is permitted to vary from its expected value in order to pass
	 * testing.
	 */
	const FloatEqualityDelta = 0.000001;

	/**
	 * The content of the test DataFile
	 * 
	 * A 12 x 2 data file.
	 */
	const TestData = [
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
	const TestDataRowCount = 12;
	const TestDataColumnCount = 2;

	// items (total, by-row and by-column
	const TestDataItemCount = 24;
	const TestDataRowItemCount = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,];
	const TestDataColumnItemCount = [12, 12,];

	// sums (total, by-row and by-column
	const TestDataSum = 338;
	const TestDataRowSum = [26, 26, 26, 29, 29, 27, 31, 31, 29, 28, 29, 27,];
	const TestDataColumnSum = [160, 178,];

	// means (total, by-row and by-column
	const TestDataArithmeticMean = 14.0833333;
	const TestDataRowArithmeticMean = [13, 13, 13, 14.5, 14.5, 13.5, 15.5, 15.5, 14.5, 14, 14.5, 13.5,];
	const TestDataColumnArithmeticMean = [13.33333333, 14.83333333,];

	// whether the data contains identical #s of items in each row/column
	const TestDataHasUniformRows = true;
	const TestDataHasUniformColumns = true;

	// if the data contains identical #s of items in each row/column, how many per row/column
	const TestDataUniformRowItemCount = 2;
	const TestDataUniformColumnItemCount = 12;

	/**
	 * The data file to use with all tests.
	 *
	 * @return \Statistics\DataFile
	 */
	public static function dataFile(): DataFile
	{
		static $dataFileContent = null;

		if (!isset($dataFileContent)) {
			// turn the array of values into a CSV string
			$dataFileContent = implode(
				"\n",
				array_map(
					function (array $row): string {
						return implode(
							",",
							array_map(
								function (float $value): string {
									return "{$value}";
								},
								$row
							)
						);
					},
					self::TestData
				)
			);
		}

		return new DataFile("data://text/plain,{$dataFileContent}");
	}

	/**
	 * @covers \Statistics\DataFile::rowCount
	 */
	public function testRowCount()
	{
		$dataFile = self::dataFile();
		$this->assertIsInt($dataFile->rowCount());
		$this->assertEquals(self::TestDataRowCount, $dataFile->rowCount());
	}

	/**
	 * @covers \Statistics\DataFile::columnCount
	 */
	public function testColumnCount()
	{
		$dataFile = self::dataFile();
		$this->assertIsInt($dataFile->columnCount());
		$this->assertEquals(self::TestDataColumnCount, $dataFile->columnCount());
	}

	/**
	 * @covers \Statistics\DataFile::itemCount
	 */
	public function testItemCount()
	{
		$dataFile = self::dataFile();
		$this->assertIsInt($dataFile->itemCount());
		$this->assertEquals(self::TestDataItemCount, $dataFile->itemCount());
	}

	/**
	 * @covers \Statistics\DataFile::rowItemCount
	 */
	public function testRowItemCount()
	{
		$dataFile = self::dataFile();
		
		for ($row = 0; $row < self::TestDataRowCount; ++$row) {
			$this->assertIsInt($dataFile->rowItemCount($row), "Item count for row {$row} is not an integer.");
			$this->assertEquals(self::TestDataRowItemCount[$row], $dataFile->rowItemCount($row), "Item count for row {$row} is expected to be " . self::TestDataRowItemCount[$row]);
		}

		if (self::TestDataHasUniformRows) {
			$this->assertIsInt($dataFile->rowItemCount());
			$this->assertEquals(self::TestDataUniformRowItemCount, $dataFile->rowItemCount());
		}
	}

	/**
	 * @covers \Statistics\DataFile::columnItemCount
	 */
	public function testColumnItemCount()
	{
		$dataFile = self::dataFile();
		
		for ($column = 0; $column < self::TestDataColumnCount; ++$column) {
			$this->assertIsInt($dataFile->columnItemCount($column), "Item count for column {$column} is not an integer.");
			$this->assertEquals(self::TestDataColumnItemCount[$column], $dataFile->columnItemCount($column), "Item count for column {$column} is expected to be " . self::TestDataColumnItemCount[$column]);
		}


		if (self::TestDataHasUniformColumns) {
			$this->assertIsInt($dataFile->columnItemCount());
			$this->assertEquals(self::TestDataUniformColumnItemCount, $dataFile->columnItemCount());
		}
	}

	/**
	 * @covers \Statistics\DataFile::sum
	 */
	public function testSum()
	{
		$dataFile = self::dataFile();
		$this->assertIsFloat($dataFile->sum());
		$this->assertEqualsWithDelta(self::TestDataSum, $dataFile->sum(), self::FloatEqualityDelta);
		$this->assertEqualsWithDelta(self::TestDataSum, array_sum(self::TestDataRowSum), self::FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected row sums do not agree");
		$this->assertEqualsWithDelta(self::TestDataSum, array_sum(self::TestDataColumnSum), self::FloatEqualityDelta, "ERROR IN TEST CODE: expected data file sum and expected COLUMN sums do not agree");
	}

	/**
	 * @covers \Statistics\DataFile::rowSum
	 */
	public function testRowSum()
	{
		$dataFile = self::dataFile();
		
		for ($row = 0; $row < self::TestDataRowCount; ++$row) {
			$this->assertIsFloat($dataFile->rowSum($row), "Sum for row {$row} is not a floating-point value.");
			$this->assertEqualsWithDelta(self::TestDataRowSum[$row], $dataFile->rowSum($row), self::FloatEqualityDelta, "Sum for row {$row} is expected to be " . self::TestDataRowSum[$row]);
		}
	}

	/**
	 * @covers \Statistics\DataFile::columnSum
	 */
	public function testColumnSum()
	{
		$dataFile = self::dataFile();

		for ($column = 0; $column < self::TestDataColumnCount; ++$column) {
			$this->assertIsFloat($dataFile->columnSum($column), "Sum for column {$column} is not a floating-point value.");
			$this->assertEqualsWithDelta(self::TestDataColumnSum[$column], $dataFile->columnSum($column), self::FloatEqualityDelta, "Sum for column {$column} is expected to be " . self::TestDataColumnSum[$column]);
		}
	}

	/**
	 * @covers \Statistics\DataFile::mean
	 */
	public function testMean()
	{
		$dataFile = self::dataFile();
		$this->assertIsFloat($dataFile->mean());
		$this->assertEqualsWithDelta(self::TestDataArithmeticMean, $dataFile->mean(), self::FloatEqualityDelta);
	}

	/**
	 * @covers \Statistics\DataFile::rowMean
	 */
	public function testRowMean()
	{
		$dataFile = self::dataFile();

		for ($row = 0; $row < self::TestDataRowCount; ++$row) {
			$this->assertIsFloat($dataFile->rowMean($row), "Mean for row {$row} is not a floating-point value.");
			$this->assertEqualsWithDelta(self::TestDataRowArithmeticMean[$row], $dataFile->rowMean($row), self::FloatEqualityDelta, "Mean for row {$row} is expected to be " . self::TestDataRowArithmeticMean[$row]);
		}
	}

	/**
	 * @covers \Statistics\DataFile::columnMean
	 */
	public function testColumnMean()
	{
		$dataFile = self::dataFile();

		for ($column = 0; $column < self::TestDataColumnCount; ++$column) {
			$this->assertIsFloat($dataFile->columnMean($column), "Mean for column {$column} is not a floating-point value.");
			$this->assertEqualsWithDelta(self::TestDataColumnArithmeticMean[$column], $dataFile->columnMean($column), self::FloatEqualityDelta, "Mean for column {$column} is expected to be " . self::TestDataColumnArithmeticMean[$column]);
		}
	}

	/**
	 * @covers \Statistics\DataFile::item
	 */
	public function testItem()
	{
		$dataFile = self::dataFile();

		for ($row = 0; $row < count(self::TestData); ++$row) {
			$this->assertLessThan($dataFile->rowCount(), $row, "missing row {$row} in data file");

			for ($column = 0; $column < count(self::TestData[$row]); ++$column) {
				$this->assertLessThan($dataFile->columnCount(), $column, "missing column in data file");
				$this->assertIsFloat($dataFile->item($row, $column), "Item at R{$row}, C{$column} is expected to be a floating-point value.");
				$this->assertEqualsWithDelta(self::TestData[$row][$column], $dataFile->item($row, $column), self::FloatEqualityDelta, "Item at R{$row}, C{$column} is expected to be " . self::TestData[$row][$column]);
			}
		}
	}
}
