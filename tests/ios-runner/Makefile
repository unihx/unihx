IPHONE_IP:=
PROJECTNAME:=ios-test-runner

# if compiling on Mac, find SDK path and compile with this env var
SYSROOT=$(shell head -1 $(HOME)/.iphonesdk | cut -f2 -d=)
PVT_FRAMEWORKS=$(SYSROOT)/System/Library/PrivateFrameworks

# if compiling on Mac, replace this by `clang -arch arm7v -isysroot $(SYSROOT)`
CC:=ios-clang
CXX:=ios-clang++
AR:=arm-apple-darwin11-ar

LDID:=ldid

HXCPP_PATH=$(shell haxelib path hxcpp | head -1)

CFLAGS += -I/usr/include/clang/3.2/include
CFLAGS += -F$(PVT_FRAMEWORKS)
CFLAGS += -objc-arc
CFLAGS += -fblocks
CFLAGS += -g0 -O2

CXXFLAGS += -I/usr/include/clang/3.2/include
CXXFLAGS += -objc-arc
CXXFLAGS += -fblocks
CXXFLAGS += -g0 -O2

LDFLAGS += -framework Foundation
LDFLAGS += -framework SpringBoardServices
LDFLAGS += "-L${HXCPP_PATH}/bin/IPhone" -Lbin
LDFLAGS += -lmain -lpthread -ldl -lstd.iphoneos-v7 -lregexp.iphoneos-v7 -lzlib.iphoneos-v7 -lstdc++

SRCDIR=native
OBJS+=$(patsubst %.m,%.o,$(wildcard $(SRCDIR)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
OBJS+=$(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))

all:	$(PROJECTNAME)

bin/libmain.a: $(wildcard src/*.hx)
	# compile HXCPP using ios-clang and 
	CXX="${CXX} ${CXXFLAGS}" HXCPP_AR=echo HXCPP_RANLIB=echo haxe build.hxml
	cd bin && ${AR} -cr libmain.a $$(find -name "*.o") 

$(PROJECTNAME):	$(OBJS) bin/libmain.a
	$(CC) $(CFLAGS) $(LDFLAGS) $(filter %.o,$^) -o $@ 
	$(LDID) -Snative/Entitlements.plist $(PROJECTNAME)

%.o:	%.m
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

clean:
	find . -name \*.o|xargs rm -rf
	rm -f $(PROJECTNAME)

.PHONY: all clean
