X10_PATH=/opt/x10-2.2.0.1/bin

# environment variables
X10_NTHREADS := 24
#X10_STATIC_THREADS := false
#X10LAUNCHER_NPROCS := 1

# general parameters
SEED=40

# SpellCheck Parameters 
P1=SpellCheck
DICT_LOC=/usr/share/dict/words
NUM_WORDS=10
P1_ASYNCS=1 2 4
P1_NUM_TRIALS=2

# MaxInt Parameters 
P2=MaxInt
INVEC_SIZE=5000000
P2_ASYNCS=1 2 8
P2_NUM_TRIALS=2


# MarkFour Parameters 
P3=MarkFours
DEPTH=10
P3_NUM_TRIALS=2

# GameOfLife Parameters 
P4=GameOfLife
NUM_ITERATIONS=1000
UNIVERSE_LENGTH=500
UNIVERSE_WIDTH=500
P4_ASYNCS=1 2 4


spellcheck: $(P1).out
$(P1).out: $(P1_ASYNCS:%=$(P1).%.buildandrun) 

$(P1).%.buildandrun: $(P1).exe   
	salloc -n1 srun.x10sock ./$(P1).exe  $(DICT_LOC) $(NUM_WORDS) $(SEED) $(P1_NUM_TRIALS) $* > $(P1).$*.out
	@echo "Dumping contents of $(P1).$*.out ... "
	@grep "" $(P1).$*.out
	@echo " "
	@echo "Find your results in $(P1).$*.out"
	@echo " "

$(P1).exe: $(P1).x10
	$(X10_PATH)/x10c++ -t -v -report postcompile=1 -o $(P1).exe -optimize -O -NO_CHECKS $(P1).x10




maxint: $(P2).out

$(P2).out: $(P2_ASYNCS:%=$(P2).%.buildandrun)

$(P2).%.buildandrun: $(P2).exe   
	salloc -n1 srun.x10sock ./$(P2).exe  $(INVEC_SIZE) $(P2_NUM_TRIALS) $* > $(P2).$*.out
	@echo "Dumping contents of $(P2).$*.out ... "
	@grep "" $(P2).$*.out
	@echo " "
	@echo "Find your results in $(P2).$*.out"
	@echo " "

$(P2).exe: $(P2).x10
	$(X10_PATH)/x10c++ -t -v -report postcompile=1 -o $(P2).exe -optimize -O -NO_CHECKS $(P2).x10


markfours: $(P3).out

$(P3).out: $(P3).exe
	salloc -n1 srun.x10sock ./$(P3).exe  $(DEPTH) $(SEED) $(P3_NUM_TRIALS) > $(P3).0.out
	@echo "Dumping contents of $(P3).0.out ... "
	@grep "" $(P3).0.out
	@echo " "
	@echo "Find your results in $(P3).0.out"
	@echo " "

$(P3).exe: $(P3).x10
	$(X10_PATH)/x10c++ -t -v -report postcompile=1 -o $(P3).exe -optimize -O -NO_CHECKS $(P3).x10


gameoflife: $(P4).out
	@echo "hello1" 

$(P4).out: $(P4_ASYNCS:%=$(P4).%.buildandrun) 
	@echo $(P4).%.buildandrun

$(P4).%.buildandrun: $(P4).exe   
	salloc -n1 srun.x10sock ./$(P4).exe $(UNIVERSE_LENGTH) $(UNIVERSE_WIDTH) $(SEED) $(NUM_ITERATIONS) $* > $(P4).$*.out
	@echo "Dumping contents of $(P4).$*.out ... "
	@grep "" $(P4).$*.out
	@echo " "
	@echo "Find your results in $(P4).$*.out"
	@echo " "

$(P4).exe: $(P4).x10
	@echo "hello3"
	$(X10_PATH)/x10c++ -t -v -report postcompile=1 -o $(P4).exe -optimize -O -NO_CHECKS $(P4).x10



all:	

.PRECIOUS: 
.x10: 
	@echo $@
#	$(X10_PATH)/x10c++ -t -v -report postcompile=1 -o $@ -x10rt mpi -optimize -O -NO_CHECKS  $<


.PHONY: $(P1).out clean
clean:
	rm -f *.cc *.h *.exe *.inc *.out *.mpi *~ *.java *.class \#*
