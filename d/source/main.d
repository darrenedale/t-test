module ttest;

import statistics.data : DataFile;
import statistics.tests : TTest;
import std.stdio : stdout, stderr, File;
import std.typecons : Nullable;
import std.uni : toLower;

/**
 * Program exit codes.
 */
const ExitOk = 0;
const ExitErrMissingTestType = 1;
const ExitErrUnrecognisedTestType = 2;
const ExitErrNoDataFile = 3;
const ExitErrEmptyDataFile = 4;

Nullable!(TTest.Type) parseTestType(string type)
{
	switch (type.toLower()) {
		case "paired":
			return Nullable!(TTest.Type)(TTest.Type.Paired);

		case "unpaired":
			return Nullable!(TTest.Type)(TTest.Type.Unpaired);
			
		default:
			return Nullable!(TTest.Type).init;
	}
	
	assert(0);
}

/**
 * Write a DataFile to an output stream.
 *
 * @param File outFile The output stream to write to.
 * @param DataFile data The DataFile to write.
 */
void outputDataFile(T)(ref File outFile, DataFile!T data)
{
	foreach(r; 0 .. data.rowCount()) {
		foreach(c; 0 .. data.columnCount()) {
			outFile.writef("%0.3f  ", data.item(r, c));
		}

		outFile.writeln("");
	}
}

/**
 * Entry point.
 *
 * As always, the first arg is the binary. Other possible args are:
 * - -t specifies the type of test. Follow it with "paired" or "unpaired".
 * - The first arg not recognised as an option is considered the name of the data file.
 *
 * Params:
 *    string[] args Command-line args array.
 */
int main(string[] args)
{
	TTest.Type type = TTest.Type.Unpaired;
	string dataFilePath = "";

	argLoop: for(ulong i = 1; i < args.length; ++i) {
		switch (args[i]) {
			case "-t":
				++i;

				if (i >= args.length) {
					stderr.writeln("ERR -t option requires a type of test - paired or unpaired");
					return ExitErrMissingTestType;
				}
				
				auto typeArg = parseTestType(args[i]);
				
				if (typeArg.isNull()) {
					stderr.writefln("ERR unrecognised test type \"%s\"", args[i]);
					return ExitErrUnrecognisedTestType;
				}
				
				type = typeArg.get();
				break;
				
			default:
				// first unrecognised arg is data file
				dataFilePath = args[i];
				break argLoop;
		}
	}

	if (0 == dataFilePath.length) {
		stderr.writeln("No data file provided.");
		return ExitErrNoDataFile;
	}
	
	auto data = new TTest.DataFileType(dataFilePath);
	
	if (data.isEmpty()) {
		stderr.writeln("No data in data file (or data file does not exist or could not be opened).");
		return ExitErrEmptyDataFile;
	}
	
	outputDataFile(stdout, data);
	auto t = new TTest(data, type);
	stdout.writefln("%s = %f", "t", t.t());
	return ExitOk;
}
