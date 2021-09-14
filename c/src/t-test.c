#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "statistics/datafile.h"
#include "statistics/ttest.h"
#include "util.h"

typedef struct parse_test_type_result_t{
    TTestType type;
    bool isValid;
} ParseTestTypeResult;

ParseTestTypeResult parseTestType(const char * type)
{
    if (0 == strcasecmp(type, "paired")) {
        return (ParseTestTypeResult) {PairedT, true};
    }
    
    if (0 == strcasecmp(type, "unpaired")) {
        return (ParseTestTypeResult) {UnpairedT, true};
    }

    return (ParseTestTypeResult) {0, false};
}

void outputDataFile(FILE * outFile, const DataFile * data)
{
    int rowCount = dataFileRowCount(data);
    int colCount = dataFileColumnCount(data);

    for (int row = 0; row < rowCount; ++row) {
        for (int col = 0; col < colCount; ++col) {
            fprintf(outFile, "%0.3f  ", dataFileItem(data, row, col));
        }

        fputc('\n', outFile);
    }
}

static const int ExitOk = 0;
static const int ExitErrMissingTestType = 1;
static const int ExitErrInvalidTestType = 2;
static const int ExitErrNoDatafile = 3;

int main (int argc, char ** argv)
{
    TTestType type = PairedT;
    char * dataFileName = (char *) 0;

    for (int argIndex = 1; argIndex < argc; ++argIndex) {
        if (0 == strcmp("-t", argv[argIndex])) {
            ++argIndex;

            if (argIndex >= argc) {
                fprintf(stderr, "ERR -t requires a test type - paired or unpaired\n");
                return ExitErrMissingTestType;
            }

            ParseTestTypeResult parsedType = parseTestType(argv[argIndex]);

            if (!parsedType.isValid) {
                fprintf(stderr, "ERR test type '%s' is not recognised\n", argv[argIndex]);
                return ExitErrInvalidTestType;
            }

            type = parsedType.type;
        } else {
            dataFileName = argv[argIndex];
            break;
        }
    }

    if (!dataFileName) {
        fprintf(stderr, "ERR No data file provided.\n");
        return ExitErrNoDatafile;
    }

    DataFile * data = newDataFile(dataFileName);
    outputDataFile(stdout, data);
    TTest tTest = {
        type,
        data
    };
    fprintf(stdout, "t = %0.6f\n", tTestT(&tTest));
    freeDataFile(&data);
    return ExitOk;
}
