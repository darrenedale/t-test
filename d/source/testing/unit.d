module testing.unit;

import std.string;
import std.stdio;

mixin template RunsTests(TestCaseType)
{
	public override void run()
	{
		// run each public method whose name starts with "test"
		static foreach (string test; [__traits(allMembers, TestCaseType)]) {
			static if (
				test.startsWith("test") &&
				__traits(compiles, __traits(getMember, this, test)()) &&
				"public" == __traits(getVisibility, __traits(getMember, this, test))
			) {
				writef("Running test %s.%s() ... ", this.classinfo.name, test);
				(__traits(getMember, this, test))();
				writeln("Passed");
			}
		}
	}
}

/**
 * Abstract base class for unit tests.
 */
abstract class TestCase
{
	/**
		* Run the test case.
		*
		* All public methods whose name starts with "test" and which can be invoked without any arguments will be called.
		*/
	public void run();

	/**
		* Assert that an actual value equals an expected value.
		*/
	protected static final void assertEquals(T = int)(T expected, T actual, string msg = "")
	{
		assert(actual == expected, msg);
	}

	/**
		* Assert that an actual value is less than an expected value.
		*/
	protected static final void assertLessThan(T = int)(T expected, T actual, string msg = "")
	{
		assert(actual < expected, msg);
	}

	/**
		* Assert that an actual value equals an expected value, with a tolerance delta.
		*
		* Useful for floating-point "equality" which must be somewhat vague because of the imprecision in floating-point representation.
		*/
	protected static final void assertEqualsWithDelta(T = real)(T expected, T actual, T delta, string msg = "")
	{
		assert(actual >= expected - delta, msg);
		assert(actual <= expected + delta, msg);
	}

	/**
		* Assert that a value is of a specific type.
		*/
	protected static final void assertIsType(ExpectedT, ActualT)(ActualT arg, string msg = "")
	{
		assert(typeid(ExpectedT) == typeid(ActualT), msg);
	}
}
