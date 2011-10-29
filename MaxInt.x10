import x10.util.Random;

public class MaxInt {

	// Input vector
	val inVec: Array[Int](1);

	// results
	var serialMax: Int = 0;
	var parallelMax: Int = 0;

	// size of input vector
	val insize:Int;

	var serialTime:Long = 0;
	var parallelTime:Long = 0;

	static val Meg = 1000 * 1000;

	/** Constructor **/
	public def this(inSize:Int) {
		insize = inSize;
		inVec = new Array[Int](inSize, 0);
	}

	/** populateInput() **/
	public def populateInput() {
		val seed:Int = 100;
		val rand = new Random(seed);

		for ( p in inVec ) {
			inVec(p) = rand.nextInt();
		}
	}

	/** Methods for collecting timing numbers **/
	public def resetTimers() {
		serialTime = 0;
		parallelTime = 0;
	}

	public def serialTime() : Long {
		return serialTime;
	}

	public def parallelTime() : Long {
		return parallelTime;
	}

	/** Sequential Method **/
	public def runInSequence() {
		serialMax = 0;
		val time = System.nanoTime();

		for (var i:Int = 0; i < insize; i++) {
			if (inVec(i) > serialMax) {
				serialMax = inVec(i);
			}
		}
		serialTime += (System.nanoTime() - time) / Meg;
	}

	/** Parallel Method **/
	public def runInParallel(numAsyncs:Int) {
		parallelMax = 0;
		val time = System.nanoTime();
 
		finish for ([i] in 0..(numAsyncs - 1)){
			async chunkCompute(i, numAsyncs);
		}
		parallelTime += (System.nanoTime() - time) / Meg;
	}

	/** helper for the parallel method **/
	public def chunkCompute(id:Int, numAsyncs:Int) {
		val chunkSize = inVec.size / numAsyncs;
		val start = chunkSize * id;
		val end = (id == numAsyncs-1)?inVec.size-1:start + chunkSize-1;
		for (var i:Int = start; i <= end; i++) {
			if (inVec(i) > parallelMax) {
				atomic parallelMax = inVec(i);
			}
		}
	}

	/** helper for validating result **/
	public def compareSeqVsParallel() : Boolean {
		Console.OUT.println("serial max = " + serialMax + " parallel max = " + parallelMax); 
		if (serialMax == parallelMax) return true; 
		return false; 
	}

	/** Main **/
	public static def main(args:Array[String]) {
		if (args.size < 3) {
			Console.OUT.println("Usage: MaxInt <input_vector_size> <num_trials> <num_asyncs>");
			return;
		}

		val insize = Int.parseInt(args(0));
		val num_trials = Int.parseInt(args(1));
		val num_asyncs = Int.parseInt(args(2));

		val mf = new MaxInt(insize);

		// randomly populate input
		mf.populateInput();

		// warmup run
 		Console.OUT.println("Warmup Run, serial ... ");
 		mf.runInSequence();

	 	Console.OUT.println("Warmup Run, parallel ... ");
 		mf.runInParallel(num_asyncs);

		// Verify the correctness
		if (!mf.compareSeqVsParallel()) {
			Console.OUT.println("Warmup Correctness test failed. Bye!");
			return;
		}

		mf.resetTimers();

		for (t in 0..(num_trials-1)) {
			Console.OUT.println("Trial " + t + "...");
			mf.runInSequence();
			mf.runInParallel(num_asyncs);
		}

		// Verify correctness again
		if (!mf.compareSeqVsParallel()) {
			Console.OUT.println("Correctness test failed. Bye!");
			return;
		}

		Console.OUT.println("[Done.] Over " + num_trials + " trials, average time" 
				+ " to compute serially is " + mf.serialTime()/num_trials
				+ ", and to compute in parallel is " + mf.parallelTime() / num_trials);
	}
}
