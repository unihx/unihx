#import <UIKit/UIKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

const char *hxRunLibrary();
void hxcpp_set_top_of_stack();
   
/* #ifndef SPRINGBOARDSERVICES_H_ */
/* extern int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended); */
/* extern CFStringRef SBSApplicationLaunchingErrorString(int error); */
/* #endif */

int main(int argc, char **argv, char **envp)
{
		int ret = 0;
		const char *err = NULL;
		hxcpp_set_top_of_stack();

		err = hxRunLibrary();
		if (err) {
				printf(" Error %s\n", err );
		}

    if (argc < 2) {
        fprintf(stderr, "Usage: %s com.application.identifier \n", argv[0]);
        return -1;
    }

		/* [UIApplication launchApplicationWithIdentifier:[NSString stringWithUTF8String:argv[1]] suspended:NO]; */

    /* CFStringRef identifier = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], kCFStringEncodingUTF8); */
    /* assert(identifier != NULL); */

    /* ret = SBSLaunchApplicationWithIdentifier(identifier, FALSE); */

    /* if (ret != 0) { */
    /*     fprintf(stderr, "Couldn't open application: %s. Reason: %i, ", argv[1], ret); */
    /*     CFShow(SBSApplicationLaunchingErrorString(ret)); */
    /* } */

    /* CFRelease(identifier); */

    return ret;
}
