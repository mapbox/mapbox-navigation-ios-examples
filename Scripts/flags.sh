#!/usr/bin/env bash

# http://overpass-turbo.eu/s/19QW
jq -r '.features | map(.properties | .["flag:wikidata"] | values | split(";")[]) | unique | sort_by(.[1:] | tonumber) | map("wd:" + .) | join(" ") | "SELECT * WHERE { VALUES ?flag {" + . + "} ?flag wdt:P18 ?image.}" | @uri "https://query.wikidata.org/sparql?format=json&query=\(.)"' flagpoles.geojson | xargs curl > flags.json
#jq -r '.results.bindings | map(@sh "curl \(.image.value) -o \(.flag.value | "flags/" + split("/")[-1])")[]' flags.json

jq -r '.results.bindings | map(.image.value | "File:" + split("/")[-1])[:50] | "https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url&iiurlheight=100&titles=" + join("%7C")' flags.json | xargs curl > thumbs.json
jq -r '.results.bindings | map(.image.value | "File:" + split("/")[-1])[50:] | "https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url&iiurlheight=100&titles=" + join("%7C")' flags.json | xargs curl > thumbs2.json

jq -sr '(.[0].results.bindings | map({key: (.image.value | "File%3A" + split("/")[-1]), value: (.flag.value | split("/")[-1])}) | from_entries) as $titles | (.[1].query.pages + .[2].query.pages) | map({flag: ($titles[.title | @uri | gsub("\\("; "%28") | gsub("\\)"; "%29") | gsub("\\x27"; "%27")]), "1x": .imageinfo[0].thumburl, "2x": (.imageinfo[0].responsiveUrls | .["2"])} | "curl \(.["1x"] | @sh) -o flags/\(.flag).png", "curl \(.["2x"] | @sh) -o flags/\(.flag)@2x.png")[]' flags.json thumbs.json thumbs2.json | bash
