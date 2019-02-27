# MirkoBash
Obsługa mikrobloga z poziomu terminala Unix.

# Zależności
Skrypt wymaga zainstalowanej aplikacji `cURL` (dla Debian/Ubuntu: `sudo apt-get install curl`).

# Konfiguracja
Konfiguracja skryptu nie jest trudna:

### Konfiguracja wstępna
Na początek można odpalić skrypt, by stworzył konfigurację. Tworzony jest folder `mirkobash` w `~/.config`, a w nim plik konfiguracyjny `mirkobash.conf`, do którego wrzucone zostają podstawowe zmienne, które użytkownik musi uzupełnić.

### Uzupełnienie konfiguracji
Użytkownik musi uzupełnić konfigurację skryptu, edytując plik `~/.config/mirkobash/mirkobash.conf`.

Na początek należy [stworzyć swoją aplikację poprzez Wykop](https://www.wykop.pl/dla-programistow/twoje-aplikacje/) i połączyć ją ze swoim kontem. Nadać uprawnienia należy wedle własnego uznania, ale aby wykorzystać możliwości skryptu wymagane są uprawnienia do logowania i do dostępu do mikrobloga. 

Po stworzeniu aplikacji i połączeniu jej ze swoim kontem należy przekopiować podane tam klucze do pliku konfiguracyjnego skryptu. Ma on wyglądać następująco, analogicznie do danych podanych przez Wykop:

```
### Config for MirkoBash
secret="Sekret"
appkey="Klucz"
token="Połącznie"
userkey=""
```

Userkey zostawiamy pusty.

Pierwszą rzeczą wymaganą do obsługi mikrobloga jest zalogowanie się użytkownika. W tym celu należy wywołać skrypt z parametrem `--login`.

```
./mirkobash.sh --login
```

Użytkownik zostanie zapytany o login i hasło. Dla zachowania bezpieczeństwa użytkownika, podczas wpisywania danych znaki nie pokazują się na ekranie. Wpisane dane należy zatwierdzić klawiszem Enter.

```
Enter login:
Enter password:
Logged in successfully
```

Po zalogowaniu się skrypt uzupełni `userkey` w pliku konfiguracyjnym. Zazwyczaj czas ważności tego kodu to 24 godziny (zależne od Wykopu).

## Automatyczne logowanie
Skrypt obsługuje automatyczne logowanie. Jeśli stworzymy plik `login.conf` w katalogu `~/.config/mirkobash/` i uzupełnimy go o swój login i hasło, nie trzeba będzie wpisywać tych informacji za każdym razem wywołując skrypt z parametrem `--login`. Nie będę jednak polecać tego sposobu, jako że hasła są zapisane w tym pliku czystym tekstem i każdy użytkownik może je odczytać. 

Ten plik konfiguracyjny powinien wyglądać następująco:
```
### Login data for MirkoBash
LOGIN="loginDoWykopu"
PASSWORD="mojeSuperTrudneHaslo"
```

# Obsługa skryptu
MirkoBash ma na tą chwilę niewiele funkcji, ale jest też prosty w obsłudze. Możliwości skryptu:

### `--login`
Opisane wyżej. Służy do zalogowania użytkownika na Wykopie.

### `--post`
`./mirkobash.sh --post "treść"` - polecenie to wysyła posta o podanej treści. Należy pamiętać, żeby treść zawrzeć w cudzysłowiu. Jeśli tekst, który chcemy wysłać, zawiera cudzysłowia, każdy z nich należy poprzedzić znakiem `\`, np. `a wtedy powiedział \"usuń konto\"`.

Można też wysłać zawartość podanego pliku. W tym celu składnia może wyglądać następująco:

`./mirkobash.sh --post "$(cat loremipsum.txt)"` - jak widać, wywołanie odczytania pliku też należy zawrzeć w cudzysłowiu. W innym wypadku zostanie wysłane tylko pierwsze słowo pliku.

Przy pomocy programu `at` (`sudo apt-get install at`) możemy zaplanować wysłanie postu na określoną godzinę. W tym celu zapraszam do zapoznania się z [instrukcją obsługi](https://linux.die.net/man/1/at) tego programu.

To samo można osiągnąć przy użyciu `crontab`.

### `--hot`
Parametr `--hot` służy do przeglądania gorących wpisów. Zwraca ID, autora, datę i godzinę, ilość plusów, i ewentualnie treść i załącznik (nie wszystkie wpisy posiadają treść i nie wszystkie mają załącznik).

Aby poprawnie uzyć tego parametru należy wpisać np:

`./mirkobash.sh --hot 1 24` - gdzie `1` to strona pierwsza (może być druga czy dziesiąta), a `24` to okres czasu w godzinach, z których chcemy pobrać gorące wpisy.

Zwrot będzie wyglądać w następujący sposób:

```
ID wpisu: 21372137
Autor: Bielecki
Data: 2019-02-27 00:21:37
Ilość plusów: 2137

Treść wpisu

Ten wpis zawiera załącznik dostępny tutaj: <link>

Czytać dalej? (Y/n/+)  
```

Jeśli użytkownik będzie potwierdzać, że chce czytać dalej, skrypt wypisze wszystkie wpisy z podanej strony, po czym zakończy działanie.

Użytkownik może w każdej chwili przerwać przeglądanie odpowiadając literą `n` na pytanie "Czytać dalej", lub przerywając działanie skryptu kombinacją `^C`.

#### Plusowanie
Podczas przeglądania wpisów użytkownik może zdecydować by dać plus wpisowi. W takiej sytuacji na pytanie "Czytać dalej" może odpowiedzieć znakiem `+`, który spowoduje zaplusowanie wpisu i wyświetlenie kolejnego.

### `--hot_stats`
Parametr `--hot_stats` służy do pobrania podstawowych informacji o gorących wpisach. Zwraca ID wpisu, datę i godzinę jego wstawienia oraz ilość plusów, które otrzymał.

Aby poprawnie użyć tego parametru należy skrypt wywołać np. w ten sposób:
`./mirkobash.sh --hot_stats 1 24` - gdzie `1` to strona pierwsza (może być druga czy dziesiąta), a `24` to okres czasu w godzinach, z których chcemy pobrać informacje o gorących wpisach. Okres czasu jest ustalany przez serwis Wykop, dlatego mimo że skrypt przyjmie każdą wartość, to Wykop ograniczy go do 24h, 12h lub 6h (z tego co mi wiadomo poprawnie działają też parametry od 1 do 5 godzin).

Zwrócone informacje będą wyglądać w ten sposób:

```
ID		Date - time Votes
39085313  2019-02-19 09:47:30  1303 
39083943  2019-02-19 07:26:09  198 
39074485  2019-02-18 20:17:56  1401 
39070287  2019-02-18 17:16:49  1681 
39083285  2019-02-19 04:21:04  321 
39085717  2019-02-19 10:25:12  1397 
39083929  2019-02-19 07:22:30  1477 
39085849  2019-02-19 10:34:39  970 
39074575  2019-02-18 20:20:50  293 
```
