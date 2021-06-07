#!/bin/bash
export DFUSETOKEN=`cat ../dfuse.token`
step=$((500))
i=$((0))
rm -f $1.partnames
while true ; do
	j=$(( $i + $step ))
	name=$1.allscopes.$i.$j.binary
	scopes=`../stores/scopelist_piper $i $j < $1.scopelist.json`
	if [ "$scopes" == "" ] ; then
		break
	fi
	curl --get \
	     -k \
	     -H "Authorization: Bearer $DFUSETOKEN" \
	     --data-urlencode "account=prospectorsc" \
	     --data-urlencode "table=$1" \
	     --data-urlencode "scopes=$scopes" \
	     --data-urlencode "json=false" \
	     --data-urlencode "key_type=$2" \
	     --compressed \
	     "https://wax.dfuse.eosnation.io/v0/state/tables/scopes" \
	     > $name
	i=$(( $j ))
	echo $name >> $1.partnames
done
cat $1.partnames | xargs ../stores/table_gluer $1.allscopes.binary
