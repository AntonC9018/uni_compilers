Tema: *Gramatici de precedență*.

A realizat: *Curmanschii Anton, MIA2201*.

## Sarcina

$ G=(V_N, V_T, P, S), V_N = \\{S, A, B, C\\}, V_T = \\{a, b,c, d, e \\} $

$ P = \begin{cases}
S \rightarrow A \\\\
A \rightarrow B \\\\
A \rightarrow B c B \\\\
B \rightarrow a \\\\
B \rightarrow b \\\\
B \rightarrow d C \\\\
C \rightarrow A e \\\\
\end{cases} 
$

Construiți matricea relațiilor de precedenţă şi efectuați analiza șirului **dbccdac**.

## Rezolvarea

Gramatica nu are epsilon producții, nu are simboluri inutile sau inaccesibile.

```                                           
Head(S) = {A, B, a, b, d}            
Head(A) = {B, a, b, d}               
Head(B) = {a, b, d}                  
Head(C) = {A, B, a, b, d}            
Head(c) = {}                         
Head(a) = {}                         
Head(b) = {}                         
Head(d) = {}                         
Head(e) = {}   

Tail(S) = {A, B, C, a, b, e}     
Tail(A) = {B, C, a, b, e}        
Tail(B) = {C, a, b, e}           
Tail(C) = {e}                    
Tail(c) = {}                     
Tail(a) = {}                     
Tail(b) = {}                     
Tail(d) = {}                     
Tail(e) = {}    

  | S| A| B| C| c| a| b| d| e| $  
 S|  |  |  |  |  |  |  |  |  |    
 A|  |  |  |  |  |  |  |  | =| >  
 B|  |  |  |  | =|  |  |  | >| >  
 C|  |  |  |  | >|  |  |  | >| >  
 c|  |  | =|  |  | <| <| <|  |    
 a|  |  |  |  | >|  |  |  | >| >  
 b|  |  |  |  | >|  |  |  | >| >  
 d|  | <| <| =|  | <| <| <|  |    
 e|  |  |  |  | >|  |  |  | >| >  
 $|  | <| <|  |  | <| <| <|  |    
```

```
Stack                 Input              Actiune
$                 <   d b c c d a c $    d pus pe stivă
$ < d             <   b c c d a c $      b pus pe stivă
$ < d < b         >   c c d a c $        c > b, se potrivește regula B --> b
$ < d < B         =   c c d a c $        c pus pe stivă
$ < d < B = c         c d a c $          relația c c nu există, input-ul nu se potrivește
```