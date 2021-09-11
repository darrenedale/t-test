#! /usr/bin/ruby

##
# Main module for the t-test program.
module TTestProgram
    ##
    # Exit code for when -t has been specified without a test type.
    ExitErrMissingTestType = 1;

    ##
    # Exit code for when -t has been specified with an unrecognised test type.
    ExitErrUnrecognisedTestType = 2;

    ##
    # Exit code for when no datafile has been provided on the command line..
    ExitErrNoDataFile = 3;

    ##
    # Parse the test type provided on the command line to a symbol.
    #
    # [Params]
    # - +type+ +String+ The string to parse.
    #
    # [Return]
    # +Symbol+ The test type symbol, or +nil+ if the string is not a valid test type.
    def self.parseTestType(type)
        if !type.instance_of?(String)
            raise "Invalid argument - type must be a string"
        end

        case type.downcase()
        when "paired"
            return :PairedTTest;
        when "unpaired"
            return :UnpairedTTest;
        else
            return nil;
        end
    end

    ##
    # Write a DataFile to an output stream.
    #
    # [Params]
    # - +outStream+ +IO+ The output stream to write to.
    # - +data+ +DataFile+ The DataFile to write.
    def self.outputDataFile(outStream, data)
        if !outStream.instance_of?(IO)
            raise "Invalid argument - outStream must be an IO"
        end

        if !data.instance_of?(DataFile)
            raise "Invalid argument - data must be a DataFile"
        end

        (0 .. data.rowCount - 1).each {
            |row|
            (col = 0 .. data.columnCount - 1).each {
                |col|
                print("%0.3f  " % data.item(row: row, col: col));
            }
        
            puts();
        }
    end

    require_relative "Statistics/DataFile";
    require_relative "Statistics/TTest";

    # Entry point
    testType = :UnpairedTTest;
    dataFilePath = nil;

    # read command-line args
    idx = 0;

    while idx < ARGV.length
        case ARGV[idx]
        when "-t"
            idx += 1;

            if idx >= ARGV.length
                STDERR.puts("ERR -t option requires a type of test - paired or unpaired");
                exit(ExitErrMissingTestType);
            end

            testType = parseTestType(ARGV[idx]);

            if (!testType)
                STDERR.puts("ERR unrecognised test type \"#{ARGV[idx]}\"");
                exit(ExitErrUnrecognisedTestType);
            end
        else
            dataFilePath = ARGV[idx];
            break;
        end

        idx += 1;
    end

    # no data file, no t-ttest
    if !dataFilePath
        STDERR.puts("No data file provided.");
        exit(ExitErrNoDataFile);
    end

    data = DataFile.new(dataFilePath);
    outputDataFile(STDOUT, data);
    printf("t = %0.6f\n", (TTest.new(data, testType)).t);
end