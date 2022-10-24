# Laborator 1 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Gramatici simple de precedență. Parser shift-reduce*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina

Fie gramatica independentă de context 
$ G = (V_N, V_T, P, S), V_N = \\{S, A, B, D \\}, V_T = \\{a,b,c,d\\} \\
\begin{cases}
S \rightarrow A \\\\
A \rightarrow B | AcB \\\\
B \rightarrow a | b | dB \\\\
D \rightarrow Ae \\\\
\end{cases} $
Să se construiască matricea relaţiilor de precedenţă şi să se analizeze şirul *dacbcbeca*.

## Realizarea

Rulez [programul meu](https://github.com/AntonC9018/uni_compilers/blob/5566defe6a0f04e0e39c6494df36b4de62af33d0/code/source/precedence/app.d) la această gramatică:

```
S --> A                          
A --> B                          
A --> AcB                        
B --> a                          
B --> b                          
B --> dD                         
D --> Ae

Head(S) = {A, B, a, b, d}        
Head(A) = {A, B, a, b, d}        
Head(B) = {a, b, d}              
Head(c) = {}                     
Head(a) = {}                     
Head(b) = {}                     
Head(d) = {}                     
Head(D) = {A, B, a, b, d}        
Head(e) = {}                     
Tail(S) = {A, B, a, b, D, e}     
Tail(A) = {B, a, b, D, e}        
Tail(B) = {a, b, D, e}           
Tail(c) = {}                     
Tail(a) = {}                     
Tail(b) = {}                     
Tail(d) = {}                     
Tail(D) = {e}                    
Tail(e) = {}

  | S| A| B| c| a| b| d| D| e| $ 
 S|  |  |  |  |  |  |  |  |  |   
 A|  |  |  | =|  |  |  |  | =| > 
 B|  |  |  | >|  |  |  |  | >| > 
 c|  |  | =|  | <| <| <|  |  |   
 a|  |  |  | >|  |  |  |  | >| > 
 b|  |  |  | >|  |  |  |  | >| > 
 d|  | <| <|  | <| <| <| =|  |   
 D|  |  |  | >|  |  |  |  | >| > 
 e|  |  |  | >|  |  |  |  | >| > 
 $|  | <| <|  | <| <| <|  |  |   

Enter input: dacbcbeca
Stack               Input
$                   d a c b c b e c a $
$ < d               a c b c b e c a $
$ < d < a           c b c b e c a $
$ < d < B           c b c b e c a $
$ < d < A           c b c b e c a $
$ < d < A = c       b c b e c a $
$ < d < A = c < b   c b e c a $
$ < d < A = c = B   c b e c a $
$ < d < A           c b e c a $
$ < d < A = c       b e c a $
$ < d < A = c < b   e c a $
$ < d < A = c = B   e c a $
$ < d < A           e c a $
$ < d < A = e       c a $
$ < d = D           c a $
$ < B               c a $
$ < A               c a $
$ < A = c           a $
$ < A = c < a       $
$ < A = c = B       $
$ < A               $
$   S               $
Input matched
```