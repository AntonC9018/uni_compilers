# Laborator 1 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Forma normală Greibach*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina


> Construiți forma normală Greybach pentru gramatica independentă de context:
> $ G = (\{E, T, F, G, H\}, \{+, -, *, /, n, m, h\}, P, E) $, unde 
>
> $
> P = \begin{cases}
> E \rightarrow T | E + T | E - T | m \\\\
> T \rightarrow F | F * T | F / T | \varepsilon \\\\
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

$ T \rightarrow F * T \xrightarrow{F \rightarrow \varepsilon} T \rightarrow * T $

$ T \rightarrow F * T \xrightarrow{T \rightarrow \varepsilon} T \rightarrow F * $

$ T \rightarrow F / T \xrightarrow{F \rightarrow \varepsilon} T \rightarrow / T $

$ T \rightarrow F / T \xrightarrow{T \rightarrow \varepsilon} T \rightarrow F / $

$ F \rightarrow Fn \xrightarrow{F \rightarrow \varepsilon} F \rightarrow n $

$
P ^ {\prime} = \begin{cases}
E \rightarrow T | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow F | F * T | F / T | *T | F* | /T | F/ \\\\
F \rightarrow G | Fn | n \\\\
G \rightarrow Hm \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

2. Se elimină regulile singulare.

Regulile $ F \rightarrow G $, $ T \rightarrow F $, $ E \rightarrow T $ sunt singulare.

Se substituie regula $ F \rightarrow G $ la $ F \rightarrow G_i $, unde $ G_i $ sunt toate părțile din dreapta la regulile lui G.
După aceasta, tot așa se procedează pentru $ T \rightarrow F $ și $ E \rightarrow T $.

$
P ^ {\prime \prime} = \begin{cases}
E \rightarrow Hm | Fn | n | F * T | F / T | *T | F* | /T | F/ | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow Hm | Fn | n | F * T | F / T | *T | F* | /T | F/ \\\\
F \rightarrow Hm | Fn | n \\\\
G \rightarrow Hm \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

3. Se elimină regulile inaccesibile.

$ E $ este regula de start. $ T $, $ H $ și $ F $ sunt accesibile din $ E $, $ G $ este inaccesibil. $ G $ se elimină.

$
P ^ {\prime \prime \prime} = \begin{cases}
E \rightarrow Hm | Fn | n | F * T | F / T | *T | F* | /T | F/ | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow Hm | Fn | n | F * T | F / T | *T | F* | /T | F/ \\\\
F \rightarrow Hm | Fn | n \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

4. Se elimină regulile inutile.

Toate regulile trec într-un terminal, deci toate sunt utile.


## Aducerea la formă Greibach

1. Se redenumesc toate elementele neterminale.

Redenumim $ (E, T, F, H) \rightarrow (A_0, A_1, A_2, A_3) $.

$ G _ 1 = (\{A_0, A_1, A_2, A_3\}, \{+, -, *, /, n, m, h\}, P, A_0) $

$
P _ 1 = \begin{cases}
A_0 \rightarrow A_3m | A_2n | n | A_2 * A_1 | A_2 / A_1 | *A_1 | A_2* | /A_1 | A_2/ | A_0 + A_1 | A_0 - A_1 | m | +A_1 | A_0+ | -A_1 | A_0- | \varepsilon \\\\
A_1 \rightarrow A_3m | A_2n | n | A_2 * A_1 | A_2 / A_1 | *A_1 | A_2* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3m | A_2n | n \\\\
A_3 \rightarrow A_3h | h \\\\
\end{cases}
$


2. Se modifică mulțimea de producții $ P _ 1 $ astfel încât toate producțiile de tip $ A_i → A_j \beta $ să satisfacă condiția $ j > i $.
    - Dacă există $ A_i \rightarrow A_k \delta $ pentru care $ k < i $ se substituie cu $ A_i \rightarrow A_l {\delta}_1 \delta $, $ A_k \rightarrow A_l {\delta}_1 $.
    - Dacă avem $ A_i \rightarrow A_i \beta $ (recursie de stângă) se elimină recursia stângă.

