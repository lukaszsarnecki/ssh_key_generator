# ssh_key_generator

Prosty skrypt Bash, który automatycznie tworzy nowy klucz SSH i kopiuje go na wskazany zdalny serwer.
Pomaga w szybkim skonfigurowaniu logowania bez hasła (SSH key-based authentication).

## Funkcjonalności

- Tworzy nowy klucz SSH typu ed25519.
- Automatycznie nadaje bezpieczne uprawnienia katalogowi .ssh.
- Kopiuje klucz publiczny na zdalny serwer przez ssh-copy-id lub metodą alternatywną.
- Obsługuje własny port SSH i nazwę klucza.
- Wyświetla czytelne komunikaty błędów i pomoc (--help).

## Instalacja

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

## Użycie

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
