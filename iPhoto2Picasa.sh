#!/bin/sh

IPHOTODIR=~/Pictures/iPhoto\ Library/Masters
BASEDIR=$(cd $(dirname $0);pwd)
TMPDIR=$BASEDIR/work
TMPFILE=$BASEDIR/.iPhoto2Picasa
CONFFILE=$BASEDIR/.iPhoto2Picasa.conf #設定ファイル。別アカ記入。
#cron実行用。
PATH=$PATH:/usr/local/bin
IFS="
"


#コマンド存在チェック
#google コマンドがなければ終了
which google >/dev/null 2>&1
if [ $? -ne 0 ];then
  echo "googlecl not found."
  echo "Download at http://code.google.com/p/googlecl/downloads/list and Install"
  exit 1
fi
# 動画圧縮部分コメントアウト
#which ffmpeg >/dev/null 2>&1
#if [ $? -ne 0 ];then
#  echo "ffmpeg not found."
#  echo "Prease Install ffmpeg"
#  exit 1
#fi

#TMPDIR作成 あれば動作中なので終了
#mkdir $TMPDIR 2>/dev/null ||(echo "Cannot run multiple." >&2; exit;)
mkdir $TMPDIR 2>/dev/null
if [ $? -ne 0 ];then
  echo "Cannot Run Multiple."
  exit 9;
fi
trap "rm -rf $TMPDIR;exit" 1 2 3 15

if [ ! -e $CONFFILE ];then
  echo ".iPhoto2Picasa.conf is need."
  exit 9;
fi


#動画・静止画ファイルをリサイズする関数
function fnc_resize()
{
  file="$1"
  filename="`basename "$file"`" #ファイル名のみ
  ext=`echo ${filename##*.}|tr "A-Z" "a-z"` #拡張子（小文字）
  if [ $ext = "jpg" ];then
    sips -Z 2048 "$file" --out "$TMPDIR/$filename"
    UPLOADFILE="$TMPDIR/$filename"
# 動画を圧縮すると付加がかかるのでコメントアウト
#  elif [ $ext = "mov" ];then
#    UPLOADFILE=$TMPDIR/"`echo $filename|sed -e 's/.mov/.mp4/'`"
#    ffmpeg -i "$file" -s 960x540 "$UPLOADFILE"
  else
    #cp "$file" "$TMPDIR/$filename"
    UPLOADFILE="$file"
  fi
}

function fnc_upload()
{
  file="$1"
  filename="`basename "$file"`" #ファイル名のみ
  ext=`echo ${filename##*.}|tr "A-Z" "a-z"` #拡張子（小文字）
  albumname=`stat -l -t %Y/%m/%d "$file"|cut -f6 -d" "`
  for account in `cat $CONFFILE`
  do
    # アルバム名存在チェック
    google picasa list-albums --user="$account"|grep $albumname
    # アルバムがあればファイル名チェック
    if [ $? -eq 0 ];then
      google picasa list --title $albumname --user="$account"|cut -f1 -d,|grep "$filename"
      # ファイルがアルバムになければPOST
      if [ $? -eq 1 ];then
        fnc_resize "$file"
        google picasa post --title $albumname "$UPLOADFILE" --user="$account"
      fi
      # アルバムがなければ作成してUPLOAD
    else
      fnc_resize "$file"
      if [ -f "$UPLOADFILE" ];then
        google picasa create --title $albumname "$UPLOADFILE" --user="$account"
      fi
    fi
  done
  # 動画はYoutubeにも非公開で送信。
  if [ $ext = "mov" -o $ext = "avi" ];then
    google youtube post "$UPLOADFILE" --category People --access=private
  fi
}

if [ $# -ge 1 ];then
  for f in $*
  do
    fnc_upload "$f"
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
        fnc_upload $file
      done
    fi
  done
  #最終アップロードDIRを出力。
  #echo `date +%Y%m%d%H%M%S` >$TMPFILE
  echo $dirnum >$TMPFILE
fi
rm -rf $TMPDIR
