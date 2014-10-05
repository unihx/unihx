#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
/* #include <CoreFoundation/CoreFoundation.h> */
#include <stdio.h>
#include <dlfcn.h>

const char *hxRunLibrary();
void hxcpp_set_top_of_stack();
   
/* #ifndef SPRINGBOARDSERVICES_H_ */
/* extern int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended); */
/* extern CFStringRef SBSApplicationLaunchingErrorString(int error); */
/* #endif */

static int (*pvt_launchApplication)(CFStringRef, Boolean);
static CFStringRef (*pvt_errorString)(int);
static void (*pvt_setBacklight)(float);

static char * MYCFStringCopyUTF8String(CFStringRef aString) {
	if (aString == NULL) {
		return NULL;
	}

	CFIndex length = CFStringGetLength(aString);
	CFIndex maxSize =
		CFStringGetMaximumSizeForEncoding(length,
				kCFStringEncodingUTF8);
	char *buffer = (char *)malloc(maxSize);
	if (CFStringGetCString(aString, buffer, maxSize, kCFStringEncodingUTF8)) 
	{
		return buffer;
	}

	return NULL;
}

void mainSetScreenDim(float val)
{
	if (NULL != pvt_setBacklight)
	{
		pvt_setBacklight(val);
	} else {
		printf("set screen dim not available!\n");
	}
}

char *mainLaunchApplication(char *name, int suspended)
{
	@autoreleasepool { 
		int ret;
		char *error = NULL;

		CFStringRef identifier = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingUTF8);
		if (identifier == NULL)
		{
			return NULL;
		}

		ret = pvt_launchApplication(identifier,suspended);
		if (ret != 0)
		{
			if (NULL != pvt_errorString)
			{
				error = MYCFStringCopyUTF8String( pvt_errorString(ret) );
			} else {
				const char *msg = "Unkown error occurred. Returned: ";
				char num[25];
				snprintf(num, 24, "%d", ret);
				error = malloc( strlen(msg) + 25);
				strcpy(error,msg);
				strcat(error,num);
			}
		}
		CFRelease(identifier);

		return error;
	}
}

int main(int argc, char **argv, char **envp)
{
		char *ret = 0;
		const char *err = NULL;
		void *hndl;
		hxcpp_set_top_of_stack();

		// Dynamic loading of private API
		hndl = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY);
		assert(hndl != NULL);
		pvt_launchApplication = dlsym(hndl, "SBSLaunchApplicationWithIdentifier");
		assert(pvt_launchApplication != NULL);
		pvt_errorString = dlsym(hndl, "SBSApplicationLaunchingErrorString");
		dlclose(hndl);
		hndl = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices",RTLD_LAZY);
		if (NULL != hndl)
		{
			pvt_setBacklight = dlsym(hndl, "GSEventSetBacklightLevel");
			dlclose(hndl);
		}

		err = hxRunLibrary();
		if (err) {
				printf(" Error %s\n", err );
		}

    if (argc < 2) {
        fprintf(stderr, "Usage: %s com.application.identifier \n", argv[0]);
        return -1;
    }

		ret = mainLaunchApplication(argv[1], FALSE);

    if (ret != NULL) 
		{
        fprintf(stderr, "Couldn't open application: %s. Reason: %s\n", argv[1], ret);
				free(ret);
				return -1;
    }

    return 0;
}

