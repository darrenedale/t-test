#include <iostream>
#include <iomanip>
#include <string>
#include <cctype>
#include <functional>
#include <algorithm>
#include <optional>

#include "TTest.h"

using namespace Statistics;

namespace
{
    /**
     * Program exit codes.
     */
    constexpr const int ExitOk = 0;
    constexpr const int ExitErrMissingTestType = 1;
    constexpr const int ExitErrUnrecognisedTestType = 2;
    constexpr const int ExitErrNoDataFile = 3;
    constexpr const int ExitErrEmptyDataFile = 4;

    /**
     * Options for for -t command-line arg.
     */
    constexpr const char * PairedTestTypeArg = "paired";
    constexpr const char * UnpairedTestTypeArg = "unpaired";

    /**
     * Get a lower-case version of a string.
     *
     * @param str The string to convert.
     *
     * @return The lower-case equivalent of the provided string.
     */
    inline std::string toLower(const std::string_view & str)
    {
        std::string ret;
        std::transform(str.cbegin(), str.cend(), std::back_inserter(ret), [](const auto & ch) -> auto {
            return static_cast<std::string_view::value_type>(std::tolower(ch));
        });

        return ret;
    }

    /**
     * Parse the test type provided on the command line to a TestType.
     *
     * @param type The string to parse.
     *
     * @return The test type, or an empty optional if the string is invalid.
     */
    std::optional<TTestType> parseTestType(const std::string_view & type)
    {
        const auto lowerType = toLower(type);

        if (PairedTestTypeArg == lowerType) {
            return TTestType::Paired;
        } else if(UnpairedTestTypeArg == lowerType) {
            return TTestType::Unpaired;
        }

        return {};
    }

    /**
     * Write a DataFile to an output stream.
     *
     * @tparam T The (inferred) value type for the data file.
     * @param out The output stream to write to.
     * @param data The DataFile to write.
     * @return The output stream.
     */
    template<class ValueType>
    std::ostream & operator<<(std::ostream & out, const DataFile<ValueType> & data)
    {
        out << std::dec << std::fixed << std::left << std::setfill(' ') << std::setprecision(3);

        for (int row = 0; row < data.rowCount(); ++row) {
            for (int column = 0; column < data.columnCount(); ++column) {
                try {
                    out << data.item(row, column) << "  ";
                } catch (const std::invalid_argument & e) {
                    out << "      ";
                }
            }

            out << "\n";
        }

        return out;
    }
}

/**
 * Entry point.
 * 
 * As always, the first argv is the binary. Other possible args are:
 * - -t specifies the type of test. Follow it with "paired" or "unpaired".
 * - The first arg not recognised as an option is considered the name of the data file.
 *
 * @param argc Number of command-line args.
 * @param argv Command-line args array, all null-terminated c strings.
 */
int main(int argc, char ** argv)
{
	auto type = TTestType::Unpaired;
	std::optional<std::string> dataFilePath;

    // read command-line args
	if (1 < argc) {
		for (int i = 1; i < argc; ++i) {
			std::string_view arg(argv[i]);

			if ("-t" == arg) {
				++i;

				if (i >= argc) {
					std::cerr << "ERR -t option requires a type of test - paired or unpaired\n";
					return ExitErrMissingTestType;
				}

				auto parsedType = parseTestType(argv[i]);

                if (!parsedType) {
					std::cerr << "ERR unrecognised test type \"" << argv[i] << "\"\n";
					return ExitErrUnrecognisedTestType;
				}

				type = *parsedType;
			} else {
				// first unrecognised arg is data file path
				dataFilePath = arg;
				break;
			}
		}
	}

	if (!dataFilePath) {
		std::cerr << "No data file provided.\n";
		return ExitErrNoDataFile;
	}

	// read and output the data
	auto data = TTest::DataFileType(*dataFilePath);
	
	if (data.isEmpty()) {
		std::cerr << "No data in data file (or data file does not exist or could not be opened).\n";
		return ExitErrEmptyDataFile;
	}
	
	std::cout << std::dec << std::fixed << std::left << std::setfill(' ') << std::setprecision(3) << data;

	// output the calculated statistic - note we don't need the data any longer so we move it into the temporary test object
	std::cout << "t = " << std::setprecision(6) << TTest(std::move(data), type).t() << "\n";
	return ExitOk;
}
