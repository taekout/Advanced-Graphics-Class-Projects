# files and intermediate files we create
OBJS  = trace.o World.o ObjectList.o Object.o \
	Polygon.o Sphere.o Cone.o \
	Intersection.o Appearance.o 
PROG  = trace

# compilation flags
CXXFLAGS = -O4
LDFLAGS = -O4

# rules for building -- ordered from final output to original .c for no
# particular reason other than that the first rule is the default

# program from .o files
$(PROG): $(OBJS)
	$(CXX) -o $(PROG) $(OBJS) $(LDFLAGS) $(LDLIBS)


# remove everything but the program
clean:
	rm -f *~ *.o *.ncb *.suo *.user

# remove everything including program
clobber: clean
	rm -f $(PROG)

# any .o from .cxx uses built-in rule
# the following dependencies (generated with 'g++ -MM *.cpp) 
# ensure that the .o files will be regenerated when any source file 
# they depend on changes
Appearance.o: Appearance.cpp Appearance.hpp Vec3.hpp ObjectList.hpp \
  Intersection.hpp Object.hpp Ray.hpp
Intersection.o: Intersection.cpp Intersection.hpp Vec3.hpp Object.hpp \
  Appearance.hpp
Object.o: Object.cpp Object.hpp Appearance.hpp Vec3.hpp
ObjectList.o: ObjectList.cpp ObjectList.hpp Intersection.hpp Vec3.hpp \
  Object.hpp Appearance.hpp
Polygon.o: Polygon.cpp Polygon.hpp Object.hpp Appearance.hpp Vec3.hpp \
  Ray.hpp
Sphere.o: Sphere.cpp Sphere.hpp Object.hpp Appearance.hpp Vec3.hpp \
  Ray.hpp
World.o: World.cpp World.hpp Vec3.hpp ObjectList.hpp Intersection.hpp \
  Object.hpp Appearance.hpp
trace.o: trace.cpp ObjectList.hpp Intersection.hpp Vec3.hpp Object.hpp \
  Appearance.hpp Polygon.hpp Sphere.hpp Ray.hpp World.hpp
