#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

void writeToLogFile(const char* file, const char* string) {
    FILE* fp = fopen(file, "w");

    if (fp == NULL) {
        syslog(LOG_ERR, "Error opening file: %s", file);
        return;
    }

    fprintf(fp, "%s", string);
    fclose(fp);

    syslog(LOG_DEBUG, "Writing '%s' to '%s'", string, file);
}

int main(int argc, char* argv[]) {
    openlog("writer", LOG_CONS | LOG_PID | LOG_NDELAY, LOG_USER);

    if (argc < 3) {
        syslog(LOG_ERR, "Insufficient arguments. Usage: writer <file> <string>");
        closelog();
        return 1;
    }

    const char* file = argv[1];
    const char* string = argv[2];

    writeToLogFile(file, string);

    closelog();

    return 0;
}
