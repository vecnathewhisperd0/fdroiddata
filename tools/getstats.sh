#!/bin/env bash

# Get options
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
grep_file=""
versions=1
file_suf=""
output="mystats"
USAGE="Usage: $0 -f <app name> [-v <num versions of stats>] [-a] [-o <output file>]; -a searches per app version stats"

while getopts "hv:f:o:a" opt; do
    case "$opt" in
    h)  echo $USAGE
		exit 0
		;;
    v)  versions=$OPTARG
        ;;
    f)  grep_file=$OPTARG
        ;;
    a)  file_suf="_version"
        ;;
    o)  output=$OPTARG
		;;
    esac
done

shift $((OPTIND-1))

if [ -z $grep_file ]
then
  echo $USAGE
  exit 1
fi

echo Starting git show for $versions revisions of stats and $grep_file app
output=$output$file_suf
early_break=0

echo -n > $output
for i in `seq 0 $versions`;
do 
  if [ `expr $i % 10` == "0" ]
  then
   pct=$i
  else
   pct=""
  fi

#  echo "# ver $i" >> $output
  line=`git show HEAD~${i}:stats/total_downloads_app${file_suf}.txt | grep $grep_file`
  if [ $? == "1" ]
  then
    echo "Early break at $i version"
	early_break=1
    break
  fi
  echo $line | sed -e 's/\\n/ /g' >> $output
  echo -n $pct.
done
echo

if [ $early_break == "0" ]
then
  echo "WARN: Consider increasing num version of stats (-v) since it appears app exists in older versions too"
fi

echo "Uniquify..."
uniq $output | tac > $output.uniq

col_names=`tail -1 $output.uniq`
col_names_arr=($col_names)
num_versions=`tail -1 $output.uniq | wc -w`
num_versions=`expr $num_versions / 2`
echo "Plotting $num_versions versions..."

gplt_cmd="set terminal png; set output \"$output.png\";"
gplt_cmd="$gplt_cmd plot "

for i in `seq 1 $num_versions`
do
  echo -n "$i "
  col_num=`expr $i \* 2`
  col_name_ind=`expr $col_num - 2`
  col_name=${col_names_arr[$col_name_ind]}
  gplt_cmd="$gplt_cmd \"$output.uniq\" using $col_num title \"$col_name\" with lp"
  if [ $i != $num_versions ]
  then
    gplt_cmd="$gplt_cmd, "
  fi
done
gplt_cmd="$gplt_cmd;"
echo
#echo "Gnuplot: $gplt_cmd"
echo $gplt_cmd | gnuplot
