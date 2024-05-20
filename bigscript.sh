#!/bin/bash
# Author           : Mateusz Grzonka ( mateuszgrzonka2003@gmail.com )
# Created On       : 14.05.2024
# Last Modified By : Mateusz Grzonka ( mateuszgrzonka2003@gmail.com )
# Last Modified On : 20.05.2024 
# Version          : 1.2
#
# Description      : An app to inspect and modify tags in mp3 files. And make playlists by choosing 
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

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

    find . -name "*.mp3" | while read file; do
        title_tag=$(id3v2 -l "$file" | grep -i "TIT2" | awk -F": " '{print $2}')
        genre_tag=$(id3v2 -l "$file" | grep -i "TCON" | awk -F": " '{print $2}')
        year_tag=$(id3v2 -l "$file" | grep -i "TYER" | awk -F": " '{print $2}')
        artist_tag=$(id3v2 -l "$file" | grep -i "TPE1" | awk -F": " '{print $2}')
        album_tag=$(id3v2 -l "$file" | grep -i "TALB" | awk -F": " '{print $2}')
        track_tag=$(id3v2 -l "$file" | grep -i "TRCK" | awk -F": " '{print $2}')

        if [[ ( -z "$genre" || "$genre_tag" == *"$genre"* ) &&
              ( -z "$year" || "$year_tag" == *"$year"* ) &&
              ( -z "$artist" || "$artist_tag" == *"$artist"* ) ]]; then
            echo "ARTIST - TITLE: $artist_tag - $title_tag"
            echo "Genre: $genre_tag"
            echo "Year: $year_tag"
            echo "Album: $album_tag"
            echo "Track: $track_tag"
            echo "File Path: $file"
            echo "-----------------------------"
        fi
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

# User Menu
echo "Choose option:"
echo "1. Search for MP3 files"
echo "2. Modifying MP3 tags"
read -p "Option: " option

case $option in
    1)
        read -p "Enter genre (or leave empty): " genre
        read -p "Enter year (or leave empty): " year
        read -p "Enter artist (or leave empty): " artist
        search_mp3 "$genre" "$year" "$artist"
        ;;
    2)
        read -p "Enter the path to the MP3 file: " file
        if [[ ! -f "$file" ]]; then
            echo "The file '$file' does not exist or cannot be accessed."
            exit 1
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
    *)
        echo "Unknown option."
        ;;
esac
