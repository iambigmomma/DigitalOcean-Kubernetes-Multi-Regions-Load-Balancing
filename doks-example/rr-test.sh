#!/bin/bash
while read -r URL; do
    echo -n "$URL --> "
    wget -q -O - "$URL" | \
       tr "\n" " " | \
       sed 's|.*<title>\([^<]*\).*</head>.*|\1|;s|^\s*||;s|\s*$||'
    echo
done