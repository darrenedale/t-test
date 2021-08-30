module ttest;

import Statistics.DataFile;
import Statistics.TTest;
import std.stdio;

void main( string[] args )
{
	TTest.Type type = TTest.Type.Unpaired;
	string dataFilePath = "";

	if(1 < args.length) {
		for(ulong i = 1; i < args.length; ++i) {
			if("-t" == args[i]) {
				++i;

				if("paired" == args[i]) {
					type = TTest.Type.Paired;
				}
				else if("unpaired" == args[i]) {
					type = TTest.Type.Unpaired;
				}
				else {
					writefln("ERR unrecognised test type \"%s\"", args[i]);
				}
			}
			else {
				/* first unrecognised arg is datafile */
				dataFilePath = args[i];
				break;
			}
		}
	}

	auto data = new TTest.DataFileType(dataFilePath);

	foreach(r; 0 .. data.rowCount()) {
		foreach(c; 0 .. data.columnCount()) {
			writef("%0.3f  ", data.item(r, c));
		}

		writeln("");
	}

	auto t = new TTest(data, type);
	writefln("%s = %f", "t", t.t());
}
