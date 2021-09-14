#include <stdio.h>
#include "generics/array.h"

DECLARE_AND_DEFINE_ARRAY_TYPE(double, DoubleArray)
DECLARE_AND_DEFINE_ARRAY_TYPE(int, IntArray)

int main()
{
    DoubleArray * doubleArray = newDoubleArray();
    appendToDoubleArray(doubleArray, 12.0);
    printf("Array has %d elements\n", getDoubleArraySize(doubleArray));
    freeDoubleArray(&doubleArray);

    IntArray intArray;
    initialiseIntArray(&intArray);
    appendToIntArray(&intArray, 12);
    appendToIntArray(&intArray, 14);
    printf("Array has %d elements\n", getIntArraySize(&intArray));
    disposeIntArray(&intArray);
    return 0;
}
