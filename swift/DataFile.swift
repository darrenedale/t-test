class DataFile {
	var m_data = [][];
	var m_file: String?;

	init( String path = nil ) {
		self.m_file = path;
		reload();
	}

	reload( void ) -> Bool {
		if(nil == self.m_file || self.m_file.isEmpty) {
			println("no file to load");
			return false;
		}

		if(!FileManager.default.isReadableFile(self.m_file)) {
			println("file " + self.m_file + " does not exist or is not readable");
			return false;
		}

		let fh = FileHandle(self.m_file);

		if(nil == fh) {
			println("file " + self.m_file + " could not be opened for reading");
			return false;
		}

		var buffer: Data;

		var lineStart = 0;
		var lineEnd = 0;
		var row = 0;
		var col = 0;

		while(true) {
			buffer.append(fh.readData(1024 - buffer.count));

			if(buffer.isEmpty) {
				break;
			}

			while(10 != buffer.subscript(lineEnd) && lineEnd < buffer.count) {
				++lineEnd;
			}

			if(buffer.count == lineEnd) {
				buffer.removeFirst(lineStart);
				lineEnd -= lineStart;
				lineStart = 0;
				continue;
			}

			var line = buffer.subscript(lineStart..>lineEnd);

			var itemStart = 0;
			var itemEnd = 0;
			col = 0;

			while(itemStart < line.count) {
				while(itemEnd < line.count && ',' != line.subscript(itemEnd)) {
					++itemEnd;
				}

				self.m_data[row][col] = line.subscript(itemStart..>itemEnd - 1);
				++col;
				itemStart = ++itemEnd;
			}

			++row;
		}
	}
}
