#include once "Types.bi"
#include once "OptionalValue.bi"

' A custom type to automatically manage a dynamically expanding array of Doubles

Namespace Statistics

	Type OptionalValueVector
		Public:
			Declare Constructor
			Declare Constructor(size As SizeType, ByRef value As Const OptionalValue = OptionalValue())

			Declare Operator [] (idx As SizeType) ByRef As OptionalValue
			Declare Operator &= (value As DataValue)
			Declare Operator &= (ByRef value As Const OptionalValue)
			
			Declare Const Function item(idx As SizeType) ByRef As Const OptionalValue
			Declare Sub clear()
			Declare Const Function size() As SizeType

		Private:
			ReDim m_data(10) As OptionalValue
			Dim m_size as Long = 0
	End Type

End Namespace
