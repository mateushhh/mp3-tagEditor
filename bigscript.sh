#!/bin/bash
# Author           : Mateusz Grzonka ( mateuszgrzonka2003@gmail.com )
# Created On       : 14.05.2024
# Last Modified By : Mateusz Grzonka ( mateuszgrzonka2003@gmail.com )
# Last Modified On : 20.05.2024 
# Version          : 1.3
#
# Description      : An app to inspect and modify tags in mp3 files and create playlists by choosing 
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

# Display help information
show_help() {
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  -h          Display this help message."
    echo "  -v          Display version and author information."
    echo
    echo "Interactive Options:"
    echo "  1           Search for MP3 files based on tags."
    echo "  2           Modify MP3 tags."
    echo "  3           Create a playlist."
    echo "  4           Exit."
}

# Display version and author information
show_version() {
    echo "MP3 Tag Tool"
    echo "Version: 1.3"
    echo "Author: Mateusz Grzonka (mateuszgrzonka2003@gmail.com)"
    echo "Created On: 14.05.2024"
    echo "Last Modified On: 20.05.2024"
}

# Check if id3v2 is installed
if ! command -v id3v2 &> /dev/null
then
    echo "id3v2 could not be found. Please install id3v2 and try again."
    exit 1
fi

# Function that searches for mp3 files based on tags and displays information about them
search_mp3() {
    local genre="$1"
    local year="$2"
    local artist="$3"

    # Tablica przechowująca informacje o plikach
    declare -a files_info

    # Przetwarzanie plików MP3 i zapisywanie informacji do tablicy
    while IFS= read -r file; do
        title_tag=$(id3v2 -l "$file" | grep -i "TIT2" | awk -F": " '{print $2}')
        genre_tag=$(id3v2 -l "$file" | grep -i "TCON" | awk -F": " '{print $2}')
        year_tag=$(id3v2 -l "$file" | grep -i "TYER" | awk -F": " '{print $2}')
        artist_tag=$(id3v2 -l "$file" | grep -i "TPE1" | awk -F": " '{print $2}')
        album_tag=$(id3v2 -l "$file" | grep -i "TALB" | awk -F": " '{print $2}')
        track_tag=$(id3v2 -l "$file" | grep -i "TRCK" | awk -F": " '{print $2}')

        # Sprawdzanie czy plik pasuje do filtrów
        if [[ ( -z "$genre" || "$genre_tag" == *"$genre"* ) &&
            ( -z "$artist" || "$artist_tag" == *"$artist"* ) && 
            ( -z "$year" || "$year_tag" =~ ${year//\*/.*} ) ]]; then
            files_info+=("ARTIST - TITLE: $artist_tag - $title_tag" 
                        "Genre: $genre_tag" 
                        "Year: $year_tag" 
                        "Album: $album_tag" 
                        "Track: $track_tag" 
                        "File Path: $file"
                        "-----------------------------")
        fi
    done < <(find . -name "*.mp3")

    # Wyświetlanie informacji o plikach z tablicy
    echo ""
    for info in "${files_info[@]}"; do
        echo "$info"
    done
}

# Function to modify mp3 tags
modify_tags() {
    local file="$1"
    local title="$2"
    local artist="$3"
    local album="$4"
    local year="$5"
    local genre="$6"
    local track="$7"
    local cover="$8"

    if [[ ! -f "$file" ]]; then
        echo "The file '$file' does not exist or cannot be accessed."
        return
    fi

    [[ -n "$title" ]] && id3v2 --song "$title" "$file"
    [[ -n "$artist" ]] && id3v2 --artist "$artist" "$file"
    [[ -n "$album" ]] && id3v2 --album "$album" "$file"
    [[ -n "$year" ]] && id3v2 --year "$year" "$file"
    [[ -n "$genre" ]] && id3v2 --genre "$genre" "$file"
    [[ -n "$track" ]] && id3v2 --track "$track" "$file"
    [[ -n "$cover" ]] && id3v2 --APIC "$cover" "$file"
}

# Function to create playlist
create_playlist() {
    local playlist_name="$1"
    shift
    local files_str="$1"

    # Split the files_str by semicolon into an array
    IFS=';' read -ra files <<< "$files_str"

    # Check if any files are provided
    if [ ${#files[@]} -eq 0 ]; then
        echo "No files provided to create playlist."
        return
    fi

    # Create playlist file
    echo "#EXTM3U" > "$playlist_name.m3u"

    # Add files to the playlist
    for file in "${files[@]}"; do
        echo "$file" >> "$playlist_name.m3u"
    done

    echo "Playlist '$playlist_name' created successfully."
}

# Command-line options
while getopts ":hv" opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        v)
            show_version
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Main program loop
while true; do
    echo
    echo "Choose option:"
    echo "1. Search for MP3 files"
    echo "2. Modify MP3 tags"
    echo "3. Create a playlist"
    echo "4. Exit"
    read -p "Option: " option

    case $option in
        1)
            read -p "Enter genre (or leave empty): " genre
            read -p "Enter year (or leave empty, use * for wildcard): " year
            read -p "Enter artist (or leave empty): " artist
            search_mp3 "$genre" "$year" "$artist"
            ;;
        2)
            read -p "Enter the path to the MP3 file: " file
            if [[ ! -f "$file" ]]; then
                echo "The file '$file' does not exist or cannot be accessed."
                continue
            fi

            read -p "Enter new title (or leave empty): " title
            read -p "Enter new artist (or leave empty): " artist
            read -p "Enter new album (or leave empty): " album
            read -p "Enter new year (or leave empty): " year
            read -p "Enter new genre (or leave empty): " genre
            read -p "Enter new track number (or leave empty): " track
            read -p "Enter the path to the new cover (or leave empty): " cover
            modify_tags "$file" "$title" "$artist" "$album" "$year" "$genre" "$track" "$cover"
            ;;
        3)
            read -p "Enter playlist name: " playlist_name
            read -p "Enter file paths separated by semicolon (;) to add to the playlist: " files_str
            create_playlist "$playlist_name" "$files_str"
            ;;
        4)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Unknown option."
            ;;
    esac
done
