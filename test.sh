#!/bin/sh

CURRENT_PATH=$(pwd)

sh install.sh

# Test Syntax Text

syntax_text_result="$(sourcekitten --syntax-text 'import Foundation // Hello World!')"
syntax_text_expected="$(cat tests/syntax_text.json)"
if [ "$syntax_text_result" == "$syntax_text_expected" ]; then
    echo "syntax text passed"
else
    echo "syntax text failed"
    echo "$syntax_text_result"
    exit 1
fi

# Test Syntax

echo 'import Foundation // Hello World' > syntax.swift
syntax_result="$(sourcekitten --syntax ${CURRENT_PATH}/syntax.swift)"
if [ "$syntax_result" == "$syntax_text_expected" ]; then
    echo "syntax passed"
else
    echo "syntax failed"
    echo "$syntax_result"
    exit 1
fi
rm syntax.swift

# Test Structure

echo 'class MyClass { var variable = 0 }' > structure.swift
structure_result="$(sourcekitten --structure ${CURRENT_PATH}/structure.swift | jsonlint -s)"
structure_expected="$(cat tests/structure.json | jsonlint -s)"
if [ "$structure_result" == "$structure_expected" ]; then
    echo "structure passed"
else
    echo "structure failed"
    echo "$structure_result"
    exit 1
fi
rm structure.swift

# Test Swift Documentation Generation

BICYCLE_FILE="${CURRENT_PATH}/tests/Bicycle.swift"
BICYCLE_COMMAND="sourcekitten --single-file ${BICYCLE_FILE} -j4 ${BICYCLE_FILE}"
ESCAPED_CURRENT_PATH=$(echo ${CURRENT_PATH} | sed 's/\//\\\\\\\//g')

doc_result="$(${BICYCLE_COMMAND} 2> /dev/null | sed s/${ESCAPED_CURRENT_PATH}/sourcekit_path/g | jsonlint -s)"
doc_expected="$(cat tests/Bicycle.json | jsonlint -s)"
if [ "$doc_result" == "$doc_expected" ]; then
    echo "swift documentation generation passed"
else
    echo "swift documentation generation failed"
    echo "$doc_result"
    exit 1
fi

# Test Objective-C Documentation Generation

MUSICIAN_FILE="${CURRENT_PATH}/tests/JAZMusician.h"
MUSICIAN_COMMAND="sourcekitten --objc ${MUSICIAN_FILE}"
ESCAPED_CURRENT_PATH=$(echo ${CURRENT_PATH} | sed 's/\//\\\//g')

doc_result="$(${MUSICIAN_COMMAND} 2> /dev/null | sed s/${ESCAPED_CURRENT_PATH}/sourcekit_path/g)"
doc_expected="$(cat tests/Musician.xml)"
if [ "$doc_result" == "$doc_expected" ]; then
    echo "objc documentation generation passed"
else
    echo "objc documentation generation failed"
    echo "$doc_result"
    exit 1
fi
