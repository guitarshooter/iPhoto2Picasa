#!/bin/sh

IPHOTODIR=~/Pictures/iPhoto\ Library/Masters
TMPDIR=/tmp
TMPFILE=$TMPDIR/.iPhoto2Picasa

#tmpファイルから日付を読む
if [ -f $TMPFILE ];then
  LASTDATE=`cat $TMPFILE`
else
  LASTDATE=`date +%Y%m%d000000`
fi

#iPhoto の Mastersフォルダから、該当日付以降のフォルダを検索
cd "$IPHOTODIR"
for dir in `find . -d 4 -print`
do
  targetdir=`basename "$dir"`
  dirnum=`echo $targetdir|sed -e 's/-//'`
  #albumname=`echo $dir|sed -e "s/\/$targetdir//"|sed -e "s/^\.\///g"`
  if [ $dirnum -gt $LASTDATE ];then
    for file in $dir/*.JPG
    do
      filename=`basename $file`
      albumname=`stat -l -t %Y/%m/%d $file|cut -f6 -d" "`
      # アルバム名存在チェック
      google picasa list-albums |grep $albumname
      # アルバムがあればファイル名チェック
      if [ $? -eq 0 ];then
        google picasa list --title $albumname|cut -f1 -d,|grep $filename
	# ファイルがアルバムになければPOST
	if [ $? -eq 1 ];then
	  sips -Z 2048 $file --out $TMPDIR/$filename
	  google picasa post --title $albumname $TMPDIR/$filename 
	  if [ $? -eq 0 ];then
	    echo "$albumname - $file POST"
	  fi
	fi
      # アルバムがなければ作成してUPLOAD
      else
        echo "CREATE"
	sips -Z 2048 $file --out $TMPDIR/$filename
	google picasa create --title $albumname $TMPDIR/$filename
	if [ $? -eq 0 ];then
	  echo "$albumname CREATE $file POST"
	fi
      fi
    done
  fi
done

echo `date +%Y%m%d%H%M%S` >$TMPFILE

#検索にマッチしたフォルダ
   #アルバム名のリストを取得
   #あれば、画像圧縮。そのアルバムにPOST
   #なければ、画像圧縮。撮影日付でCREATE

 #tmpファイルにUPしたフォルダを書く
