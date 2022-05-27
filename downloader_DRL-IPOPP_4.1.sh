#!/bin/bash
SName="DRL-IPOPP_4.1"
SCheckSum="md5_checksum.txt"
SegName="DRL-IPOPP_4.1-seg"
segments="segments.txt"
	
err_msg ()
{
echo ""
echo "Download failed. Please visit DRL website to get the most recent version of the downloader script for this package. If you continue having difficulties, please contact DRL for assistance."
}

get_segs ()
{
for i in $( seq -w 0 $fix )
do
   link=$( cat $segments | awk '{printf $1"\n"}' | head -n $((10#$i+1)) | tail -n 1 )
   expected_size=$( cat $segments | awk '{printf $2"\n"}' | head -n $((10#$i+1)) | tail -n 1 )

   if [[ -f "$SegName$i" ]]
   then
     current_size=$( wc -c $SegName$i | awk '{printf $1}' )
     if [ $current_size -ne $expected_size ]
     then
        rm -f $SegName$i
        wget --timeout=90 -q -c -N --content-disposition "$link"
        foo=$?
        if [ $foo -ne 0 ]
        then
        err_msg
        exit 0
        fi
     fi
     continue
   fi

   wget --timeout=90 -q -c -N --content-disposition "$link"
        foo=$?
        if [ $foo -eq 4 ]
        then
        err_msg
        exit 0
        fi
done
}

get_segs2 ()
{
for i in $( seq -w 0 $fix )
do
   link=$( cat $segments | awk '{printf $1"\n"}' | head -n $((10#$i+1)) | tail -n 1 )
   expected_size=$( cat $segments | awk '{printf $2"\n"}' | head -n $((10#$i+1)) | tail -n 1 )

   if [[ -f "$SegName$i" ]]
   then
     current_size=$( wc -c $SegName$i | awk '{printf $1}' )
     if [ $current_size -ne $expected_size ]
     then
        rm -f $SegName$i
        wget --timeout=90 -q -c -N --content-disposition "$link"
        foo=$?
        if [ $foo -ne 0 ]
        then
        err_msg
        exit 0
        fi
     fi
     continue
   fi
done
}



pdisplay ()
{
  stZ="*-----*-----*-----*-----*"
  loop=0
  while true
  do
   case "$1" in
   Downloading)
    dSUM=$( du -bc ${SegName}* 2>/dev/null | tail -1 | awk '{print $1}')
    pSUM=$(echo "${dSUM}/${2}*100" | bc -l 2>/dev/null )
    pT=$( printf "%0.0f\n" $pSUM )"%   \r   "
    ;;
   Assembling)
    dSUM=$( du -bc ${SName}.tar.gz 2>/dev/null | tail -1 | awk '{print $1}')
    pSUM=$(echo "${dSUM}/${2}*100" | bc -l 2>/dev/null )
    pT=$( printf "%0.0f\n" $pSUM )"%   \r   "
    ;;
   Verifying)
    pT="   \r   "
    ;;
   esac
    loop=$(($loop % 25))
    echo -en "\e[K"$1" ${stZ:${loop}:5} "$pT
    loop=$(($loop + 5))
    sleep 5
  done
}
kdisplay ()
{
  exec 2>/dev/null
  kill $1
}

Dpackage=$( wget --timeout=90 -q -O $segments "http://directreadout.sci.gsfc.nasa.gov/download_package.cfm?softwareid=320&uniqueid=0DBFE976-A9F7-A942-FAB98E3AB2F84B46" )
foo=$?
if [ $foo -ne 0 ]
then
err_msg
exit 0
fi

sleep 5

SegSize=$( cat $segments | awk '{sum+=$2} END {printf ("%0.0f\n", sum)}' )
count=$( cat $segments | wc -l )

if [ $count -lt 10 ]
then
fix=10
else
fix=$count
fi

pdisplay "Downloading" $SegSize &
D_id=$!
trap "kdisplay $D_id; exit" INT TERM EXIT

get_segs

sleep 5

get_segs2	

sleep 5

get_segs2

kdisplay $D_id
	
pdisplay "Assembling" $SegSize &
A_id=$!
trap "kdisplay $A_id; exit" INT TERM EXIT
cat ${SegName}* > "${SName}.tar.gz"
kdisplay $A_id

pdisplay "Verifying" &
N_id=$!
trap "kdisplay $N_id; exit" INT TERM EXIT
OK=$( md5sum -c ${SCheckSum} | grep OK | wc -l )
kdisplay $N_id
	
if [ $OK -eq "1" ]
then
rm ${SegName}* ${SCheckSum}
rm $segments
echo "File successfully downloaded"
else
err_msg
fi

exit 0
	
