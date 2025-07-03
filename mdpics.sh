
#!/usr/bin/env bash
# Author : Amr Alasmer
# Project Name : mdpics
# License: GPLv3 or later


# Copyright (C) 2025 Amr Alasmer

# This file is part of mdpics.

# mdpics is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later 
# version.

# mdpics is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.






# check deps
command -v curl &> /dev/null || { echo "please install curl to be able to run this program!" &>2 ; exit 1; }
command -v base64 &> /dev/null || { echo "please install base64 to be able to run this program!" &>2 ; exit 1; }
command -v gawk &> /dev/null || { echo "please install gawk to be able to run this program!" &>2 ; exit 1; }

get_pic(){
    if [ $# -ne 1 ]; then
        exit 1
    fi

    local __COUNTER=$1
   
    # get the url from url details file
    local __URL="$(/usr/bin/env gawk -v COUNTER="$__COUNTER" 'BEGIN{c=1} /^url: /{if (c==COUNTER) {print $2;exit} else{c++;next}}' "$__TMP/urlsdetails" )"
    
    # get the url name from url details file
    local __URL_NAME="$(/usr/bin/env gawk -F": " -v COUNTER="$__COUNTER" 'BEGIN{c=1} /^urlname: /{if (c==COUNTER) {print $2;exit} else{c++;next}}' "$__TMP/urlsdetails" )"

    # send GET request to the url to get the picture, store the picture in new file in the temp dir "file name is the picture number"
    # and store request/response headers in new file in the temp dir "file name is the picture number, followed by _headers word"
    /usr/bin/env curl -L -v "$__URL" -o  "$__TMP/$__COUNTER" 2> "$__TMP/${__COUNTER}_headers"  || exit 1

    # encode the picture using base64 encode, and store result in new file in the temp dir "file name is the picture number, followed by _encoded word"
    /usr/bin/env base64 --wrap=0 "$__TMP/$__COUNTER" > "$__TMP/${__COUNTER}_encoded" || exit 1

    # get image type "suffix/extinsion", by searching for content-type in headers file
    local __SUFFIX="$(/usr/bin/env gawk  '/content-type:/ {match($0,/content-type: image\/(.*)/,arr);gsub("\r","",arr[1]); print arr[1]}' "$__TMP/${__COUNTER}_headers"  )"
    
    # if the first method failed, then try using "file" utility to get file type
    if [ -z "$__SUFFIX" ]; then 
        __SUFFIX="$(file "$__TMP/$__COUNTER" | /usr/bin/env   gawk  -F: '{split($2,arr," "); print arr[1]}' )"    
    fi 
    
    # if the both methods failed to get the image type, then exit
    if [ -z "$__SUFFIX" ]; then 
        exit 1
    fi 

    # construct the new line 
    local __NEW_LINE="![$__URL_NAME](data:image/$__SUFFIX;base64,$(/usr/bin/env cat "$__TMP/${__COUNTER}_encoded"))"

    # store the new line in  "$__TMP/${__COUNTER}_newline"
    echo -n "$__NEW_LINE" > "$__TMP/${__COUNTER}_newline"

    # remove unused files 
    /usr/bin/env  rm "$__TMP/${__COUNTER}_encoded" "$__TMP/$__COUNTER" "$__TMP/${__COUNTER}_headers" 2>/dev/null 

}


# create temp dir
__TMP=$(/usr/bin/env mktemp -d)

if [ $# -ne 1 ]; then
    exit 1
fi

# check if the provided .md file is readable
if [ ! -r "$1" ]; then
    exit 1
fi

INPUT_FILE="$1"

# gawk script to detect all images urls, and collect url details, like urlname, url
/usr/bin/env gawk   '
    function get_image_data(line){
        #extract the url, the extract done by chatGPT
            match(line, /!\[([^\]]+)\]\(([^\) ]+)\)/, arr)
            urlname = arr[1]
            url = arr[2]
            print "counter: " c
            print "urlname: " urlname
            print "url: " url
            print ""

    }

    BEGIN{c=1}

  
    #if the line matches the regex  /!\[[^\]]*\]\(https?:[^\) ]+\)/ , for example [Hello World](http://www.github.com/a.png)
    /!\[[^\]]*\]\(https?:[^\) ]+\)/{
        get_image_data($0)
        c++
    } 
    
   ' "$INPUT_FILE" > "$__TMP/urlsdetails" || exit 1


__PREV_COUNTER=0
while true; do
    # set the counter to the next value in url details file 
    __COUNTER=$(/usr/bin/env gawk -v PREVCOUNTER="$__PREV_COUNTER" '/^counter: /{if ($2<=PREVCOUNTER) {next} else{print $2;exit}}' "$__TMP/urlsdetails" ); 
    __PREV_COUNTER=$__COUNTER
    if [ -z "$__COUNTER" ]; then 
        break
    fi 

    
    get_pic $__COUNTER &
    
    # get all pids to wait
    pids+=( $! )
    
    

done

for pid in "${pids[@]}"; do
    wait $pid
done


# gawk script to replace url with the base64 copy of the image, for more details look into the script comments
/usr/bin/env gawk -v TMP="$__TMP"  '
function replaceurl(line){            
    file = TMP "/" c "_newline"
    getline new_line < file
    
    # replace url with the new base64 copy of the image
    gsub(/!\[[^\]]*\]\(http[^\) ]+\)/, new_line, line)

    return line
}


    # BEGIN{replaced="false";c=1}
    BEGIN{c=1}


    #if the line matches the regex  /!\[[^\]]*\]\(https?:[^\) ]+\)/ , for example [Hello World](http://www.github.com/a.png)
    /!\[[^\]]*\]\(https?:[^\) ]+\)/{
        print replaceurl($0)
        c++
        next
    } 
    
    #default case
    {print $0}' "$INPUT_FILE" 



# clean the temp files
/usr/bin/env rm -r "$__TMP"  2>/dev/null || exit 1

