#!/bin/sh

IPHOTODIR=~/Pictures/iPhoto\ Library/Masters
TMPDIR=/tmp
TMPFILE=$TMPDIR/.iPhoto2Picasa
#cron実行用。
PATH=$PATH:/usr/local/bin

#コマンド存在チェック
#google コマンドがなければ終了

which google >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo "googlecl not found."
  echo "Download at http://code.google.com/p/googlecl/downloads/list and Install"
  exit 1
fi

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
  if [ "$dirnum" -gt $LASTDATE ];then
    for file in $dir/* #フルパス
    do
      filename=`basename $file` #ファイル名のみ
      albumname=`stat -l -t %Y/%m/%d "$file"|cut -f6 -d" "`
      ext=`echo ${filename##*.}|tr "A-Z" "a-z"` #拡張子（小文字）
      # アルバム名存在チェック
      google picasa list-albums |grep $albumname
      # アルバムがあればファイル名チェック
      if [ $? -eq 0 ];then
        google picasa list --title $albumname|cut -f1 -d,|grep $filename
        # ファイルがアルバムになければPOST
        if [ $? -eq 1 ];then
          if [ $ext -eq "jpg" ];then
            sips -Z 2048 "$file" --out "$TMPDIR/$filename"
          else
            cp "$file" "$TMPDIR/$filename"
          fi
          google picasa post --title $albumname $TMPDIR/$filename 
          rm $TMPDIR/$filename
        fi
        # アルバムがなければ作成してUPLOAD
      else
        if [ $ext -eq "jpg" ];then
          sips -Z 2048 "$file" --out "$TMPDIR/$filename"
        else
          cp "$file" "$TMPDIR/$filename"
        fi
        google picasa create --title $albumname "$TMPDIR/$filename"
        rm "$TMPDIR/$filename"
      fi
    done
  fi
done
#実行日を出力。
echo `date +%Y%m%d%H%M%S` >$TMPFILE
