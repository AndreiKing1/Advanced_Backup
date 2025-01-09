#!/bin/bash

REPO_URL="git@github.com:AndreiKing1/Advanced_Backup.git"

PARSED=$(getopt --options h,u --longoptions help,usage: -- "$@")
eval set -- "$PARSED"

while true; do
    case "$1" in
        -h|--help)
            echo "Utilizare: $0 [optiuni]"
            echo "Optiuni:"
            echo "  -u, --usage           Afiseaza cum sa folosesti aplicatia"
            echo "1. Gasire fisiere vechi"
            echo "2. Mutare fisiere"
            echo "3. Stergere fisiere"
            echo "4. Editare continut fisiere"
            echo "5. Inchiriere Masini"
            echo "6. Vanzare Masini"
            exit 0
            ;;
        -u|--usage)
            echo "Exemplu de utilizare:"
            echo "1. Gasire fisiere vechi - userul introduce o data calendaristica in terminal, aceasta optiune va afisa fisierele care au fost create inainte de acea data."
            echo "2. Mutare fisiere - userul va avea 2 optiuni, local sau cloud, daca este local va muta fisierele din directorul sursa in directorul specificat de utilizator."
            echo "3. Stergere fisiere - fisierele userului vor fi sterse daca acestea au fost create cu 60 de zile inainte."
            exit 0
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

while true; do
    echo ""
    echo "Meniu principal:"
    echo "1. Gasire fisiere vechi"
    echo "2. Mutare fisiere"
    echo "3. Stergere fisiere"
    echo "4. Editare continut fisiere"
    echo "5. Inchiriere Masini"
    echo "6. Vanzare Masini"
    echo "7. Filtre de cautare"
    echo "8. Exit"
    echo "Alegeti o optiune:"
    read option

    case $option in
        1)
            echo "Introduceti perioada dorita (in formatul dd-mm-yy):"
            read -r input
           
            data_zi=$(date +%-d)
            data_luna=$(date +%-m)
            data_an=$(date +%-y)

            zi="${input:0:2}"
            luna="${input:3:2}"
            an="${input:6:2}"

            zi=$((zi + 0))
            luna=$((luna - 1))
            an=$((an + 0))
            data_zi=$((data_zi + 0))
            data_luna=$((data_luna - 1))
            data_an=$((data_an + 0))
           
            numar_zile_input=$((zi + (30 * (luna - 1)) + (365 * an) + (an / 4)))
            numar_zile_data=$((data_zi + (30 * (data_luna - 1)) + (365 * data_an) + (data_an / 4)))
            numar_zile=$((numar_zile_data - numar_zile_input))

            data_luna=$((data_luna + 1))
            luna=$((luna + 1))

            if [[ ${#input} -ne 8 || ${input:2:1} != "-" || ${input:5:1} != "-" ]]; then
                echo "Eroare: Formatul este invalid. Vă rugăm respectați formatul (dd-mm-yy)."
            else
                if [[ $luna -eq 2 ]]; then
                    if [[ $((an % 4)) -ne 0 && $zi -gt 28 ]]; then
                        echo "Data invalida: Februarie poate avea doar 28 zile in ani non-bisecti."
                    elif [[ $zi -gt 29 ]]; then
                        echo "Data invalida: Februarie poate avea maxim 29 zile in ani bisecti."
                    fi
                fi

                if [[ $luna -eq 1 || $luna -eq 3 || $luna -eq 5 || $luna -eq 7 || $luna -eq 8 || $luna -eq 10 || $luna -eq 12 ]]; then
                    if [[ $zi -gt 31 ]]; then
                        echo "Data invalida: Luna $luna poate avea maxim 31 zile."
                        exit 1
                    fi
                fi

                if [[ $luna -eq 4 || $luna -eq 6 || $luna -eq 9 || $luna -eq 11 ]]; then
                    if [[ $zi -gt 30 ]]; then
                        echo "Data invalida: Luna $luna poate avea maxim 30 zile."
                        exit 1
                    fi
                fi

                if [[ "$numar_zile" -lt 0 ]]; then
                    echo "Data introdusa este una gresita. Introduceti o data valida."
                else
                    find /home/$USER/Desktop/ -type f -mtime +$numar_zile
                fi
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
                    find /home/"$USER"/Desktop/Firma_vanzare_cumparare_masini -type f | xargs -I {} mv {} "$local_path"
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

                    # Verificare daca folderul este repository Git, altfel initializare
                    if [ ! -d "$upload_path/.git" ]; then
                        cd "$upload_path" || { echo "Calea specificata nu exista."; continue; }
                        git init
                        git branch -M main
                        git remote add origin "$REPO_URL"
                    fi

                    cd "$upload_path" || { echo "Calea specificata nu exista."; continue; }

                    # Sincronizare cu repository-ul remote
                    echo "Sincronizare cu repository-ul remote..."
                    git fetch origin main || {
                        echo "Eroare la sincronizare. Verificati permisiunile si configurarea repository-ului."
                        continue
                    }
                    git reset --soft origin/main

                    git add .

                    # Verificare daca exista fisiere pentru commit
                    if git diff --cached --quiet && git diff-index --quiet HEAD --; then
                        echo "Nu exista fisiere noi sau modificari pentru commit."
                    else
                        echo "Comiterea modificarilor..."
                        git commit -m "$commit_message"

                        # Push modificarile
                        git push -u origin main || {
                            echo "Eroare la push. Fortam actualizarea..."
                            git push --force -u origin main
                        }
                        echo "Fisierele au fost urcate in repository-ul GitHub: $REPO_URL."
                    fi
                    ;;
                *)
                    echo "Optiune invalida."
                    ;;
            esac
            ;;
        3)
            TARGET_DIR="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
            if [ -d "$TARGET_DIR" ]; then
                find "$TARGET_DIR" -type f -mtime +60 -exec rm -f {} \;
                echo "Fisierele mai vechi de 60 de zile au fost șterse din fisierul dumneavoastra."
            else
                echo "Directorul dumneavoastra nu exista."
            fi
            ;;
        4)
            echo "Adaug o linie in fiecare fisier: ##### DEPRECATED #####"
            for file in $(find . -type f -mtime +7); do
                echo "##### DEPRECATED #####" >> "$file"
            done
            ;;
        5)
            echo "Alege modelul masinii pe care vrei sa o inchiriezi: "
            read masina
            echo ""
            dir="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
            if [ ! -d "$dir" ]; then
                echo "Eroare: Directorul $dir nu exista."
            fi

            for file in "$dir"/*; do
                if [ -f "$file" ]; then
                    grep -i "$masina" "$file" | grep -i "inchiriere" >> output.txt
                fi
            done

            if [ -s output.txt ]; then
                cat output.txt
            else
                echo "Nu am gasit nicio masina $masina de inchiriat."
            fi
            rm output.txt
            ;;
        6)
            echo "Alege modelul masinii pe care vrei sa o cumperi: "
            read masina
            dir="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
            if [ ! -d "$dir" ]; then
                echo "Eroare: Directorul $dir nu exista."
            fi

            for file in "$dir"/*; do
                if [ -f "$file" ]; then
                    grep -i "$masina" "$file" | grep -i "vanzare" >> output.txt
                fi
            done

            if [ -s output.txt ]; then
                cat output.txt
            else
                echo "Nu am gasit nicio masina $masina de vanzare."
            fi
            rm output.txt
            ;;
        7)
            echo "Alegeti sortarea masinilor: (1.an, 2.diesel, 3.benzina)"
            read optiune

            case $optiune in
                1)
                    dir="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
                    echo "Alegeti anul fabricarii: "
                    read anul
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            grep -i "$anul" "$file" >> output.txt
                        fi
                    done

                    if [ -s output.txt ]; then
                        cat output.txt
                    else
                        echo "Nu exista nicio masina fabricata in anul $anul."
                    fi
                    rm output.txt
                    ;;
                2)
                    dir="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            grep -i "diesel" "$file" >> output.txt
                        fi
                    done

                    if [ -s output.txt ]; then
                        cat output.txt
                    else
                        echo "Nu exista nicio masina diesel."
                    fi
                    rm output.txt
                    ;;
                3)
                    dir="/home/$USER/Desktop/Firma_vanzare_cumparare_masini"
                    for file in "$dir"/*; do
                        if [ -f "$file" ]; then
                            grep -i "benzina" "$file" >> output.txt
                        fi
                    done

                    if [ -s output.txt ]; then
                        cat output.txt
                    else
                        echo "Nu exista nicio masina pe benzina."
                    fi
                    rm output.txt
                    ;;
            esac
            ;;
        8)	
            clear
            echo "Mersi<3!"
            exit 0
            ;;
        *)
            echo "Optiune invalida. Reincercati."
            ;;
    esac
done

