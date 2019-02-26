#!/bin/bash

author="Bielecki"
version="0.0.5"
lastupdate="26.02.2019"

## Changelog
#
# 0.0.5 - infos about entries and coloring some shit
# 0.0.4 - moving hot to hot_stats; hot function is now for reading mirko
# 0.0.3 - moved config data to ~/.config/mirkobash/, added polish comments
# 0.0.2 - added hot page scrapping
# 0.0.1 - initial version - post and quick login with userkey updating
#
##

main() {	# funkcja startowa, wywoływana na końcu skryptu, by wpierw załadować ustawienia

if [ -n "$1" ]; then		# użytkownik podał parametr, więc sprawdźmy który to i przenieśmy do odpowiedniej funkcji
	case "$1" in
	--login)	login
		;;
	--post)	shift && post "$@"
		;;
	--hot)	shift && hot "$@"
		;;
	--hot_stats) shift && hot_stats "$@"
		;;
	--help | --usage | -h | -\? | -u)	usage; exit 0
		;;
	* )	usage; exit 1
		;;
	esac
	shift
fi
}


usage() {	# pomoc
printf "%b\n" "MirkoBash v$version by $author" "Last updated: $lastupdate\n"
printf "%s\n" "Dostępne opcje:" \
	"--login: logowanie użytkownika, renowacja klucza" \
	"--post \"(zawartość)\": wrzuca na mirko post z podaną zawartością" \
	"--hot (strona) (czas: 6, 12 lub 24): zwraca ID, datę i ilość plusów postów z gorących"
}

## Sprawdzamy czy config w ogóle istnieje
if [ ! -d "$HOME/.config/mirkobash" ]; then	# folder instnieje?
	mkdir "$HOME/.config/mirkobash"
else	# jeśli nie ma configu, to stwórzmy nowy
	if [ ! -s "$HOME/.config/mirkobash/mirkobash.conf" ]; then
		printf "
## Config for MirkoBash
secret=\"\"
appkey=\"\"
token=\"\"
userkey=\"\"
" > "$HOME/.config/mirkobash/mirkobash.conf"
	fi
fi

if [ -z "$1" ]; then usage; fi	# sprawdzamy czy użytkownik podał parametry, jeśli nie to wyrzucamy usage

## Load settings:
. "$HOME/.config/mirkobash/mirkobash.conf"		# ładujemy config
if [ -z "$secret" -o -z "$appkey" -o -z "$token" ]; then	#sprawdzamy czy użytkownik uzupełnił config swoimi danymi
	echo "Uzupelnij konfigurację w ~/.config/mirkobash/mirkobash.conf, wpisujac dane z tworzenia aplikacji wykopu"
	exit 1
fi


sign() {	# podpisywanie żądań, wywołując funkcję zyskujemy czytelność
md5all=$(echo -n "$secret$url$data2" | md5sum | awk '{print $1}')
}


hot() {		# funkcja wyświetlania gorących do czytania
if [ -z "$1" -o -z "$2" ]; then	# jeśli użytkownik nie podał parametrów, odeślij do usage
	usage
	exit 1
fi
page="$1"	# pobieramy stronę z parametru pierwszego
period="$2"	# pobieramy zakres czasu z parametru drugiego
url="https://a2.wykop.pl/Entries/Hot/page/$page/period/$period/appkey/$appkey/token/$token/userkey/$userkey/"
sign
content=$(curl -s -H "apisign: $md5all" -X GET "$url")	# ładujemy cały content
body=$(grep -oP '((?<="body":")(\\"|[^"])*)' <<< "$content")	# wyciąg treści wpisów
id_list=$(grep -oP '((?<="id":)[^,]*)' <<< "$content")	# wyciąg ID wpisów
date_list=$(grep -oP '((?<="date":")[^"]*)' <<< "$content")	# wyciąg dat wpisów
votes_list=$(grep -oP '((?<="vote_count":)[^,]*)' <<< "$content")	# wyciąg plusów wpisów
content_count=$(wc -l <<< "$id_list")	# liczymy ilość wpisów na stronie na podstawie listy ID (body może być puste, gdy ktoś wstawia sam obrazek)
					# [NOTE] czy nie popierdoli się łączenie ID z body w takim wypadku? Może body jest, ale tylko puste? Do sprawdzenia.
					# [NOTE] up sprawdzone - pierdoli się. To nie tak, że body jest puste, jego po prostu nie ma...
for ((i = 1; i <= "$content_count"; i++)); do	# otwieramy pętlę przez wszystkie wpisy
	printf "\033[0m%b\033[0;36m%b\t" "ID wpisu: " "$(sed -n "${i}p" <<< $id_list )" "Data: " "$(sed -n "${i}p" <<< $date_list )" "Ilość plusów: " "$(sed -n "${i}p" <<< $votes_list )"	# wypisujemy info na temat wpisu
	printf "\033[0m"	# mały reset koloru
	printf "\n%b\n" "$(sed -n "${i}p" <<< $body | sed 's,<br \\/>,,g;s,<a href=[^>]*>,,g;s,<\\/a>,,g;s,&quot;,",g' )" # tu wypisujemy treść wpisu
	echo ""; read -e -p "Czytać dalej? (Y/n)  " YN	# pytamy się użytkownika czy chce czytać dalej
	[[ "$YN" == "n" || "$YN" == "N" ]] && break	# jeśli user stwierdzi że dość, to przerwij pętlę
done
exit 0
}


hot_stats() {		# funkcja wyświetlania statystyk gorących
if [ -z "$1" -o -z "$2" ]; then	# jeśli użytkownik nie podał parametrów, odeślij do usage
	usage
	exit 1
fi
page="$1"	# pobieramy stronę z parametru pierwszego
period="$2"	# pobieramy zakres czasu z parametru drugiego
url="https://a2.wykop.pl/Entries/Hot/page/$page/period/$period/appkey/$appkey/token/$token/userkey/$userkey/"
sign
if [ "$3" != "-s" ]; then	# jako trzeci parametr możemy dodać "-s", co wyciszy nagłówek
	printf "%b" "ID\t\t" "Date - time\t" "Votes\n"	# jeśli parametru -s nie ma, wyświetl nagłówek
fi
curl -s -H "apisign: $md5all" -X GET "$url" | grep -oP '((?<="id":)[^,]*|(?<="date":")[^"]*|(?<="vote_count":)[^,]*)' | sed 's/$/ /g' | awk 'ORS=NR%3?FS:RS'	# pobieramy i wyciągamy potrzebne dane, wyświetlamy w trzech kolumnach

exit 0
}


login() {	# funkcja logująca użytkownika i dorzucająca userkey do configu
if [ -s "$HOME/.config/mirkobash/login.conf" ]; then	# jeśli użytkownik wprowadził tam swoje dane logowania, wykorzystamy je
	. "$HOME/.config/mirkobash/login.conf"
else		# jeśli nie, pytamy użytkownika o login i hasło
	echo "Enter login:"
	read -s LOGIN
	echo "Enter password:"
	read -s PASSWORD
fi

url="https://a2.wykop.pl/Login/Index/accountkey/$token/appkey/$appkey/"
data="login=$LOGIN&password=$PASSWORD&accountkey=$token"
data2="$LOGIN,$PASSWORD,$token"
sign
newuserkey=$(curl -s -H "apisign: $md5all" -X POST --data "$data" "$url" | grep -oP '(?<="userkey":")[^"]*')	# wyciągamy nowy userkey
if [ -z "$newuserkey" ]; then	# jeśli curl nie zwróci userkey, wyświetlamy że był błąd
	echo "Error during login"
	exit 1
else
	sed -i 's/^userkey=".*"/userkey="'"$newuserkey"'"/' "$HOME/.config/mirkobash/mirkobash.conf"	# a jeśli zwrócił, to wrzucamy nowy klucz do configu
	echo "Logged in successfully"
	exit 0
fi
}


post() {	# funkcja pozwalająca na zapostowanie tekstu na mirko
if [ -z "$1" ]; then usage; fi

tresc="$1"	# pierwszy parametr to treść postu - musi być podany w cudzysłowiu
data="body=$tresc"
data2="$tresc"
url="https://a2.wykop.pl/entries/add/appkey/$appkey/token/$token/userkey/$userkey/"
sign

response=$(curl -s -H "apisign: $md5all" -X POST --data "$data" "$url")	# generalnie pobieramy info czy się udało, czy wystąpił błąd

if grep -q "error\":" <<< "$response"; then	# jeśli wyłapiemy błąd, należy o tym poinformować użytkownika
        errorcode=$(grep -oP '(?<="code":)[^,]*' <<< "$response")
        errormsg_en=$(grep -oP '(?<="message_en":")[^"]*' <<< "$response")
        errormsg_pl=$(grep -oP '(?<="message_pl":")[^"]*' <<< "$response")
        printf "%b\n" "Wystąpił błąd!" "Kod błędu: $errorcode" "Treść błędu (en): $errormsg_en" "Treść błędu: $errormsg_pl"
	exit "$errorcode"
else		# jeśli nie ma błędu - zwróć okejkę
        echo "Done :)"
	exit 0
fi
}

main "$@"	# po załadowaniu wszystkich configów etc, przenosimy użytkownika do ustalania jaki parametr wpisał
exit 2	# na wszelki wypadek, gdyby użytkownik przypadkiem opuścił ifa

