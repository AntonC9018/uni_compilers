# Laborator 6 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Notația poloneză (postfix)*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina

Fie gramatica independentă de context 

$ G = (V_N, V_T, P, S), V_N = \\{E, T, F \\}, V_T = \\{a ,b, c, +, -, *,/, (, )\\} $

$ P = \begin{cases}
E \rightarrow T \\\\
E \rightarrow E + T \\\\
E \rightarrow E - T \\\\
T \rightarrow T * F \\\\
T \rightarrow T / F \\\\
T \rightarrow F \\\\
F \rightarrow (E) \\\\
F \rightarrow a \\\\
F \rightarrow b \\\\
F \rightarrow c \\\\
\end{cases} $

Aplicând schema de traducere dirijată prin sintaxă cu atributul sintetizat *postfix* construiţi notaţia postfix pentru expresia $ (a + b) / d - a * b - c $.


| Reguli sintactice       | $ p $                   |
|-------------------------|-------------------------|
| $ E \rightarrow T $     | $ p.0 = p.1 $           |
| $ E \rightarrow E + T $ | $ p.0 = p.1 ~ p.3 ~ + $ |
| $ E \rightarrow E - T $ | $ p.0 = p.1 ~ p.3 ~ - $ |
| $ T \rightarrow T * F $ | $ p.0 = p.1 ~ p.3 ~ * $ |
| $ T \rightarrow T / F $ | $ p.0 = p.1 ~ p.3 ~ / $ |
| $ T \rightarrow F $     | $ p.0 = p.1 $           |
| $ F \rightarrow (E) $   | $ p.0 = p.2 $           |
| $ F \rightarrow a $     | $ p.0 = a $             |
| $ F \rightarrow b $     | $ p.0 = b $             |
| $ F \rightarrow c $     | $ p.0 = c $             |


## Derivarea

$ E \xrightarrow{E \rightarrow E - T} E - T $

$ E - T \xrightarrow{E \rightarrow E - T} E - T - T $

$ E - T - T \xrightarrow{E \rightarrow T} T - T - T $

$ T - T - T \xrightarrow{T \rightarrow T / F} T / F - T - T $

$ T / F - T - T \xrightarrow{T \rightarrow (E)} (E) / F - T - T $

$ (E) / F - T - T \xrightarrow{E \rightarrow E + T} (E + T) / F - T - T $

$ (E + T) / F - T - T \xrightarrow{E \rightarrow T} (T + T) / F - T - T $

$ (T + T) / F - T - T \xrightarrow{T \rightarrow F} (F + T) / F - T - T $

$ (F + T) / F - T - T \xrightarrow{F \rightarrow a} (a + T) / F - T - T $

$ (a + T) / F - T - T \xrightarrow{T \rightarrow F} (a + F) / F - T - T $

$ (a + F) / F - T - T \xrightarrow{F \rightarrow b} (a + b) / F - T - T $

$ (a + b) / F - T - T \xrightarrow{F \rightarrow d} (a + b) / d - T - T $

$ (a + b) / d - T - T \xrightarrow{T \rightarrow T * F} (a + b) / d - T * F - T $

$ (a + b) / d - T * F - T \xrightarrow{T \rightarrow F} (a + b) / d - F * F - T $

$ (a + b) / d - F * F - T \xrightarrow{F \rightarrow a} (a + b) / d - a * F - T $

$ (a + b) / d - a * F - T \xrightarrow{F \rightarrow b} (a + b) / d - a * b - T $

$ (a + b) / d - a * b - T \xrightarrow{T \rightarrow F} (a + b) / d - a * b - F $

$ (a + b) / d - a * b - F \xrightarrow{F \rightarrow c} (a + b) / d - a * b - c $


## Arborele sintactic

```mermaid
flowchart TD
A0("E") --> A1("E") & A2("-") & A3("T")
A1 --> A4("E") & A5("-") & A6("T")
A4 --> A7("T")
A7 --> A8("T") & A9("/") & A10("F")
A8 --> A11("(") & A12("E") & A13(")")
A12 --> A14("E") & A15("+") & A16("T")
A14 --> A17("T")
A17 --> A18("F")
A18 --> A19("a")
A16 --> A20("F")
A20 --> A21("b")
A10 --> A22("d")
A6 --> A23("T") & A24("*") & A25("F")
A23 --> A26("F")
A26 --> A27("a")
A25 --> A28("b")
A3 --> A29("F")
A29 --> A30("c")
```

## Derivarea notației postfix

![attribute derivation](p.png)