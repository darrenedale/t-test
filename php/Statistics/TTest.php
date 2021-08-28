<?php

namespace Statistics;

class TTest
{
	/**
	 * Paired test type constant.
	 */
	public const PairedTestType = 0;

	/**
	 * Unpaired test type constant.
	 */
	public const UnpairedTestType = 1;

	/**
	 * The default type of t-test.
	 */
	const DefaultTestType = self::PairedTestType;

	/**
	 * Initialise a new t-test.
	 *
	 * The t-test object shares ownership of the provided data with the provider. The
	 * data is intended to be available to modify externally (e.g. an app could
	 * implement a store of data files and an editor for data files), with the t-test
	 * automatically keeping up-to-date with external changes.
	 *
	 * The default test type is a paired test.
	 *
	 * @param DataFile|null data The data to process.
	 * @param int type The type of test.
	 */
	public function __construct(?DataFile $data, int $type = self::DefaultTestType)
	{
		$this->data = $data;
		$this->type = $type;
	}

	/**
	 * Check whether the test has data to work with.
	 */
	public function hasData(): bool
	{
		return isset($this->data);
	}

	/**
	 * Calculate and return t.
	 *
	 * Do not call unless you are certain that the t-test has data. See hasData().
	 *
	 * If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
	 */
	public function t(): float
	{
		if(self::PairedTestType == $this->type) {
			return $this->pairedT();
		}

		return $this->unpairedT();
	}

	/**
	 * Helper to calculate t for paired data.
	 *
	 * Do not call unless you are certain that the t-test has data. See hasData().
	 */
	protected function pairedT(): float
	{
		// the number of pairs of observations
		$n = $this->data->columnItemCount(0);

        // differences between pairs of observations: (x1 - x2)
		$diffs = [];

        // squared differences between pairs of observations: (x1 - x2) ^ 2
		$diffs2 = [];

        // sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
		$sumDiffs = 0.0;

        // sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
		$sumDiffs2 = 0.0;

		for($i = 0; $i < $n; ++$i) {
			$diffs[$i] = $this->data->item($i, 0) - $this->data->item($i, 1);
			$diffs2[$i] = $diffs[$i] * $diffs[$i];
			$sumDiffs += $diffs[$i];
			$sumDiffs2 += $diffs2[$i];
		}

		return $sumDiffs / pow((($n * $sumDiffs2) - ($sumDiffs * $sumDiffs)) / ($n - 1), 0.5);
	}

	/**
	 * Helper to calculate t for unpaired data.
	 *
	 * Do not call unless you are certain that the t-test has data. See hasData().
	 */
	protected function unpairedT(): float
	{
		// observation counts for each condition
		$n1 = $this->data->columnItemCount(0);
		$n2 = $this->data->columnItemCount(1);
        
        // sums for each condition
		$sum1 = $this->data->columnSum(0);
		$sum2 = $this->data->columnSum(1);
        
        // means for each condition
		$mean1 = $sum1 / $n1;
		$mean2 = $sum2 / $n2;

        // sum of differences between items and the mean for each condition
		$sumMeanDiffs1 = 0.0;
		$sumMeanDiffs2 = 0.0;

		for ($i = $this->data->rowCount() - 1; $i >= 0; --$i) {
			$x = $this->data->item($i, 0);

			if (!is_nan($x)) {
				$x -= $mean1;
				$sumMeanDiffs1 += ($x * $x);
			}

			$x = $this->data->item($i, 1);

			if(!is_nan($x)) {
				$x -= $mean2;
				$sumMeanDiffs2 += ($x * $x);
			}
		}

        $sumMeanDiffs1 /= $n1;
        $sumMeanDiffs2 /= $n2;

        // calculate the statistic
		$t = ($mean1 - $mean2) / pow(($sumMeanDiffs1 / ($n1 - 1)) + ($sumMeanDiffs2 / ($n2 - 1)), 0.5);

        // always return +ve t
		if(0 > $t) {
			$t = -$t;
		}

		return $t;
	}

	/**
	 * The data.
	 *
	 * Stored as a shared pointer so that the test can outlive its creator while still
	 * retaining automatic storage lifetime management for the provided data, and so
	 * that the provided data can still be modified or used externally.
	 */
	public ?DataFile $data;

	/**
	 * The type of test.
	 */
	public int $type;
}