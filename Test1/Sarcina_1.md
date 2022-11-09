Tema: *Forma normală Greibach*.

A realizat: *Curmanschii Anton, MIA2201*.


## Sarcina


$ G=(V_N, V_T, P, S), V_N = \\{S, A, B, C\\}, V_T = \\{a, b,c,d \\} $

$ P = \begin{cases}
S \rightarrow aSA  |  ab \\\\
A \rightarrow Bab | Ab | b \\\\
B \rightarrow BaC | da \\\\
C \rightarrow cb \\\\
\end{cases} 
$

Construiți forma Normală Greibach.


## Normalizarea gramaticii

1. Se elimină $ \varepsilon $. Nu avem așa reguli.

2. Se elimină regulile singulare. Nu avem așa reguli.

3. Se elimină regulile inaccesibile.

$A$ este accesibil din $S$, $B$ este accesibil din $A$, $C$ este accesibil din $B$. Toate regulile sunt accesibile.

4. Se elimină regulile inutile.

Toate regulile trec într-un terminal, deci toate sunt utile.

## Aducerea la forma Greibach

1. Performăm substituirile:

$ S \rightarrow A_0 \\\\
A \rightarrow A_1 \\\\
B \rightarrow A_2 \\\\
C \rightarrow A_3
$

$ P ^ {\prime} = \begin{cases}
A_0 \rightarrow a A_0 A_1  |  ab \\\\
A_1 \rightarrow A_2 ab | A_1 b | b \\\\
A_2 \rightarrow A_2 a A_3 | da \\\\
A_3 \rightarrow cb \\\\
\end{cases} 
$

2. Se elimină recursia stângă.

Regula $ A_2 \rightarrow A_2 a A_3 $ manifestă recursia stângă.

Adaugăm regula $ X_1 \rightarrow a A_3 $ și $ X_1 \rightarrow a A_3 X_1 $, eliminăm regula $ A_2 \rightarrow A_2 a A_3 $, adaugăm regula $ A_2 \rightarrow d a X_1 $. 

$ P ^ {\prime \prime} = \begin{cases}
A_0 \rightarrow a A_0 A_1  |  a b \\\\
A_1 \rightarrow A_2 a b | A_1 b | b \\\\
A_3 \rightarrow cb \\\\
X_1 \rightarrow a A_3 \\\\
X_1 \rightarrow a A_3 X_1 \\\\
A_2 \rightarrow d a X_1 \\\\
A_2 \rightarrow d a \\\\
\end{cases} 
$

Regula $ A_1 \rightarrow A_1 b $ manifestă recursia stângă.

Adaugăm regula $ X_2 \rightarrow b $, $ X_2 \rightarrow b X_2 $, eliminăm regula $ A_1 \rightarrow A_1 b $, adaugăm regulile $ A_1 \rightarrow A_2 a b X_2 $, $ A_1 \rightarrow b X_2 $.

$ P ^ {\prime \prime \prime} = \begin{cases}
A_0 \rightarrow a A_0 A_1  |  a b \\\\
A_3 \rightarrow cb \\\\
X_1 \rightarrow a A_3 \\\\
X_1 \rightarrow a A_3 X_1 \\\\
A_2 \rightarrow d a X_1 \\\\
A_2 \rightarrow d a \\\\
X_2 \rightarrow b \\\\
X_2 \rightarrow b X_2 \\\\
A_1 \rightarrow A_2 a b X_2 \\\\
A_1 \rightarrow A_2 a b \\\\
A_1 \rightarrow b X_2 \\\\
A_1 \rightarrow b \\\\
\end{cases} 
$

Redenumim $X$-urile: $ X_1 \rightarrow A_4 $, $ X_2 \rightarrow A_5 $.

$ P ^ {\prime \prime \prime \prime} = \begin{cases}
A_0 \rightarrow a A_0 A_1  |  a b \\\\
A_3 \rightarrow cb \\\\
A_4 \rightarrow a A_3 \\\\
A_4 \rightarrow a A_3 A_4 \\\\
A_2 \rightarrow d a A_4 \\\\
A_2 \rightarrow d a \\\\
A_5 \rightarrow b \\\\
A_5 \rightarrow b A_5 \\\\
A_1 \rightarrow A_2 a b A_5 \\\\
A_1 \rightarrow A_2 a b \\\\
A_1 \rightarrow b A_5 \\\\
A_1 \rightarrow b \\\\
\end{cases} 
$

3. Se aduce la forma $ A_i \rightarrow A_j \alpha, j > i $.

Gramatica deja este în această formă.
