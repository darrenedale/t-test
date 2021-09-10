class DataFile
    def initialize(fileName)
        @file = fileName;
        @data = [];
        reload()
    end

    def rowCount
        return @data.length
    end

    def columnCount
        if 0 == @data.length
            return 0
        end

        return @data[0].length
    end
    
    def isEmpty
        return 0 == rowCount
    end

    def itemCount
        if isEmpty
            return 0;
        end
        
        return rangeItemCount(0, 0, rowCount - 1, columnCount - 1);
    end

    def rowItemCount(row)
        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if isEmpty
            return 0;
        end

        rangeItemCount(row, 0, row, columnCount - 1);
    end

    def columnItemCount(col)
        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        if isEmpty
            return 0;
        end

        return rangeItemCount(0, col, rowCount - 1, col);
    end

    def sum(pow = 1.0)
        if isEmpty
            return 0.0;
        end
        
        return rangeSum(0, 0, rowCount - 1, columnCount - 1, pow);
    end

    def rowSum(row, pow = 1.0)
        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if isEmpty
            return 0.0;
        end

        rangeSum(row, 0, row, columnCount - 1, pow);
    end

    def columnSum(col, pow = 1.0)
        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        if isEmpty
            return 0.0;
        end

        return rangeSum(0, col, rowCount - 1, col, pow);
    end

    def mean(meanNumber = 1.0)
        if isEmpty
            return 0.0;
        end
        
        return rangeMean(0, 0, rowCount - 1, columnCount - 1, meanNumber);
    end

    def rowMean(row, meanNumber = 1.0)
        if  0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if isEmpty
            return 0.0;
        end

        rangeMean(row, 0, row, columnCount - 1, meanNumber);
    end

    def columnMean(col, meanNumber = 1.0)
        if  0 > col || columnCount <= col
            raise "column out of bounds";
        end

        if isEmpty
            return 0.0;
        end

        return rangeMean(0, col, rowCount - 1, col, meanNumber);
    end

    def item(row, col)
        if 0 > row || rowCount <= row
            raise "row out of bounds";
        end

        if 0 > col || columnCount <= col
            raise "column out of bounds";
        end

        return @data[row][col];
    end

    protected

    def rangeItemCount(r1, c1, r2, c2)
        count = 0;

        (r1 .. r2).each {
            |row|
            (c1 .. c2).each {
                |col|

                if !item(row, col).nan?
                    count += 1;
                end
            }
        }

        return count;
    end

    def rangeSum(r1, c1, r2, c2, pow = 1.0)
        sum = 0.0;

        (r1 .. r2).each {
            |row|
            (c1 .. c2).each {
                |col|
                value = item(row, col);

                if !value.nan?
                    sum += (value ** pow);
                end
            }
        }

        return sum;
    end

    def rangeMean(r1, c1, r2, c2, meanNumber = 1.0)
        sum = 0.0;
        n = 0;

        (r1 .. r2).each {
            |row|
            (c1 .. c2).each {
                |col|
                value = item(row, col);

                if !value.nan?
                    sum += (value ** meanNumber);
                    n += 1;
                end
            }
        }

        return (sum / n) ** (1.0 / meanNumber);
    end

    private

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

                    if item.match(/^\s*[+-]?[0-9]+(?:\.[0-9]+)?\s*$/)
                        row.append(item.to_f())
                    else
                        if !item.strip().empty?
                            # if it's not empty it's an invalid number
                            STDOUT.puts("ERR invalid data item : #{item}");
                        end

                        row.append(Float::NAN);
                    end
                }

                @data.append(row);
            }

            return true;
        end

        return false;
    end
end
