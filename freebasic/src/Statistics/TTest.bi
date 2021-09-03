#include once "Types.bi"
#include once "DataFile.bi"

Namespace Statistics

	Type TTest
		Public:
			Enum TestType
				Paired
				Unpaired
			End Enum
			
			Declare Constructor(ByRef As Const DataFile, As TestType = Paired)
			
			Declare Function data() ByRef As DataFile
			Declare Const Function testType() As TestType
			
			Declare Const Function t() As DataValue
		
		Protected:
			Declare Const Function pairedT() As DataValue
			Declare Const Function unpairedT() As DataValue
			
		Private:
			Dim m_data As DataFile
			Dim m_type As TestType
	End Type

End Namespace
