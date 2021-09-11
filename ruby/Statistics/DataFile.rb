##
# A data file for use with a statistical test.
class DataFile
    ##
    # Initialise a new data file.
    #
    # The CSV parser is very simple. It reads successive lines from the provided file and splits each line at every comma (,). Each element in the
    # resulting array of strings for each line is parsed as a +Float+. If this fails, the value for that cell is considered missing (+Float::NAN+);
    # otherwise, the parsed value is used for the cell.
    #
    # The +parser+ argument is an object (e.g. method, lambda, ...) that can be called with a single +String+ argument and which returns a +Float+
    # when called.
    # It will be called once for each string cell read from the CSV file to parse it to a value for the data. The default implementation checks
    # whether the string is a valid representation of a decimal floating point value and calls <code>to_f()</code> if it is, or returns +Float::NAN+
    # if it's not. It is guaranteed that it will never be called with anything other than a single +String+ argument.
    #
    # [Params]
    # - +path+ The path to a local CSV file to load.
    # - +parser+ A custom parser to convert string cells in the CSV file to numeric values.
    def initialize(fileName, parser = DataFile.method(:defaultParser))
        if !fileName.instance_of?(String)
            raise "fileName must be a String";
        end

        @file = fileName;
        @data = [];
        @parser = parser;
        reload()
    end

    ##
    # The number of rows in the DataFile.
    #
    # [Return]
    # +Integer+ The row count.
    def rowCount
        return @data.length
    end

    ##
    # The number of columns in the DataFile.
    #
    # Currently the count naively assumes the first row contains all the columns that exist in the data.
    #
    # [Return]
    # +Integer+ The column count.
    def columnCount
        if 0 == @data.length
            return 0
        end

        return @data[0].length
    end
    
    ##
    # Check whether the data file contains any data.
    #
    # [Return]
    # +true+ if the data file contains zero rows, +false+ otherwise.
    def empty?
        return 0 == rowCount
    end

    ##
    # Count the number of values in the DataFile.
    #
    # [Return]
    # +Integer+ The number of values.
    def itemCount
        if empty?
            return 0;
        end
        
        return rangeItemCount(0, 0, rowCount - 1, columnCount - 1);
    end

    ##
    # Count the number of values in a row in the DataFile.
    #
    # [Params]
    # - +row+ The row to count. Defaults to 0 so that it can be called without a row index when it is known that all rows contain an identical
    #   number of items.
    #
    # [Return]
    # +Integer+ The number of values.
    def rowItemCount(row = 0)
        if empty?
            return 0;
        end

        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        rangeItemCount(row, 0, row, columnCount - 1);
    end

    ##
    # Count the number of values in a column in the DataFile.
    #
    # [Params]
    # - +col+ The column to count. Defaults to 0 so that it can be called without a column index when it is known that all columns contain an
    #   identical number of items.
    #
    # [Return]
    # +Integer+ The number of values.
    def columnItemCount(col)
        if empty?
            return 0;
        end

        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        return rangeItemCount(0, col, rowCount - 1, col);
    end

    ##
    # Calculate the sum of the values in the DataFile.
    #
    # [Params]
    # - +pow+ The power to which to raise each value before it is added to the sum. Defaults to 1.0.
    #
    # [Return]
    # +Float+ The sum.
    def sum(pow = 1.0)
        if empty?
            return 0.0;
        end
        
        return rangeSum(0, 0, rowCount - 1, columnCount - 1, pow);
    end

    ##
    # Calculate the sum of the values in a row in the DataFile.
    #
    # [Params]
    # - +row+ The row whose items are to be summed.
    # - +pow+ The power to which to raise each value before it is added to the sum. Defaults to 1.0.
    #
    # [Return]
    # +Float+ The sum.
    def rowSum(row, pow = 1.0)
        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if empty?
            return 0.0;
        end

        rangeSum(row, 0, row, columnCount - 1, pow);
    end

    ##
    # Calculate the sum of the values in a row in the DataFile.
    #
    # [Params]
    # - +col+ The column whose items are to be summed.
    # - +pow+ The power to which to raise each value before it is added to the sum. Defaults to 1.0.
    #
    # [Return]
    # +Float+ The sum.
    def columnSum(col, pow = 1.0)
        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        if empty?
            return 0.0;
        end

        return rangeSum(0, col, rowCount - 1, col, pow);
    end

    ##
    # Calculate the mean of the values in the DataFile.
    #
    # [Params]
    # - +meanNumber+ Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
    #
    # [Return]
    # +Float+ The mean.
    def mean(meanNumber = 1.0)
        if empty?
            return 0.0;
        end
        
        return rangeMean(0, 0, rowCount - 1, columnCount - 1, meanNumber);
    end

    ##
    # Calculate the mean of the values for a row in the DataFile.
    #
    # [Params]
    # - +row+ The row whose items are to be included in the calculation.
    # - +meanNumber+ Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
    #
    # [Return]
    # +Float+ The mean.
    def rowMean(row, meanNumber = 1.0)
        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if empty?
            return 0.0;
        end

        rangeMean(row, 0, row, columnCount - 1, meanNumber);
    end

    ##
    # Calculate the mean of the values for a column in the DataFile.
    #
    # [Params]
    # - +col+ The column whose items are to be included in the calculation.
    # - +meanNumber+ Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
    #
    # [Return]
    # +Float+ The mean.
    def columnMean(col, meanNumber = 1.0)
        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        if empty?
            return 0.0;
        end

        return rangeMean(0, col, rowCount - 1, col, meanNumber);
    end

    ##
    # Fetch an item from the DataFile.
    #
    # [Params]
    # - +row+ The index of the row from which the value is sought. Named parameter.
    # - +col+ The index of the column from which the value is sought. Named parameter.
    #
    # [Return]
    # +Float+ The value. This will be Float::NAN if the cell is empty. 
    def item(row:, col:)
        if 0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if 0 > col || columnCount <= col
            raise "column out of bounds";
        end

        return @data[row][col];
    end

    private

    ## Default getter for @parser (for use in subclasses only)
    attr_reader :parser;

    ##
    # The default parser for the CSV file content.
    #
    # [Params]
    # - +str+ +String+ The string from a single cell of the CSV file to parse.
    #
    # [Return]
    # +Float+ The parsed value (+Float::NAN+ if the string is not a valid decimal floating-point number).
    def self.defaultParser(str)
        if str.match(/^\s*[+-]?[0-9]+(?:\.[0-9]+)?\s*$/)
            return str.to_f();
        else
            return Float::NAN;
        end
    end

    ##
    # Helper to count the number of items in a given range in the data file.
    #
    # Note that some cells in the data file can be empty, so the count is not simply the product of the range dimensions.
    #
    # [Params]
    # - +r1+ The topmost row to include in the count.
    # - +c1+ The leftmost column to include in the count.
    # - +r2+ The bottom-most row to include in the count.
    # - +c2+ The rightmost column to include in the count.
    #
    # [Return]
    # +Integer+ The number of data items in the range.
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

    ##
    # Helper to Sum the values in a given range.
    #
    # [Params]
    # - +r1+ The topmost row to include in the count.
    # - +c1+ The leftmost column to include in the count.
    # - +r2+ The bottom-most row to include in the count.
    # - +c2+ The rightmost column to include in the count.
    # - +pow+ The power to which to raise each value before it is added to the sum. Defaults to 1.0.
    #
    # [Return]
    # +Float+ The mean of the values in the range.
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

    ##
    # Calculate the mean of the items in a given range.
    #
    # The arithmetic mean, which is often referred to as the average, is meanNumber 1; the quadratic is 2; the geometric is -1.
    #
    # [Params]
    # - +r1+ The topmost row to include in the count.
    # - +c1+ The leftmost column to include in the count.
    # - +r2+ The bottom-most row to include in the count.
    # - +c2+ The rightmost column to include in the count.
    # - +meanNumber+ Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
    #
    # [Return]
    # +Float+ The mean of the values in the range.
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

    ##
    # Helper to reload the data from the file.
    # 
    # [Return]
    # +true+ on success, +false+ on failure.
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
