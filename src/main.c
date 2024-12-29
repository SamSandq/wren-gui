//For more details, visit https://wren.io/embedding/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>
#include "wren.h"

WrenVM *vm;         //used all over the place
WrenHandle *appEvents;              //used for sending events to be handled in Application
WrenHandle *appNotifications;              //used for sending notifications to be handled in Application
WrenHandle *appTimer;              //used for timed events to be handled in Application
WrenHandle *appClass;               //used for getting the Application class

const char *script; //the wren source
FILE *log_file;
char *time_buf;

char resourcePath[PATH_MAX], log_file_name[PATH_MAX];
char main_file_name[PATH_MAX];

//command line
int storedArgc;
char **storedArgv;

//protos
extern void appStart();
// WrenForeignMethodFn bindMethods(WrenVM* vm, const char* module, const char* className, bool isStatic, const char* signature);
// WrenForeignClassMethods bindClasses(WrenVM* vm, const char* module, const char* className);

void initialiseGUI();

//get now time
char *nowTime() {
	struct tm *loctime;
    long num = time(NULL);
	loctime = (struct tm *) localtime((const time_t *) &num);
	sprintf(time_buf, "%d-%02d-%02d %02d:%02d:%02d", loctime->tm_year+1900, loctime->tm_mon+1, loctime->tm_mday, loctime->tm_hour, loctime->tm_min, loctime->tm_sec);
    return time_buf;
}

void getResourcePath() {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
    CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8 *)resourcePath, PATH_MAX);
    CFRelease(resourcesURL);
}

// Reads the contents of the file at [path] and returns it as a heap allocated string.
// Returns `NULL` if the path could not be found. Exits if it was found but could not be read.
const char* readFile(const char* path) {
    FILE* file = fopen(path, "rb");
    if (file == NULL) {
#ifdef DEBUG
        fprintf(log_file, "%s: Could not read '%s'\n", nowTime(), path);
#endif
        return NULL;
    } else {
#ifdef DEBUG
        fprintf(log_file, "%s: reading file '%s'\n", nowTime(), path);
#endif
    }

    // Find out how big the file is.
    fseek(file, 0L, SEEK_END);
    size_t fileSize = ftell(file);
    rewind(file);
  
    // Allocate a buffer for it.
    char* buffer = (char*)malloc(fileSize + 1);
    if (buffer == NULL) {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        exit(74);
    }
  
    // Read the entire file.
    size_t bytesRead = fread(buffer, 1, fileSize, file);
    if (bytesRead < fileSize) {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        exit(74);
    }
  
    // Terminate the string.
    buffer[bytesRead] = '\0';
    
    fclose(file);
    return buffer;
}

void appEnd() {
    //free stuff and exit
#ifdef DEBUG
    fprintf(log_file, "%s: %s\n", nowTime(), "Ending app");
#endif
    if (appEvents != NULL) {
        wrenReleaseHandle(vm, appEvents);
        wrenReleaseHandle(vm, appNotifications);
        wrenReleaseHandle(vm, appTimer);
        wrenReleaseHandle(vm, appClass);
        }
    wrenFreeVM(vm);
#ifdef DEBUG
    fclose(log_file);
#endif
    free((void *) script);
    free((void *) time_buf);
}

//MAIN
int main(int argc, char *argv[]) {

    char *fileName;
    time_buf = malloc(50);
    storedArgc = argc;
    storedArgv = argv;

    getResourcePath();

#ifdef DEBUG
    //create logfile
    strcat(log_file_name, resourcePath);
    strcat(log_file_name, "/wren_log.log");
    log_file = fopen(log_file_name, "wa");
    if (log_file == NULL) {
        perror("Failed to open log file");
        exit(EXIT_FAILURE);
    }
#endif

    //main file
    strcat(main_file_name, resourcePath);
    strcat(main_file_name, "/main.wren");

    if (argc >= 2) {
        fileName = argv[1];
    } else {
        fileName = main_file_name;
    }
    
#ifdef DEBUG
    fprintf(log_file, "-----------------------------------------\n%s: %s\n", nowTime(), "Starting app");
#endif

    //get Wren file to buffer
    script = readFile(fileName);
    if (script == NULL) {
        fprintf(stderr, "Could not read file \"%s\".\n", fileName);
#ifdef DEBUG
        fprintf(log_file, "%s: Could not read file '%s'\n", nowTime(), fileName);
#endif
        exit(74);
    }

    //initialise GUI, wren
    initialiseGUI();

    appStart();     //never returns

}