#ifndef STATISTICS_DATAFILE_H
#define STATISTICS_DATAFILE_H

#include <utility>
#include <vector>
#include <string>
#include <algorithm>
#include <functional>
#include <iostream>
#include <fstream>
#include <cctype>
#include <cmath>
#include <cctype>
#include <charconv>

namespace Statistics
{
    /**
     * Convenience type alias for a data item parser function.
     */
    template<class T>
    using DataItemParser = T(const std::string_view &);

    /**
     * Default value parser for DataFiles with integer value types.
     *
     * The implementation uses std::from_chars() for all numeric types for which it is defined. To use other types as the underlying value type for DataFile
     * objects, you will need to provide your own implementation.
     *
     * @param str The string to parse. Leading and trailing whitespace is ignored.
     * @return The parsed value.
     * @throws std::invalid_argument if str cannot be parsed to the required value.
     */
    template<typename IntType, int base = 10, std::enable_if_t<std::is_integral_v<IntType>, bool> = true>
    IntType defaultDataItemParser(const std::string_view & str)
    {
        auto * begin = str.data();
        auto * end = begin + str.size();

        while (begin < end && std::isspace(*begin)) {
            ++begin;
        }

        while (end > begin && std::isspace(*end)) {
            --end;
        }

        IntType ret;
        auto [firstUnusedChar, exitCode] = std::from_chars(begin, end, ret, base);

        if (exitCode != std::errc()) {
            throw std::invalid_argument("invalid numeric value");
        } else if (firstUnusedChar != end) {
            throw std::invalid_argument("unexpected non-numeric characters at end");
        }

        return ret;
    }

    /**
     * Default value parser for DataFiles with integer value types.
     *
     * The implementation uses std::from_chars() for all numeric types for which it is defined. To use other types as the underlying value type for DataFile
     * objects, you will need to provide your own implementation.
     *
     * @param str The string to parse. Leading and trailing whitespace is ignored.
     * @return The parsed value.
     * @throws std::invalid_argument if str cannot be parsed to the required value.
     */
    template<typename FloatType, std::chars_format format = std::chars_format::general, std::enable_if_t<std::is_floating_point_v<FloatType>, bool> = true>
    FloatType defaultDataItemParser(const std::string_view & str)
    {
        auto * begin = str.data();
        auto * end = begin + str.size();

        // ignore leading whitespace
        while (begin < end && std::isspace(*begin)) {
            ++begin;
        }

        // ignore trailing whitespace: note we decrement end before the loop and increment it after because it points to one-past-the-last-char not actually the
        // last char
        --end;

        while (end > begin && std::isspace(*end)) {
            --end;
        }

        ++end;

        FloatType ret;
        auto [firstUnusedChar, exitCode] = std::from_chars(begin, end, ret, format);

        if (exitCode != std::errc()) {
            throw std::invalid_argument("invalid numeric value");
        } else if (firstUnusedChar != end) {
            throw std::invalid_argument("unexpected non-numeric characters at end");
        }

        return ret;
    }

    /**
     * A data file for use with a statistical test.
     *
     * @tparam T The data type for the data file. Items in the data file are parsed to values of this type. Defaults to long double.
     * @tparam parser A function that will be used to parse string content read from the file into values of the data type. Each built-in floating-point type
     * and each built-in integral type, including unsigned variants, are compatible with the default parser template function. For custom types (e.g. big
     * integer implementations) or if you want to support bases greater than 36 you can provide a custom implementation.
     */
	template<class T = long double, DataItemParser<T> parser = defaultDataItemParser<T>>
	class DataFile
	{
		public:
            /**
             * Alias for the type used to index rows and columns in the data file.
             */
			using IndexType = long;

            /**
             * Alias for the type of data items in the data file.
             */
            using ValueType = T;

            static_assert(std::is_integral_v<IndexType>, "DataFile::IndexType must be an integral numeric type.");
            static_assert(!std::is_unsigned_v<IndexType>, "DataFile::IndexType should not be unsigned because it makes looping over rows and columns error prone.");

            /**
             * Initialise a new data file.
             *
             * The CSV parser is very simple. It loads successive lines from the provided file and splits it at each comma (,). Each element in the resulting
             * array of strings is parsed to the ValueType. If this fails, the value for that cell is considered missing (NaN); otherwise, the parsed value is
             * used for the cell.
             *
             * @param path The path to a local CSV file to load.
             */
			explicit DataFile(std::string path = {})
			:	m_file(std::move(path))
			{
				reload();
			}

            /**
             * Initialise a DataFile as a copy of another.
             *
             * @param other The DataFile to copy.
             */
			DataFile(const DataFile & other) = default;

            /**
             * Initialise a data file by taking over the data from another.
             *
             * @param other The DataFile to move.
             */
			DataFile(DataFile && other) noexcept = default;

            /**
             * Destroy the DataFile.
             */
			virtual ~DataFile() = default;

            /**
             * Copy the content of another data file into this one.
             *
             * @param other The DataFile to copy.
             * @return
             */
			DataFile & operator=(const DataFile & other) = default;

            /**
             * Move the content of another data file into this one.
             *
             * @param other The DataFile whose content should be stolen.
             * @return
             */
			DataFile & operator=(DataFile && other) noexcept = default;

            /**
             * The number of rows in the DataFile.
             * @return The row count.
             */
			[[nodiscard]] inline IndexType rowCount() const
            {
				return m_data.size();
			}

            /**
             * The number of columns in the DataFile.
             *
             * Currently the count naively assumes the first row contains all the columns that exist in the data.
             * @return The column count.
             */
			[[nodiscard]] inline IndexType columnCount() const
            {
				if(!m_data.empty()) {
					return m_data[0].size();
				}

				return 0;
			}

            /**
             * Count the number of values in the DataFile.
             *
             * @return The number of values.
             */
			[[nodiscard]] inline IndexType itemCount() const
            {
				return itemCount(0, 0, rowCount() - 1, columnCount() - 1);
			}

            /**
             * Count the number of values in a row in the DataFile.
             *
             * @param row The row to count. Defaults to 0 so that it can be called without a row index when it is known that all rows contain an identical
             * number of items.
             *
             * @return The number of values.
             */
			[[nodiscard]] inline IndexType rowItemCount(const IndexType & row = 0) const
            {
				return itemCount(row, 0, row, columnCount() - 1);
			}

            /**
             * Count the number of values in a column in the DataFile.
             *
             * @param col The column to count. Defaults to 0 so that it can be called without a column index when it is known that all columns contain an
             * identical number of items.
             *
             * @return The number of values.
             */
			[[nodiscard]] inline IndexType columnItemCount(const IndexType & col = 0) const {
				return itemCount(0, col, rowCount() - 1, col);
			}

            /**
             * Calculate the mean of the values in the DataFile.
             *
             * @return The mean.
             */
			inline ValueType mean(double meanNumber = 1.0L) const
            {
				return mean(0, 0, rowCount() - 1, columnCount() - 1, meanNumber);
			}

            /**
             * Calculate the mean of the values in a row in the DataFile.
             *
             * @return The mean.
             */
			inline ValueType rowMean(const IndexType & row, double meanNumber = 1.0L) const
            {
				return meanNumber(row, 0, row, columnCount() - 1, meanNumber);
			}

            /**
             * Calculate the mean of the values in a column in the DataFile.
             *
             * @return The mean.
             */
			inline ValueType columnMean(const IndexType & col, double meanNumber = 1.0L) const
            {
				return meanNumber(0, col, rowCount() - 1, col, meanNumber);
			}

            /**
             * Calculate the sum of the values in the DataFile.
             *
             * @return The sum.
             */
			inline ValueType sum(double pow = 1.0L) const
            {
				return sum(0, 0, rowCount() - 1, columnCount() - 1, pow);
			}

            /**
             * Calculate the sum of the values in a row in the DataFile.
             *
             * @return The sum.
             */
			inline ValueType rowSum(const IndexType & row, double pow = 1.0L) const
            {
				return sum(row, 0, row, columnCount() - 1, pow);
			}

            /**
             * Calculate the sum of the values in a column in the DataFile.
             *
             * @return The sum.
             */
			inline ValueType columnSum(const IndexType & col, double pow = 1.0L) const
            {
				return sum(0, col, rowCount() - 1, col, pow);
			}

            /**
             * Fetch an item from the DataFile.
             *
             * @param row The index of the row from which the value is sought.
             * @param col The index of the column from which the value is sought.
             *
             * @return The value. This will be NaN if the cell is empty.
             * @throws std::invalid_argument if row or col is OOB
             */
			inline const ValueType & item(const IndexType & row, const IndexType & col) const
            {
				if(0 > row || rowCount() <= row) {
					throw std::invalid_argument("row out of bounds");
				}

				if(0 > col || columnCount() <= col) {
					throw std::invalid_argument("column out of bounds");
				}

				return m_data[row][col];
			}

            /**
             * Fetch an item from the DataFile.
             *
             * @param row The index of the row from which the value is sought.
             * @param col The index of the column from which the value is sought.
             *
             * @return The value. This will be NaN if the cell is empty.
             */
			inline ValueType item( const IndexType & row, const IndexType & col )
            {
				// force this to be const so that overload resolution of the (apparent)
                //recursive call results in the above const ValueType & item() const method
                //being called instead of this one again.
                return const_cast<const DataFile<T, parser> *>(this)->item(row, col);
			}

		protected:
            /**
             * Count the number of items in a given range in the data file.
             *
             * Note that some cells in the data file can be empty, so the count is not simply the product of the range dimensions.
             *
             * @param r1 The topmost row to include in the count.
             * @param c1 The leftmost column to include in the count.
             * @param r2 The bottom-most row to include in the count.
             * @param c2 The rightmost column to include in the count.
             *
             * @return The number of data items in the range.
             */
			[[nodiscard]] IndexType itemCount(IndexType r1, IndexType c1, IndexType r2, IndexType c2) const
            {
				IndexType count = 0;

                // TODO use std::count_if()?
				for(IndexType r = r1; r <= r2; ++r) {
					for(IndexType c = c1; c <= c2; ++c) {
						if(!std::isnan(m_data[r][c])) {
							++count;
						}
					}
				}

				return count;
			}

            /**
             * Sum the items in a given range.
             *
             * @param r1 The topmost row to include in the sum.
             * @param c1 The leftmost column to include in the sum.
             * @param r2 The bottom-most row to include in the sum.
             * @param c2 The rightmost column to include in the sum.
             * @param pow An optional power to which to raise each value before it is added to the sum.
             *
             * @return
             */
            ValueType sum(IndexType r1, IndexType c1, IndexType r2, IndexType c2, double pow = 1.0L ) const
            {
                ValueType sum = 0.0L;

				for(IndexType r = r1; r <= r2; ++r) {
					for(IndexType c = c1; c <= c2; ++c) {
                        ValueType itemValue = m_data[r][c];

						if(!std::isnan(itemValue)) {
							sum += std::pow(itemValue, pow);
						}
					}
				}

				return sum;
			}

            /**
             * Calculate the mean of the items in a given range.
             *
             * The arithmetic mean, which is often referred to as the average, is meanNumber 1; the quadratic is 2; the geometric is -1.
             *
             * @param r1 The topmost row to include in the sum.
             * @param c1 The leftmost column to include in the sum.
             * @param r2 The bottom-most row to include in the sum.
             * @param c2 The rightmost column to include in the sum.
             * @param meanNumber Which mean to calculate. Defaults to 1.0 for the arithmetic mean.
             *
             * @return
             */
            ValueType mean(IndexType r1, IndexType c1, IndexType r2, IndexType c2, double meanNumber = 1.0L) const
            {
                ValueType mean = 0.0L;
				IndexType n = 0;

				for(IndexType r = r1; r <= r2; ++r) {
					for(IndexType c = c1; c <= c2; ++c) {
                        ValueType itemValue = m_data[r][c];

						if(!std::isnan(itemValue)) {
							++n;
							mean += std::pow(itemValue, meanNumber);
						}
					}
				}

				return std::pow(mean / static_cast<ValueType>(n), 1.0L / meanNumber);
			}

		private:
            /**
             * Type for storage of row data.
             */
			using RowStorage = std::vector<ValueType>;

            /**
             * Type for storage of the rows in the DataFile.
             */
            using DataStorage = std::vector<RowStorage>;

            /**
             * Helper to reload the data from the file.
             * @return true on success, false on failure.
             */
			bool reload() 
            {
				if(m_file.empty()) {
					std::cerr << "no file to load\n";
					return false;
				}

				std::ifstream in(m_file);

				if(!in.is_open()) {
					std::cerr << "could not open file\n";
					return false;
				}

				m_data.clear();

				// read buffer
				std::string line;

				while(!in.eof()) {
					std::getline(in, line);
					std::string::size_type valueStartPos = 0;
					RowStorage row;

					while(true) {
						std::string::size_type valueEndPos = line.find(',', valueStartPos);

						try {
							row.push_back(parser(line.substr(valueStartPos, valueEndPos)));
						}
						catch( const std::exception & e ) {
							std::cerr << "ERR exception parsing data: " << e.what() << "\n";
							row.push_back(NAN);
						}

						if(std::string::npos == valueEndPos) {
							row.shrink_to_fit();
							break;
						}

                        valueStartPos = valueEndPos + 1;
					}

					m_data.push_back(std::move(row));
				}

				m_data.shrink_to_fit();
				return true;
			}

            /**
             * The parsed data.
             */
            DataStorage m_data;

            /**
             * The path to the file containing the data.
             */
			std::string m_file;
	};
}

#endif
