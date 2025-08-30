| <img width="128" height="128" alt="MKL" src="https://github.com/user-attachments/assets/94f88cc5-5d6a-4660-b0c8-dbfbea3b561b" />  | The Programming System made for Micros |
| ------------- | ------------- |

`MK/L` is a programming language system inspired by 60s-80s computer systems. It's based on the DartmouthBASIC syntax, with portability adaptations and systematic statements.

The language itself is comparable to BASIC.

Hello World Example
Here's a comparison of a simple "Hello, World!" program in both languages:


```
> 10 PRINT "hello"
> RUN
hello
> LIST
   10 PRINT "hello"
> 9 REM This is BASIC

MK/L

* A1: PRINT "hello"
* A2: "This is MK/L
* LIST
  a1   print --str-> "hello"
  a2   This is MK/L
* EXE
hello
```
(> is the BASIC REPL prompt, * is the MK/L REPL prompt)

Comparing Data
Here is an example of comparing data in both languages.
```
BASIC

> 10 LET X = 2
> 20 LET Y = 4
> 30 IF Y < X THEN PRINT "X is greater than Y"
> 40 END

MK/L

* A1: SET X TO 2
* A2: SET Y TO 4
* A3: IF X ?+ Y $$ PRINT "X is greater than Y"
```
Getting Input
This is how you get user input.
```
BASIC

> 10 PRINT "MINIMINIE MINIE..."
> 20 LET MOW = INPUT "? "
> 30 PRINT MOW

MK/L

* A2: PRINT "MINIMINIE MINIE..."
* B2: LET MOW = IN "? "
* A3: PRINT MOW
```
