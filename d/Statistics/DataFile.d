module Statistics.DataFile;

import std.stdio;
import std.math;
import std.file;
import std.string;
import std.conv;

class DataFile
{
	private double[][] m_data;
	private string m_file;

	this(string path = "")
	{
		m_file = path;
		reload();
	}

	bool reload()
	{
		if("" == m_file) {
			writefln("no file to load");
			return false;
		}

		File f;

		try {
			f = File(m_file, "r");
		}
		catch( Exception e ) {
			writefln("exception raised opening file \"%s\": %s", m_file, e.msg);
			return false;
		}

		uint n = 0;
		m_data.length = 50;

		/* this is just a quick and dirty CSV parser */
		while(!f.eof()) {
			string line = strip(f.readln());

			if(n >= m_data.length) {
				m_data.length += 50;
			}

			double[] row;
			row.length = 10;

			uint c = 0;
			long p = 0;

			while(true) {
				long myP = line.indexOf(',', p);

				if(c >= row.length) {
					row.length += 10;
				}

				if(-1 == myP) {
					row[c] = to!double(line[p .. line.length]);
					row.length = c + 1;
					break;
				}

				row[c] = to!double(line[p .. myP]);
				++c;
				p = myP + 1;
			}

			m_data[n] = row;
			++n;
		}

		m_data.length = n;
		f.close();
		return true;
	}

	ulong rowCount() const {
		return m_data.length;
	}

	ulong columnItemCount( ulong c = 0 ) const {
		ulong count = 0;

		foreach(ulong r; 0 .. m_data.length) {
			if(isNaN(m_data[r][c])) {
				continue;
			}

			++count;
		}

		return count;
	}

	ulong columnCount() const {
		if(0 < m_data.length) {
			return m_data[0].length;
		}

		return 0;
	}

	protected double sum( ulong r1, ulong c1, ulong r2, ulong c2, double pow = 1.0 ) const {
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
			double sum = 0.0;

			foreach(ulong c; c1 .. c2) {
				foreach(ulong r; r1 .. r2) {
					sum += item(r, c) ^^ pow;
				}
			}

			return sum;
// 		}
	}

	double sum( double pow = 1.0 ) const {
		return sum(0, 0, rowCount(), columnCount(), pow);
	}

	double rowSum( ulong r, double pow = 1.0 ) const {
		return sum(r, 0, r + 1, columnCount(), pow);
	}

	double columnSum( ulong c, double pow = 1.0 ) const {
		return sum(0, c, rowCount(), c + 1, pow);
	}

	double item( ulong row, ulong col ) const {
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
