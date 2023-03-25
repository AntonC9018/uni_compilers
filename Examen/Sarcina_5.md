Tema: *Sethi-Ullman*.

A realizat: *Curmanschii Anton, MIA2201*.


## Sarcina

Utilizând modelul calculatorului cu 2 registre R_1 şi R_2 generaţi, aplicând algoritmul Sethi-Ullman, codul optimal pentru expresia  $ a - b * d + d / (b + c) $.

## Arborele de derivare

```mermaid
flowchart TD
A0("+ (A0)")
A0 --> A1 & A2
A1("- (A1)")
A1 --> A3 & A4
A3("a (A3)")
A4("* (A4)")
A4 --> A5 & A6
A5("b (A5)")
A6("d (A6)")
A2("/ (A2)")
A2 --> A7 & A8
A7("d (A7)")
A8("+ (A8)")
A8 --> A9 & A10
A9("b (A9)")
A10("c (A10)")
```

## Derivarea atributelor

A0: 3     

A3: 1 (a) 

A1: 2     

A2: 2     

A4: 1     

A9: 1 (b) 

A8: 1     

A10: 0 (c)

A5: 1 (b) 

A7: 1 (d) 

A6: 0 (d) 



## Codul

```
mov R1, a;    
mov R2, b;    
mul R2, d;    
sub R1, R2;   
mov Mem1, R1; 
mov R1, d;    
mov R2, b;    
add R2, c;    
div R1, R2;   
add R1, Mem1; 
```

```mermaid
flowchart LR
A0("gencod(A0, 1)") --> A1("gencod(A1, 1)") & B0("mov Mem1, R1") & A2("gencod(A2, 1)") & B1("add R1, Mem1")
A1 --> A3("gencod(A3, 1)") & A4("gencod(A4, 2)") & B2("sub R1, R2")
A3 --> B3("mov R1, a")
A4 --> A5("gencod(A5, 2)") & A6("mul R2, d")
A5 --> B4("mov R2, b")
A2 --> A7("gencod(A7, 1)") & A8("gencod(A8, 2)") & B8("div R1, R2")
A7 --> B6("mov R1, d")
A8 --> A9("gencod(A9, 2)") & B10("add R2, c")
A9 --> B7("mov R2, b")
```