#include once "OptionalValueVector.bi"

' A custom type to automatically manage a dynamically expanding array of Doubles

Namespace Statistics
	Constructor OptionalValueVector
		' defaults are sufficient
	End Constructor
	
	Constructor OptionalValueVector(theSize As SizeType, ByRef value As Const OptionalValue)
		ReDim This.m_data(theSize)
		This.m_size = theSize
		
		For idx As SizeType = 1 To theSize
			This.m_data(idx) = value
		Next
	End Constructor

	Operator OptionalValueVector.[](idx as SizeType) byref as OptionalValue
		Assert(idx > 0 And idx <= This.m_size)
		Return This.m_data(idx)
	End Operator

	Const Function OptionalValueVector.item(idx As SizeType) ByRef As Const OptionalValue
		Assert(idx > 0 And idx <= This.m_size)
		Return This.m_data(idx)
	End Function

	Operator OptionalValueVector.&=(value as Double)
		This.m_size += 1
		
		If UBound(This.m_data) < This.m_size Then
			ReDim Preserve This.m_data(This.m_size * 1.5)
		End If
		
		This.m_data(This.m_size) = value
	End Operator

	Operator OptionalValueVector.&=(ByRef value as Const OptionalValue)
		This.m_size += 1
		
		If UBound(This.m_data) < This.m_size Then
			ReDim Preserve This.m_data(This.m_size * 1.5)
		End If
		
		This.m_data(This.m_size) = value
	End Operator

	Const Function OptionalValueVector.size() As SizeType
		Return This.m_size
	End Function
	
	Sub OptionalValueVector.clear()
		Redim This.m_data(10)
		This.m_size = 0
	End Sub

End Namespace
