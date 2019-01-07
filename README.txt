To run the program- compile compiler.hs with GHC or your Haskell compiler of choice and then run the program in the command line with the file to be translated as a command line parameter. The input must be in the subset of C accepted by the compiler (namely no heap operations like pointers, or structs). The output will be another C file in a written in a von Neumann like subset which can be compiled and run for the same effect as teh original program.

The program works in much the same way as the translator:
First the translator module is given the file name.
This is passed to the Scanner module, which opens the file and reads it.
Using pattern matching and recursive iteration, the Scanner module runs through the the entire file and produces a list of Tokens.
This is all assuming that there are no malformed tokens, however, if there are malformed tokens, an error is raised.
The translator then takes this list and copies all the comments to stdout.
It then calls the program method to begin the parse.
The parse/translation methods all take a "Token Iterator" (A tuple containing the contents of the next token, the list of the the remaining tokens, and an integer indicating the progress through the list).
The methods also take a table, which is a symbol table with all the mappings.
The methods in return give back a tuple of a TokenIterator, a string containing all the translated program to this point, and the name table.
The program proceeds using the same productions used in the parser provided for A4.
At the end of the call, the code generated is printed to the console.
In order to predict which production to use, there is a separate ParseTable module which contains the first and follow sets for each of the productions.
These sets are combined using the predict function.
The inclusion of the next token in this predict set is used to decied which production to use.

the primary differences come in function calls and in variable name translation.
Instead of providing global[x], the compiler provides mem[x] and sets base/top to start after them.
Instead of providing local[x], the compiler provides mem[base + x].
Instead of providing param, the compiler provides mem[base - (numParams - param.Index + 4)].
The function calls use and augmented FAV order for storing for bookeeping (Frame base, return address, return value, and the newly added frame top). 
Since the program as it stands does not know how many blocks the whole program uses when it is processing an expression, as such, attempts to use this number results in the top being underallocated. To fix this problem, a fourth bookeeping item was added, the top (top is added after parameters have been added so it is original top plus parameters).
Other than that, the caller pre-jump, caller post-jump, callee prologue, and callee epilogue occur much as outline in the slides.
In the caller pre-jump, the program:
	1. Stores the parameters in ascending order (i.e. first parameter goes in top, second in top+1, etc.) and adjusts the top accordingly
	2. Stores the base at the new top.
	3. Stores the return label (using the GNU labels as values extension, this is why the mem array is an array of longs), in top + 1.
	4. Stores the top at top + 3.
	5. Increases the value of top by 4 (leaving top + 2 empty for the return value).
	6. Jumps to the function (all function labels are the functions name plus "Func" (i.e. main is mainFunc)).
In the caller post-jump, the program:
	1. Sets the base to be the value stored at top - 4.
	2. Sets the top to be the value stored at top -1.
	3. Sets the location the return value is desired to top + 2.
In the callee prologue, the program:
	1. Sets the base to be equal to the top.
	2. Sets the top to be equal to the base plus the number of blocks required by the function.
In the callee epilogue, the program:
	1. Sets the top equal to the base.
	2. Goes to the label stored at base - 3 (goto *mem[base-3]).
The last item of note is how the main function is handled.
At the top of the main function (the actual one output by the program, not the one given as input, which will be referred to as mainFunc for clarity) base and top are instantiated.
Then a full caller pre-jump is performed, with the label exit as the return address.
Then the program gotos mainFunc.
Beneath this goto is the label exit, and below the label is the code exit(0);. 
This means that the program does not have to handle main functions differently and instead just has them go to a section of code that ends the program.

The following are the test files and the result of running the compiler on them (Note that while a program may be successful, it can still exceed the memory allotted by the program, 200,000 blocks are normally allotted, which has been more than enough for my purposes, if a program that is said to work does not for larger inputs, this may be the cause):
ab.c - Success
automoton.c - Success
loop_while.c - Success
mandel.c - Success
MeaningOfLife.c - Success
tax.c - Success
