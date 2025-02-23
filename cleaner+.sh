#!/usr/bin/env fish
# iCleaner Alternative with Extended Cleanup and Detailed Freed Space Analysis for iOS >= 15 (Rootless) in Fish
# This script cleans cache, temporary files, and logs within /var,
# including additional directories such as /var/mobile/Library/Caches and app container tmp folders.
#
# 🚨 WARNING:
# Run at your own risk. Backup your data before executing this script.
# このスクリプトを使用する前に、必ずデータのバックアップを取ってください。

# Function: Convert bytes to a human-readable format.
function bytes_to_human
    set b $argv[1]
    if test $b -lt 1024
        echo "$b B"
    else if test $b -lt (math "1024*1024")
        set kb (math "$b / 1024")
        printf "%.2f KB" $kb
    else if test $b -lt (math "1024*1024*1024")
        set mb (math "$b / (1024*1024)")
        printf "%.2f MB" $mb
    else
        set gb (math "$b / (1024*1024*1024)")
        printf "%.2f GB" $gb
    end
end

# Function: Get total size of files in a directory (optionally matching a given pattern).
function get_dir_size
    set DIR $argv[1]
    set PATTERN ""
    if test (count $argv) -gt 1
        set PATTERN $argv[2]
    end
    set total 0
    if test -z "$PATTERN"
        for file in (find $DIR -type f 2>/dev/null)
            if test -f "$file"
                set size (stat -f%z "$file" 2>/dev/null)
                set total (math "$total + $size")
            end
        end
    else
        for file in (find $DIR -type f -name "$PATTERN" 2>/dev/null)
            if test -f "$file"
                set size (stat -f%z "$file" 2>/dev/null)
                set total (math "$total + $size")
            end
        end
    end
    echo $total
end

set total_freed 0

echo "Starting extended cleanup process for rootless iOS with detailed report..."
echo "開始拡張クリーンアッププロセス..."

#---------------------------------
# Clean Cache Directories (キャッシュディレクトリ)
#---------------------------------
set CACHE_DIRS "/var/mobile/Library/Caches" "/var/mobile/Containers/Data/Application/*/Library/Caches"

for DIR in $CACHE_DIRS
    for expanded_dir in (eval echo $DIR)
        if test -d "$expanded_dir"
            set size_before (get_dir_size "$expanded_dir")
            echo "Cleaning cache directory: $expanded_dir"
            echo "Size before cleanup: "(bytes_to_human $size_before)
            find "$expanded_dir" -type f -delete 2>/dev/null
            echo "Freed: "(bytes_to_human $size_before)
            set total_freed (math "$total_freed + $size_before")
        else
            echo "Directory $expanded_dir not found. Skipping..."
        end
    end
end

#---------------------------------
# Clean Temporary Directories (一時ファイルディレクトリ)
#---------------------------------
set TMP_DIRS "/var/tmp" "/private/var/mobile/Library/Caches/com.apple.keyboards" "/private/var/mobile/Library/Caches/Snapshots" "/var/mobile/Containers/Data/Application/*/tmp"

for DIR in $TMP_DIRS
    for expanded_dir in (eval echo $DIR)
        if test -d "$expanded_dir"
            set size_before (get_dir_size "$expanded_dir")
            echo "Cleaning temporary directory: $expanded_dir"
            echo "Size before cleanup: "(bytes_to_human $size_before)
            find "$expanded_dir" -type f -delete 2>/dev/null
            echo "Freed: "(bytes_to_human $size_before)
            set total_freed (math "$total_freed + $size_before")
        else
            echo "Directory $expanded_dir not found. Skipping..."
        end
    end
end

#---------------------------------
# Clean Log Files (ログファイル, only *.l
