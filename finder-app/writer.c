#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    openlog(NULL, 0, LOG_USER);
    if (argc < 3)
    {
        printf("Usage: %s <write-file-path> <text-string>\n", argv[0]);
        syslog(LOG_ERR, "Invalid Number of argumetns: %d", argc);
        return 1;
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

    // Open the file with write-only, create if it doesn't exist, truncate if it does
    int fd = open(writefile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0)
    {
        return 1; // Error handling
    }

    ssize_t len = strlen(writestr);
    ssize_t written = write(fd, writestr, len);

    if (written == -1)
    {
        perror("error when write");
        syslog(LOG_ERR, "error when write");
    }
    else if (written != len)
    {
        perror("Partial write");
        syslog(LOG_ERR, "Partial write");
    }

    return 0;
}
