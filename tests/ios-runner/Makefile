IPHONE_IP:=
PROJECTNAME:=ios-test-runner

SYSROOT=$(shell head -1 $(HOME)/.iphonesdk | cut -f2 -d=)
PVT_FRAMEWORKS=$(SYSROOT)/System/Library/PrivateFrameworks

CC:=ios-clang
CPP:=ios-clang++

LDID:=ldid

CFLAGS += -F$(PVT_FRAMEWORKS)
CFLAGS += -objc-arc
CFLAGS += -fblocks
CFLAGS += -g0 -O2

CPPFLAGS += -objc-arc
CPPFLAGS += -fblocks
CPPFLAGS += -g0 -O2

LDFLAGS += -framework Foundation
LDFLAGS += -framework SpringBoardServices

SRCDIR=.
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SRCDIR)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
OBJS+=$(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))

all:	$(PROJECTNAME)

$(PROJECTNAME):	$(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(filter %.o,$^) -o $@ 
	$(LDID) -SEntitlements.plist $(PROJECTNAME)

%.o:	%.m
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.cpp
	$(CPP) -c $(CPPFLAGS) $< -o $@

clean:
	find . -name \*.o|xargs rm -rf
	rm -f $(PROJECTNAME)

.PHONY: all clean
