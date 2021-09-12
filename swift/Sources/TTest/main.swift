import Foundation;

// Exit code for when -t has been specified without a test type.
let ExitErrMissingTestType: Int32 = 1;

// Exit code for when -t has been specified with an unrecognised test type.
let ExitErrUnrecognisedTestType: Int32 = 2;

// Exit code for when no datafile has been provided on the command line..
let ExitErrNoDataFile: Int32 = 3;

func parseTestType(_ type: String) -> TTest.TestType?
{
    switch (type.lowercased()) {
        case "paired":
            return TTest.TestType.Paired;

        case "unpaired":
            return TTest.TestType.Unpaired;

        default:
            return nil;
    }
}

func outputDataFile<ValueType>(_ data: DataFile<ValueType>)
{
    for row in (0 ..< data.rowCount) {
        for col in (0 ..< data.columnCount) {
            print(String(format: "%0.3f  ", Double(data.item(row: row, column: col))), terminator: "");
        }

        print("");
    }
}

var testType = TTest.TestType.Unpaired;
var dataFilePath: String? = nil;
var argIdx = 1;

argTraversalLoop: while argIdx < CommandLine.arguments.count {
    switch (CommandLine.arguments[argIdx]) {
        case "-t":
            argIdx += 1;

            if (CommandLine.arguments.count <= argIdx) {
                print("ERR -t option requires a type of test - paired or unpaired");
                exit(ExitErrMissingTestType);
            }

            let parsedTestType = parseTestType(CommandLine.arguments[argIdx]);

            if (nil == parsedTestType) {
                print("ERR unrecognised test type \"\(CommandLine.arguments[argIdx])\"");
                exit(ExitErrUnrecognisedTestType);
            }

            testType = parsedTestType!;
 
        default:
            dataFilePath = CommandLine.arguments[argIdx];
            break argTraversalLoop;
    }

    argIdx += 1;
}

// no data file, no t-ttest
if (nil == dataFilePath) {
    print("No data file provided.");
    // TODO exit with appropriate exit code
    exit(ExitErrNoDataFile)
}

let data = DataFile<TTest.ValueType>(fromFile: dataFilePath);
outputDataFile(data);
print(String(format: "t = %0.6f", (TTest(withData: data, ofType: testType)).t));
