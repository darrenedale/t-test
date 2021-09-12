import Foundation;

public class TTest
{
	public typealias ValueType = Double;

	public enum TestType
	{
		case Paired
		case Unpaired
	}

	private var m_data: DataFile<ValueType>?;
	private var m_type: TestType;

	public init(withData data: DataFile<ValueType>, ofType type: TestType = TestType.Unpaired)
	{
		self.m_data = data;
		self.m_type = type;
	}

	public var hasData: Bool
	{
		return nil != m_data;
	}

	public var data: DataFile<ValueType>
	{
		get
		{
			return m_data!;
		}

		set {
			m_data = newValue;
		}
	}

	public var type: TestType
	{
		get
		{
			return m_type;
		}

		set
		{
			m_type = newValue;
		}
	}

	public var t: ValueType
	{
		if (TestType.Paired == type) {
			return pairedT;
		}

		return unpairedT;
	}

	private var pairedT: ValueType
	{
		// the number of pairs of observations
		let n = data.columnItemCount(0);

		// sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
		var sumDiffs: ValueType = 0.0;

		// sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
		var sumSquaredDiffs: ValueType = 0.0;

		for row in (0 ..< n) {
			let diff = m_data!.item(row: row, column: 0) - m_data!.item(row: row, column: 1);
			sumDiffs += diff;
			sumSquaredDiffs += (diff * diff);
		}

		let sumDiffsSquared = sumDiffs * sumDiffs;
		let calcN = ValueType(n);		// convert once for calculation rather than casting inline twice
		return sumDiffs / (((calcN * sumSquaredDiffs) - sumDiffsSquared) / (calcN - 1.0)).squareRoot();
	}

	private var unpairedT: ValueType
	{
		// observation counts for each condition
		let n1 = data.columnItemCount(0);
		let n2 = data.columnItemCount(1);

		// means for each condition
		let mean1 = data.columnMean(0);
		let mean2 = data.columnMean(1);

		// sum of differences between items and the mean for each condition
		var sumMeanDiffs1: ValueType = 0.0;
		var sumMeanDiffs2: ValueType = 0.0;

		for row in (0 ..< data.rowCount) {
			var x = data.item(row: row, column: 0);

			if (!x.isNaN) {
				x -= mean1;
				sumMeanDiffs1 += (x * x);
			}

			x = data.item(row: row, column: 1);

			if (!x.isNaN) {
				x -= mean2;
				sumMeanDiffs2 += (x * x);
			}
		}

		sumMeanDiffs1 /= ValueType(n1);
		sumMeanDiffs2 /= ValueType(n2);

		// calculate the statistic
		var t = (mean1 - mean2) / ((sumMeanDiffs1 / (ValueType(n1) - 1.0)) + (sumMeanDiffs2 / (ValueType(n2) - 1.0))).squareRoot();

		// always return +ve t
		if (0.0 > t) {
			t.negate();
		}

		return t;
	}
}
