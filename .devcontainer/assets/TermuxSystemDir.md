# Termux Dev Locations

| Asset Type | Location Example | Purpose |
|---|---|---|
| Executables | $PREFIX/bin/ | User commands |
| Python modules | $PREFIX/lib/pythonX.Y/site-packages/ | Importable code |
| Data/Assets | $PREFIX/share/<pkg>/ | Static files |
| Documentation | $PREFIX/share/doc/<pkg>/ | README, LICENSE, etc |
| System Config | $PREFIX/etc/<pkg>/ | Default configs|
| User Config | $HOME/.config/<pkg>/ | User settings|
| User Data | $HOME/.local/share/<pkg>/ | User data|
| Shell Completion | $PREFIX/share/bash-completion/completions/ | Tab-completion scripts|
| Man Pages | $PREFIX/share/man/man1/ | Manual pages|
| Service Scripts | $PREFIX/etc/<pkg>/ or $PREFIX/libexec/<pkg>/ | Daemons, helpers|
| Cache | $HOME/.cache/<pkg>/ | Temporary files|
