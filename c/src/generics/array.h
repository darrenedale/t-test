#ifndef GENERIC_ARRAY_H
#define GENERIC_ARRAY_H

#include <stdlib.h>
#include <assert.h>

/**
 * macros that defines a type that is a self-managing "array" of an arbitrary type. This is a very rough polyfill
 * for the absence of generics from the C language. It's far more limited than actual generics, but it serves a
 * purpose.
 * 
 * Example:
 * 
 *     DECLARE_AND_DEFINE_ARRAY_TYPE(doube, DoubleArray)
 * 
 * creates a type 'DoubleArray' that represents an array of doubles.
 * 
 * The following functions are available:
 * 
 * - DoubleArray * newDoubleArray()
 *   Create a new DoubleArray. The array is created on the heap. You can create a DoubleArray on the stack as long
 *   as you immediately call initialiseDoubleArray() with the address of the array and call disposeDoubleArray() with
 *   the address of the array when you no longer need it. Once disposed, the array must not be used unless you
 *   re-initialise it. It is recommended that you stick to heal allocation using this function rather than using
 *   stack allocation unless you really need the slight speed benefit you gain from stack allocation (e.g. you're
 *   allocating arrays inside a tight loop).
 *
 * - void initialiseDoubleArray(DoubleArray * arr)
 *   Initialise the internal state of an array. You only need to use this for arrays you create on the stack. Arrays
 *   you create on the heap using newDoubleArray() are initialised automatically.
 *
 * - void freeDoubleArray(DoubleArray **)
 *   Free a DoubleArray created with newDoubleArray(). Pass it the address of the pointer returned by newDoubleArray()
 *   and it will completely deallocate the array, and the pointer you received from newDoubleArray() will become null.
 *
 * - void disposeDoubleArray(DoubleArray * arr)
 *   Dispose of the internal state of an array. You only need to use this for arrays you create on the stack when you
 *   no longer need them. You *must* call this before the stack-allocated array goes out of scope otherwise you will
 *   leak memeory. You do not need to use this function for arrays you create using newDoubleArray() - freeDoubleArray()
 *   will do all the necessary disposal for you when you call it.
 *
 * - int getDoubleArrayCapacity(DoubleArray * arr)
 *   Fetch the capacity of an array. The capacity is the number of items to which its size can expand before it needs
 *   to reallocate its internal storage.
 *
 * - int getDoubleArraySize(DoubleArray * arr)
 *   Fetch the size of an array. The size is the number of items currently in the array.
 *
 * - double getDoubleArrayItem(DoubleArray * arr, int idx)
 *   Fetch an item from the array. The provided index is 0-based, so must be from 0 .. size - 1. The provided index
 *   will not be bounds checked - it is your responsibility to check the size of the array before fetching from it.
 *
 * - void setDoubleArrayItem(DoubleArray * arr, int idx, double value)
 *   Set the value of an item in the array. The provided index is 0-based, so must be from 0 .. size - 1. The
 *   provided index will not be bounds checked - it is your responsibility to check the size of the array before
 *   fetching from it. You can't use this function to expand the size of the array - use appendToDoubleArray() for
 *   that.
 * 
 * - void setDoubleArrayCapacity(DoubleArray * arr, int capacity)
 *   Explicitly set the capacity of an array. The capacity must be > 0. If you set the capacity to less than the
 *   current size of the array, the array's content will be truncated.
 *
 * - void appendToDoubleArray(DoubleArray * arr, double value)
 *   Append a value to the end of the array. The array will automatically have its capacity expanded if it is full to
 *   its current capacity.
 * 
 * There are a lot of potentially useful functions that are missing. The above functions are those required for the
 * current use case.
 * 
 * The example type 'DoubleArray' that represents an array of double values has been used in the above API definition.
 * Substitute these for the name and type you provide to the macro for your own invocations. So if you use
 * 
 *     DEFINE_ARRAY_TYPE(int, IntArray)
 * 
 * Then the function to retrieve an item from the array will be:
 * 
 *     int getIntArrayItem(IntArray * arr, int idx)
 * 
 * The array starts with a capacity of 10. Whenever it needs to increase its capacity, it does so by a factor of 1.5.
 * So by default the array capacity will increase as items are appended to 15, 22, 33, 49 and so on. You can set the
 * capacity directly if you know you are going to append a number of items beyond its current capacity. Setting the
 * capacity lower than the array's size will truncate the array. It cannot have its capacity set lower than 1.
 * 
 * The above example both declares and defines your custom array type. This is useful for when the declaration and
 * definition of the array type need to exist within the same translation unit (i.e. you are just using it internally
 * in a single source file). If you need to declare re-usable types in the usual .h/.c way, use DECLARE_ARRAY_TYPE()
 * in the header file and DEFINE_ARRAY_TYPE() with the same arguments in the related source file. For example:
 * 
 * doublearray.h:
 * 
 *     #ifndef DOUBLEARRAY_H
 *     #define DOUBLEARRAY_H
 *
 *     #include "array.h"       // this header file
 *
 *     DECLARE_ARRAY_TYPE(double, DoubleArray)
 * 
 *     #endif
 * 
 * doublearray.c
 * 
 *     #include "doublearray.h"
 * 
 *     DEFINE_ARRAY_TYPE(double, DoubleArray)
 *
 * Then just use doublearray.h and doublearray.c as you would any other pair of .h/.c files as if you'd written them
 * normally. (i.e. usually this means you add doublearray.c to your compiled sources, and #include doublearray.h
 * wherever you want to use your DoubleArray type.)
 */
#define DECLARE_ARRAY_TYPE(StoredType, ArrayTypeName)    \
struct array_##ArrayTypeName##_s    \
{    \
    int capacity;    \
    int size;    \
    StoredType * data;    \
};    \
    \
typedef struct array_##ArrayTypeName##_s ArrayTypeName;    \
    \
ArrayTypeName * new##ArrayTypeName();    \
void initialise##ArrayTypeName(ArrayTypeName *); \
void free##ArrayTypeName(ArrayTypeName **);    \
void dispose##ArrayTypeName(ArrayTypeName *);    \
int get##ArrayTypeName##Capacity(ArrayTypeName *);    \
int get##ArrayTypeName##Size(ArrayTypeName *);    \
StoredType get##ArrayTypeName##Item(ArrayTypeName *, int idx);    \
void set##ArrayTypeName##Item(ArrayTypeName *, int, StoredType);    \
void set##ArrayTypeName##Capacity(ArrayTypeName * arr, int);    \
void appendTo##ArrayTypeName(ArrayTypeName *, StoredType);

#define DEFINE_ARRAY_TYPE(StoredType, ArrayTypeName)    \
    \
ArrayTypeName * new##ArrayTypeName()    \
{    \
    ArrayTypeName * arr = (ArrayTypeName *) malloc(sizeof(ArrayTypeName));    \
    initialise##ArrayTypeName(arr);    \
    return arr;    \
}    \
    \
void initialise##ArrayTypeName(ArrayTypeName * arr) \
{    \
    arr->capacity = 10;    \
    arr->size = 0;    \
    arr->data = (StoredType *) malloc(arr->capacity * sizeof(StoredType));    \
}    \
    \
void free##ArrayTypeName(ArrayTypeName ** arr)    \
{    \
    dispose##ArrayTypeName(*arr);    \
    free(*arr);    \
    *arr = (ArrayTypeName *) 0;    \
}    \
    \
void dispose##ArrayTypeName(ArrayTypeName * arr)    \
{    \
    free(arr->data);    \
    arr->data = (StoredType *) 0;    \
    arr->capacity = 0;    \
    arr->size = 0;    \
}    \
    \
int get##ArrayTypeName##Capacity(ArrayTypeName * arr)    \
{    \
    return arr->capacity;    \
}    \
    \
int get##ArrayTypeName##Size(ArrayTypeName * arr)    \
{    \
    return arr->size;    \
}    \
    \
StoredType get##ArrayTypeName##Item(ArrayTypeName * arr, int idx)    \
{    \
    assert(0 > idx && idx < arr->size);    \
    return arr->data[idx];    \
}    \
    \
void set##ArrayTypeName##Item(ArrayTypeName * arr, int idx, StoredType value)    \
{    \
    assert(0 > idx && idx < arr->size);    \
    arr->data[idx] = value;    \
}    \
    \
void set##ArrayTypeName##Capacity(ArrayTypeName * arr, int capacity)    \
{    \
    assert(0 < capacity);    \
    \
    if (capacity == arr->capacity) {    \
        return;    \
    }    \
    \
    arr->data = (StoredType *) realloc(arr->data, capacity);    \
    \
    if (capacity < arr->size) {    \
        arr->size = arr->capacity;    \
    }    \
    \
    arr->capacity = capacity;    \
}    \
    \
void appendTo##ArrayTypeName(ArrayTypeName * arr, StoredType value)    \
{    \
    if (arr->size == arr->capacity) {    \
        int newCapacity = arr->capacity * 1.5;    \
    \
        /* in case capacity has been set to < 2 externally */    \
        if (newCapacity == arr->capacity) {    \
            ++newCapacity;    \
        }    \
    \
        set##ArrayTypeName##Capacity(arr, newCapacity);    \
    }    \
    \
    arr->data[arr->size] = value;    \
    ++arr->size;    \
}

#endif

#define DECLARE_AND_DEFINE_ARRAY_TYPE(StoredType, ArrayTypeName)    \
DECLARE_ARRAY_TYPE(StoredType, ArrayTypeName)    \
DEFINE_ARRAY_TYPE(StoredType, ArrayTypeName)
