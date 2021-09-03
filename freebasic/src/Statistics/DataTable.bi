#include once "Types.bi"
#include once "OptionalValueVector.bi"

Namespace Statistics

	Type DataTable
		Public:
			Declare Operator [] Overload (idx As SizeType) ByRef As OptionalValueVector
			Declare Operator &= (value As OptionalValueVector)
			
			Declare Const Function row(idx As SizeType) ByRef As Const OptionalValueVector
			Declare Const Function size() As SizeType
			Declare Sub clear()
			
		Private:
			ReDim m_rows(10) As OptionalValueVector
			Dim m_size as SizeType = 0
	End Type

End Namespace
