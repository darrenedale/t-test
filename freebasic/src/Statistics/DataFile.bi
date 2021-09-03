#include once "Types.bi"
#include once "DataTable.bi"
#include once "OptionalValue.bi"

Namespace Statistics

	Type DataFile
		Public:
			Declare Constructor(byref as const String = "")

			Declare Const Function rowCount() As SizeType
			Declare Const Function columnCount() As SizeType

			Declare Const Function item(row As SizeType, column As SizeType) As OptionalValue

			Declare Const Function itemCount() As SizeType
			Declare Const Function rowItemCount(row As SizeType) As SizeType
			Declare Const Function columnItemCount(column As SizeType) As SizeType

			Declare Const Function sum(pow As DataValue = 1.0) As DataValue
			Declare Const Function rowSum(row As SizeType, pow As DataValue = 1.0) As DataValue
			Declare Const Function columnSum(column As SizeType, pow As DataValue = 1.0) As DataValue

			Declare Const Function mean(meanNumber As DataValue = 1.0) As DataValue
			Declare Const Function rowMean(row As SizeType, meanNumber As DataValue = 1.0) As DataValue
			Declare Const Function columnMean(column As SizeType, meanNumber As DataValue = 1.0) As DataValue

		Protected:
			Declare Const Function itemCount(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType) As SizeType
			Declare Const Function sum(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType, pow As DataValue = 1.0 ) As DataValue
			Declare Const Function mean(r1 As SizeType, c1 As SizeType, r2 As SizeType, c2 As SizeType, meanNumber As DataValue = 1.0) As DataValue
			Declare Function reload() as Boolean

		Private:
			m_file as String
			Dim m_data as DataTable
	End Type

End Namespace
