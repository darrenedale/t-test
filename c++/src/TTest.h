#ifndef STATISTICS_TTEST_TTEST_H
#define STATISTICS_TTEST_TTEST_H

#include <memory>
#include <optional>

#include "DataFile.h"

namespace Statistics::TTest
{
    /**
     * Alias for the type of numeric data.
     *
     * Helps keep the code easily maintainable - the underlying numeric type for the data being
     * processed only needs to change here and the entire codebase will understand.
     */
    using DataType = double;

    /**
     * Convenience alias for the concrete type of the DataFile.
     */
    using DataFileType = DataFile<DataType>;

    /**
     * Type alias for the data file shared pointer.
     */
    using DataFilePtr = std::shared_ptr<DataFileType>;

    /**
     * The available test types.
     */
    enum class TestType
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
     */
    class TTest {
        public:
            /**
             * The default type of t-test.
             */
            static const TestType DefaultTestType = TestType::Paired;

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
            explicit TTest(DataFilePtr && data, const TestType & type = DefaultTestType);

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
            explicit TTest(DataFileType && data, const TestType & type = DefaultTestType);

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
            explicit TTest(const DataFileType & data, const TestType & type = DefaultTestType);

            /**
             * Initialise a new t-test with no data.
             *
             * @param type The test type.
             */
            explicit TTest(const TestType & type = DefaultTestType);

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
            [[nodiscard]] inline TestType type() const
            {
                return m_type;
            }

            /**
             * Set the type of test.
             */
            inline void setType( const TestType & type )
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
            [[nodiscard]] virtual inline DataType t() const
            {
                if(TestType::Paired == m_type) {
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
            [[nodiscard]] DataType pairedT() const;

            /**
             * Helper to calculate t for unpaired data.
             *
             * Do not call unless you are certain that the t-test has data. See hasData().
             */
            [[nodiscard]] DataType unpairedT() const;

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
            TestType m_type;
    };
}

#endif
