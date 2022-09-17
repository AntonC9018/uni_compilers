# Laborator 1 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Forma normală Greibach*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina


> Construiți forma normală Greibach pentru gramatica independentă de context:
> $ G = (\{E, T, F, G, H\}, \{+, -, *, /, n, m, h\}, P, E) $, unde 
>
> $
> P = \begin{cases}
> E \rightarrow T | E + T | E - T | m \\\\
> T \rightarrow F | F \* T | F / T | \varepsilon \\\\
> F \rightarrow G | Fn | \varepsilon \\\\
> G \rightarrow Hm \\\\
> H \rightarrow Hh | h \\\\
> \end{cases}
> $


## Normalizarea gramaticii

1. Se elimină $ \varepsilon $

Avem două simboluri ce trec în $ \varepsilon $, $ M_0 = \{ T, F \} $.

În $ M_1 $ vom adăuga toate simbolurile care trec în unul sau mai multe simboluri din $ M_0 $, și toate elementele din $ M_0 $. $ M_1 = \{ T, F, E \}$. Nu mai avem simboluri care trec în $ E $.

Acum se substituie toate aparițiile elementelor din $ \{ M_1 \} $ în orice alte reguli la $ \vareplison $. Se mai adaugă și regula $ E \rightarrow \varepsilon $, deoarece $ E \in M_1 $ și $ E $ este regula de start.

$ E \rightarrow E + T \xrightarrow{E \rightarrow \varepsilon} E \rightarrow + T $

$ E \rightarrow E + T \xrightarrow{T \rightarrow \varepsilon} E \rightarrow E + $

$ E \rightarrow E - T \xrightarrow{E \rightarrow \varepsilon} E \rightarrow - T $

$ E \rightarrow E - T \xrightarrow{T \rightarrow \varepsilon} E \rightarrow E - $

$ T \rightarrow F \* T \xrightarrow{F \rightarrow \varepsilon} T \rightarrow \* T $

$ T \rightarrow F \* T \xrightarrow{T \rightarrow \varepsilon} T \rightarrow F \* $

$ T \rightarrow F / T \xrightarrow{F \rightarrow \varepsilon} T \rightarrow / T $

$ T \rightarrow F / T \xrightarrow{T \rightarrow \varepsilon} T \rightarrow F / $

$ F \rightarrow Fn \xrightarrow{F \rightarrow \varepsilon} F \rightarrow n $


$$ P^\prime =
\begin{cases}
E \rightarrow T | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow F | F \* T | F / T | \*T | F\* | /T | F/ \\\\
F \rightarrow G | Fn | n \\\\
G \rightarrow Hm \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$$

2. Se elimină regulile singulare.

Regulile $ F \rightarrow G $, $ T \rightarrow F $, $ E \rightarrow T $ sunt singulare.

Se substituie regula $ F \rightarrow G $ la $ F \rightarrow G_i $, unde $ G_i $ sunt toate părțile din dreapta la regulile lui G.
După aceasta, tot așa se procedează pentru $ T \rightarrow F $ și $ E \rightarrow T $.

$ P ^ {\prime \prime} =
\begin{cases}
E \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ \\\\
F \rightarrow Hm | Fn | n \\\\
G \rightarrow Hm \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

3. Se elimină regulile inaccesibile.

$ E $ este regula de start. $ T $, $ H $ și $ F $ sunt accesibile din $ E $, $ G $ este inaccesibil. $ G $ se elimină.

$ P ^ {\prime \prime \prime} =
\begin{cases}
E \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ \\\\
F \rightarrow Hm | Fn | n \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

4. Se elimină regulile inutile.

Toate regulile trec într-un terminal, deci toate sunt utile.


## Aducerea la forma normală Chomsky

1. 

$ E \rightarrow Hm \xrightarrow{X_m \rightarrow m} E \rightarrow H X_m $.

$ E \rightarrow Fn \xrightarrow{X_n \rightarrow n} E \rightarrow F X_n $.

$ E \rightarrow n \xrightarrow{X_n \rightarrow n} E \rightarrow X_n $.

$ E \rightarrow F \* T \xrightarrow{X_{mul} \rightarrow \*} E \rightarrow F X_{mul} T $.

$ E \rightarrow F / T \xrightarrow{X_{div} \rightarrow /} E \rightarrow F X_{div} T $.

$ E \rightarrow E + T \xrightarrow{X_{plus} \rightarrow +} E \rightarrow E X_{plus} T $.

$ E \rightarrow E - T \xrightarrow{X_{minus} \rightarrow -} E \rightarrow E X_{minus} T $.

$ H \rightarrow Hh \xrightarrow{X_h \rightarrow h} H \rightarrow H X_h $.

etc.

$ P ^ C _ 1 =
\begin{cases}
E \rightarrow H X_m | F X_n | n | F X_{mul} T | F X_{div} T | X_{mul} T | F X_{mul} | X_{div} T | F X_{div} | E X_{plus} T | E X_{minus} T | m | X_{plus} T | E X_{plus} | X_{minus} T | E X_{minus} | \varepsilon \\\\
T \rightarrow H X_m | F X_n | n | F X_{mul} T | F X_{div} T | X_{mul} T | F X_{mul} | X_{div} T | F X_{div} \\\\
F \rightarrow H X_m | F X_n | n \\\\
H \rightarrow H X_h | h \\\\
X_m \rightarrow m   \\\\
X_n \rightarrow n   \\\\
X_{mul} \rightarrow \*   \\\\
X_{div} \rightarrow /     \\\\
X_{plus} \rightarrow +     \\\\
X_{minus} \rightarrow -     \\\\
X_h \rightarrow h   \\\\
\end{cases}
$


2. Se înlocuiască regulile de tipul $ A \rightarrow BCD $.

$ E \rightarrow F X_{mul} T \xrightarrow{ Z_1 \rightarrow X_{mul} T } E \rightarrow F Z_1 $.

$ E \rightarrow F X_{div} T \xrightarrow{ Z_2 \rightarrow X_{div} T } E \rightarrow F Z_2 $.

$ E \rightarrow E X_{plus} T \xrightarrow{ Z_3 \rightarrow X_{plus} T } E \rightarrow E Z_3 $.

$ E \rightarrow E X_{minus} T \xrightarrow{ Z_4 \rightarrow X_{minus} T } E \rightarrow E Z_4 $.

etc.

$ P ^ C _ 2 =
\begin{cases}
E \rightarrow H X_m | F X_n | n | F Z_1 | F Z_2 | X_{mul} T | F X_{mul} | X_{div} T | F X_{div} | E Z_3 | E Z_4 | m | X_{plus} T | E X_{plus} | X_{minus} T | E X_{minus} | \varepsilon  \\\\
T \rightarrow H X_m | F X_n | n | F Z_1 | F Z_2 | X_{mul} T | F X_{mul} | X_{div} T | F X_{div} \\\\
F \rightarrow H X_m | F X_n | n \\\\
H \rightarrow H X_h | h \\\\
X_m \rightarrow m   \\\\
X_n \rightarrow n   \\\\
X_{mul} \rightarrow \*   \\\\
X_{div} \rightarrow /     \\\\
X_{plus} \rightarrow +     \\\\
X_{minus} \rightarrow -     \\\\
X_h \rightarrow h   \\\\
Z_1 \rightarrow X_{mul} T \\\\
Z_2 \rightarrow X_{div} T \\\\
Z_3 \rightarrow X_{plus} T \\\\
Z_4 \rightarrow X_{minus} T \\\\
\end{cases}
$



## Aducerea la formă Greibach

1. Se redenumesc toate elementele neterminale.

$
E \rightarrow A_1 \\\\
T \rightarrow A_2 \\\\
F \rightarrow A_3 \\\\
H \rightarrow A_4 \\\\
X_m \rightarrow A_5 \\\\
X_n \rightarrow A_6 \\\\
X_{mul} \rightarrow A_7 \\\\
X_{div} \rightarrow A_8 \\\\
X_{plus} \rightarrow A_9 \\\\
X_{minus} \rightarrow A_{10} \\\\
X_h \rightarrow A_{11} \\\\
Z_1 \rightarrow A_{12} \\\\
Z_2 \rightarrow A_{13} \\\\
Z_3 \rightarrow A_{14} \\\\
Z_4 \rightarrow A_{15} \\\\
$

$ P ^ G _ 1 =
\begin{cases}
A_1 \rightarrow A_4 A_5 | A_3 A_6 | n | A_3 A_{12} | A_3 A_{13} | A_7 A_2 | A_3 A_7 | A_8 A_2 | A_3 A_8 | A_1 A_{14} | A_1 A_{15} | m | A_9 A_2 | A_1 A_9 | A_{10} A_2 | A_1 A_{10} | \varepsilon \\\\
A_2 \rightarrow A_4 A_5 | A_3 A_6 | n | A_3 A_{12} | A_3 A_{13} | A_7 A_2 | A_3 A_7 | A_8 A_2 | A_3 A_8 \\\\
A_3 \rightarrow A_4 A_5 | A_3 A_6 | n \\\\
A_4 \rightarrow A_4 A_{11} | h \\\\
A_5 \rightarrow m   \\\\
A_6 \rightarrow n   \\\\
A_7 \rightarrow \*   \\\\
A_8 \rightarrow /     \\\\
A_9 \rightarrow +     \\\\
A_{10} \rightarrow -     \\\\
A_{11} \rightarrow h   \\\\
A_{12} \rightarrow A_7 A_2 \\\\
A_{13} \rightarrow A_8 A_2 \\\\
A_{14} \rightarrow A_9 A_2 \\\\
A_{15} \rightarrow A_{10} A_2 \\\\
\end{cases}
$ 

2. Se modifică mulțimea de producții $ P^G_1$ astfel încât toate producțiile de tip $ A_i \rightarrow A_j \beta $ să satisfacă condiția $ j > i $.
    1. Dacă există $ A_i \rightarrow A_k \delta $ pentru care $ k < i $ se substituie cu $ A_i \rightarrow A_l \delta, A_k \rightarrow A_l $.
    2. Dacă există $ A_i \rightarrow A_i \beta $ (recursie de stângă) se elimină recursia stângă.


$ A_1 \rightarrow A_1 A_{14} $. $ 1 \ngtr 1 $, de aceea o înlocuim la 
$ A_1 \rightarrow A_{16} A_{14}; $
$ A_{16} \rightarrow A_1 $.

?????

