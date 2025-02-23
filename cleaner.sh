#!/usr/bin/env fish
# iCleaner Alternative with Detailed Freed Space Analysis for iOS >= 15 (Rootless) in Fish
# This script cleans cache, temporary files, and logs within /var,
# and provides a detailed report on the disk space freed.
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

echo "Starting cleanup process for rootless iOS with detailed report..."
echo "開始クリーンアッププロセス..."

#-------------------------------
# Clean Cache Directories
# キャッシュディレクトリのクリーンアップ
#-------------------------------
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

#-------------------------------
# Clean Temporary Directories
# 一時ファイルディレクトリのクリーンアップ
#-------------------------------
set TMP_DIRS "/var/tmp" "/private/var/mobile/Library/Caches/com.apple.keyboards" "/private/var/mobile/Library/Caches/Snapshots"

for DIR in $TMP_DIRS
    if test -d "$DIR"
        set size_before (get_dir_size "$DIR")
        echo "Cleaning temporary directory: $DIR"
        echo "Size before cleanup: "(bytes_to_human $size_before)
        find "$DIR" -type f -delete 2>/dev/null
        echo "Freed: "(bytes_to_human $size_before)
        set total_freed (math "$total_freed + $size_before")
    else
        echo "Directory $DIR not found. Skipping..."
    end
end

#-------------------------------
# Clean Log Files (only .log files)
# ログファイル（*.log）のクリーンアップ
#-------------------------------
set LOG_DIRS "/var/mobile/Library/Logs" "/var/mobile/Library/Caches/CrashReporter"

for DIR in $LOG_DIRS
    if test -d "$DIR"
        set size_before (get_dir_size "$DIR" "*.log")
        echo "Cleaning log directory: $DIR (only .log files)"
        echo "Size before cleanup: "(bytes_to_human $size_before)
        find "$DIR" -type f -name "*.log" -delete 2>/dev/null
        echo "Freed: "(bytes_to_human $size_before)
        set total_freed (math "$total_freed + $size_before")
    else
        echo "Directory $DIR not found. Skipping..."
    end
end

echo "-------------------------------------------------"
echo "Total space freed: "(bytes_to_human $total_freed)
echo "Cleanup completed."
exit 0
