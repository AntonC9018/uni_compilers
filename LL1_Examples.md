$ P = \begin{cases}
S \rightarrow A \\\\
A \rightarrow A B | a | b \\\\
B \rightarrow A D \\\\
D \rightarrow c | d \\\\
\end{cases}
$

Recursia stângă $ A \rightarrow A B $.
$ A \rightarrow a X | b X $, $ X \rightarrow B X | \varepsilon $

$ P _ 1 = \begin{cases} 
S \rightarrow A \\\\
B \rightarrow A D \\\\
D \rightarrow c | d \\\\
A \rightarrow a X | b X \\\\
X \rightarrow B X | \varepsilon \\\\
\end{cases}
$

SD - simbolul director.

$ SD(A \rightarrow a X) = primul(a X) = \\{ a \\} $

$ SD(A \rightarrow b X) = primul(b X) = \\{ b \\} $

$ SD(S \rightarrow A) = primul(A) = SD(A \rightarrow a X) \cup SD(A \rightarrow b X) = \\{ a, b \\} $

$ SD(B \rightarrow A D) = primul(A) = \\{ a, b \\} $

$ SD(X \rightarrow B X) = primul(B) = \\{ a, b \\} $

$ SD(D \rightarrow c) = \\{ c \\} $

$ SD(D \rightarrow d) = \\{ d \\} $

$ primul(D) = \\{ c, d \\} $

$ SD(X \rightarrow \varepsilon) = urmatorul(X) = urmatorul(A) = urmatorul(S) \cup urmatorul(D) $

După definiție, $ urmatorul(S) = \\{ \\$ \\} $.

$ SD(X \rightarrow \varepsilon) = urmatorul(S) \cup urmatorul(D) = \\{ \\$ \\} \cup \\{ c, d \\} = \\{ c, d, \\$ \\} $.

$ SD(X \rightarrow A) = \\{ a, b \\} $


|   | c | d | a | b | $ |
|---|---|---|---|---|---|
| c | + |   |   |   |   |
| d |   | + |   |   |   |
| a |   |   | + |   |   |
| b |   |   |   | + |   |
| $ |   |   |   |   | A |
| S |   |   |   |   |   |
| A |   |   |   |   |   |
| B |   |   |   |   |   |
| D |   |   |   |   |   |
| X |   |   |   |   |   |

Prima regulă $ S \rightarrow A $.


```mermaid
flowchart TD
A0("S") --> A1          
A1("A") --> A2 & A3     
A2("a")                 
A3("X") --> A4 & A5     
A4("B") --> A6 & A7     
A5("X") --> A12 & A13   
A6("A") --> A8 & A9     
A7("D") --> A11         
A8("b")                 
A9("X") --> A10         
A10("eps")              
A11("d")                
A12("B") --> A14 & A15  
A13("X") --> A20 & A21  
A14("A") --> A16 & A17  
A15("D") --> A19        
A16("a")                
A17("X") --> A18        
A18("eps")              
A19("c")                
A20("B") --> A22 & A23  
A21("X") --> A36        
A22("A") --> A24 & A25  
A23("D") --> A35        
A24("a")                
A25("X") --> A26 & A27  
A26("B") --> A28 & A29  
A27("X") --> A34        
A28("A") --> A30 & A31  
A29("D") --> A33        
A30("b")                
A31("X") --> A32        
A32("eps")              
A33("c")                
A34("eps")              
A35("d")                
A36("eps")              
```


dbaacbaaa

```
S        | d b a a c b a a a
A d      | d b a a c b a a a
A        | b a a c b a a a
X D      | b a a c b a a a
X B b    | b a a c b a a a
X B      | a a c b a a a
X Y a    | a a c b a a a
X Y      | a c b a a a
X B      | a c b a a a
X Y a    | a c b a a a
X Y      | c b a a a
X        | c b a a a
A c      | c b a a a
A        | b a a a
X D      | b a a a
X B b    | b a a a
X B      | a a a
X Y a    | a a a
X Y      | a a
X B      | a a
X Y a    | a a
X Y      | a
X B      | a
X Y a    | a
X Y      | 
X        | 
```

```mermaid
flowchart TD
A0("S") --"S --> d A"--> A1 & A2      
A1("d")                               
A2("A") --"A --> D X"--> A3 & A4      
A3("D") --"D --> b B"--> A5 & A6      
A4("X") --"X --> c A"--> A13 & A14    
A5("b")                               
A6("B") --"B --> a Y"--> A7 & A8      
A7("a")                               
A8("Y") --"Y --> B"--> A9             
A9("B") --"B --> a Y"--> A10 & A11    
A10("a")                              
A11("Y") --"Y --> eps"--> A12         
A12("eps")                            
A13("c")                              
A14("A") --"A --> D X"--> A15 & A16   
A15("D") --"D --> b B"--> A17 & A18   
A16("X") --"X --> eps"--> A28         
A17("b")                              
A18("B") --"B --> a Y"--> A19 & A20   
A19("a")                              
A20("Y") --"Y --> B"--> A21           
A21("B") --"B --> a Y"--> A22 & A23   
A22("a")                              
A23("Y") --"Y --> B"--> A24           
A24("B") --"B --> a Y"--> A25 & A26   
A25("a")                              
A26("Y") --"Y --> eps"--> A27         
A27("eps")                            
A28("eps")                            
```


```
S --> A              
A --> c B            
B --> C d            
C --> D X            
D --> a Y            
X --> b D X          
X --> eps            
Y --> eps            
Y --> c C d     

First(S) = {A, c}    
First(A) = {c}       
First(B) = {C, D, a} 
First(C) = {D, a}    
First(D) = {a}       
First(X) = {b, eps}  
First(Y) = {c, eps}  
First(c) = {c}       
First(d) = {d}       
First(b) = {b}       
First(a) = {a}       
First(eps) = {eps}   

Follow(S) = {$}      
Follow(A) = {$}      
Follow(B) = {$}      
Follow(C) = {d}      
Follow(D) = {d, b}   
Follow(X) = {d}      
Follow(Y) = {d, b}  
```

 - | c              | d            | b               | a            | $
--|----------------|--------------|-----------------|--------------|--
S | $ S --> A$     |              |                 |              |
A | $ A --> c B$   |              |                 |              |
B |                |              |                 | $ B --> C d$ |
C |                |              |                 | $ C --> D X$ |
D |                |              |                 | $ D --> a Y$ |
X |                | $ X --> eps$ | $ X --> b D X $ |              |
Y | $ Y --> c C d$ | $ Y --> eps$ | $ Y --> eps$    |              |


```
Enter input: cabacabadbad                                                                
Stack            Input                                
S                c a b a c a b a d b a d              
A                c a b a c a b a d b a d              
B c              c a b a c a b a d b a d              
B                a b a c a b a d b a d                
d C              a b a c a b a d b a d                
d X D            a b a c a b a d b a d                
d X Y a          a b a c a b a d b a d                
d X Y            b a c a b a d b a d                  
d X              b a c a b a d b a d                  
d X D b          b a c a b a d b a d                  
d X D            a c a b a d b a d                    
d X Y a          a c a b a d b a d                    
d X Y            c a b a d b a d                      
d X d C c        c a b a d b a d                      
d X d C          a b a d b a d                        
d X d X D        a b a d b a d                        
d X d X Y a      a b a d b a d                        
d X d X Y        b a d b a d                          
d X d X          b a d b a d                          
d X d X D b      b a d b a d                          
d X d X D        a d b a d                            
d X d X Y a      a d b a d                            
d X d X Y        d b a d                              
d X d X          d b a d                              
d X d            d b a d                              
d X              b a d                                
d X D b          b a d                                
d X D            a d                                  
d X Y a          a d                                  
d X Y            d                                    
d X              d                                    
d                d                                    
```

```mermaid
flowchart TD
A0("S") --"S --> A"--> A1
A1("A") --"A --> c B"--> A2 & A3
A2("c")
A3("B") --"B --> C d"--> A4 & A5
A4("C") --"C --> D X"--> A6 & A7
A5("d")
A6("D") --"D --> a Y"--> A8 & A9
A7("X") --"X --> b D X"--> A11 & A12 & A13
A8("a")
A9("Y") --"Y --> eps"--> A10
A10("eps")
A11("b")
A12("D") --"D --> a Y"--> A14 & A15
A13("X") --"X --> b D X"--> A31 & A32 & A33
A14("a")
A15("Y") --"Y --> c C d"--> A16 & A17 & A18
A16("c")
A17("C") --"C --> D X"--> A19 & A20
A18("d")
A19("D") --"D --> a Y"--> A21 & A22
A20("X") --"X --> b D X"--> A24 & A25 & A26
A21("a")
A22("Y") --"Y --> eps"--> A23
A23("eps")
A24("b")
A25("D") --"D --> a Y"--> A27 & A28
A26("X") --"X --> eps"--> A30
A27("a")
A28("Y") --"Y --> eps"--> A29
A29("eps")
A30("eps")
A31("b")
A32("D") --"D --> a Y"--> A34 & A35
A33("X") --"X --> eps"--> A37
A34("a")
A35("Y") --"Y --> eps"--> A36
A36("eps")
A37("eps")
```

```
S matched production: S --> A
  A matched production: A --> c B
    c
    B matched production: B --> C d
      C matched production: C --> D X
        D matched production: D --> a Y
          a
          Y matched production: Y --> eps
            eps
        X matched production: X --> b D X
          b
          D matched production: D --> a Y
            a
            Y matched production: Y --> c C d
              c
              C matched production: C --> D X
                D matched production: D --> a Y
                  a
                  Y matched production: Y --> eps
                    eps
                X matched production: X --> b D X
                  b
                  D matched production: D --> a Y
                    a
                    Y matched production: Y --> eps
                      eps
                  X matched production: X --> eps
                    eps
              d
          X matched production: X --> b D X
            b
            D matched production: D --> a Y
              a
              Y matched production: Y --> eps
                eps
            X matched production: X --> eps
              eps
      d
```