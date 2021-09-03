<?php

/**
 * Requires PHP 8.0 or later.
 */

declare(strict_types=1);

include __DIR__ . "/autoload.php";

use Statistics\DataFile;
use Statistics\TTest;

/**
 * Program exit codes.
 */
const ExitErrMissingTestType = 1;
const ExitErrUnrecognisedTestType = 2;
const ExitErrNoDataFile = 3;
const ExitErrEmptyDataFile = 4;

/**
 * Options for for -t command-line arg.
 */
const PairedTestTypeArg = "paired";
const UnpairedTestTypeArg = "unpaired";


/**
 * Parse the test type provided on the command line to a TestType constant.
 *
 * @param string type The string to parse.
 *
 * @return int The test type, or null if the string is invalid.
 */
function parseTestType(string $type): ?int
{
	return match ($type) {
		PairedTestTypeArg => TTest::PairedTestType,
		UnpairedTestTypeArg => TTest::UnpairedTestType,
		default => null
	};
}

/**
 * Write a DataFile to an output stream.
 *
 * @param resource $out The output stream to write to.
 * @param DataFile $data The DataFile to write.
 */
function outputDataFile($out, DataFile $data)
{
	for ($row = 0; $row < $data->rowCount(); ++$row) {
		for ($column = 0; $column < $data->columnCount(); ++$column) {
			$value = $data->item($row, $column);

			if (is_nan($value)) {
				fprintf($out, "      ");
			} else {
				fprintf($out, "%0.3f  ", $value);
			}
		}

		fprintf($out, "\n");
	}
}

/**
 * Entry point.
 *
 * As always, the first argv is the binary. Other possible args are:
 * - -t specifies the type of test. Follow it with "paired" or "unpaired".
 * - The first arg not recognised as an option is considered the name of the data file.
 *
 * @param int $argc Number of command-line args.
 * @param string[] $argv Command-line args array, all null-terminated c strings.
 */
$type = TTest::UnpairedTestType;

// read command-line args
if (1 < $argc) {
	for ($i = 1; $i < $argc; ++$i) {
		$arg = $argv[$i];

		if ("-t" == $arg) {
			++$i;

			if ($i >= $argc) {
				fprintf(STDERR, "ERR -t option requires a type of test - paired or unpaired\n");
				return ExitErrMissingTestType;
			}

			$parsedType = parseTestType($argv[$i]);

			if (!isset($parsedType)) {
				fprintf(STDERR, "ERR unrecognised test type \"%s\"\n", $argv[$i]);
				return ExitErrUnrecognisedTestType;
			}

			$type = $parsedType;
		} else {
			// first unrecognised arg is data file path
			$dataFilePath = $arg;
			break;
		}
	}
}

if (!isset($dataFilePath)) {
	fprintf(STDERR, "No data file provided.\n");
	return ExitErrNoDataFile;
}

// read and output the data
$data = new DataFile($dataFilePath);

if ($data->isEmpty()) {
	fprintf(STDERR, "No data in data file (or data file does not exist or could not be opened).\n");
	return ExitErrEmptyDataFile;
}

outputDataFile(STDOUT, $data);

// output the calculated statistic
echo "t = ";
printf("%0.6f\n", (new TTest($data, $type))->t());
