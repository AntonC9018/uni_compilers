# Laborator 1 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Algoritmul Cocke-Younger-Kasami*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina


> Construiți forma normală Greibach pentru gramatica independentă de context:
> $ G=(V_N, V_T, P, M), V_N=\\{M, L, X, I, A, Y\\}, V_T=\\{v, =,  , , ; \\}, $
> $ P =
> \begin{cases}
> M \rightarrow L \\\\
> L \rightarrow IX \\\\
> X \rightarrow \varepsilon | ;L \\\\
> I \rightarrow v = A \\\\
> A \rightarrow v Y \\\\
> Y \rightarrow \varepsilon | , A \\\\
> \end{cases} $
> Generați un cuvânt alcătuit din 5-7 simboluri. Efectuați analiza sintactică utilizând algoritmul Cocke-Younger-Kasami.

## Construirea unui cuvânt

$ M \xrightarrow{M \rightarrow L} L \\\\
L \xrightarrow{L \rightarrow IX} IX \\\\
IX \xrightarrow{X \rightarrow ;L} I;L \\\\
I;L \xrightarrow{L \rightarrow IX} I;IX \\\\
I;IX \xrightarrow{X \rightarrow \varepsilon} I;I \\\\
I;I \xrightarrow{I \rightarrow v = A} I;v = A \\\\
I;v = A \xrightarrow{A \rightarrow vY} I;v = vY \\\\
I;v = vY \xrightarrow{Y \rightarrow \varepsilon} I;v = v \\\\
I;v = v \xrightarrow{I \rightarrow v = A} v = A;v = v \\\\
v = A;v = v \xrightarrow{A \rightarrow vY} v = vY;v = v \\\\
v = vY;v = v \xrightarrow{Y \rightarrow ,A} v = v, A;v = v \\\\
v = v, A;v = v \xrightarrow{A \rightarrow vY} v = v, vY;v = v \\\\
v = v, vY;v = v \xrightarrow{Y \rightarrow \varepsilon} v = v, v; v = v $


## Normalizarea gramaticii

1. Se elimină $ \varepsilon $.

$ X \rightarrow \varepsilon $, $ Y \rightarrow \varepsilon $.

Substituind $ \varepsilon $ pentru $ X $ și $ Y $ peste tot unde ele apar în alte reguli, primim regulile noi $ L \rightarrow I $ și $ A \rightarrow v $.

$ P_1 ^ {\prime}=
\begin{cases}
M \rightarrow L \\\\
L \rightarrow IX | I \\\\
X \rightarrow ;L \\\\
I \rightarrow v = A \\\\
A \rightarrow v Y | v \\\\
Y \rightarrow , A \\\\
\end{cases} $

2. Se elimină regulile singulare.

$ M \rightarrow L $, $ L \rightarrow I $ sunt cele două reguli singulare.
Substituim definițiile lor acolo unde apar.

$ P_1 ^ {\prime \prime}=
\begin{cases}
M \rightarrow IX | v = A \\\\
L \rightarrow IX | v = A \\\\
X \rightarrow ;L \\\\
I \rightarrow v = A \\\\
A \rightarrow v Y | v \\\\
Y \rightarrow , A \\\\
\end{cases} $

3. Se elimină regulile inutile.

Toate regulile evident sunt utile.


4. Se elimină toate regulile inaccesibile.

Toate regulile evident sunt accesibile.


Putem face o mică optimizare, eliminând cu totul simbolul $ M $, făcând $ L $ simbolul de start.

$ P_1 ^ {\prime \prime \prime}=
\begin{cases}
L \rightarrow IX | v = A \\\\
X \rightarrow ;L \\\\
I \rightarrow v = A \\\\
A \rightarrow v Y | v \\\\
Y \rightarrow , A \\\\
\end{cases} $


## Aducerea la forma normală Chomsky

1. 

$ L \rightarrow v = A \xrightarrow{X_v \rightarrow v \\& X_{=} \rightarrow =} L \rightarrow X_v X_{=} A $.

$ X \rightarrow ;L \xrightarrow{X_{;} \rightarrow ;} X \rightarrow X_{;} L $.

$ I \rightarrow v = A \xrightarrow{X_v \rightarrow v \\& X_{=} \rightarrow =} I \rightarrow X_v X_{=} A $.

etc.

$ P_2 ^ {\prime}=
\begin{cases}
L \rightarrow IX | X_v X_{=} A \\\\
X \rightarrow X_{;} L \\\\
I \rightarrow X_v X_{=} A \\\\
A \rightarrow X_v Y | v \\\\
Y \rightarrow X_{,} A \\\\
X_v \rightarrow v
X_{;} \rightarrow ;
X_{,} \rightarrow ,
X_{=} \rightarrow =
\end{cases} $


1. Aducerea la formă $ A \rightarrow BC $ sau $ A \rightarrow t $, unde $ t \in V_T $.

Regula $ I \rightarrow X_v X_{=} A $ se trasformă în regulile $ I \rightarrow X_v Z_1 $ și $ Z_1 \rightarrow X_{=} A $.

Regula $ L \rightarrow X_v X_{=} A $ se trasformă în regulile $ L \rightarrow X_v Z_1 $.

$ P_2 ^ {\prime \prime}=
\begin{cases}
L \rightarrow I X | X_v Z_1 \\\\
X \rightarrow X_{;} L \\\\
I \rightarrow X_v Z_1 \\\\
A \rightarrow X_v Y | v \\\\
Y \rightarrow X_{,} A \\\\
X_v \rightarrow v
X_{;} \rightarrow ;
X_{,} \rightarrow ,
X_{=} \rightarrow =
Z_1 \rightarrow X_{=} A
\end{cases} $


## Folosirea algoritmului Cocke-Younger-Kasami

Rulez programul meu care aplică algoritmul pe gramatica dată și cuvântul dedus interior.

```
Terminals: v,;,,,=                                                                                     
Enter a word (q to quit): v=v,v;v=v                                                                    
Is part of language? true                                                                              
|v          |=          |v          |,          |v          |;          |v          |=          |v     
|X_v,A      |X_equal    |X_v,A      |X_comma    |X_v,A      |X_semicolon|X_v,A      |X_equal    |X_v,A 
|           |Z_1        |           |Y          |           |           |           |Z_1               
|L,I        |           |A          |           |           |           |L,I                           
|           |Z_1        |           |           |           |X                                         
|L,I        |           |           |           |                                                      
|           |           |           |                                                                  
|           |           |                                                                              
|           |                                                                                          
|L                                                                                                     
```