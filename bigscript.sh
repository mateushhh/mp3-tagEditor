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
    echo -e "Usage: $0 [OPTION]\n\nOptions:\n  -h          Display this help message.\n  -v          Display version and author information.\n\nInteractive Options:\n  1           Search for MP3 files based on tags.\n  2           Modify MP3 tags.\n  3           Create a playlist."
}

# Display version and author information
show_version() {
    echo -e "MP3 Tag Tool\nVersion: 1.3\nAuthor: Mateusz Grzonka (mateuszgrzonka2003@gmail.com)\nCreated On: 14.05.2024\nLast Modified On: 20.05.2024"
}

# Check if id3v2 is installed
if ! command -v id3v2 &> /dev/null; then
    echo "id3v2 could not be found. Please install id3v2 and try again."
    exit 1
fi

# Handle command-line options
while getopts ":vh" opt; do
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

# Function that searches for mp3 files based on tags and displays information about them
search_mp3() {
    local genre="$1"
    local year="$2"
    local artist="$3"

    declare -a files_info

    while IFS= read -r file; do
        title_tag=$(id3v2 -l "$file" | grep -i "TIT2" | awk -F": " '{print $2}')
        genre_tag=$(id3v2 -l "$file" | grep -i "TCON" | awk -F": " '{print $2}')
        year_tag=$(id3v2 -l "$file" | grep -i "TYER" | awk -F": " '{print $2}')
        artist_tag=$(id3v2 -l "$file" | grep -i "TPE1" | awk -F": " '{print $2}')
        album_tag=$(id3v2 -l "$file" | grep -i "TALB" | awk -F": " '{print $2}')
        track_tag=$(id3v2 -l "$file" | grep -i "TRCK" | awk -F": " '{print $2}')

        if [[ ( -z "$genre" || "$genre_tag" == *"$genre"* ) &&
              ( -z "$artist" || "$artist_tag" == *"$artist"* ) && 
              ( -z "$year" || "$year_tag" =~ ${year//\*/.*} ) ]]; then
            files_info+=("Artist: $artist_tag\nTitle: $title_tag\nGenre: $genre_tag\nYear: $year_tag\nAlbum: $album_tag\nTrack: $track_tag\nFile Path: $file\n\n")
        fi
    done < <(find . -name "*.mp3")

    # Join the files_info array into a single string
    results="${files_info[*]}"

    # Display the results in a scrollable text box
    echo -e "$results" | zenity --text-info --title="Search Results" --width=600 --height=1000 --ok-label="Close"
}

# Funkcja do wyboru pliku MP3
choose_mp3_file() {
    zenity --file-selection --title="Select MP3 file"
}

# Funkcja do modyfikacji tagów
modify_tags() {
    local file
    file=$(choose_mp3_file)

    if [[ -z "$file" ]]; then
        echo "No file selected."
        return
    fi

    local title artist album year genre track cover

    input=$(zenity --forms --title="Modify MP3 Tags" --text="Enter the details:" \
        --add-entry="New title" \
        --add-entry="New artist" \
        --add-entry="New album" \
        --add-entry="New year" \
        --add-entry="New genre" \
        --add-entry="New track number" \
        --add-entry="Cover image path")

    IFS="|" read -r title artist album year genre track cover <<< "$input"
    modify_tags_for_file "$file" "$title" "$artist" "$album" "$year" "$genre" "$track" "$cover"
}

# Funkcja do rzeczywistej modyfikacji tagów dla wybranego pliku
modify_tags_for_file() {
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
    local files

    files=$(zenity --file-selection --multiple --separator=$'\n' --file-filter='MP3 files (mp3) | *.mp3' --title="Select MP3 files")

    if [ -z "$files" ]; then
        echo "No files selected."
        return
    fi

    echo "#EXTM3U" > "$playlist_name.m3u"

    for file in "${files[@]}"; do
        echo "$file" >> "$playlist_name.m3u"
    done

    echo "Playlist '$playlist_name' created successfully."
}

# Main program loop
while true; do
    option=$(zenity --list --title="MP3 Tag Tool" --text="Choose option:" --radiolist --column="Select" --column="Option" TRUE "Search for MP3 files" FALSE "Modify MP3 tags" FALSE "Create a playlist" --cancel-label="Quit")

    if [ "$?" -ne 0 ]; then
        break
    fi

    case $option in
        "Search for MP3 files")
            input=$(zenity --forms --title="Search for MP3 files" --text="Enter search criteria:" \
                --add-entry="Genre" \
                --add-entry="Year (use * for wildcard)" \
                --add-entry="Artist")

            IFS="|" read -r genre year artist <<< "$input"
            search_mp3 "$genre" "$year" "$artist"
            ;;
        "Modify MP3 tags")
            modify_tags
            ;;
        "Create a playlist")
            input=$(zenity --forms --title="Create Playlist" --text="Enter playlist details:" \
                --add-entry="Playlist name")

            IFS="|" read -r playlist_name <<< "$input"
            create_playlist "$playlist_name"
            ;;
        *)
            echo "Unknown option."
            ;;
    esac
done
