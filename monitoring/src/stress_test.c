#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

void *burn_cpu(void *arg) {
    while (1) {
        double x = 0;
        for (int i = 0; i < 1000000; i++) {
            x += i * i;
        }
    }
    return NULL;
}

void burn_memory(size_t mb) {
    size_t size = mb * 1024 * 1024; 
    char *block = malloc(size);
    if (block == NULL) {
        perror("malloc failed");
        exit(1);
    }
    for (size_t i = 0; i < size; i += 4096) {
        block[i] = 1;
    }
    printf("Allocated and touched %zu MB of memory\n", mb);
    sleep(3600);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: %s <cpu_threads> <memory_mb>\n", argv[0]);
        return 1;
    }

    int threads = atoi(argv[1]);
    int mem_mb = atoi(argv[2]);

    for (int i = 0; i < threads; i++) {
        pthread_t tid;
        if (pthread_create(&tid, NULL, burn_cpu, NULL) != 0) {
            perror("pthread_create failed");
            return 1;
        }
    }
    burn_memory(mem_mb);

    return 0;
}


// gcc stress_test.c -o stress_test -lpthread
// ./stress_test 4 1024
