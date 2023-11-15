#include "systemcalls.h"
#include <fcntl.h>
#include <unistd.h>
 #include <stdio.h>  // perror()
 #include <stdlib.h> // exit(), EXIT_SUCCESS, EXIT_FAILURE
 #include <unistd.h> // fork()
 #include <sys/wait.h>
 #include <sys/types.h>
/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
int result = system(cmd);
    if (result == -1)
    {
        // Erreur lors de l'exécution de la commande système
        return false;
    }

    return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{

    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
     fflush(stdout);
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/

pid_t pid = fork();

    if (pid == -1)
    {
        // Error occurred while forking
        perror("Fork failed");
        return false;
    }
    else if (pid == 0)
    {
        // Child process
        execv(command[0], command);
        // execv returns only if an error occurred
        perror("Execv failed");
        exit(1);
    }
    else
    {
        // Parent process
        int status;
        wait(&status);
        if (WIFEXITED(status))
        {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0)
            {
                // Child process exited with a non-zero status
                printf("Command execution failed with exit status: %d\n", exit_status);
                return false;
            }
        }
        else
        {
            // Child process exited abnormally
            printf("Command execution failed\n");
            return false;
        }
    }

    va_end(args);

    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/
outputfile = "redirected.txt";
// Open the output file
    int fd = open(outputfile, O_WRONLY | O_TRUNC | O_CREAT, 0644);
    if (fd == -1) {
        perror("Error opening output file");
        va_end(args);
        return false;
    }

    // Redirect stdout to the output file
    if (dup2(fd, STDOUT_FILENO) == -1) {
        perror("Error redirecting stdout");
        close(fd);
        va_end(args);
        return false;
    }

    close(fd); // Close the original file descriptor

    // Execute the command
    execv(command[0], command);

    // If execv returns, an error occurred
    perror("Error executing command");

    va_end(args);
    return false;
}
