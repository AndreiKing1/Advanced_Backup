#!/bin/bash

# Variabile de configurare implicite
DEBUG_MODE=0
LOG_FILE="backup.log"
REPO_URL="git@github.com:AndreiKing1/Advanced_Backup.git"

# Procesarea argumentelor din linia de comanda cu getopt
PARSED=$(getopt --options h,u --longoptions help,usage,debug: -- "$@")
if [[ $? -ne 0 ]]; then
    echo "Utilizare: $0 [optiuni]"
    echo "Optiuni:"
    echo "  -h, --help            Afiseaza acest mesaj"
    echo "  -u, --usage           Afiseaza cum sa folosesti aplicatia"
    echo "  --debug=on|off        Activeaza/dezactiveaza modul de depanare"
    exit 1
fi

eval set -- "$PARSED"

while true; do
    case "$1" in
        -h|--help)
            echo "Utilizare: $0 [optiuni]"
            echo "Optiuni:"
            echo "  -h, --help            Afiseaza acest mesaj"
            echo "  -u, --usage           Afiseaza cum sa folosesti aplicatia"
            echo "  --debug=on|off        Activeaza/dezactiveaza modul de depanare"
            exit 0
            ;;
        -u|--usage)
            echo "Exemplu de utilizare:"
            echo "$0 --debug=on"
            exit 0
            ;;
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Optiune necunoscuta: $1"
            exit 1
            ;;
    esac
    shift
done

# Meniul interactiv
while true; do
    echo "Meniu principal:"
    echo "1. Gasire fisiere vechi"
    echo "2. Mutare fisiere"
    echo "3. Stergere fisiere"
    echo "4. Editare continut fisiere"
    echo "5. Iesire"
    echo "Alegeti o optiune:"
    read option

    case $option in
        1)
            echo "Introduceti perioada dorita (ex: 7 zile, 2 luni, 1 an):"
            read input
            pattern="([0-9]+) (zile|luni|ani|saptamani)"

            if [[ $input =~ $pattern ]]; then
                num=${BASH_REMATCH[1]}
                unit=${BASH_REMATCH[2]}

                case $unit in
                    "zile")
                        find . -type f -mtime +$num
                        ;;
                    "luni")
                        find . -type f -mtime +$(($num * 30))
                        ;;
                    "ani")
                        find . -type f -mtime +$(($num * 365))
                        ;;
                    "saptamani")
                        find . -type f -mtime +$(($num * 7))
                        ;;
                esac
            else
                echo "Format invalid."
            fi
            ;;
        2)
            echo "Alegeti destinatia (local sau cloud):"
            read destination

            case $destination in
                "local")
                    echo "Introduceti calea destinatiei locale:"
                    read local_path
                    mkdir -p "$local_path"
                    find . -type f -mtime +7 | xargs -I {} mv {} "$local_path"
                    ;;
                "cloud")
                    echo "Upload fisiere in cloud folosind GitHub."
                    echo "Introduceti calea fisierelor pentru upload:"
                    read upload_path
                    echo "Introduceti un mesaj pentru commit:"
                    read commit_message

                    # Verificare daca identitatea Git este configurata
                    if ! git config user.email >/dev/null || ! git config user.name >/dev/null; then
                        echo "Configurare identitate Git..."
                        echo "Introduceti email-ul pentru Git:"
                        read git_email
                        echo "Introduceti numele pentru Git:"
                        read git_name
                        git config --global user.email "$git_email"
                        git config --global user.name "$git_name"
                    fi

                    cd "$upload_path" || { echo "Calea specificata nu exista."; continue; }

                    # Verificare si configurare remote
                    if git remote | grep -q origin; then
                        git remote remove origin
                    fi
                    git remote add origin "$REPO_URL"

                    git init
                    git add .

                    # Verificare modificari necomise
                    if ! git diff-index --quiet HEAD --; then
                        echo "Exista modificari necomise. Le comit automat..."
                        git commit -am "Salvare automata a modificarilor inainte de pull"
                    fi

                    # Sincronizare cu repository-ul remote
                    echo "Sincronizare cu repository-ul remote..."
                    git pull origin main --rebase || { echo "Eroare la sincronizare. Verificati conflictele."; continue; }

                    # Verificare daca exista fisiere pentru commit
                    if git diff --cached --quiet; then
                        echo "Nu exista fisiere pentru commit. Asigurati-va ca aveti fisiere in directorul specificat."
                        continue
                    fi

                    git commit -m "$commit_message"
                    git branch -M main
                    git push -u origin main
                    echo "Fisierele au fost urcate in repository-ul GitHub: $REPO_URL."
                    ;;
                *)
                    echo "Optiune invalida."
                    ;;
            esac
            ;;
        3)
            echo "Sterg fisierele mai vechi de 60 de zile..."
            find . -type f -mtime +60 -exec rm -f {} \;
            if [[ $DEBUG_MODE -eq 1 ]]; then
                echo "$(date +'%Y-%m-%d %H:%M:%S') - Fisierele mai vechi de 60 de zile au fost sterse." >> "$LOG_FILE"
            fi
            ;;
        4)
            echo "Adaug o linie in fiecare fisier: ##### DEPRECATED #####"
            for file in $(find . -type f -mtime +7); do
                echo "##### DEPRECATED ######" >> "$file"
            done
            ;;
        5)
            echo "La revedere!"
            exit 0
            ;;
        *)
            echo "Optiune invalida."
            ;;
    esac

done
