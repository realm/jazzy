#!/bin/sh

CURRENT_PATH=$(pwd)

sh install.sh

# Test Syntax Text

syntax_text_result="$(sourcekitten --syntax-text 'import Foundation // Hello World!')"
syntax_text_expected="$(cat tests/syntax_text.txt)"
if [ "$syntax_text_result" == "$syntax_text_expected" ]; then
    echo "syntax_text passed"
else
    echo "syntax_text failed"
    echo "$syntax_text_result"
    exit 1
fi

# Test Syntax

echo 'import Foundation // Hello World' > syntax.txt
syntax_result="$(sourcekitten --syntax ${CURRENT_PATH}/syntax.txt)"
if [ "$syntax_result" == "$syntax_text_expected" ]; then
    echo "syntax passed"
else
    echo "syntax failed"
    echo "$syntax_result"
    exit 1
fi
rm syntax.txt

# Test Structure

echo 'class MyClass { var variable = 0 }' > structure.txt
structure_result="$(sourcekitten --structure ${CURRENT_PATH}/structure.txt | jsonlint -s)"
structure_expected="$(cat tests/structure.txt | jsonlint -s)"
if [ "$structure_result" == "$structure_expected" ]; then
    echo "structure passed"
else
    echo "structure failed"
    echo "$structure_result"
    exit 1
fi
rm structure.txt
