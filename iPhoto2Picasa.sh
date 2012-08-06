#!/bin/sh

IPHOTODIR=~/Pictures/iPhoto\ Library/Masters

#tmpファイルから日付を読む
#tmpファイルがない場合、今日
#LASTDATE=`date +%Y%m%d000000`
LASTDATE=20120801000000

#iPhoto の Mastersフォルダから、該当日付以降のフォルダを検索
cd "$IPHOTODIR"
for dir in `find . -d 4 -print`
do
  dirname=`basename "$dir"`
  datedir=`echo $dirname|sed -e 's/-//'`
  #echo $datedir
  if [ $datedir -gt $LASTDATE ];then
    echo $datedir
  fi
done

#検索にマッチしたフォルダ
   #アルバム名のリストを取得
   #あれば、画像圧縮。そのアルバムにPOST
   #なければ、画像圧縮。撮影日付でCREATE

 #tmpファイルにUPしたフォルダを書く
