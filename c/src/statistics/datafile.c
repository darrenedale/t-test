#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include <ctype.h>
#include <math.h>
#include "datafile.h"

bool reloadDataFile(struct DataFile *, const char *);
void resetDataFile(struct DataFile *);

struct DataFile * newDataFile(const char * fileName)
{
    struct DataFile * dataFile = (struct DataFile *) malloc(sizeof(struct DataFile));
    dataFile->data = (void *) 0;
    dataFile->rowCount = 0;
    dataFile->columnCounts = (void *) 0;

    if (fileName) {
        reloadDataFile(dataFile, fileName);
    }

    return dataFile;
}

void freeDataFile(struct DataFile ** dataFile)
{
    resetDataFile(*dataFile);
    free(*dataFile);
    *dataFile = (void *) 0;
}

int dataFileRowCount(const struct DataFile * dataFile)
{
    return dataFile->rowCount;
}

int dataFileColumnCount(const struct DataFile * dataFile)
{
    if (!dataFile->columnCounts) {
        return 0;
    }

    return dataFile->columnCounts[0];
}

int dataFileRowColumnCount(const struct DataFile * dataFile, int row)
{
    assert(0 < row && dataFile->rowCount > row);
    return dataFile->columnCounts[row];
}

double dataFileItem(const struct DataFile * dataFile, int row, int column)
{
    assert(0 <= row && row < dataFile->rowCount);
    assert(0 <= column && column < dataFileColumnCount(dataFile));
    return dataFile->data[row][column];
}

/*
 * Private functions.
 */

void resetDataFile(struct DataFile * dataFile)
{
    if (dataFile->data) {
        for (int row = 0; row < dataFile->rowCount; ++row) {
            free(dataFile->data[row]);
            dataFile->data[row] = (void *) 0;
        }

        free(dataFile->data);
        dataFile->data = (void *) 0;
    }

    if (dataFile->columnCounts) {
        free(dataFile->columnCounts);
        dataFile->columnCounts = (void *) 0;
    }

    dataFile->rowCount = 0;
}

void parseLineIntoDataFile(struct DataFile * dataFile, char * line)
{
    int col = 0;

    if (!dataFile->data) {
        dataFile->data = (double **) malloc(sizeof(double *));
    } else {
        dataFile->data = (double **) realloc(dataFile->data, (dataFile->rowCount + 1) * sizeof(double *));
    }

    int capacity = 10;
    dataFile->data[dataFile->rowCount] = malloc(sizeof(double) * capacity);
    char * start = line;
    char * end;

    while (*start) {
        end = start;

        while (*end && ',' != *end) {
            ++end;
        }

        char delimiter = *end;
        char * firstUnparsed;
        *end = 0;
        double value = strtod(start, &firstUnparsed);

        // check whether the parsed value consumed all the non-whitespace in the cell
        while (*firstUnparsed) {
            if (!isspace(*firstUnparsed)) {
                // invalid value
                value = NAN;
                break;
            }

            ++firstUnparsed;
        }

        if (col == capacity) {
            capacity *= 1.5;
            dataFile->data[dataFile->rowCount] = realloc(dataFile->data[dataFile->rowCount], sizeof(double) * capacity);
        }

        dataFile->data[dataFile->rowCount][col] = value;
        ++col;

        if (!delimiter) {
            // EOL - exit parse loop
            break;
        }

        start = end + 1;
    }

    // add the column count for the row
    if (!dataFile->columnCounts) {
        dataFile->columnCounts = (int *) malloc(sizeof(int));
    } else {
        dataFile->columnCounts = (int *) realloc(dataFile->columnCounts, (dataFile->rowCount + 1) * sizeof(int));
    }

    dataFile->columnCounts[dataFile->rowCount] = col;
    ++dataFile->rowCount;
}

bool reloadDataFile(struct DataFile * dataFile, const char * fileName)
{
    resetDataFile(dataFile);
    FILE * inFile = fopen(fileName, "r");

    if (!inFile) {
        return false;
    }

    {
        int bufferSize = 1024;
        char * buffer = (char *) malloc(bufferSize);
        char * eol = buffer;

        while (!feof(inFile)) {
            if (eol == buffer + bufferSize) {
                // reallocate buffer
                int previousBufferSize = bufferSize;
                bufferSize *= 1.5;
                buffer = realloc(buffer, bufferSize);
                eol = buffer + previousBufferSize;
            }

            *eol = (char) fgetc(inFile);

            if (EOF == *eol || 10 == *eol) {
                // found a line
                *eol = 0;
                parseLineIntoDataFile(dataFile, buffer);
                eol = buffer;
            } else {
                ++eol;
            }
        }

        free (buffer);
    }

    fclose(inFile);
    return true;
}
