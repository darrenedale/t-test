#include <stdlib.h>

struct DataFile
{
    double ** data;
    int rowCount;
    int * columnCounts;
};

/**
 * Create a new DataFile and load the data from a CSV file.
 */
struct DataFile * newDataFile(const char * fileName);

/**
 * Dispose of a DataFile.
 */
void freeDataFile(struct DataFile ** dataFile);

/**
 * Get the count of the rows in a DataFile.
 */
int dataFileRowCount(const struct DataFile * dataFile);

/**
 * Get the count of the columns in a DataFile.
 *
 * This function naively assumes that the first row in the data file contains data for all columns.
 */
int dataFileColumnCount(const struct DataFile * dataFile);

/**
 * Fetch the number of columns for a specific row in the DataFile.
 *
 * The row index must be valid - it will not be bounds checked.
 *
 * @param row The row whose columns are to be counted.
 *
 * @return the count.
 */
int dataFileRowColumnCount(const struct DataFile * dataFile, int row);

double dataFileItem(const struct DataFile *, int row, int column);
