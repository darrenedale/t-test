#include once "TTest.bi"
#include once "OptionalValueVector.bi"

Namespace Statistics

	Constructor TTest(ByRef theDataFile As Const DataFile, theType As TestType)
		This.m_data = theDataFile
		This.m_type = theType
	End Constructor

	Function TTest.data() ByRef As DataFile
		Return m_data
	End Function

	Const Function TTest.testType() As TestType
		Return m_type
	End Function

	Const Function TTest.t() As DataValue
		Select Case testType()
			Case Paired
				Return pairedT()
				
			Case Unpaired
				Return unpairedT()
				
			Case Else
				' TODO throw exception?
		End Select
	End Function

	Const Function TTest.pairedT() As DataValue
        ' the number of pairs of observations
		Var n = m_data.columnItemCount(0)
        
        ' differences between pairs of observations: (x1 - x2)
		Dim diffs(n) As DataValue
        
        ' squared differences between pairs of observations: (x1 - x2) ^ 2
		Dim diffs2(n) As DataValue
        
        ' sum of differences between pairs of observations: sum[i = 1 to n](x1 - x2)
		Dim sumDiffs As DataValue = 0.0

        ' sum of squared differences between pairs of observations: sum[i = 1 to n]((x1 - x2) ^ 2)
		Dim sumDiffs2 As DataValue = 0.0

		For idx As SizeType = 0 To n - 1
			diffs(idx) = m_data.item(idx, 0).value() - m_data.item(idx, 1).value()
			diffs2(idx) = diffs(idx) * diffs(idx)
			sumDiffs += diffs(idx)
			sumDiffs2 += diffs2(idx)
		Next

		Return sumDiffs / ((((n * sumDiffs2) - (sumDiffs * sumDiffs)) / (n - 1)) ^ 0.5)
	End Function

	Const Function TTest.unpairedT() As DataValue
		' observation counts for each condition
		Var n1 = m_data.columnItemCount(0)
		Var n2 = m_data.columnItemCount(1)
        
		' sums for each condition
		Var sum1 = m_data.columnSum(0)
		Var sum2 = m_data.columnSum(1)
        
		' means for each condition
		Var mean1 = sum1 / n1
		Var mean2 = sum2 / n2

		' sum of differences between items and the mean for each condition
		Dim sumMeanDiffs1 As DataValue = 0.0
		Dim sumMeanDiffs2 As DataValue = 0.0

		For row As SizeType = 0 To m_data.rowCount() - 1
			Var item = m_data.item(row, 0)

			If item Then
				Var x  = *item - mean1
                sumMeanDiffs1 += (x * x)
			End If

			item = m_data.item(row, 1)

			If item Then
				Var x = *item - mean2
                sumMeanDiffs2 += (x * x)
			End If
		Next
		
		sumMeanDiffs1 /= n1
		sumMeanDiffs2 /= n2

		' calculate the statistic
		Return Abs((mean1 - mean2) / (((sumMeanDiffs1 / (n1 - 1)) + (sumMeanDiffs2 / (n2 - 1))) ^ 0.5))
	End Function

End Namespace
