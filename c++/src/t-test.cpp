#include <iostream>
#include <iomanip>
#include <string>
#include <cctype>
#include <functional>
#include <algorithm>

#include "TTest.h"
#include "DataFile.h"

using namespace Statistics;

/**
 * Convert a string to lower case, in-place.
 *
 * After the function returns, the string will be all lower-case.
 *
 * @note This should be a tad quicker than std::transform() because it requires fewer args passed to for_each and only transforms the char if necessary.
 * TODO put this in a namespace.
 *
 * @param str The string to convert.
 */
void toLower( std::string & str )
{
	std::for_each(str.begin(), str.end(), [] (char & c) {
        if(std::isupper(c)) {
            c = static_cast<char>(std::tolower(c));
        }
    });
}

/**
 * Entry point.
 * 
 * As always, the first argv is the binary. Other args are:
 * - -t specifies the type of test. Follow it with "paried" or "unpaired".
 * - The first arg not recognised as an option is considered the name of the data file.
 *
 * TODO error constants not numeric literals.
 *
 * @param argc Number of command-line args.
 * @param argv Command-line args array, all null-terminated c strings.
 */
int main(int argc, char ** argv)
{
    using TTest::TestType;
	auto type = TestType::Unpaired;
	std::string dataFilePath;

    // read command-line args
	if(1 < argc) {
		for(int i = 1; i < argc; ++i) {
			std::string arg(argv[i]);
			toLower(arg);

			if("-t" == arg) {
				++i;
				arg = argv[i];
				toLower(arg);

				if("paired" == arg) {
					type = TestType::Paired;
				}
				else if("unpaired" == arg) {
					type = TestType::Unpaired;
				}
				else {
					std::cerr << "ERR unrecognised test type \"" << arg << "\"" << std::endl;
                    return 1;
				}
			}
			else {
				// first unrecognised arg is data file path
				dataFilePath = arg;
				break;
			}
		}
	}

	if (dataFilePath.empty()) {
      std::cerr << "No data file provided.\n";
      return 2;
    }

    // read the data
	auto data = TTest::DataFileType(dataFilePath);
	std::cout << std::dec << std::fixed << std::left << std::setfill(' ') << std::setprecision(3);

    // output the table of data
	for(int r = 0; r < data.rowCount(); ++r) {
		for(int c = 0; c < data.columnCount(); ++c) {
			try {
				std::cout << data.item(r, c) << "  ";
			}
			catch (const std::invalid_argument & e) {
				std::cout << "      ";
			} catch (const std::exception & e) {
              std::cerr << "Unexpected exception retrieving data item: " << e.what() << "\n";
              return 2;
            }
		}

		std::cout << "\n";
	}

    // output the calculated statistic - note we don't need the data any more so we move it into the temporary test object
	std::cout << "t = " << std::setprecision(6) << TTest::TTest(std::move(data), type).t() << std::endl;
	return 0;
}
