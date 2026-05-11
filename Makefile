CXX = g++
ZIG = zig
CXXFLAGS = -std=c++23 -Wall -Wextra -O2 $(shell pkg-config --cflags raylib)
CPP_LDFLAGS = $(shell pkg-config --libs raylib) -lm
ZIG_CFLAGS = $(shell pkg-config --cflags raylib)
ZIG_LDFLAGS = $(shell pkg-config --libs raylib) -lc -lm

CPP_TARGET = cpp-raylib/main
CPP_SRCS = cpp-raylib/main.cpp
CPP_OBJS = $(CPP_SRCS:.cpp=.o)
ZIG_TARGET = zig-raylib/main
ZIG_SRCS = zig-raylib/main.zig

all: cpp zig

cpp: $(CPP_TARGET)

zig: $(ZIG_TARGET)

$(CPP_TARGET): $(CPP_OBJS)
	$(CXX) $(CPP_OBJS) -o $@ $(CPP_LDFLAGS)

cpp-raylib/%.o: cpp-raylib/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(ZIG_TARGET): $(ZIG_SRCS)
	$(ZIG) build-exe $< -O ReleaseFast $(ZIG_CFLAGS) $(ZIG_LDFLAGS) --cache-dir .zig-cache --global-cache-dir .zig-global-cache -femit-bin=$@

run-cpp: $(CPP_TARGET)
	./$(CPP_TARGET)

run-zig: $(ZIG_TARGET)
	./$(ZIG_TARGET)

clean:
	rm -f $(CPP_OBJS) $(CPP_TARGET) $(ZIG_TARGET) main main.o

.PHONY: all cpp zig run-cpp run-zig clean
