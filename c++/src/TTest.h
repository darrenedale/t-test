#ifndef STATISTICS_TTEST_TTEST_H
#define STATISTICS_TTEST_TTEST_H

#include <memory>
#include <optional>
#include "DataFile.h"

namespace Statistics
{
    /**
     * The available test types.
     */
    enum class TTestType
    {
        Paired = 0,
        Unpaired,
    };

    /**
     * A class representing a t-test on a given dataset.
     *
     * The class can perform both paired and unpaired analyses. It assumes that:
     * - the data is organised with conditions represented by columns and observations represented by rows
     * - the data to analyse has has at least two columns
     * - the data to analyse is in the first two columns
     *
     * For paired tests it further assumes that:
     * - each row contains valid values in both of the first two columns
     *
     * The data provided is not validated against these assumptions - that is the caller's responsibility.
     *
     * @tparam T The underlying data type for the values to be tested. Must be a floating-point type. Custom types can be used so long as they satisfy the
     * following criteria:
     * - default constructable
     * - constructable from the constant NAN
     * - constructable from built-in integer and floating-point types
     * - implements multiplication with operator *
     * - implements division with operator /
     * - implements addition with operator +
     * - implements subtraction with operator -
     * - implements comparison with operator > and operator < or some other combination of comparison operators that enable the compiler to automatically
     *   create these operators
     * - has an implementation of std::isnan()
     */
    template<class T = long double, typename = std::enable_if_t<std::is_floating_point_v<T>>>
    class TTest
    {
        public:
            /**
             * Alias for the type of numeric data.
             *
             * Helps keep the code easily maintainable - the underlying numeric type for the data being
             * processed only needs to change here and the entire codebase will understand.
             */
            using ValueType = T;

            /**
             * Convenience alias for the concrete type of the DataFile used for TTest objects.
             */
            using DataFileType = DataFile<ValueType>;

            /**
             * Type alias for the data file shared pointer.
             */
            using DataFilePtr = std::shared_ptr<DataFileType>;

            /**
             * The default type of t-test.
             */
            static const TTestType DefaultTestType = TTestType::Paired;

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
             * @param data The data to process.
             * @param type The type of test.
             */
            explicit TTest(DataFilePtr && data, const TTestType & type = DefaultTestType)
            :	m_data(std::move(data)),
                 m_type(type)
            {}

            /**
             * Initialise a new t-test.
             *
             * The t-test object moves the data from the provided DataFile to its own shared
             * version, which is then available from data().
             *
             * The default test type is a paired test.
             *
             * @param data The data to process.
             * @param type The type of test.
             */
            explicit TTest(DataFileType && data, const TTestType & type = DefaultTestType)
            :	m_data(std::make_shared<DataFileType>(std::move(data))),
                 m_type(type)
            {}

            /**
             * Initialise a new t-test.
             *
             * The t-test object copies the data from the provided DataFile to its own shared
             * version, which is then available from data().
             *
             * The default test type is a paired test.
             *
             * @param data The data to process.
             * @param type The type of test.
             */
            explicit TTest(const DataFileType & data, const TTestType & type = DefaultTestType)
            :	m_data(std::make_shared<DataFileType>(data)),
                 m_type(type)
            {}

            /**
             * Initialise a new t-test with no data.
             *
             * @param type The test type.
             */
            explicit TTest(const TTestType & type = DefaultTestType)
            :	m_data(nullptr),
                 m_type(type)
            {}

            /**
             * Check whether the test has data to work with.
             */
            [[nodiscard]] inline bool hasData() const
            {
                return static_cast<bool>(m_data);
            }

            /**
             * Fetch a reference to the t-test's data.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             *
             * The reference is only guaranteed to be valid as long as the t-test is in scope. It *may* live longer if some other object is sharing
             * ownership.
             */
            [[nodiscard]] inline const DataFileType & data() const
            {
                return *m_data;
            }

            /**
             * Fetch a reference to the t-test's data.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             *
             * The reference is only guaranteed to be valid as long as the t-test is in scope. It *may* live longer if some other object is sharing
             * ownership.
             */
            inline DataFileType & data()
            {
                return *m_data;
            }

            /**
             * Fetch the t-test's data.
             *
             * Use this when you want to share ownership of the t-test's DataFile with another object. When you just want to refer to the t-test's data,
             * use data() instead.
             *
             * The returned pointer shares ownership of the underlying DataFile object with the t-test. The DataFile only goes out of scope once all of the
             * shared pointers to it are no longer in scope.
             * @return
             */
            [[nodiscard]] inline DataFilePtr dataPtr() const
            {
                return m_data;
            }

            /**
             * The t-test object moves the data from the provided DataFile to its own shared
             * version, which is then available from data().
             *
             * @param data
             *
             */
            inline void setData(DataFileType && data)
            {
                m_data = std::make_shared<DataFileType>(std::move(data));
            }

            /**
             * Set the data.
             *
             * The t-test will share ownership of the provided data with any pre-existing owners.
             */
            inline void setData(const DataFilePtr & data)
            {
                m_data = data;
            }

            /**
             * Set the data.
             *
             * The t-test will share ownership of the provided data with any pre-existing owners.
             */
            inline void setData(std::shared_ptr<DataFileType> && data)
            {
                m_data = std::move(data);
            }

            /**
             * Fetch the type of test.
             */
            [[nodiscard]] inline TTestType type() const
            {
                return m_type;
            }

            /**
             * Set the type of test.
             */
            inline void setType(const TTestType & type)
            {
                m_type = type;
            }

            /**
             * Calculate and return t.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             *
             * If you find a way to optimise the calculation so that it runs 10 times faster, you can reimplement this in a subclass.
             */
            [[nodiscard]] virtual inline ValueType t() const
            {
                if(TTestType::Paired == m_type) {
                    return pairedT();
                }

                return unpairedT();
            }

        protected:
            /**
             * Helper to calculate t for paired data.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             */
            [[nodiscard]] ValueType pairedT() const
            {
                // the number of pairs of observations
                auto n = m_data->columnItemCount(0);

                // differences between pairs of observations: (x1 - x2)
                std::vector<ValueType> diffs(n, NAN);

                // squared differences between pairs of observations: (x1 - x2) ^ 2
                std::vector<ValueType> diffs2(n, NAN);

                // sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
                ValueType sumDiffs = 0.0L;

                // sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
                ValueType sumDiffs2 = 0.0L;

                for(int i = 0; i < n; ++i) {
                    diffs[i] = m_data->item(i, 0) - m_data->item(i, 1);
                    diffs2[i] = diffs[i] * diffs[i];
                    sumDiffs += diffs[i];
                    sumDiffs2 += diffs2[i];
                }

                return sumDiffs / static_cast<ValueType>(std::pow((((static_cast<ValueType>(n) * sumDiffs2) - (sumDiffs * sumDiffs)) / static_cast<ValueType>(n - 1)), 0.5L));
            }

            /**
             * Helper to calculate t for unpaired data.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             */
            [[nodiscard]] ValueType unpairedT() const
            {
                // observation counts for each condition
                auto n1 = static_cast<ValueType>(m_data->columnItemCount(0));
                auto n2 = static_cast<ValueType>(m_data->columnItemCount(1));

                // sums for each condition
                auto sum1 = m_data->columnSum(0);
                auto sum2 = m_data->columnSum(1);

                // means for each condition
                auto mean1 = sum1 / n1;
                auto mean2 = sum2 / n2;

                // sum of differences between items and the mean for each condition
                auto sumMeanDiffs1 = static_cast<ValueType>(0.0L);
                auto sumMeanDiffs2 = static_cast<ValueType>(0.0L);

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

                sumMeanDiffs1 /= n1;
                sumMeanDiffs2 /= n2;

                // calculate the statistic
                ValueType t = (mean1 - mean2) / std::pow(((sumMeanDiffs1 / (n1 - 1.0L)) + (sumMeanDiffs2 / (n2 - 1.0L))), 0.5L);

                // always return +ve t
                if(0.0L > t) {
                    t = -t;
                }

                return t;
            }

        private:
            /**
             * The data.
             *
             * Stored as a shared pointer so that the test can outlive its creator while still
             * retaining automatic storage lifetime management for the provided data, and so
             * that the provided data can still be modified or used externally.
             */
            DataFilePtr m_data;

            /**
             * The type of test.
             */
            TTestType m_type;
    };
}

#endif
