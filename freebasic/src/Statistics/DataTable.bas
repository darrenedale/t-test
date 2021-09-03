#include once "DataTable.bi"
#include once "OptionalValueVector.bi"

Namespace Statistics

	Operator DataTable.[](idx as SizeType) byref as OptionalValueVector
		Assert(idx > 0 And idx <= This.m_size)
		Return This.m_rows(idx)
	End Operator

	Const Function DataTable.row(idx As SizeType) ByRef As Const OptionalValueVector
		Assert(idx > 0 And idx <= This.m_size)
		Return This.m_rows(idx)
	End Function

	Operator DataTable.&=(value as OptionalValueVector)
		This.m_size += 1
		
		If UBound(This.m_rows) < This.m_size Then
			ReDim Preserve This.m_rows(This.m_size * 1.5)
		End If
		
		This.m_rows(This.m_size) = value
	End Operator

	Function DataTable.size() As SizeType
		Return This.m_size
	End Function
	
	Sub DataTable.clear()
		ReDim This.m_rows(10)
		This.m_size = 0
	End Sub

End Namespace
