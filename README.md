# LegacyDynEnv
glibc 2.23버전을 샤용하는 바이너리를 기존에 사용하던 분석환경에서 동적 분석을 하기 위한 컨테이너 시스템

## 🖥️ 프로그램 소개
해당 시스템은 glibc 2.23버전으로 동작하는 바이너리를 이용하기를 원하는 분들에게 
편하게 기존에서 이용하시던 환경에서 사용할 수 있도록 세팅 파일들을 제공해주는 시스템이다.

- 시스템 구성도
<center><img width="450" alt="github_LegacyDynEnv_figure1" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/b467db75-f494-4f9b-ac74-0ef2671f9709"></center>

- 개발의도
  - glibc 2.23버전을 쓰기 위해선 ubuntu 16.04가 필요
  - 도커를 이용하여 구축한 후 이용하려 했지만 파이썬 3.6까지 지원하여 제약 발생
   (해결할 방법은 있지만 그 방법은 오래 걸림)
  - 역으로 최신 우분투에서 glibc 2.23버전을 사용하는 바어너리를 동적 디버깅할까? 고민
  - 여러가지 방법으로 실험한 끝에 현재 이 시스템을 개발

- 개발과정 - https://greedun.tistory.com/68
  => 개발 과정이 궁금하시다면 위 링크로 들어가셔서 확인하시면 됩니다.
  
- 반자동화를 선택한 이유
  => 사용자마다 기존에 사용한 분석환경이 다르기 때문에 시스템이 생성한 파일을 이동하도록 설계

## ⚙️ 개발 환경 및 파일 역할
low_compile.sh
  - 핵심파일
  - 해당 쉘스크립트를 실행시 분석환경에 옮길 파일들이 export폴더에 생성
- target.c
  - 컴파일하기 원하는 c코드
- Dockerfile
  - 추가로 defaule는 백그라운드 실행이지만 주석으로 명령어를 바꾼다면 접속 가능
- patchelf.sh
	- 바이너리를 사용할 환경에서 실행
	- 바이너리가 이용하는 libc, ld.so파일을 변경하는 작업을 수행

## 환경 구축 결과
최신 ubuntu버전에서 이 시스템에서 생성한 파일 (컴파일된 바이너리, ld.so, libc.so.6)을 동적 디버깅 시도

<center><img width="400" alt="github_LegacyDynEnv_figure2" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/99582c41-ab77-48b8-9403-1c57579368f6"></center>

최신 glibc에서는 tcache가 우선적으로 쓰인다.
해당 시스템에서 생성한 파일을 동적 디버깅한 결과 tcache가 아닌 unsorted bin에 들어간 것으로 glibc 2.23라이브러리가 실행된 것을 확인할 수 있다.

## 📌 사용방법
```text
[시스템 구성]
(host)
1. 동적 디버깅 해야할 코드(target.c)를 준비

2. ubuntu 16버전 docker를 이용해서 코드를 컴파일하고 내부에서 libc.so.6, ld.so파일을 확보
   (target, libc.so.6, ld.so 파일 확보)
   => low_compile.sh파일 실행

3. 분석하는 환경에 export폴더 안에 파일들을 직접 옮김
   (target, libc.so.6, ld.so, target.c, patchelf.sh)
   (수동으로 한 이유 : vmware, docker, local, mac등 다양한 상황을 전부 충족시키기 어려워서)
   => 직접 옮김

(분석환경)
4. patchelf.sh를 실행시켜 바이너리에 대한 패치 진행
   => 내부 코드 중 ldd, strings를 통해 패치 확인

5. "gdb target"을 통해 동적 디버깅 수행
```


> (1) 동적 디버깅 해야 할 코드 준비
ex) target.c

```c
// ex) target.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#define BUFFER_SIZE 1024

int main() {
    char *buffer;
    ssize_t bytesRead;
    int fd;

    // 파일 열기
    fd = open("example.txt", O_RDONLY);
    if (fd == -1) {
        perror("파일 열기 실패");
        return EXIT_FAILURE;
    }

    // 메모리 동적 할당
    buffer = (char *)malloc(BUFFER_SIZE * sizeof(char));
    if (buffer == NULL) {
        perror("메모리 할당 실패");
        close(fd);
        return EXIT_FAILURE;
    }

    // 파일에서 데이터 읽기
    bytesRead = read(fd, buffer, BUFFER_SIZE);
    if (bytesRead == -1) {
        perror("읽기 실패");
        free(buffer);
        close(fd);
        return EXIT_FAILURE;
    }

    // 읽은 데이터 화면에 출력
    printf("읽은 데이터: %s\n", buffer);

    // 동적으로 할당된 메모리 해제
    free(buffer);

    // 파일 닫기
    close(fd);

    return EXIT_SUCCESS;
}
```
=> chathpt를 이용해 생성한 malloc, free함수를 이용하는 코드

> (2) docker(ubuntu16)을 이용해서 코드 컴파일한 후 내부에서 libc.so.6, ld.so파일을 확보
   low_compile.sh파일 실행 (target, libc.so.6, ld.so 파일 확보)

```bash
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
```

> (3) 분석 환경에 필요한 파일들을 직접 옮김

<img width="400" alt="github_LegacyDynEnv_figure3" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/bf2ddf52-8fbf-4bc9-aa40-4bbee0de0246">

시스템을 가동시키면 export폴더에 이후 분석환경에서 필요한 파일들이 생성된다.
export폴더에 있는 파일들을 원하는 분석 환경에 옮겨둔다.

> (4) patchelf.sh를 실행시켜 바이너리 패치 진행

```bash
# patchelf.sh
# chmod +x patchelf.sh # 외부에서 진행

chmod +x target
chmod +x ld.so
chmod +x libc.so.6

patchelf --set-interpreter ./ld.so target
patchelf --replace-needed libc.so.6 ./libc.so.6 target

# print
echo "> ldd target"
ldd target
echo ""
echo "> strings target | grep GLIBC"
strings target | grep GLIBC
```
=> 바이너리의 종속되어 있는 ld.so와 libc.so.6를 patchelf도구를 이용하여 변경해준다.


<img width="838" alt="github_LegacyDynEnv_figure4" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/598bc565-35d8-4c42-b395-a4904da26306">
<img width="655" alt="github_LegacyDynEnv_table1" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/0790e4d9-7f1b-4fcf-b499-b8dab2c96ff9">
=> 바이너리를 ldd, strings명령어를 통해 확인하면 위 표와 같은 차이점이 존재한다.

> (5) "gdb target"을 통해 동적 디버깅 수행

<img width="518" alt="github_LegacyDynEnv_figure5" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/0ac25192-b7eb-4122-a356-e3d5309287f3">
<img width="885" alt="github_LegacyDynEnv_figure6" src="https://github.com/Greedun/LegacyDynEnv/assets/78598657/9302fbff-d2a5-4b67-b221-fc9e29fd6050">

vmmap으로 ld.so, libc.so.6의 맵핑상황을 확인하고 동적 디버깅을 진행한다.
이 시스템을 구축하려던 목적은 heap에서 glibc2.23을 적용시키것이었기 때문에 free함수까지 동적디버깅을 진행시켜보았다.

free함수가 지났을때 (이미지2) 우측사진에 heap상황을 보니 tcache명령어는 해당 libc버전이 없다고 명시되고, unsorted bin에 해제된 청크가 들어가는 것을 확인하였다.

