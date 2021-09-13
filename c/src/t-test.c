#include <stdio.h>
#include "statistics/datafile.h"

void outputDataFile(FILE * outFile, const struct DataFile * data)
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

int main (int argc, char ** argv)
{
    if (1 == argc) {
        fprintf(stdout, "No data file provided.\n");
        return 1;
    }

    struct DataFile * data = newDataFile(argv[1]);
    outputDataFile(stdout, data);
    freeDataFile(&data);
    return 0;
}
