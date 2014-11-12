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

# Test Documentation Generation
BICYCLE_FILE="${CURRENT_PATH}/tests/Bicycle.swift"
BICYCLE_COMMAND="sourcekitten --single-file ${BICYCLE_FILE} -j4 ${BICYCLE_FILE}"

doc_result="$(${BICYCLE_COMMAND} 2> /dev/null | jsonlint -s)"
doc_expected="$(cat tests/Bicycle.json | jsonlint -s)"
if [ "$doc_result" == "$doc_expected" ]; then
    echo "documentation generation passed"
else
    echo "documentation generation failed"
    echo "$doc_result"
    exit 1
fi

# Test Documentation Coverage

doc_coverage_result="$(${BICYCLE_COMMAND} 2>&1 > /dev/null)"
doc_coverage_expected="Bicycle.swift is 100% documented"
if [ "$doc_coverage_result" == "$doc_coverage_expected" ]; then
    echo "documentation coverage passed"
else
    echo "documentation coverage failed"
    echo "$doc_coverage_result"
    exit 1
fi
