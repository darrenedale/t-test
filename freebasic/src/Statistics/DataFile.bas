#include once "string.bi"
#include once "Types.bi"
#include once "OptionalValue.bi"
#include once "DataFile.bi"
#include once "DataTable.bi"
#include once "OptionalValueVector.bi"

Namespace Statistics

	Constructor DataFile(byref file as const String)
		m_file = file
		reload()
	End Constructor

	Const Function DataFile.rowCount() as SizeType
		return m_data.size()
	End Function

	Const Function DataFile.columnCount() as SizeType
		If 0 < rowCount() Then
			return m_data.row(0).size()
		End If
		
		return 0
	End Function

	Const Function DataFile.isEmpty() As Boolean
		Return 0 = m_data.size()
	End Function

	Const Function DataFile.item(row As SizeType, column As SizeType) As OptionalValue
		return m_data.row(row + 1).item(column + 1)
	End Function

	Const Function DataFile.itemCount() As SizeType
		Return itemCount(0, 0, rowCount() - 1, columnCount() - 1)
	End Function
	
	Const Function DataFile.rowItemCount(row As SizeType) As SizeType
		Return itemCount(row, 0, row, columnCount() - 1)
	End Function

	Const Function DataFile.columnItemCount(column As SizeType) As SizeType
		Return itemCount(0, column, rowCount() - 1, column)
	End Function

	Const Function DataFile.sum(pow As DataValue) As DataValue
		Return sum(0, 0, rowCount() - 1, columnCount() - 1, pow)
	End Function

	Const Function DataFile.rowSum(row As SizeType, pow As DataValue) As DataValue
		Return sum(row, 0, row, columnCount() - 1, pow)
	End Function

	Const Function DataFile.columnSum(column As SizeType, pow As DataValue) As DataValue
		Return sum(0, column, rowCount() - 1, column)
	End Function

	Const Function DataFile.mean(meanNumber As DataValue) As DataValue
		Return mean(0, 0, rowCount() - 1, columnCount() - 1, meanNumber)
	End Function

	Const Function DataFile.rowMean(row As SizeType, meanNumber As DataValue) As DataValue
		Return mean(row, 0, row, columnCount() - 1, meanNumber)
	End Function

	Const Function DataFile.columnMean(column As SizeType, meanNumber As DataValue) As DataValue
		Return mean(0, column, rowCount() - 1, column, meanNumber)
	End Function

	Const Function DataFile.itemCount(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType) As SizeType
		Dim count As SizeType = 0

		For r As SizeType = r1 To r2
			For c As SizeType = c1 To c2
				If item(r, c) Then
					count += 1
				End If
			Next
		Next

		Return count
	End Function
	
	Const Function DataFile.sum(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType, pow As DataValue) As DataValue
		Dim theSum As DataValue = 0.0

		For r As SizeType = r1 To r2
			For c As SizeType = c1 To c2
				Var itemValue = item(r, c)

				If itemValue Then
					theSum += itemValue ^ pow
				End If
			Next
		Next

		Return theSum
	End Function

	Const Function DataFile.mean(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType, meanNumber As DataValue) As DataValue
		Dim theMean As DataValue = 0.0
		Dim n As SizeType = 0

		For r As SizeType = r1 To r2
			For c As SizeType = c1 To c2
				Var itemValue = item(r, c)

				If itemValue Then
					n += 1
					theMean += itemValue ^ meanNumber
				End If
			Next
		Next

		Return (theMean / n) ^ (1.0 / meanNumber)
	End Function
	
	Function DataFile.reload() as Boolean
		If 0 = Len(m_file) Then
			Return False
		EndIf
		
		Var inFile = FreeFile()
		
		Open m_file For Input As inFile
		
		If Err Then
			Return False
		End If
		
		Dim inLine as String
		m_data.clear()
		
		While Not Eof(infile)
			Line Input #inFile, inLine
			Dim row as OptionalValueVector
			Var startPos = 0

			Do
				Var endPos = InStr(startPos + 1, inLine, ",")
				
				If 0 = endPos Then
					endPos = Len(inLine) + 1
				EndIf
				
				If endPos = startPos Then
					Exit Do
				End If
				
				' TODO check for non-numeric
				row &= Val(Mid(inLine, startPos + 1, endPos - startPos - 1))
				startPos = endPos
			Loop
			
			m_data &= row
		Wend
		
		Close inFile
		Return True
	End Function

End Namespace
