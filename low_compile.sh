# low_compile.sh
#! /bin/bash

# target file name(args)
file_name="target.c"
folder_path="./export" # 확인할 폴더 경로

# 폴더가 존재하는지 확인
if [ ! -d "$folder_path" ]; then
    mkdir -p "$folder_path"
    echo "[!] export 폴더가 생성되었습니다."
fi

echo "[*] copy internal file"
cp -r $file_name ./export/$file_name
cp -r patchelf.sh ./export/patchelf.sh

echo "[*] Build container image"
docker build --build-arg file=$file_name -t img_low_compile . # build명령어
echo "[*] Run container"
docker run --name low_compile -d img_low_compile # run명령어(백그라운드)
# docker run --name compile -it img_low_compile /bin/bash # run명령어(접속용)

# 파일 꺼내오기
echo "[*] export file(target , libc-2.23.so , ld-2.23.so)"
docker cp low_compile:/target ./export/target
docker cp low_compile:/lib/x86_64-linux-gnu/libc-2.23.so ./export/libc.so.6
docker cp low_compile:/lib/x86_64-linux-gnu/ld-2.23.so ./export/ld.so

# 컨테이너 종료
echo "[*] remove container"
docker rm -f low_compile

# export 결과
echo "[*] result export file"
ls ./export