# SSH Key Generator

[English version](#english-version)

## Polska wersja

Prosty skrypt Bash, który automatycznie tworzy nowy klucz SSH i kopiuje go na wskazany zdalny serwer.
Pomaga w szybkim skonfigurowaniu logowania bez hasła (SSH key-based authentication).

### Funkcjonalności

- Tworzy nowy klucz SSH typu ed25519.
- Automatycznie nadaje bezpieczne uprawnienia katalogowi .ssh.
- Kopiuje klucz publiczny na zdalny serwer przez ssh-copy-id lub metodą alternatywną.
- Obsługuje własny port SSH i nazwę klucza.
- Wyświetla czytelne komunikaty błędów i pomoc (--help).

### Instalacja

1. Upewnij się, że masz zainstalowanego Gita.
2. Sklonuj repozytorium z GitHuba:
```bash
git clone https://github.com/lukaszsarnecki/ssh_key_generator.git
```
3. Przejdź do katalogu projektu:
```bash
cd ssh-key-generator
```        
4. Nadaj skryptowi uprawnienia do uruchomienia:
```bash
chmod +x ssh-key-generator.sh
```

### Użycie

Przykład standardowego użycia:
```bash
./ssh-key-generator.sh -n devops -H example.com -u user
```

Opcjonalnie możesz dodać port:
```bash
./ssh-key-generator.sh -n devops -H example.com -u user -P 2222
```
Aby zobaczyć pomoc:
```bash
./ssh-key-generator.sh -h
```
#### Przeniesienie do /usr/local/bin

Jeśli będziesz użwać skryptu więcej niż raz, możesz go przenieść do katalogu /usr/local/bin. 
Dzięki temu będziesz go mógł wykonać bez konieczność wchodzenia w jego lokalizację.

```bash
sudo mv ssh-key-generator.sh /usr/local/bin
```
### Kod źródłowy
```bash
#!/bin/bash
# Określa, że ten skrypt ma być uruchamiany przez program Bash.

# --- USTAWIENIA SKRYPTU ---
# Te opcje powodują, że skrypt zatrzyma się, jeśli napotka jakikolwiek błąd.
set -Eeuo pipefail

# Jeśli w skrypcie wystąpi błąd, to polecenie wyświetli komunikat z numerem linii, gdzie się on wydarzył.
trap 'echo -e "\e[31mBŁĄD:\e[0m skrypt zatrzymał się w linii $LINENO." >&2' ERR


# --- PRZYGOTOWANIE ZMIENNYCH ---
# Tutaj przygotowujemy zmienne, które będą przechowywać dane podane przez użytkownika.
SSH_KEY_DIR="${HOME}/.ssh" # Ścieżka do folderu .ssh w katalogu domowym.
HOST=""                   # Przechowuje nazwę serwera, na który kopiujemy klucz.
HOST_USER=""              # Przechowuje nazwę użytkownika na tym serwerze.
PORT=""                   # Przechowuje numer portu SSH.
NAME=""                   # Przechowuje nazwę dla nowego klucza.


# --- FUNKCJA WYŚWIETLAJĄCA POMOC ---
# Ta funkcja jest odpowiedzialna za wyświetlenie instrukcji obsługi skryptu.
print_help() {
# Wyświetla poniższy blok tekstu aż do linii zawierającej słowo 'EOF'.
cat <<'EOF'
OPIS:
  Skrypt do generowania nowej pary kluczy SSH (ed25519) i bezpiecznego
  kopiowania klucza publicznego na zdalny serwer.

UŻYCIE:
  ./ssh-key-generator.sh -n <nazwa_klucza> -H <zdalny_host> -u <użytkownik> [OPCJE]

  Jeśli skrypt zostanie uruchomiony bez argumentów, wyświetli to menu pomocy.

OPCJE OBOWIĄZKOWE:
  -n, --name <nazwa>       Nazwa dla klucza (np. "devops"). Wynikowy plik: id_devops_ed25519
  -H, --hostname <host>    Nazwa zdalnego hosta lub adres IP, na który skopiować klucz.
  -u, --user <użytkownik>  Nazwa użytkownika na zdalnym hoście.

OPCJE DODATKOWE:
  -P, --port <numer>       Port SSH na zdalnym hoście (domyślnie: 22).
  -h, --help               Wyświetla tę pomoc.
EOF
}


# --- GŁÓWNA LOGIKA SKRYPTU ---

# Sprawdza, czy użytkownik uruchomił skrypt bez podawania jakichkolwiek parametrów.
if [ "$#" -eq 0 ]; then
    print_help # Jeśli tak, wyświetla pomoc.
    exit 0     # I kończy działanie.
fi

# --- ODCZYTYWANIE PARAMETRÓW ---
# To polecenie odczytuje i porządkuje parametry podane przy uruchamianiu skryptu (np. -n, --name).
PARSED=$(getopt -o n:H:u:P:h --long name:,hostname:,user:,port:,help -- "$@")
# Sprawdza, czy parametry zostały podane poprawnie.
if ! [ "$?" -eq 0 ]; then
    print_help
    exit 1
fi
# Aktualizuje listę parametrów, aby pętla poniżej mogła je poprawnie odczytać.
eval set -- "$PARSED"

# Ta pętla odczytuje każdy parametr i przypisuje jego wartość do odpowiedniej zmiennej.
while true; do
  case "$1" in
    -n|--name) NAME="$2"; shift 2;;
    -H|--hostname) HOST="$2"; shift 2;;
    -u|--user) HOST_USER="$2"; shift 2;;
    -P|--port) PORT="$2"; shift 2;;
    -h|--help) print_help; exit 0;;
    --) shift; break;;
    *) echo "Błąd - nie podano wszyskich parametrów"; exit 1 ;;
  esac
done

# --- SPRAWDZANIE PARAMETRÓW ---
# Sprawdza, czy użytkownik podał wszystkie wymagane informacje.
if [[ -z "$NAME" || -z "$HOST" || -z "$HOST_USER" ]]; then
  # Jeśli czegoś brakuje, wyświetla błąd i informuje, co trzeba podać.
  echo -e "\e[31mBŁĄD:\e[0m Brak wymaganych argumentów: -n, -H, -u są obowiązkowe." >&2
  echo -e "\e[33mUżyj opcji -h, aby wyświetlić pomoc.\e[0m" >&2
  exit 1
fi

# --- PRZYGOTOWANIE NAZW PLIKÓW ---
# Na podstawie podanej nazwy, tworzy pełne nazwy dla plików klucza.
SSH_KEY_NAME="id_${NAME}_rsa"
SSH_KEY_PATH="${SSH_KEY_DIR}/${SSH_KEY_NAME}"
SSH_PUB_KEY="${SSH_KEY_PATH}.pub"


# --- GENEROWANIE KLUCZA SSH ---
echo -e "\e[34m===> Sprawdzanie/Tworzenie klucza SSH...\e[0m"
# Tworzy folder .ssh, jeśli jeszcze nie istnieje.
mkdir -p "$SSH_KEY_DIR"
# Ustawia bezpieczne uprawnienia dla tego folderu (tylko właściciel ma dostęp).
chmod 700 "$SSH_KEY_DIR"

# Sprawdza, czy plik z kluczem o tej nazwie już istnieje.
if [[ -f "$SSH_KEY_PATH" ]]; then
    # Jeśli tak, wyświetla ostrzeżenie i nic nie robi.
    echo -e "\e[33mUWAGA:\e[0m Klucz ${SSH_KEY_PATH} już istnieje. Pomijam tworzenie."
else
    # Jeśli nie, generuje nowy klucz SSH bez hasła.
    ssh-keygen -t ed25519 -a 100 -f "$SSH_KEY_PATH" -C "${USER}@$(hostname)-$(date +%F)" -N ""
    echo -e "\e[32m✓ Klucz został wygenerowany pomyślnie:\e[0m ${SSH_KEY_PATH}"
fi


# --- KOPIOWANIE KLUCZA NA SERWER ---
echo -e "\n\e[34m===> Kopiowanie klucza publicznego na ${HOST_USER}@${HOST}...\e[0m"

# Przygotowuje opcję portu (-p), jeśli została podana przez użytkownika.
PORT_ARG=""
if [[ -n "$PORT" ]]; then
    PORT_ARG="-p ${PORT}"
fi

# Sprawdza, czy w systemie jest dostępne polecenie 'ssh-copy-id'.
if command -v ssh-copy-id > /dev/null 2>&1; then
    # Jeśli 'ssh-copy-id' jest dostępne, używa go do skopiowania klucza. To jest zalecany sposób.
    ssh-copy-id -i "$SSH_PUB_KEY" ${PORT_ARG} "${HOST_USER}@${HOST}"
    echo -e "\e[32m✓ Klucz został skopiowany pomyślnie za pomocą ssh-copy-id.\e[0m"
else
    # Jeśli 'ssh-copy-id' nie jest dostępne, używa alternatywnej, ręcznej metody.
    echo -e "\e[33mUWAGA:\e[0m Polecenie ssh-copy-id nie zostało znalezione. Używam metody alternatywnej.\e[0m"
    # To polecenie loguje się na serwer i dopisuje klucz publiczny do pliku `authorized_keys`.
    ssh "${HOST_USER}@${HOST}" ${PORT_ARG} "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" < "$SSH_PUB_KEY"
    echo -e "\e[32m✓ Klucz powinien zostać dodany do authorized_keys na hoście zdalnym.\e[0m"
fi


# --- ZAKOŃCZENIE ---
echo -e "\n\e[32mGOTOWE!\e[0m"
# Wyświetla informację o zakończeniu pracy i podaje przykładowe polecenie do logowania.
echo -e "Możesz teraz zalogować się za pomocą: ssh ${PORT_ARG} -i ${SSH_KEY_PATH} ${HOST_USER}@${HOST}"
```

## English version
