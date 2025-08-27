#!/bin/bash

cleanup() {
    rm -f $TMPFILE
}

QUERY="$@"
QUERY=$(echo $QUERY | tr ' ' '+')
TMPFILE=$(mktemp -u)
trap cleanup SIGINT
curl -s --max-time 1 --connect-timeout 1 -H "Connection: close" -o $TMPFILE https://github.com/search?q=$QUERY+AND+PoC&type=repositories&s=stars&o=desc
sleep 1
COUNT=$(grep hl_name $TMPFILE | sed 's#</script>##g; s#<script.*>##g' | jq | grep -E "hl_name" | wc -l)
echo "$COUNT results found"
NUM=1
ANS=n
while [ $COUNT -ge 0 ] && [ "${ANS,,}" != "y" ]; do
    PAIR="grep hl_name $TMPFILE | sed 's#</script>##g; s#<script.*>##g' | jq | grep -A 1 -m $NUM hl_name | tail -n 2"
    REPO=$(echo $PAIR | sh | head -n 1 | cut -d '"' -f 4 | sed -e 's|</b>|-|g' -e 's|<[^>]*>||g')
    DESC=$(echo $PAIR | sh | tail -n 1 | cut -d '"' -f 4 | sed -e 's|</b>|-|g' -e 's|<[^>]*>||g')
    echo $REPO
    echo "Description: $DESC"
    read -p "Clone the above repo? " ANS
    if [ "${ANS,,}" == "yes" ]; then
        ANS=y
    fi
    if [ "${ANS,,}" == "no" ]; then
        ANS=n
    fi
    if [ "${ANS,,}" == "y" ]; then
        git clone https://github.com/$REPO.git
    elif [ "${ANS,,}" == "n" ]; then
        ((NUM++))
        ((COUNT--))
        echo ""
    else
        echo "Invalid response. Please try again"
        continue
    fi
done
cleanup
