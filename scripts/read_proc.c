#include <stdio.h>
#include <stdlib.h>
#define BS 1024

void die(char *x){ perror(x); exit(1); };

int main(int argc, char **argv)
{
    int n = 0;
    char    filepath[BS], buf[BS];
    FILE    *f = NULL;
    
    //get the filename to open
        if(argc < 2){
                fprintf(stderr, "Usage: %s <proc file>\n", argv[0]);
        return 1;
    }
    
    //get the path of the file
    n = snprintf(filepath, BS-1, "/proc/%s", argv[1]);
    filepath[n] = 0;
    
    //open the file
    f = fopen(filepath, "r");
    if(!f)
        die("fopen");

    //print its contents
    while(fgets(buf, BS-1, f))
        printf("%s", buf);
    if(ferror(f))
        die("fgets");
    fclose(f);

    return 0;
}
