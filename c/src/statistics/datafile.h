#ifndef STATISTICS_DATAFILE_H
#define STATISTICS_DATAFILE_H

#include <stdlib.h>
#include <stdbool.h>

typedef struct datafile_t
{
    double ** data;
    int rowCount;
    int * columnCounts;
} DataFile;

/**
 * Create a new DataFile and load the data from a CSV file.
 */
DataFile * newDataFile(const char * fileName);

/**
 * Dispose of a DataFile.
 */
void freeDataFile(DataFile ** dataFile);

bool dataFileIsEmpty(const DataFile * dataFile);

/**
 * Get the count of the rows in a DataFile.
 */
int dataFileRowCount(const DataFile * dataFile);

/**
 * Get the count of the columns in a DataFile.
 *
 * This function naively assumes that the first row in the data file contains data for all columns.
 */
int dataFileColumnCount(const DataFile * dataFile);

int dataFileItemCount(const DataFile * dataFile);

/**
 * Fetch the number of items for a specific row in the DataFile.
 *
 * The row index must be valid - it will not be bounds checked.
 *
 * @param row The row whose items are to be counted.
 *
 * @return the count.
 */
int dataFileRowItemCount(const DataFile * dataFile, int row);

int dataFileColumnItemCount(const DataFile * dataFile, int column);
double dataFileSum(const DataFile * dataFile, double power);
double dataFileRowSum(const DataFile * dataFile, int row, double power);
double dataFileColumnSum(const DataFile * dataFile, int column, double power);
double dataFileMean(const DataFile * dataFile, double meanNumber);
double dataFileRowMean(const DataFile * dataFile, int row, double meanNumber);
double dataFileColumnMean(const DataFile * dataFile, int column, double meanNumber);

double dataFileItem(const DataFile *, int row, int column);

#endif
