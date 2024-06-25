FROM ubuntu:16.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ Asia/Seoul
ENV PYTHONIOENCODING UTF-8
ENV LC_CTYPE C.UTF-8

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install gcc curl sudo -y
#RUN apt install vim git gcc curl tmux wget sudo python3 python3-dev python3-pip libffi-dev build-essential libssl-dev libc6-i386 libc6-dbg gcc-multilib make unzip -y

# 라이브러리 업데이트?
#RUN dpkg --add-architecture i386
#RUN apt update
#RUN apt install libc6:i386 -y

WORKDIR /

ARG file
ENV env_target $file

# 컴파일할 파일 들여오기
ADD $file /target.c

# 파일 컴파일
RUN gcc -g -o target target.c

# 컨테이너 실행 시, 아무런 작업을 하지 않도록 설정 (무한 루프)
CMD tail -f /dev/null

# sh스크립트
# 파일들 외부로 전달
#CMD ["./move.sh"]

# docker build --build-arg file=target.c -t low_compile . # build명령어
# docker run --name compile -d low_compile # run명령어