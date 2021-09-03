#include once "Types.bi"
#include once "OptionalValue.bi"

Namespace Statistics

	Constructor OptionalValue
		' default state is sufficient
	End Constructor

	Constructor OptionalValue(theValue As DataValue)
		This.m_hasValue = True
		This.m_value = theValue
	End Constructor

	Const Operator OptionalValue.Cast() As Double
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Single
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Short
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Integer
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Long
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Longint
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As UShort
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As UInteger
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As ULong
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As ULongint
		Return This.value()
	End Operator

	Const Operator OptionalValue.Cast() As Boolean
		Return This.hasValue()
	End Operator

	Operator OptionalValue.Let(theValue As DataValue)
		This.m_hasValue = True
		This.m_value = theValue
	End Operator

	Sub OptionalValue.clear()
		This.m_hasValue = False
	End Sub

	Function OptionalValue.value() As DataValue
		Assert(This.hasValue())
		Return This.m_value
	End Function

	Function OptionalValue.hasValue() As Boolean
		return This.m_hasValue
	End Function

	Operator *(ByRef optDouble As OptionalValue) As DataValue
		Return optDouble.value()
	End Operator

	Operator Not(ByRef optDouble As OptionalValue) As Boolean
		return Not optDouble.hasValue()
	End Operator
End Namespace
