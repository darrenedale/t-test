IDENTIFICATION DIVISION.
PROGRAM-ID. t-test.
*> compile with:
*>   /opt/gnucobol2.0/bin/cobc -free -x t-test.cbl
*> or
*>   cobc -free -x t-test.cbl
*> 
*> (On the development machine (Ubuntu 14.10), GNUCOBOL2.0 is installed in
*> /opt/gnucobol2.0. The distro-supplied OpenCOBOL1.1 compiler cobc is installed
*> to the system path.)
*> 
*> GNUCOBOL2.0 can be downloaded here:
*> http://sourceforge.net/projects/open-cobol/files/gnu-cobol/2.0/
*> 
*> As of March 2015, compile GNUCOBOL2.0 cobc using:
*>    ./configure --prefix=/opt/guncobol2.0
*>    make
*>    sudo make install
*> 
*> This will not install anything anywhere other than /opt/gnucobol2/
*> 
*> To make the GNUCOBOL2.0 runtime library available system-wide, do:
*>    sudo install -m 644 /opt/gnucobol2/lib/libcob.so.4.0.0 /usr/lib/ &&
*>         cd /usr/lib &&
*>         sudo ln -s ./libcob.so.4.0.0 ./libcob.so.4
*>    
*> This will work alongside the libcob.so.1 installed by the OpenCOBOL 1.1
*> package.
ENVIRONMENT DIVISION.
  INPUT-OUTPUT SECTION.
  FILE-CONTROL.
    SELECT f-dataFile ASSIGN TO DYNAMIC ws-dataFilePath.

DATA DIVISION.
FILE SECTION.
  FD f-dataFile.
     01 f-df-char PIC X.

WORKING-STORAGE SECTION.
*> command line args
  01 ws-testType PIC X(256).
     88 ws-tt-testIsPaired VALUE "paired" "related" "repeated" "repeated-measures".
     88 ws-tt-testIsUnpaired VALUE "unpaired" "unrelated".
  01 ws-dataFilePath PIC X(256).
     88 ws-dfp-empty VALUE SPACES.

*> the state of the data file while reading items from it. 0 means OK, 1 means
*> EOF
  01 ws-dataFileState PIC 9 VALUE 0 USAGE IS COMPUTATIONAL-5.
     88 ws-dfs-isEof VALUE 1.

*> storage for a row of items read out of the data file
*>   char is a single char read from the file (see char of dataFile in the FILE
*>        section above
*>   buf  is a "string" buffer built up by appending one char at a time from the
*>        datafile until a LF (CHAR(10)) is read. would a table of BINARY_CHAR
*>        be more appropriate?
*>   i    indexes where the next char will be inserted into buf
*>   a    is populated with the content of the first data item parsed from buf.
*>        it is basically all of the content up to the first delimiter
*>   b    is populated with the content of the first data item parsed from buf.
*>        it is basically all of the content from the first delimiter to the
*>        second or the end of the line
  01 ws-readBuffer.
     05 ws-rb-char PIC X VALUE SPACE.
        88 ws-rb-isEol VALUE x'0a'.
     05 ws-rb-buffer PIC X(1024) VALUE SPACES.
     05 ws-rb-length PIC 9999 VALUE 1 USAGE IS COMPUTATIONAL-5.
     05 ws-rb-a.
        10 ws-rb-a-val PIC X(10) VALUE SPACES.
           88 ws-rb-a-isEmpty VALUE SPACES.
        10 ws-rb-a-isValid PIC 9 VALUE ZERO.
     05 ws-b.
        10 ws-rb-b-val PIC X(10) VALUE SPACES.
           88 ws-rb-b-isEmpty VALUE SPACES.
        10 ws-rb-b-isValid PIC 9 VALUE ZERO.

*> storage used when calculating t. t host the statistic itself. temp1 is some
*> temporary storage used during the calculation to help avoid rounding errors
*> that can arise from putting the whole calculation in a single COMPUTE
*> statement
  01 ws-temp1 PIC 9(6)V999 VALUE ZEROS.
  01 ws-t PIC 9(6)V999 VALUE ZEROS.

*> storage used when the numeric values of data items read from the data file
*> are transferred from the character buffers in readBuffer to storage that is
*> allocated for numeric values
  01 ws-dataItems.
     05 ws-di-a.
        10 ws-di-a-val PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.
        10 ws-di-a-isValid PIC 9 VALUE ZERO.
        10 ws-di-a-isEmpty PIC 9 VALUE ZERO.
     05 ws-di-b.
        10 ws-di-b-val PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.
        10 ws-di-b-isValid PIC 9 VALUE ZERO.
        10 ws-di-b-isEmpty PIC 9 VALUE ZERO.

*> the sums of conditions A and B used in calculating t and output with the
*> raw data table
  01 ws-sums.
     05 ws-sum-a PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.
     05 ws-sum-b PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> the sums of squared values from conditions A and B used in calculating an
*> unrealted t and output with the raw data table
  01 ws-sumSquares.
     05 ws-sumsq-a PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.
     05 ws-sumsq-b PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> counts of the number of items in conditions A and B used in the calculation
*> of t and outut with the raw data table
  01 ws-counts.
     05 ws-count-a PIC 9(6) VALUE ZEROS USAGE IS COMPUTATIONAL-5.
     05 ws-count-b PIC 9(6) VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> arithmetic means of the values of items in conditions A and B, used during
*> the calculation of an unrealted t and output with the raw data table
  01 ws-means.
     05 ws-mean-a PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.
     05 ws-mean-b PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> the sum of the differences between pairs of items in conditions A and B, used
*> during the calculation of a paired t and output with the results
  01 ws-sumOfDiffs PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> the sum of the squared differences between pairs of items in conditions A and
*> B, used during the calculation of a paired t and output with the results
  01 ws-sumOfSquaredDiffs PIC 9(6)V999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> used to track the row number when the data table is being generated for
*> output. the firstLine condition is used to check when the table headings need
*> to be generated
  01 ws-dataTableLineNumber PIC 9999 VALUE 1.
     88 ws-dtln-firstLine VALUE 1.

*> a general-purpose looping value, used with PERFORM for iteration. no
*> assumptions may be made about its content before using it. always initialize
*> it
  01 ws-loop1 PIC 9999 VALUE ZEROS USAGE IS COMPUTATIONAL-5.

*> data items are MOVEd to this variable in order to be output nicely
  01 ws-formattedDataItem PIC Z(6).999 VALUE ZEROS.

*> row numbers in the output data table are MOVEd to this variable in order to
*> be output nicely
  01 ws-formattedIndex PIC ZZZ9 VALUE ZERO.
  

PROCEDURE DIVISION CHAINING ws-testType ws-dataFilePath.
  IF ws-dfp-empty of ws-dataFilePath
    DISPLAY "No data file specified."
    PERFORM showUsage
    STOP RUN
  END-IF.

  OPEN INPUT f-dataFile.

  IF ws-tt-testIsPaired
    PERFORM pairedTest
  ELSE IF ws-tt-testIsUnpaired
    PERFORM unpairedTest
  ELSE
    DISPLAY "Unrecognised test type '" FUNCTION trim(ws-testType) "'"
  END-IF.

  exitProgram.
    CLOSE f-dataFile.
    STOP RUN.

  showUsage.
    DISPLAY "t-test <type> <data-file>".
    DISPLAY " ".
    DISPLAY '  <type>       The test type. This can be "paired", "related", "repeated", or'.
    DISPLAY '               "repeated-measures" for a paired t-test, or it can be "unpaired"'.
    DISPLAY '               or "unrelated" for an unpaired t-test. Anything else is'.
    DISPLAY '               considered an error. There is no default, this option must be'.
    DISPLAY '               present on the command line.'.
    DISPLAY "  <data-file>  The path to the file containing the data to be analysed. The".
    DISPLAY "               file must contain CSV data, with completely numeric content".
    DISPLAY "               using either the comma ',' or space ' ' as the item delimiter.".
    DISPLAY "               Empty lines are ignored. For paired t-tests there must be".
    DISPLAY "               exactly two data items per non-empty line. For unpaired t-tests".
    DISPLAY "               there can be one or two items per non-empty line. In such cases,".
    DISPLAY "               if the delimiter appears first the data item is assigned to".
    DISPLAY "               group B; otherwise it is assigned to group A. Any non-numeric".
    DISPLAY "               data items found in the data file will cause the program to emit".
    DISPLAY "               an error message and exit".
    DISPLAY "               The data file reader is very particular about the format of each".
    DISPLAY "               row of values. There must be no whitespace around values (except".
    DISPLAY "               a single whitespace between values if that is the delimiter) and".
    DISPLAY "               there must be only one instance of the delimiter per row.".

  readChar.
      READ f-dataFile INTO ws-rb-char AT END MOVE 1 TO ws-dataFileState.

      IF NOT ws-dfs-isEof AND NOT ws-rb-isEol
        MOVE ws-rb-char TO ws-rb-buffer(ws-rb-length:1)
        ADD 1 TO ws-rb-length
      END-IF.

  readData.
    INITIALIZE ws-dataItems.
    INITIALIZE ws-readBuffer.
    MOVE 1 TO ws-rb-length.

    PERFORM readChar WITH TEST AFTER UNTIL ws-rb-length > LENGTH OF ws-rb-buffer OR ws-rb-isEol OR ws-dfs-isEof.
    
    UNSTRING ws-rb-buffer DELIMITED BY ',' OR ' ' INTO ws-rb-a-val, ws-rb-b-val.
*>       ON OVERFLOW DISPLAY "invalid content in data file: '" FUNCTION trim(buf) "'"
*>       PERFORM exitProgram.

*> validate value for condition A
    IF ws-rb-a-isEmpty
      MOVE 0 TO ws-di-a-isValid
      MOVE 1 TO ws-di-a-isEmpty
    ELSE IF FUNCTION trim(ws-rb-a-val) IS NOT NUMERIC
      MOVE 0 TO ws-di-a-isValid
      MOVE 0 TO ws-di-a-isEmpty
    ELSE
      MOVE 1 TO ws-di-a-isValid
      MOVE 0 TO ws-di-a-isEmpty
      MOVE ws-rb-a-val TO ws-di-a-val
    END-IF.

*> validate value for condition B
    IF ws-rb-b-isEmpty
      MOVE 0 TO ws-di-b-isValid
      MOVE 1 TO ws-di-b-isEmpty
    ELSE IF FUNCTION trim(ws-rb-b-val) IS NOT NUMERIC
      MOVE 0 TO ws-di-b-isValid
      MOVE 0 TO ws-di-b-isEmpty
    ELSE
      MOVE 1 TO ws-di-b-isValid
      MOVE 0 TO ws-di-b-isEmpty
      MOVE ws-rb-b-val TO ws-di-b-val
    END-IF.

  displayData.
    IF ws-dtln-firstLine
      MOVE LENGTH OF ws-dataTableLineNumber TO ws-loop1

      PERFORM ws-loop1 TIMES
        DISPLAY ' ' WITH NO ADVANCING
      END-PERFORM

      DISPLAY " " WITH NO ADVANCING

      MOVE LENGTH OF ws-formattedDataItem TO ws-loop1

      PERFORM ws-loop1 TIMES
        DISPLAY ' ' WITH NO ADVANCING
      END-PERFORM

      DISPLAY "A " WITH NO ADVANCING

      PERFORM ws-loop1 TIMES
        DISPLAY ' ' WITH NO ADVANCING
      END-PERFORM

      DISPLAY 'B'
    END-IF.

    MOVE LENGTH OF ws-formattedDataItem TO ws-loop1
    MOVE ws-dataTableLineNumber TO ws-formattedIndex.
    DISPLAY ws-formattedIndex "  " WITH NO ADVANCING.

    IF 1 = ws-di-a-isValid
      MOVE ws-di-a-val TO ws-formattedDataItem
      DISPLAY ws-formattedDataItem WITH NO ADVANCING
    ELSE
      PERFORM ws-loop1 TIMES
        DISPLAY ' ' WITH NO ADVANCING
      END-PERFORM
    END-IF.

    DISPLAY "  " WITH NO ADVANCING.

    IF 1 = ws-di-b-isValid
      MOVE ws-di-b-val TO ws-formattedDataItem
      DISPLAY ws-formattedDataItem WITH NO ADVANCING
    ELSE
      PERFORM ws-loop1 TIMES
        DISPLAY ' ' WITH NO ADVANCING
      END-PERFORM
    END-IF.

    DISPLAY " ".
    ADD 1 TO ws-dataTableLineNumber.

  calculateMeans.
    IF ws-count-a NOT = 0
      COMPUTE ws-mean-a ROUNDED MODE IS NEAREST-EVEN = ws-sum-a / ws-count-a
    ELSE
      MOVE 0 TO ws-mean-a
    END-IF.

    IF ws-count-b NOT = 0
      COMPUTE ws-mean-b ROUNDED MODE IS NEAREST-EVEN = ws-sum-b / ws-count-b
    ELSE
      MOVE 0 TO ws-mean-b
    END-IF.

  pairedTest.
    INITIALIZE ws-sums.
    INITIALIZE ws-means.

    PERFORM WITH TEST AFTER UNTIL ws-dfs-isEof
      PERFORM readData

      IF 1 = ws-di-a-isValid AND 1 = ws-di-b-isValid
        ADD ws-di-a-val TO ws-sum-a
        ADD 1 TO ws-count-a
        ADD ws-di-b-val TO ws-sum-b
        ADD 1 TO ws-count-b
        COMPUTE ws-sumOfDiffs = ws-sumOfDiffs + (ws-di-a-val - ws-di-b-val)
        COMPUTE ws-sumOfSquaredDiffs = ws-sumOfSquaredDiffs + ((ws-di-b-val - ws-di-a-val) ** 2)
        PERFORM displayData
      ELSE IF 1 = ws-di-a-isEmpty AND 1 = ws-di-b-isEmpty
*>         DISPLAY "ignoring empty line in data file."
        CONTINUE
      ELSE IF 0 = ws-di-a-isValid OR 0 = ws-di-b-isValid
        DISPLAY "invalid data found in data file: '" FUNCTION trim(ws-rb-buffer) "'"
        PERFORM exitProgram
      ELSE
        DISPLAY "Unpaired data found in data file: '" FUNCTION trim(ws-rb-buffer) "'"
        PERFORM exitProgram
      END-IF
    END-PERFORM.

    PERFORM calculateMeans.

    IF 2 > ws-count-a
      DISPLAY "insufficient data - must have at least two observations"
      PERFORM exitProgram
    END-IF.

*>  t must be computed in stages to ensure that rounding is applied to all 
*>  parts of the calculation rather than just the final assignment (if done in
*>  one COMPUTE statement, all parts of the calculation will be rounded by 
*>  TRUNCATION, only the assignment of the result to t will be rounded as we
*>  intend)
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = (ws-count-a) - 1.
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = ((ws-count-a * ws-sumOfSquaredDiffs) - (ws-sumOfDiffs ** 2)) / ws-t.
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = FUNCTION sqrt(ws-t).
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = ws-sumOfDiffs / ws-t.

    DISPLAY " ".
    MOVE ws-sum-a TO ws-formattedDataItem.
    DISPLAY "Sum   " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-sum-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    MOVE ws-count-a TO ws-formattedDataItem.
    DISPLAY "N     " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-count-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    MOVE ws-mean-a TO ws-formattedDataItem.
    DISPLAY "Mean  " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-mean-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    DISPLAY " ".
    MOVE ws-sumOfDiffs TO ws-formattedDataItem.
    DISPLAY "Sum D     = " ws-formattedDataItem.
    COMPUTE ws-sumOfDiffs = ws-sumOfDiffs ** 2.
    MOVE ws-sumOfDiffs TO ws-formattedDataItem.
    DISPLAY "(Sum D)2  = " ws-formattedDataItem.
    MOVE ws-sumOfSquaredDiffs TO ws-formattedDataItem.
    DISPLAY "Sum D2    = " ws-formattedDataItem.
    COMPUTE ws-sumOfSquaredDiffs = ws-sumOfSquaredDiffs * ws-count-a.
    MOVE ws-sumOfSquaredDiffs TO ws-formattedDataItem.
    DISPLAY "N(Sum D2) = " ws-formattedDataItem.
    DISPLAY " ".
    MOVE ws-t TO ws-formattedDataItem.
    DISPLAY "t         = " ws-formattedDataItem.

  unpairedTest.
    INITIALIZE ws-sums.
    INITIALIZE ws-sumSquares.
    INITIALIZE ws-means.

    PERFORM WITH TEST AFTER UNTIL ws-dfs-isEof
      PERFORM readData

      IF 1 = ws-di-a-isValid
        ADD ws-di-a-val TO ws-sum-a
        COMPUTE ws-sumsq-a ROUNDED MODE IS NEAREST-EVEN = ws-sumsq-a + (ws-di-a-val ** 2)
        ADD 1 TO ws-count-a
      END-IF

      IF 1 = ws-di-b-isValid
        ADD ws-di-b-val TO ws-sum-b
        COMPUTE ws-sumsq-b ROUNDED MODE IS NEAREST-EVEN = ws-sumsq-b + (ws-di-b-val ** 2)
        ADD 1 TO ws-count-b
      END-IF

      IF 1 = ws-di-a-isEmpty AND 1 = ws-di-b-isEmpty
*>         DISPLAY "ignoring empty line in data file."
        CONTINUE
      ELSE IF 0 = ws-di-a-isValid AND 0 = ws-di-b-isValid
        DISPLAY "invalid data found in data file: '" FUNCTION trim(ws-rb-buffer) "'"
        PERFORM exitProgram
      ELSE
        PERFORM displayData
      END-IF
    END-PERFORM.

    IF 2 > ws-count-a OR ws-count-b
      DISPLAY "insufficient data = must have at least two observations in each condition"
      PERFORM exitProgram
    END-IF.

    PERFORM calculateMeans.

*>  t must be computed in stages to ensure that rounding is applied to all 
*>  parts of the calculation rather than just the final assignment (if done in
*>  one COMPUTE statement, all parts of the calculation will be rounded by 
*>  TRUNCATION, only the assignment of the result to t will be rounded as we
*>  intend)
    COMPUTE ws-temp1 ROUNDED MODE IS NEAREST-EVEN = (ws-count-a + ws-count-b) / (ws-count-a * ws-count-b).
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = ((ws-sumsq-a - ((ws-sum-a ** 2) / (ws-count-a ))) + (ws-sumsq-b - ((ws-sum-b ** 2) / (ws-count-b)))) / (ws-count-a+ ws-count-b - 2).

    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = ws-t * ws-temp1.
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = FUNCTION sqrt(ws-t).
    COMPUTE ws-t ROUNDED MODE IS NEAREST-EVEN = FUNCTION abs(ws-mean-a - ws-mean-b) / ws-t.

    DISPLAY " ".
    MOVE ws-sum-a TO ws-formattedDataItem.
    DISPLAY "Sum   " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-sum-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    MOVE ws-sumsq-a TO ws-formattedDataItem.
    DISPLAY "E(x2) " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-sumsq-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    COMPUTE ws-temp1 = ws-sum-a ** 2.
    MOVE ws-temp1 TO ws-formattedDataItem.
    DISPLAY "(Ex)2 " ws-formattedDataItem WITH NO ADVANCING.
    COMPUTE ws-temp1 = ws-sum-b ** 2.
    MOVE ws-temp1 TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    MOVE ws-count-a TO ws-formattedDataItem.
    DISPLAY "N     " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-count-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    MOVE ws-mean-a TO ws-formattedDataItem.
    DISPLAY "Mean  " ws-formattedDataItem WITH NO ADVANCING.
    MOVE ws-mean-b TO ws-formattedDataItem.
    DISPLAY "  " ws-formattedDataItem.

    DISPLAY " ".
    MOVE ws-t TO ws-formattedDataItem.
    DISPLAY "t = " FUNCTION trim(ws-formattedDataItem).
