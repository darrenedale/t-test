using System;
using System.IO;

namespace Statistics
{
    using System;

    class TTestProgram
    {
        const TTestType DefaultTestType = TTestType.Unpaired;

        const int ExitOk = 0;
        const int ExitErrInvalidArgs = 1;
        const int ExitErrUnrecognisedTestType = 2;

        static int Main(string[] args)
        {
            string dataFilePath = null;
            TTestType type = DefaultTestType;

            for (int i = 0; i < args.Length; ++i) {
                if("-t" == args[i]) {
                    ++i;

                    if (i >= args.Length) {
                        Console.Error.WriteLine("ERR -t must be supplied with the type of test");
                        return ExitErrInvalidArgs;
                    }

                    string arg = args[i].ToLower();

                    if("paired" == arg) {
                        type = TTestType.Paired;
                    }
                    else if("unpaired" == arg) {
                        type = TTestType.Unpaired;
                    }
                    else {
                        Console.Error.WriteLine($"ERR unrecognised test type \"{arg}\"");
                        return ExitErrUnrecognisedTestType;
                    }
                }
                else {
                    /* first unrecognised arg is data file path */
                    dataFilePath = args[i];
                    break;
                }
            }

            if (null == dataFilePath) {
                Console.Error.WriteLine("ERR no data file specified");
                return ExitErrInvalidArgs;
            }

            DataFile data = new DataFile(dataFilePath);
            writeData(data, Console.Out);

            TTest tTest = new TTest(data, type);
            Console.WriteLine($"t = {tTest.t}");
            return ExitOk;
        }

        static void writeData(DataFile data, TextWriter outWriter)
        {
            for(int r = 0; r < data.rowCount; ++r) {
                for(int c = 0; c < data.columnCount; ++c) {
                    double dataItem = data.item(r, c);

                    if (Double.IsNaN(dataItem)) {
                        outWriter.Write("      ");
                    }
                    else {
                        outWriter.Write(data.item(r, c));
                        outWriter.Write("  ");
                    }
                }

                outWriter.WriteLine();
            }
        }
    }
}
