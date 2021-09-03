# T Test

A simple command-line program to perform a Students' T-Test, implemented in a number of programming
languages.

The program can calculate both paired (AKA related, within-subjects) and unpaired (AKA unrelated,
between-subjects) statistics. It reads the data from CSV files and outputs the data for the two
conditions and the t statistic.

The program does not verify that the provided data is valid for the chosen test type - it assumes
that the user knows that the data in the file is suitable for the test they select. It is intended
as a simple demonstration of programming in various langauges, it is not intended for real-world
data analysis.

## Usage

Once built, in all cases the program is invoked as:

    t-test [-t {paired|unpaired}] data-file
    
- **-t** indicates the type of t-test to run. It defaults to a paired test if -t is not specified
- **data-file** must be the path to a file containing the data to analyse.

## Output

If the data can be analysed, the program outputs the content parsed from the data file followed
by the t statistic. Otherwise, it outputs an error message indicating why it cannot perform the
calculation.

## Data files

Data files must be plain-text CSV containing two columns of observed values. Conditions are
represented by the first two columns, observations are in rows. Values must be in decimal notation.
Only the first two columns are considered, any data in further columns is ignored. There must be at
least one row, and no empty rows.

For paired tests, each row must have at least two values and these must be in the first two columns;
for unpaired tests, one or other of the columns in each row is permitted to be empty - this is to
ease use of data files generated where each row represents a single observation that is not paired
with any other observation. Only the comma is supported as a delimiter, and cell encapsulation (e.g.
with ' or ") is not supported.

## Languages

The following langauges have implementations:
- C++
- C#.NET
- D
- PHP
- FreeBASIC

The following languages are in the works:
- C
- Python
- Perl
- Swift
- Rust
- Ruby
- x64 ASM