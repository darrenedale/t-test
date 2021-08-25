namespace Statistics
{
    using System;
    using System.IO;
    using System.Collections.Generic;

    using ValueType = System.Double;

    public class DataFile
    {
        public DataFile(string fileName)
        {
            file = fileName;
            m_data = new List<List<double>>();
            reload();
        }

        public int rowCount
        {
            get
            {
                return m_data.Count;
            }
        }

        public int columnCount
        {
            get
            {
                if (0 < m_data.Count) {
                    return m_data[0].Count;
                }

                return 0;
            }
        }

        public int itemCount
        {
            get
            {
                return rangeItemCount(0, 0, rowCount - 1, columnCount - 1);
            }
        }

        public int rowItemCount(int row = 0)
         {
            return rangeItemCount(row, 0, row, columnCount - 1);
        }

        public int columnItemCount(int col = 0)
        {
            return rangeItemCount(0, col, rowCount - 1, col);
        }

        public double mean(double meanNumber =  1.0)
        {
            return mean(0, 0, rowCount - 1, columnCount - 1, meanNumber);
        }

        public double rowMean(int row, double meanNumber =  1.0)
        {
            return mean(row, 0, row, columnCount - 1, meanNumber);
        }

        public double columnMean(int col, double meanNumber =  1.0)
        {
            return mean(0, col, rowCount - 1, col, meanNumber);
        }

        public double sum(double pow =  1.0)
        {
            return sum(0, 0, rowCount - 1, columnCount - 1, pow);
        }

        public double rowSum(int row, double pow =  1.0)
        {
            return sum(row, 0, row, columnCount - 1, pow);
        }

        public double columnSum(int col, double pow =  1.0)
        {
            return sum(0, col, rowCount - 1, col, pow);
        }

        public double item(int row, int col)
        {
            if(0 > row || rowCount <= row) {
                throw new InvalidDataException("row out of bounds");
            }

            if(0 > col || columnCount <= col) {
                throw new InvalidDataException("column out of bounds");
            }

            return m_data[row][col];
        }

        /**
         * Reload the content of the data file from disk.
         */
        protected bool reload()
        {
            if ("" == file) {
                Console.Error.WriteLine("no file to load");
                return false;
            }

            if (!File.Exists(file)) {
                Console.Error.WriteLine($"the file {file} does not exist");
                return false;
            }

            FileStream inStream = File.OpenRead(file);

            if (!inStream.CanRead) {
                Console.Error.WriteLine($"could not open {file} for reading");
                return false;
            }

            m_data.Clear();
            string line;

            while (0 < (line = DataFile.readLine(inStream)).Length) {
                int startPos = 0;
                List<double> row = new List<double>();

                while(true) {
                    int endPos = line.IndexOf(',', startPos);

                    if (-1 == endPos) {
                        endPos = line.Length;
                    }

                    try {
                        row.Add(Double.Parse(line.Substring(startPos, endPos - startPos)));
                    }
                    catch (Exception) {
                        // invalid or empty value
                        row.Add(double.NaN);
                    }

                    if(line.Length == endPos) {
                        break;
                    }

                    startPos = endPos + 1;
                }

                m_data.Add(row);
            }

            return true;
        }

        private int rangeItemCount(int r1, int c1, int r2, int c2)
        {
            int count = 0;

            for(int r = r1; r <= r2; ++r) {
                for(int c = c1; c <= c2; ++c) {
                    double v = m_data[r][c];

                    if(!Double.IsNaN(m_data[r][c])) {
                        ++count;
                    }
                }
            }

            return count;
        }

			private double sum(int r1, int c1, int r2, int c2, double pow = 1.0)
            {
				double sum = 0.0;

				for(int r = r1; r <= r2; ++r) {
					for(int c = c1; c <= c2; ++c) {
						double v = m_data[r][c];

						if(!Double.IsNaN(v)) {
							sum += Math.Pow(m_data[r][c], pow);
						}
					}
				}

				return sum;
			}

        double mean(int r1, int c1, int r2, int c2, double meanNumber = 1.0)
        {
            double mean = 0.0;
            int n = 0;

            for(int r = r1; r <= r2; ++r) {
                for(int c = c1; c <= c2; ++c) {
                    double v = m_data[r][c];

                    if(!Double.IsNaN(v)) {
                        ++n;
                        mean += Math.Pow(m_data[r][c], meanNumber);
                    }
                }
            }

            return Math.Pow(mean / (double) (n), 1.0 / meanNumber);
        }

        public static string readLine(FileStream inStream)
        {
            int ch;
            string line = "";

            while (-1 != (ch = inStream.ReadByte())) {
                line += (char) ch;

                if ('\n' == ch || '\r' == ch) {
                    // consume following \r or \n, if present
                    int peekCh = inStream.ReadByte();

                    if (
                        -1 != peekCh &&
                        (
                            ('\n' == ch && '\r' != peekCh) ||
                            ('\r' == ch && '\n' != peekCh)
                        )
                    ) {
                        // the peeked ch is not part of a /r/n or /n/r sequence, so put it back in the stream
                        inStream.Seek(-1, SeekOrigin.Current);
                    }

                    break;
                }
            }

            return line;
        }

        public string file {get;}
        private List<List<double>> m_data;
    }
}