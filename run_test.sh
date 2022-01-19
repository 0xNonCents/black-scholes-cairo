clear &&
    mkdir ./artifacts || true
touch ./artifacts/$1.json || true
cairo-compile ./tests/$1.cairo --output ./artifacts/$1.json &&
    cairo-run --program=./artifacts/$1.json --layout=all
