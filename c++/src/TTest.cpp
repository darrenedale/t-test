#include "TTest.h"

#include <vector>
#include <cmath>

namespace Statistics::TTest
{
	TTest::TTest(DataFilePtr && data, const TestType & type )
	:	m_data(std::move(data)),
		m_type(type)
	{}

	TTest::TTest(const DataFileType & data, const TestType & type )
	:	m_data(std::make_shared<DataFileType>(data)),
		m_type(type)
	{}

	TTest::TTest(DataFileType && data, const TestType & type )
	:	m_data(std::make_shared<DataFileType>(std::move(data))),
		m_type(type)
	{}

	TTest::TTest(const TestType & type)
	:	m_data(nullptr),
		m_type(type)
	{}

	DataType TTest::pairedT() const
	{
        // the number of pairs of observations
		auto n = m_data->columnItemCount(0);
        
        // differences between pairs of observations: (x1 - x2)
		std::vector<DataType> diffs(n, NAN);
        
        // squared differences between pairs of observations: (x1 - x2) ^ 2
		std::vector<DataType> diffs2(n, NAN);
        
        // sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
		DataType sumDiffs = 0.0;

        // sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
		DataType sumDiffs2 = 0.0;

		for(int i = 0; i < n; ++i) {
			diffs[i] = m_data->item(i, 0) - m_data->item(i, 1);
			diffs2[i] = diffs[i] * diffs[i];
			sumDiffs += diffs[i];
			sumDiffs2 += diffs2[i];
		}

		return sumDiffs / static_cast<DataType>(std::pow((((static_cast<double>(n) * sumDiffs2) - (sumDiffs * sumDiffs)) / static_cast<double>(n - 1)), 0.5L));
	}

	DataType TTest::unpairedT() const
	{
        // observation counts for each condition
		auto n1 = m_data->columnItemCount(0);
		auto n2 = m_data->columnItemCount(1);
        
        // sums for each condition
		auto sum1 = m_data->columnSum(0);
		auto sum2 = m_data->columnSum(1);
        
        // means for each condition
		auto mean1 = sum1 / static_cast<double>(n1);
		auto mean2 = sum2 / static_cast<double>(n2);

        // sum of differences between items and the mean for each condition
		auto sumMeanDiffs1 = 0.0;
		auto sumMeanDiffs2 = 0.0;

		for(auto i = m_data->rowCount() - 1; i >= 0; --i) {
			auto x = m_data->item(i, 0);

			if(!std::isnan(x)) {
				x -= mean1;
                sumMeanDiffs1 += (x * x);
			}

			x = m_data->item(i, 1);

			if(!std::isnan(x)) {
				x -= mean2;
                sumMeanDiffs2 += (x * x);
			}
		}

        sumMeanDiffs1 /= static_cast<DataType>(n1);
        sumMeanDiffs2 /= static_cast<DataType>(n2);

        // calculate the statistic
		DataType t = (mean1 - mean2) / std::pow(((sumMeanDiffs1 / static_cast<DataType>(n1 - 1)) + (sumMeanDiffs2 / static_cast<DataType>(n2 - 1))), 0.5);

        // always return +ve t
		if(0 > t) {
			t = -t;
		}

		return t;
	}
}
