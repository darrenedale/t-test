module statistics.tests;

import std.stdio;
import std.math;
import statistics.data : DataFile;

class TTest
{
    /**
     * The default type of test to use when no type is specified in the c'tor.
     */
    public static const Type DefaultType = Type.Paired;
    
    /**
     * Alias for the type for the values analysed in a t-test.
     */
    public alias ValueType = real;
    public alias DataFileType = DataFile!(ValueType);

    /**
     * The types of t-test available.
     */
    enum Type : ubyte
    {
		Paired = 0,
		Unpaired,
	}

	/**
	 * The test type.
	 */
	private Type m_type;
	
	/**
	 * The data.
	 */
	private DataFileType m_data;

	/**
	 * Initialise a new TTest with a data file and optional type.
	 */
	public this(DataFileType data, Type type = DefaultType)
	{
		m_type = type;
		m_data = data;
	}

	/**
	 * Fetch the data.
	 */
	public ref pure DataFileType data()
	{
		return m_data;
	}

	/**
	 * Set the data to use.
	 */
	public void setData(ref DataFileType data)
	{
		m_data = data;
	}

	/**
	 * Fetch the test type.
	 */
	public pure Type type() const
	{
		return m_type;
	}

	/**
	 * Set the test type.
	 */
	public void setType(Type type)
	{
		m_type = type;
	}

	/**
	 * Helper to calculate the paired t statistic.
	 */
	protected pure ValueType pairedT() const
	{
		auto n = m_data.columnItemCount(0);
		ValueType[] diffs;
		ValueType[] diffs2;
		ValueType sumDiffs = 0.0;
		ValueType sumDiffs2 = 0.0;

		diffs.length = n;
		diffs2.length = n;

		foreach(DataFileType.IndexType i; 0 .. n) {
			diffs[i] = m_data.item(i, 0) - m_data.item(i, 1);
			diffs2[i] = diffs[i] * diffs[i];
			sumDiffs += diffs[i];
			sumDiffs2 += diffs2[i];
		}

		return sumDiffs / ((((cast(ValueType) n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ^^ 0.5);
	}

	/**
	 * Helper to calculate the unpaired t statistic.
	 */
	protected pure ValueType unpairedT() const
	{
		auto n1 = m_data.columnItemCount(0);
		auto n2 = m_data.columnItemCount(1);
		auto sum1 = m_data.columnSum(0);
		auto sum2 = m_data.columnSum(1);
		auto mean1 = sum1 / n1;
		auto mean2 = sum2 / n2;
		auto sumMeanDiffs1 = 0.0;
		auto sumMeanDiffs2 = 0.0;

		foreach(DataFileType.IndexType row; 0 .. m_data.rowCount()) {
			auto x = m_data.item(row, 0);

			if(!isNaN(x)) {
				x -= mean1;
				sumMeanDiffs1 += (x * x);
			}

			x = m_data.item(row, 1);

			if(!isNaN(x)) {
				x -= mean2;
				sumMeanDiffs2 += (x * x);
			}
		}

		sumMeanDiffs1 /= n1;
		sumMeanDiffs2 /= n2;
		ValueType t = (mean1 - mean2) / (((sumMeanDiffs1 / (n1 - 1)) + (sumMeanDiffs2 / (n2 - 1))) ^^ 0.5);

		if (0 > t) {
			t = -t;
		}

		return t;
	}

	/**
	 * Calculate the t statistic.
	 */
	public pure ValueType t() const
	{
		switch(type()) {
			case Type.Paired:
				return pairedT();

			case Type.Unpaired:
				return unpairedT();

			default:
				// should never get here!
				throw new Exception("unrecognised t-test type");
		}
	}
}
