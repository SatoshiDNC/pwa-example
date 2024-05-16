#!/bin/bash

# Calculates the total time each dev contributed to the current git repo, and
# the total wages asked.
#
# Design:
#
# 1. Commits with less than 15 minutes between form a contiguous block of time
#    (an arbitrary cutoff which was heuristically determined).
#
# 2. Isolated commits are worth at least as much as the threshold of point 1.
#
# 3. Time spent can be manually indicated with the first word in the commit
#    subject line, using one of the following two formats:
#
#     * 1.5h would signify one and a half hours spent on this (and any
#       overlapping prior) commits.
#
#     * 90m would also signify one and a half hours. In both cases, the final
#       results of the calculations are aways in seconds.
#
# 4. Developers can set a new wage rate going forward using an optional
#    extension to the above syntax. This initially defaults to 3600 per hour.
#
#     * 1.5h@4000/h would request compensation of 4000 per hour for this block
#       of time and all future blocks until another wage is specified.
#
#     * 90m@4000/h would have the same effect.
#
#    Note that there is no financial unit assumed. The user of the script will
#    determine the unit; it should be consistent across the entire repository.

CONTIGUITY_SECONDS=900 # 15 minutes
INITIAL_PAYRATE=3600 # per hour, unit not specified; see above

JSON_OUT="$1"
if [ "$JSON_OUT" == "" ]; then
  JSON_OUT=timecalc.json
fi
TIMELOG=timelog.tmp
REVERSED=reversed.tmp
MODIFIED=modified.tmp
FILTERED=filtered.tmp

COMMIT=`git rev-parse HEAD`
git log --first-parent --pretty=%at%x20%an%x20%aE%x20%s > $TIMELOG

echo
num_devs=`cut -d' ' -f2,3 <"$TIMELOG"|sort|uniq|wc -l`
unique_devs=(`cut -d' ' -f2,3 <"$TIMELOG"|sort|uniq`)
time_spent_totals=()
pay_earned_totals=()
echo "Calculating time contributed by $num_devs devs:"

total_time_spent=0
total_pay_earned=0
: > $JSON_OUT
echo "{\"commit\":\"$COMMIT\",\"data\":[" >> $JSON_OUT
for ((i = 0; i < ${#unique_devs[@]}; i+=2)); do
  dev="${unique_devs[i]}"
  addr="${unique_devs[i+1]}"

  # filter the data to ensure every commit has the dev's payrate with it, for simplicity
  tac "$TIMELOG" > "$REVERSED"
  : > "$MODIFIED"
  cur_payrate=$INITIAL_PAYRATE
  while IFS= read -r line; do
    fields=(`echo "$line"`)
    if [ "${fields[1]} ${fields[2]}" == "$dev $addr" ]; then
      timestamp="${fields[0]}"
      infocode="${fields[3]}"

      # exact duplicate of lines below
      devhours=`echo "$infocode"|sed -e '/^[.0-9]\+h\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)h\(@[0-9]\+\/h\)\?$/\1/'`
      devmins=`echo "$infocode"|sed -e '/^[.0-9]\+m\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)m\(@[0-9]\+\/h\)\?$/\1/'`
      payrate=`echo "$infocode"|sed -e '/^[.0-9]\+h\?m\?\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)h\?m\?\(@[0-9]\+\/h\)\?$/\2/' -e 's/^@\([0-9]\+\)\/h$/\1/'`

      # keep the same payrate if not otherwise specified
      if [ "$payrate" != "" ]; then
        cur_payrate=$payrate
      fi

      # regenerate info with payrate always included
      if [ "$devhours" != "" ]; then
        infocode="${devhours}h@${cur_payrate}/h"
      elif [ "$devmins" != "" ]; then
        infocode="${devhours}m@${cur_payrate}/h"
      else
        infocode="0h@${cur_payrate}/h" # 0h for syntax; will behave like none specified
      fi
      fields[3]="$infocode"

      # output the modified data
      echo ${fields[@]} >> "$MODIFIED"
    fi
  done < "$REVERSED"
  tac "$MODIFIED" > "$FILTERED"

  # now for the main calculation
  time_spent=0
  pay_earned=0
  coveredto=
  coveredfrom=
  while IFS= read -r line; do
    fields=(`echo "$line"`)
    if [ "${fields[1]} ${fields[2]}" == "$dev $addr" ]; then
      timestamp="${fields[0]}"
      infocode="${fields[3]}"

      # get the time spent indicated by the dev (hours or minutes, not both)
      devhours=`echo "$infocode"|sed -e '/^[.0-9]\+h\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)h\(@[0-9]\+\/h\)\?$/\1/'`
      devmins=`echo "$infocode"|sed -e '/^[.0-9]\+m\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)m\(@[0-9]\+\/h\)\?$/\1/'`
      payrate=`echo "$infocode"|sed -e '/^[.0-9]\+h\?m\?\(@[0-9]\+\/h\)\?$/ ! s/.*//' -e 's/^\([.0-9]\+\)h\?m\?\(@[0-9]\+\/h\)\?$/\2/' -e 's/^@\([0-9]\+\)\/h$/\1/'`

      # convert it to seconds
      devhours_insecs=`awk -vp=$devhours -vq=3600 'BEGIN{printf "%d" ,p * q}'`
      devmins_insecs=`awk -vp=$devmins -vq=60 'BEGIN{printf "%d" ,p * q}'`
      devdur=$(( devhours_insecs + devmins_insecs ))

      # clamp to the minimum
      devdur=$(( CONTIGUITY_SECONDS > devdur ? CONTIGUITY_SECONDS : devdur ))

      # establish how far back we're accounted for, if needed
      if [ "$coveredfrom" == "" ]; then
        coveredto=$timestamp
        coveredfrom=$(( timestamp - devdur ))
      fi

      # extend coverage if we're still in the same coverage period
      if [ "$timestamp" -ge "$coveredfrom" ] && [ "$timestamp" -le "$coveredto" ]; then
        from=$(( timestamp - devdur ))
        coveredfrom=$(( from < coveredfrom ? from : coveredfrom))
      fi

      # if this commit falls outside the existing coverage period, add and reset
      if [ "$timestamp" -lt "$coveredfrom" ]; then
        time_spent=$(( time_spent + (coveredto - coveredfrom) ))
        pay_earned=$(( pay_earned + (coveredto - coveredfrom) * payrate / 3600 ))
        coveredto=$timestamp
        coveredfrom=$(( timestamp - devdur ))
      fi

    fi
  done < "$FILTERED"

  # add the last/running coverage period
  time_spent=$(( time_spent + (coveredto - coveredfrom) ))
  pay_earned=$(( pay_earned + (coveredto - coveredfrom) * payrate / 3600 ))

  # print progress
  dev_num=$((i/2+1))
  echo "$dev_num. $time_spent => $pay_earned $dev $addr"

  # build the JSON
  if [ $dev_num -lt $num_devs ]; then
    comma=","
  else
    comma=""
  fi
  echo "{time_secs:$time_spent,pay_asked:$pay_earned,dev_nym:\"$dev\",lightning_address:\"$addr\"}$comma" >> $JSON_OUT

  time_spent_totals+=($time_spent)
  pay_earned_totals+=($pay_earned)
  total_time_spent=$(( total_time_spent + time_spent ))
  total_pay_earned=$(( total_pay_earned + pay_earned ))
done
echo "]}" >> $JSON_OUT

# print summary
echo "$total_time_spent => $total_pay_earned" overall
echo
for ((i = 0; i < ${#unique_devs[@]}; i+=2)); do
  time_spent="${time_spent_totals[i/2]}"
  pay_earned="${pay_earned_totals[i/2]}"
  echo "$(( 100 * time_spent / total_time_spent ))%/$(( 100 * pay_earned / total_pay_earned ))% ${unique_devs[i]}"
done

rm "$FILTERED"
rm "$MODIFIED"
rm "$REVERSED"
rm "$TIMELOG"
