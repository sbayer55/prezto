#!/usr/bin/env zsh

local no_color='\033[0m'
local black='\033[0;30m'
local red='\033[0;31m'
local green='\033[0;32m'
local yellow='\033[0;33m'
local blue='\033[0;34m'
local pink='\033[0;35m'
local teal='\033[0;36m'
local grey='\033[0;90m'
local white='\033[0;38m'

# Set the quotes directory
QUOTES_DIR="$HOME/.zprezto/quotes"


REPLACEMENTS=(
    'no_color'      '\033[0m'
    'black'         '\033[0;30m'
    'red'           '\033[0;31m'
    'green'         '\033[0;32m'
    'yellow'        '\033[0;33m'
    'blue'          '\033[0;34m'
    'pink'          '\033[0;35m'
    'teal'          '\033[0;36m'
    'grey'          '\033[0;90m'
    'white'         '\033[0;38m'
)

# Check if the directory exists
if [[ ! -d "$QUOTES_DIR" ]]; then
    echo "Error: Quotes directory does not exist: $QUOTES_DIR"
    exit 1
fi

# Generate a random number between 1 and 100
RANDOM_NUMBER=$((RANDOM % 100 + 1))

# 30% chance of printing a quote
if (( RANDOM_NUMBER <= 30 )); then
    # Get a list of all files in the quotes directory
    QUOTE_FILES=("$QUOTES_DIR"/*)
    
    # Check if there are any files in the directory
    if (( ${#QUOTE_FILES[@]} == 0 )); then
        echo "No quote files found in $QUOTES_DIR"
        exit 1
    fi
    
    # Select a random file
    RANDOM_FILE=${QUOTE_FILES[$RANDOM % ${#QUOTE_FILES[@]} + 1]}

    CONTENT=$(<"$RANDOM_FILE")

    # # Read the file content
    # FULL_CONTENT=$(<"$RANDOM_FILE")

    # # Split the content into sections
    # SECTIONS=("${(@f)${(ps:\n\n:)FULL_CONTENT}}")
    
    # # Select a random section
    # CONTENT=${SECTIONS[$RANDOM % ${#SECTIONS[@]} + 1]}

    for ((i=1; i<=${#REPLACEMENTS[@]}; i+=2)); do
        SEARCH="{{${REPLACEMENTS[i]}}}"
        REPLACE="${REPLACEMENTS[i+1]}"
        CONTENT="${CONTENT//$SEARCH/$REPLACE}"
    done
    
    # Print the contents of the random file
    echo "${CONTENT}"
fi