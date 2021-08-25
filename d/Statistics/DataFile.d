module Statistics.DataFile;

import std.stdio;
import std.math;
import std.file;
import std.string;
import std.conv;

class DataFile
{
    public alias ValueType = double;
    public alias IndexType = ulong;
    
	private ValueType[][] m_data;
	private string m_file;

	this(string path = "")
	{
		m_file = path;
		reload();
	}

	bool reload()
	{
		if ("" == m_file) {
			writefln("no file to load");
			return false;
		}

		File f;

		try {
			f = File(m_file, "r");
		} catch(Exception e) {
			writefln("exception thrown opening file \"%s\": %s", m_file, e.msg);
			return false;
		}

		uint n = 0;
		m_data.length = 50;

		// quick and dirty CSV parser
		while(!f.eof()) {
			string line = strip(f.readln());

			if(n >= m_data.length) {
				m_data.length += 50;
			}

			ValueType[] row;
			string[] items = line.split(',');
			row.length = items.length;

			foreach (size_t i, string item; items) {
                row[i] = to!ValueType(item.strip());
			}

			m_data[n] = row;
			++n;
		}

		m_data.length = n;
		f.close();
		return true;
	}

	public IndexType rowCount() const
	{
		return cast(IndexType) m_data.length;
	}

	public IndexType columnCount() const
	{
		if (0 < m_data.length) {
			return cast(IndexType) m_data[0].length;
		}

		return 0;
	}

	protected IndexType itemCount(IndexType r1, IndexType c1, IndexType r2, IndexType c2) const
	{
		IndexType count = 0;
		
		foreach (IndexType col; c1 .. c2 + 1) {
			foreach (IndexType row; r1 .. r2 + 1) {
				if (isNaN(m_data[row][col])) {
					continue;
				}
				
				++count;
			}
		}
		
		return count;
	}
	
	public IndexType itemCount() const
	{
        return itemCount(0, 0, rowCount() - 1, columnCount() - 1);
	}
	
	public IndexType rowItemCount(IndexType row = 0) const
	{
        return itemCount(row, 0, row, columnCount() - 1);
	}
	
	public IndexType columnItemCount(IndexType col = 0) const
	{
        return itemCount(0, col, rowCount() - 1, col);
	}

	protected ValueType sum(IndexType r1, IndexType c1, IndexType r2, IndexType c2, ValueType pow = 1.0) const
	{
// 		in {
// 			assert(r1 >= 0);
// 			assert(r1 < rowCount());
// 			assert(c1 >= 0);
// 			assert(c1 < columnCount());
// 			assert(r2 >= 0);
// 			assert(r2 < rowCount());
// 			assert(c2 >= 0);
// 			assert(c2 < columnCount());
// 			assert(r2 >= r1);
// 			assert(c2 >= c1);
// 		}
// 		body {
			ValueType sum = 0.0;

			foreach(IndexType c; c1 .. c2 + 1) {
				foreach(IndexType r; r1 .. r2 + 1) {
					sum += item(r, c) ^^ pow;
				}
			}

			return sum;
// 		}
	}

	public ValueType sum(ValueType pow = 1.0) const
	{
		return sum(0, 0, rowCount() - 1, columnCount() - 1, pow);
	}

	public ValueType rowSum(IndexType row, ValueType pow = 1.0) const
	{
		return sum(row, 0, row, columnCount() - 1, pow);
	}

	public ValueType columnSum(IndexType col, ValueType pow = 1.0) const
	{
		return sum(0, col, rowCount() - 1, col, pow);
	}

	protected ValueType mean(IndexType r1, IndexType c1, IndexType r2, IndexType c2, ValueType meanNumber = 1.0) const
	{
// 		in {
// 			assert(r1 >= 0);
// 			assert(r1 < rowCount());
// 			assert(c1 >= 0);
// 			assert(c1 < columnCount());
// 			assert(r2 >= 0);
// 			assert(r2 < rowCount());
// 			assert(c2 >= 0);
// 			assert(c2 < columnCount());
// 			assert(r2 >= r1);
// 			assert(c2 >= c1);
// 		}
// 		body {
			ValueType mean = 0.0L;
			IndexType n = 0;

			foreach (IndexType row; r1 .. r2 + 1) {
				foreach (IndexType col; c1 .. c2 + 1) {
					ValueType itemValue = m_data[row][col];

					if(!isNaN(itemValue)) {
						++n;
						mean += itemValue ^^ meanNumber;
					}
				}
			}

			return mean / n ^^ (1.0L / meanNumber);
// 		}
	}

	public ValueType mean(ValueType meanNumber= 1.0) const
	{
		return mean(0, 0, rowCount(), columnCount(), meanNumber);
	}

	public ValueType rowMean(IndexType row, ValueType meanNumber = 1.0) const
	{
		return mean(row, 0, row, columnCount(), meanNumber);
	}

	public ValueType columnMean(IndexType col, ValueType meanNumber = 1.0) const
	{
		return mean(0, col, rowCount(), col, meanNumber);
	}

	public ValueType item(IndexType row, IndexType col) const
	{
// 		in {
// 			assert(row >= 0);
// 			assert(row < rowCount());
// 			assert(col >= 0);
// 			assert(col < columnCount());
// 		}
// 		body {
			return m_data[row][col];
// 		}
	}
}
