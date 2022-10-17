# Laborator 1 la Teoria Compilării și Semantica Limbajelor de Programare

Tema: *Forma normală Greibach*.

A realizat: *Curmanschii Anton, MIA2201*.

Varianta: *5*.


## Sarcina


> Construiți forma normală Greibach pentru gramatica independentă de context:
> $ G = (\\{E, T, F, G, H\\}, \\{+, -, *, /, n, m, h\\}, P, E) $, unde 
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

Avem două simboluri ce trec în $ \varepsilon $, $ M_0 = \\{ T, F \\} $.

În $ M_1 $ vom adăuga toate simbolurile care trec în unul sau mai multe simboluri din $ M_0 $, și toate elementele din $ M_0 $. $ M_1 = \\{ T, F, E \\}$. Nu mai avem simboluri care trec în $ E $.

Acum se substituie toate aparițiile elementelor din $ \\{ M_1 \\} $ în orice alte reguli la $ \varepsilon $. Se mai adaugă și regula $ E \rightarrow \varepsilon $, deoarece $ E \in M_1 $ și $ E $ este regula de start.

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

## Aducerea la forma Greibach

Începem cu gramatica din pasul normalizării:

$ G = (\\{E, T, F, H\\}, \\{+, -, *, /, n, m, h\\}, P, E) \\\\
P _ G =
\begin{cases}
E \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ | E + T | E - T | m | +T | E+ | -T | E- | \varepsilon \\\\
T \rightarrow Hm | Fn | n | F \* T | F / T | \*T | F\* | /T | F/ \\\\
F \rightarrow Hm | Fn | n \\\\
H \rightarrow Hh | h \\\\
\end{cases}
$

Performăm substituirile:

$ E \rightarrow A_0 \\\\
T \rightarrow A_1 \\\\
F \rightarrow A_2 \\\\
H \rightarrow A_3
$


$ P _ G ^ {1 \prime} =
\begin{cases}
A_0 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ | A_0 + A_1 | A_0 - A_1 | m | +A_1 | A_0+ | -A_1 | A_0- | \varepsilon \\\\
A_1 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3 m | A_2 n | n \\\\
A_3 \rightarrow A_3 h | h \\\\
\end{cases}
$

> 1. Se elimină recursia stângă.

Avem 4 instanțe de recursie stângă pentru 4 reguli ai neterminalululi $ A_0 $: $ A_0 \rightarrow A_0 + A_1 | A_0 - A_1 | A_0 + | A_0 - $.

Ca să elimine recursia stângă, se adaugă o regulă $ X_0 \rightarrow + A_1 | + A_1 X_0 | - A_1 | - A_1 X_0 | + | + X_0 | - | - X_0 $, și se adaugă regulile modifice $ A $ la $ A_0 \rightarrow A_3 m X_0 | A_2 n X_0 | n X_0 | A_2 \* A_1 X_0 | A_2 / A_1 X_0 | \* A_1 X_0 | A_2 \* X_0 | /A_1 X_0 | A_2/ X_0 | m X_0 | + A_1 X_0| - A_1 X_0 | X_0 $ și se elimine toate regulile recursive.


$ P _ 1 ^ {\prime} =
\begin{cases}
A_0 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ | m | +A_1 | -A_1 | \varepsilon \\\\
A_0 \rightarrow A_3 m X_0 | A_2 n X_0 | n X_0 | A_2 \* A_1 X_0 | A_2 / A_1 X_0 | \* A_1 X_0 | A_2 \* X_0 | /A_1 X_0 | A_2/ X_0 | m X_0 | + A_1 X_0| - A_1 X_0 | X_0  \\\\
X_0 \rightarrow + A_1 | + A_1 X_0 | - A_1 | - A_1 X_0 | + | + X_0 | - | - X_0 \\\\
A_1 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3 m | A_2 n | n \\\\
A_3 \rightarrow A_3 h | h \\\\
\end{cases}
$

În regulile $ A_2 \rightarrow A_2 n $ avem încă o instanță de recursie stângă.
Se adaugă un neterminal $ X_2 \rightarrow n | n X_2 $, eliminăm regula $ A_2 \rightarrow A_2 n $ și adaugăm regulile
$ A_2 \rightarrow A_3 m X_2 | n X_2 $.

$ P _ 1 ^ {\prime \prime} =
\begin{cases}
A_0 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ | m | +A_1 | -A_1 | \varepsilon \\\\
A_0 \rightarrow A_3 m X_0 | A_2 n X_0 | n X_0 | A_2 \* A_1 X_0 | A_2 / A_1 X_0 | \* A_1 X_0 | A_2 \* X_0 | /A_1 X_0 | A_2/ X_0 | m X_0 | + A_1 X_0| - A_1 X_0 | X_0  \\\\
X_0 \rightarrow + A_1 | + A_1 X_0 | - A_1 | - A_1 X_0 | + | + X_0 | - | - X_0 \\\\
A_1 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3 m | n | A_3 m X_2 | n X_2 \\\\
X_2 \rightarrow n | n X_2 \\\\
A_3 \rightarrow A_3 h | h \\\\
\end{cases}
$

Ultima instanță recursiei: $ A_3 \rightarrow A_3 h $.

$ P _ 1 ^ {\prime \prime \prime} =
\begin{cases}
A_0 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ | m | +A_1 | -A_1 | \varepsilon \\\\
A_0 \rightarrow A_3 m X_0 | A_2 n X_0 | n X_0 | A_2 \* A_1 X_0 | A_2 / A_1 X_0 | \* A_1 X_0 | A_2 \* X_0 | /A_1 X_0 | A_2/ X_0 | m X_0 | + A_1 X_0| - A_1 X_0 | X_0  \\\\
X_0 \rightarrow + A_1 | + A_1 X_0 | - A_1 | - A_1 X_0 | + | + X_0 | - | - X_0 \\\\
A_1 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3 m | n | A_3 m X_2 | n X_2 \\\\
X_2 \rightarrow n | n X_2 \\\\
A_3 \rightarrow h | h X_3 \\\\
X_3 \rightarrow h | h X_3 \\\\
\end{cases}
$

Se înlocuiesc $ X_0 \rightarrow A_4, X_2 \rightarrow A_5, X_3 \rightarrow A_6 $.

$ P _ 1 ^ {\prime \prime \prime \prime} =
\begin{cases}
A_0 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ | m | +A_1 | -A_1 | \varepsilon \\\\
A_0 \rightarrow A_3 m A_4 | A_2 n A_4 | n A_4 | A_2 \* A_1 A_4 | A_2 / A_1 A_4 | \* A_1 A_4 | A_2 \* A_4 | /A_1 A_4 | A_2/ A_4 | m A_4 | + A_1 A_4| - A_1 A_4 | A_4  \\\\
A_1 \rightarrow A_3 m | A_2 n | n | A_2 \* A_1 | A_2 / A_1 | \*A_1 | A_2\* | /A_1 | A_2/ \\\\
A_2 \rightarrow A_3 m | n | A_3 m A_5 | n A_5 \\\\
A_3 \rightarrow h | h A_6 \\\\
A_4 \rightarrow + A_1 | + A_1 A_4 | - A_1 | - A_1 A_4 | + | + A_4 | - | - A_4 \\\\
A_5 \rightarrow n | n A_5 \\\\
A_6 \rightarrow h | h A_6 \\\\
\end{cases}
$


> 2. Se aduce la forma $ A_i \rightarrow A_j \alpha, j > i $.

Gramatica deja este în această formă.

