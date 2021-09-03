#include once "string.bi"
#include once "Statistics/DataFile.bi"
#include once "Statistics/TTest.bi"

Using Statistics

Dim ExitOk As Const Integer = 0
Dim ExitErrMissingTestType As Const Integer = 1
Dim ExitErrMissingDataFile As Const Integer = 2
Dim ExitErrInvalidTestType As Const Integer = 3

' output the content of the data file to stdout
Sub outputDataFile(byref dataFile As Const DataFile)
	For row As ULong = 0 To dataFile.rowCount() - 1
		For column As ULong = 0 To 1
			Var dataItem = dataFile.item(row, column)
			Dim formattedDataItem As String

			If (dataItem) Then
				formattedDataItem = Format(dataItem, "0.000")
			End If
			
			Print Space(10 - Len(formattedDataItem)); formattedDataItem;
		Next
		
		Print ""
	Next
End Sub

' read the test type passed on the command line into the appropriate enumerator
Function parseTestType(ByRef typeStr As Const String, ByRef ok As Boolean = True) As TTest.TestType
	Select Case LCase(typeStr)
		Case "paired"
			ok = True
			Return TTest.Paired
			
		Case "unpaired"
			ok = True
			Return TTest.Unpaired
		
		Case Else
			ok = False
			Return TTest.Paired
	End Select
End Function

' entry point
Dim dataFileName as String
Dim testType As TTest.TestType = TTest.Paired

Scope
	Var idx = 1

	Do
		Var arg = Command(idx)
		
		If 0 = Len(arg) Then
			Exit Do
		End If
		
		Select Case arg
			Case "-t"
				idx += 1
				Var testTypeStr = Command(idx)
				
				If 0 = Len(testTypeStr) Then
					Print "-t requires a test type (paired or unpaired)"
					System(ExitErrMissingTestType)
				End If
				
				Dim ok As Boolean
				testType = parseTestType(testTypeStr, ok)
				
				If Not ok Then
					Print "Test type provided with -t (""" & testTypeStr & """) is not valid (must be one of ""paired"" or ""unpaired"")"
					System(ExitErrInvalidTestType)
				End If

			Case Else
				dataFileName = arg
				Exit Do
		End Select
		
		idx += 1
	Loop
End Scope

If 0 = Len(dataFileName) Then
	Print "No data file specified"
	System(ExitErrMissingDataFile)
End If

Dim testData as DataFile = DataFile(dataFileName)
outputDataFile(testData)
Print "t = "; Format(TTest(testData, testType).t(), "0.000000")
System(ExitOk)
