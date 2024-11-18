#!/bin/bash
url=$MS_REPO_URL

function source () {
    curl -s $url -o ~/.ms.json
}

function edit {
    curl $url | jq > ~/.ms.json
    vim ~/.ms.json
    curl -s -X PUT -H "Content-Type: application/json" -d @.ms.json $url > /dev/null
}

debug=false
if [ "$1" == "-d" ]; then
    debug=true
fi

if [ "$1" == "-" ]; then
    pgrep mpv
    exit
fi

if [ "$1" == "-e" ]; then
    edit
    echo "Done!"
    exit
fi

if [ ! -f ~/.ms.json ]; then
    echo "Sourcing index file..."
    source
fi

choice=$(cat ~/.ms.json | jq -r 'map(.name)[]' | fzf --height=40%)

if [ -z "$choice" ]; then
    echo "Good Bye!";
    exit
fi

videoURL=$(cat ~/.ms.json | jq ".[] | select(.name==\"$choice\").url")

if [ "$videoURL" == null ]; then
    videoURL=$(cat ~/.ms.json | jq ".[] | select(.name==\"$choice\").urls | .[]")
fi

stream="mpv --script-opts=osc-visibility=always --no-video --input-ipc-server=/tmp/sock $videoURL &"

if [ $debug = true ]; then
    echo $stream
    exit
fi

isPlaying=$(pgrep mpv)

if [ ! -z "$isPlaying" ]; then
    killall mpv
fi

eval $stream

echo "Now Playing: $choice @$(pgrep mpv)"
