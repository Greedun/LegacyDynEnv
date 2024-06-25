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
