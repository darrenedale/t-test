#! /usr/bin/ruby

require_relative "Statistics/DataFile";
require_relative "Statistics/TTest";

data = DataFile.new(ARGV[0]);

(0 .. data.rowCount - 1).each {
    |row|
    (col = 0 .. data.columnCount - 1).each {
        |col|
        print("%0.3f  " % data.item(row, col));
    }

    puts();
}

printf("t = %0.6f\n", (TTest.new(data, TTest::UnpairedType)).t);
