Namespace Statistics
	#include once "Types.bi"

	Type OptionalValue
		Public:
			Declare Constructor
			Declare Constructor(As DataValue)
			
			Declare Const Operator Cast() As Double
			Declare Const Operator Cast() As Single
			Declare Const Operator Cast() As Short
			Declare Const Operator Cast() As Integer
			Declare Const Operator Cast() As Long
			Declare Const Operator Cast() As Longint
			Declare Const Operator Cast() As UShort
			Declare Const Operator Cast() As UInteger
			Declare Const Operator Cast() As ULong
			Declare Const Operator Cast() As ULongint
			Declare Const Operator Cast() As Boolean
			Declare Operator Let(value As DataValue)
			
			Declare Sub clear()
			Declare Const Function value() As DataValue
			Declare Const Function hasValue() As Boolean
			
		Private:
			Dim m_value As DataValue = 0.0
			Dim m_hasValue As Boolean = false
	End Type

	Declare Operator *(ByRef As OptionalValue) As DataValue
	Declare Operator Not(ByRef As OptionalValue) As Boolean

End Namespace
