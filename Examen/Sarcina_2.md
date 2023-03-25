Tema: *Knuth*.

A realizat: *Curmanschii Anton, MIA2201*.


## Sarcina

Fie gramatica independentă de context 

$ G = (V_N, V_T, P, S), V_N = \\{N, L, B \\}, V_T = \\{0, 1, .\\} $

$ P = \begin{cases}
N \rightarrow L \\\\
N \rightarrow L.L \\\\
L \rightarrow B \\\\
L \rightarrow L B \\\\
B \rightarrow 0 \\\\
B \rightarrow 1 \\\\
\end{cases} $

Utilizând gramatica atributivă a lui D. Knuth cu atributul moştenit `s` (exponent) şi atributele sintetizate `l` (lungime), `v` (valoare) calculați valoarea zecimală a numărului binar `1100.101`.

| Reguli sintactice      | $ v $                 | $ s $                        | $ l $             |
|------------------------|-----------------------|------------------------------|-------------------|
| $ N \rightarrow L    $ | $ v.0 = v.1         $ | $ s.1 = 0                  $ | $               $ |
| $ N \rightarrow L.L  $ | $ v.0 = v.1 + v.3   $ | $ s.1 = 0, s.3 = -l.3      $ | $               $ |
| $ L \rightarrow L B  $ | $ v.0 = v.1 + v.2   $ | $ s.1 = s.0 + 1, s.2 = s.0 $ | $ l.0 = l.1 + 1 $ |
| $ L \rightarrow B    $ | $ v.0 = v.1         $ | $ s.1 = s.0                $ | $ l.0 = 1       $ |
| $ B \rightarrow 1    $ | $ v.0 = 1 * 2^{s.0} $ | $                          $ | $               $ |
| $ B \rightarrow 0    $ | $ v.0 = 0           $ | $                          $ | $               $ |


## Derivarea cuvântului

$ N \xrightarrow{N \rightarrow L.L} L.L $

$ L.L \xrightarrow{L \rightarrow L B} L B.L $

$ L B . L \xrightarrow{L \rightarrow L B} L B B . L $

$ L B B . L \xrightarrow{L \rightarrow L B} L B B B . L $

$ L B B B . L \xrightarrow{L \rightarrow B} B B B B . L $

$ B B B B . L \xrightarrow{B \rightarrow 1} 1 B B B . L $

$ 1 B B B . L \xrightarrow{B \rightarrow 1} 1 1 B B . L $

$ 1 1 B B . L \xrightarrow{B \rightarrow 0} 1 1 0 B . L $

$ 1 1 0 B . L \xrightarrow{B \rightarrow 0} 1 1 0 0 . L $

$ 1 1 0 0 . L \xrightarrow{B \rightarrow 0} 1 1 0 0 . L $

$ 1 1 0 0 . L \xrightarrow{L \rightarrow L B} 1 1 0 0 . L B $

$ 1 1 0 0 . L B \xrightarrow{L \rightarrow L B} 1 1 0 0 . L B B $

$ 1 1 0 0 . L B B \xrightarrow{L \rightarrow B} 1 1 0 0 . B B B $

$ 1 1 0 0 . B B B \xrightarrow{B \rightarrow 1} 1 1 0 0 . 1 B B $

$ 1 1 0 0 . 1 B B \xrightarrow{B \rightarrow 0} 1 1 0 0 . 1 0 B $

$ 1 1 0 0 . 1 0 B \xrightarrow{B \rightarrow 1} 1 1 0 0 . 1 0 1 $


## Arborele sintactic

```mermaid
flowchart TD
A0("N") --> A1("L") & A2(".") & A3("L")
A1 --> A4("L") & A5("B")
A4 --> A6("L") & A7("B")
A6 --> A8("L") & A9("B")
A8 --> A10("B")
A10 --> A11("1")
A9 --> A12("1")
A7 --> A13("0")
A5 --> A14("0")

A3 --> A15("L") & A16("B")
A15 --> A17("L") & A18("B")
A17 --> A23("B")
A23 --> A24("1")
A18 --> A25("0")
A16 --> A26("1")
```


## Derivarea atributelor

![s derivation](s.png)

![v derivation](v.png)

$ 2^3 + 2^2 + 2^{-1} + 2^{-3} = 8 + 4 + 0.5 + 0.125 = 12.625 $
