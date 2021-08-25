module Statistics.TTest;

import std.stdio;
import std.math;
import Statistics.DataFile;

class TTest
{
	enum Type : ubyte {
		Paired = 0,
		Unpaired,
	}

	private Type m_type;
	private DataFile m_data;

	this( DataFile data, Type type )
	{
		m_type = type;
		m_data = data;
	}

	this( DataFile data )
	{
		this(data, Type.Paired);
	}

	DataFile data()
	{
		return m_data;
	}

	void setData( DataFile data )
	{
		m_data = data;
	}

	Type type() const
	{
		return m_type;
	}

	void setType( const Type type )
	{
		m_type = type;
	}

	double pairedT() const
	{
		auto n = m_data.columnItemCount(0);
		double[] diffs;
		double[] diffs2;
		double sumDiffs = 0.0;
		double sumDiffs2 = 0.0;

		diffs.length = n;
		diffs2.length = n;

		foreach(ulong i; 0 .. n) {
			diffs[i] = m_data.item(i, 0) - m_data.item(i, 1);
			diffs2[i] = diffs[i] * diffs[i];
			sumDiffs += diffs[i];
			sumDiffs2 += diffs2[i];
		}

		return sumDiffs / ((((cast(double) n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ^^ 0.5);
	}

	double unpairedT() const
	{
		auto n1 = m_data.columnItemCount(0);
		auto n2 = m_data.columnItemCount(1);
		auto sum1 = m_data.columnSum(0);
		auto sum2 = m_data.columnSum(1);
		auto m1 = sum1 / n1;
		auto m2 = sum2 / n2;
		auto sumMDiff1 = 0.0;
		auto sumMDiff2 = 0.0;

		foreach(ulong i; 0 .. m_data.rowCount()) {
			auto x = m_data.item(i, 0);

			if(!isNaN(x)) {
				x -= m1;
				sumMDiff1 += (x * x);
			}

			x = m_data.item(i, 1);

			if(!isNaN(x)) {
				x -= m2;
				sumMDiff2 += (x * x);
			}
		}

		sumMDiff1 /= n1;
		sumMDiff2 /= n2;

// writefln("%s = %d", "n1", n1);
// writefln("%s = %d", "n2", n2);
// writefln("%s = %f", "sum1", sum1);
// writefln("%s = %f", "sum2", sum2);
// writefln("%s = %f", "mean1", m1);
// writefln("%s = %f", "mean2", m2);
// writefln("%s = %f", "sum of mean diffs squared 1", sumMDiff1);
// writefln("%s = %f", "sum of mean diffs squared 2", sumMDiff2);

		double t = (m1 - m2) / (((sumMDiff1 / (n1 - 1)) + (sumMDiff2 / (n2 - 1))) ^^ 0.5);

		if(0 > t) {
			t = -t;
		}

		return t;
	}

	double t() const {
		switch(type()) {
			case Type.Paired:
				return pairedT();

			case Type.Unpaired:
				return unpairedT();

			default:
				/* should never get here! */
				/* TODO throw exception */
				return 0.0;
		}
	}
}
