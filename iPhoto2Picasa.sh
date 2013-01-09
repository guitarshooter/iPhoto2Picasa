#!/bin/sh

IPHOTODIR=~/Pictures/iPhoto\ Library/Masters
BASEDIR=$(cd $(dirname $0);pwd)
TMPDIR=$BASEDIR/work
TMPFILE=$BASEDIR/.iPhoto2Picasa
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
which ffmpeg >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo "ffmpeg not found."
  echo "Prease Install ffmpeg"
  exit 1
fi

#TMPDIR作成 あれば動作中なので終了
mkdir $TMPDIR 2>/dev/null ||(echo "Cannot run multiple." >&2;exit 9;)
trap "rm -rf $TMPDIR;exit" 1 2 3 15

#動画・静止画ファイルをリサイズする関数
function fnc_resize()
{
  file=$1
  filename="`basename "$file"`" #ファイル名のみ
  ext=`echo ${filename##*.}|tr "A-Z" "a-z"` #拡張子（小文字）
  if [ $ext = "jpg" ];then
    sips -Z 2048 "$file" --out "$TMPDIR/$filename"
    UPLOADFILE="$TMPDIR/$filename"
  elif [ $ext = "mov" ];then
    UPLOADFILE=$TMPDIR/"`echo $filename|sed -e 's/.mov/.mp4/'`"
    ffmpeg -i "$file" -s 960x540 "$UPLOADFILE"
  else
    #cp "$file" "$TMPDIR/$filename"
    UPLOADFILE="$file"
  fi
}

if [ $# -ge 1 ];then
  for f in $*
  do
    fnc_resize $f
  done
else
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
        filename="`basename "$file"`" #ファイル名のみ
        albumname=`stat -l -t %Y/%m/%d "$file"|cut -f6 -d" "`
        # アルバム名存在チェック
        google picasa list-albums |grep $albumname
        # アルバムがあればファイル名チェック
        if [ $? -eq 0 ];then
          google picasa list --title $albumname|cut -f1 -d,|grep "$filename"
          # ファイルがアルバムになければPOST
          if [ $? -eq 1 ];then
            fnc_resize "$file"
            google picasa post --title $albumname "$UPLOADFILE"
          fi
          # アルバムがなければ作成してUPLOAD
        else
          fnc_resize "$file"
          if [ -f "$UPLOADFILE" ];then
            google picasa create --title $albumname "$UPLOADFILE"
          fi
        fi
      done
    fi
  done
  #最終アップロードDIRを出力。
  #echo `date +%Y%m%d%H%M%S` >$TMPFILE
  echo $dirnum >$TMPFILE
fi
rm -rf $TMPDIR
