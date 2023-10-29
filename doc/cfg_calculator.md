# UT-88 Calculator Add-On

The calculator add-on is a valuable extension for the UT-88 computer, introducing a 2k ROM at the memory address range `0x0800`-`0x0fff`. This calculator add-on significantly expands the computational capabilities of the UT-88 computer, enabling users to perform advanced mathematical operations and trigonometric calculations with ease. The ROM contains a set of functions designed to work with floating-point values, offering a wide range of mathematical operations. 

- **Arithmetic Operations**: The calculator ROM provides support for basic arithmetic operations, including addition (+), subtraction (-), multiplication (*), and division (/) of floating point values.
- **Trigonometric Functions**: Users can also access trigonometric functions, such as sine (sin), cosine (cos), tangent (tg), cotangent (ctg), arcsine (arcsin), arccosine (arccos), arctangent (arctg), and arccotangent (arcctg). These functions are computed using Taylor series calculations.

The calculator ROM operates with 3-byte floating-point numbers, each consisting of an 8-bit signed exponent and a 16-bit signed mantissa. These numbers are represented in Sign-Magnitude form, enhancing user-friendliness and simplifying the process of handling them as a whole or working with their individual parts (exponent and mantissa).

It's important to note that the calculator ROM does not include built-in functionality for converting these floating-point numbers to or from decimal form. Users are expected to work with these numbers in their hexadecimal representation.

The choice of 3-byte floating-point values strikes a balance between accuracy and computational efficiency. Basic arithmetic calculations are executed quite fast, enabling users to develop their own calculation algorithms based on the provided building blocks. However, some of the trigonometric functions involve high exponent values, numerous multiplications, and divisions, resulting in reduced accuracy for certain values (approximately ±0.01) and longer execution times (exceeding 10 seconds).

It's important to note that the ROM offers a set of functions with fixed starting addresses. Unlike modern programming approaches, where parameters and results are typically passed via stack or registers, these functions expect parameters and store results at specific, predetermined memory addresses. This design choice adds complexity to client programs, which must manage the copying of values to and from these specific addresses.

While the use of fixed memory addresses may present challenges, it allows for efficient use of the limited resources and capabilities of the UT-88 computer, making the most of its computational power and expanding its functionality for mathematical operations.

The disassembly of the calculator ROM can be found [here](disassembly/calculator.asm). Refer to the disassembly for parameters/result addresses, as well as for algorithm explanation. 

Functions in the library are:
- `0x0849` - add two 1-byte integers in Sign-Magnitude representation
- `0x0877` - Normalize two 3-byte floats before adding
- `0x08dd` - Add two 2-byte integers in Sign-Magnitude representation.
- `0x092d` - Normalize exponent
- `0x0987` - Add two 3-byte floats
- `0x0994` - Multiply two 2-byte mantissa values
- `0x09ec` - Multiply two 3-byte float values
- `0x0a6f` - Divide two 3-byte float values
- `0x0a98` - Calculate factorial
- `0x0b08` - Raise a floating point value to a integer power
- `0x0b6b` - Logarithm
- `0x0c87` - Sine
- `0x0d32` - Cosine
- `0x0d47` - Arcsine
- `0x0e40` - Arccosine
- `0x0e47` - Tangent
- `0x0e75` - Arctangent
- `0x0f61` - Cotangent
- `0x0f8f` - Arccotangent

To enhance comprehension of 3-byte floating-point numbers and facilitate their usage, a dedicated Python component called [Float](../misc/float.py) was developed. This component enables the conversion of these 3-byte floating-point numbers to and from regular 4-byte floating-point numbers commonly used in computing.

To streamline the process of calling library functions for disassembly and testing purposes, a comprehensive [set of automated tests](../test/test_calculator.py) was designed. These tests are intended not to _validate_ the functionality of the library functions, but rather to execute various branches of the code and assess the accuracy of the results. They serve as valuable tools for analyzing and verifying the behavior and performance of the library functions under different conditions.

Add-on schematics can be found [here](scans/UT18.djvu).

Calculator firmware is a part of the [basic emulator configuration](cfg_basic.md).
