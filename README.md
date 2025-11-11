# ssh_key_generator

Prosty skrypt Bash, który automatycznie tworzy nowy klucz SSH i kopiuje go na wskazany zdalny serwer.
Pomaga w szybkim skonfigurowaniu logowania bez hasła (SSH key-based authentication).

## Funkcjonalności

- Tworzy nowy klucz SSH typu ed25519.
- Automatycznie nadaje bezpieczne uprawnienia katalogowi .ssh.
- Kopiuje klucz publiczny na zdalny serwer przez ssh-copy-id lub metodą alternatywną.
- Obsługuje własny port SSH i nazwę klucza.
- Wyświetla czytelne komunikaty błędów i pomoc (--help).
