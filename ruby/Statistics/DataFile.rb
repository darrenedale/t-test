module Statistics
    ## A data file for use with a statistical test.
    class DataFile
        ## Initialise a new data file.
        ##
        ## The CSV parser is very simple. It loads successive lines from the provided file and splits it at each comma (,). Each element in the resulting
        ## array of strings is parsed as a Float. If this fails, the value for that cell is considered missing (Float::NAN); otherwise, the parsed value
        ## is used for the cell.
        ##
        ## The parser is a value that can be called with a string and will result in a Float value. It will be called for each string item read from the
        ## CSV file to parse it into a value to store in the data. The default implementation checks whether the string is a valid representation of a
        ## decimal floating point value and calls to_f() if it is, or returns Float::NAN if it's not.
        ##
        ## @param path The path to a local CSV file to load.
        ## @param parser A custom parser to read values from items in the CSV file.
        def initialize(fileName, parser = lambda{
            |str|
            if str.match(/^\s*[+-]?[0-9]+(?:\.[0-9]+)?\s*$/)
                return str.to_f();
            else
                return Float::NAN;
            end
        })
            if String != fileName.class
                raise "fileName must be a String";
            end

            @file = fileName;
            @data = [];
            @parser = parser;
            reload()
        end

        ## The number of rows in the DataFile.
        ##
        ## @return The row count.
        def rowCount
            return @data.length
        end

        ## The number of columns in the DataFile.
        ##
        ## Currently the count naively assumes the first row contains all the columns that exist in the data.
        ##
        ## @return The column count.
        def columnCount
            if 0 == @data.length
                return 0
            end

            return @data[0].length
        end
        
        ## Check whether the data file contains any data.
        ## 
        ## @return true if the data file contains zero rows, false otherwise.
        def isEmpty?
            return 0 == rowCount
        end

        ## Count the number of values in the DataFile.
        ##
        ## @return The number of values.
        def itemCount
            if isEmpty?
                return 0;
            end
            
            return rangeItemCount(0, 0, rowCount - 1, columnCount - 1);
        end

        ## Count the number of values in a row in the DataFile.
        ##
        ## @param row The row to count. Defaults to 0 so that it can be called without a row index when it is known that all rows contain an identical
        ## number of items.
        ##
        ## @return The number of values.
        def rowItemCount(row = 0)
            if isEmpty?
                return 0;
            end

            if  0 > row || rowCount <= row
                raise "row out of bounds";
            end

            rangeItemCount(row, 0, row, columnCount - 1);
        end

        ## Count the number of values in a column in the DataFile.
        ##
        ## @param col The column to count. Defaults to 0 so that it can be called without a column index when it is known that all columns contain an
        ## identical number of items.
        ##
        ## @return The number of values.
        def columnItemCount(col)
            if isEmpty?
                return 0;
            end

            if  0 > col || columnCount <= col
                raise "column out of bounds";
            end

            return rangeItemCount(0, col, rowCount - 1, col);
        end

        ## Calculate the sum of the values in the DataFile.
        ##
        ## @return The sum.
        def sum(pow = 1.0)
            if isEmpty?
                return 0.0;
            end
            
            return rangeSum(0, 0, rowCount - 1, columnCount - 1, pow);
        end

        ## Calculate the sum of the values in a row in the DataFile.
        ##
        ## @return The sum.
        def rowSum(row, pow = 1.0)
            if  0 > row || rowCount <= row
                raise "row out of bounds";
            end

            if isEmpty?
                return 0.0;
            end

            rangeSum(row, 0, row, columnCount - 1, pow);
        end

        ## Calculate the sum of the values in a column in the DataFile.
        ##
        ## @return The sum.
        def columnSum(col, pow = 1.0)
            if  0 > col || columnCount <= col
                raise "column out of bounds";
            end

            if isEmpty?
                return 0.0;
            end

            return rangeSum(0, col, rowCount - 1, col, pow);
        end

        ## Calculate the mean of the values in the DataFile.
        ##
        ## @return The mean.
        def mean(meanNumber = 1.0)
            if isEmpty?
                return 0.0;
            end
            
            return rangeMean(0, 0, rowCount - 1, columnCount - 1, meanNumber);
        end

        ## Calculate the mean of the values in a row in the DataFile.
        ##
        ## @return The mean.
        def rowMean(row, meanNumber = 1.0)
            if  0 > row || rowCount <= row
                raise "row out of bounds";
            end

            if isEmpty?
                return 0.0;
            end

            rangeMean(row, 0, row, columnCount - 1, meanNumber);
        end

        ## Calculate the mean of the values in a column in the DataFile.
        ##
        ## @return The mean.
        def columnMean(col, meanNumber = 1.0)
            if  0 > col || columnCount <= col
                raise "column out of bounds";
            end

            if isEmpty?
                return 0.0;
            end

            return rangeMean(0, col, rowCount - 1, col, meanNumber);
        end

        ## Fetch an item from the DataFile.
        ##
        ## @param row The index of the row from which the value is sought. Named parameter.
        ## @param col The index of the column from which the value is sought. Named parameter.
        ##
        ## @return The value. This will be Float::NAN if the cell is empty. 
        def item(row:, col:)
            if 0 > row || rowCount <= row
                raise "row out of bounds";
            end

            if 0 > col || columnCount <= col
                raise "column out of bounds";
            end

            return @data[row][col];
        end

        protected

        ## The parser for values read from the CSV file
        def parser
            return @parser;
        end

        ## Count the number of items in a given range in the data file.
        ##
        ## Note that some cells in the data file can be empty, so the count is not simply the product of the range dimensions.
        ##
        ## @param r1 The topmost row to include in the count.
        ## @param c1 The leftmost column to include in the count.
        ## @param r2 The bottom-most row to include in the count.
        ## @param c2 The rightmost column to include in the count.
        ##
        ## @return The number of data items in the range.
        def rangeItemCount(r1, c1, r2, c2)
            count = 0;

            (r1 .. r2).each {
                |row|
                (c1 .. c2).each {
                    |col|

                    if !item(row: row, col: col).nan?
                        count += 1;
                    end
                }
            }

            return count;
        end

        ## Sum the items in a given range.
        ##
        ## @param r1 The topmost row to include in the sum.
        ## @param c1 The leftmost column to include in the sum.
        ## @param r2 The bottom-most row to include in the sum.
        ## @param c2 The rightmost column to include in the sum.
        ## @param pow An optional power to which to raise each value before it is added to the sum.
        ##
        ## @return The mean of the values in the range.
        def rangeSum(r1, c1, r2, c2, pow = 1.0)
            sum = 0.0;

            (r1 .. r2).each {
                |row|
                (c1 .. c2).each {
                    |col|
                    value = item(row: row, col: col);

                    if !value.nan?
                        sum += (value ** pow);
                    end
                }
            }

            return sum;
        end

        ## Calculate the mean of the items in a given range.
        ##
        ## The arithmetic mean, which is often referred to as the average, is meanNumber 1; the quadratic is 2; the geometric is -1.
        ##
        ## @param r1 The topmost row to include in the mean.
        ## @param c1 The leftmost column to include in the mean.
        ## @param r2 The bottom-most row to include in the mean.
        ## @param c2 The rightmost column to include in the mean.
        ## @param meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
        ##
        ## @return The mean of the values in the range.
        def rangeMean(r1, c1, r2, c2, meanNumber = 1.0)
            sum = 0.0;
            n = 0;

            (r1 .. r2).each {
                |row|
                (c1 .. c2).each {
                    |col|
                    value = item(row: row, col: col);

                    if !value.nan?
                        sum += (value ** meanNumber);
                        n += 1;
                    end
                }
            }

            return (sum / n) ** (1.0 / meanNumber);
        end

        private

        ## Helper to reload the data from the file.
        ## 
        ## @return true on success, false on failure.
        def reload()
            if @file.empty?
                return false
            end

            File.open(@file, "r") do |inFile|
                @data = [];

                inFile.each_line {
                    |line|
                    row = [];

                    line.split(",").each {
                        |item|
                        value = parser.call(item);

                        if value.nan? && !item.strip().empty?
                            # if a NaN is not from an empty string it's an invalid number
                            STDOUT.puts("ERR invalid data item : #{item}");
                        end

                        row.append(value);
                    }

                    @data.append(row);
                }

                return true;
            end

            return false;
        end
    end
end
