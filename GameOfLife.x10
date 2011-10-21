import x10.util.Random;

public class GameOfLife {
	public val TheUniverseSeqRed:Array[Boolean](2);
	public val TheUniverseSeqBlack:Array[Boolean](2);
	public val TheUniverseParRed:Array[Boolean](2);
	public val TheUniverseParBlack:Array[Boolean](2);
	
	public var TheUniverseSeq:Array[Boolean](2);
	public var TheUniversePar:Array[Boolean](2);

	/**
	 * Creates an m x n 0 based array with true or false. 
	 * false indicate dead cells, true indicates live ones 
	 */
	public def this(m:Int, n:Int) { 
		val ran = new Random();
		TheUniverseSeqRed = new Array[Boolean]((0..(m - 1)) * (0..(n - 1)), ran.nextBoolean());
		TheUniverseSeqBlack = new Array[Boolean]((0..(m - 1)) * (0..(n - 1)), false);
		TheUniverseParRed = new Array[Boolean]((0..(m - 1)) * (0..(n - 1)), false);
		TheUniverseParBlack = new Array[Boolean]((0..(m - 1)) * (0..(n - 1)), false);
		for (i in (0..(m - 1))) {
			for (j in (0..(n - 1))) { 
				if (TheUniverseSeqRed(i, j)) {
					TheUniverseSeqBlack(i, j) = true;
					TheUniverseParRed(i, j) = true;
					TheUniverseParBlack(i, j) = true;
				} 
			}
		}
	}

	/**
	 * Computes on step of the sequential algorithm
	 */
	private def SeqStep(source:Array[Boolean](2), dest:Array[Boolean](2)) {
		for ([i, j] in source) {
			if (source(i, j)) dest(i, j) = true;
		}
	}

	/**
	 * Sequential simulation of the game of life for endOfTime iterations
	 */
	public def BigBangSeq(endOfTime:Int) {
		for (time in 0..(endOfTime - 1)) {
			if (time % 2 == 0) {
				SeqStep(TheUniverseSeqRed, TheUniverseSeqBlack);
			} else {
				SeqStep(TheUniverseSeqBlack, TheUniverseSeqRed);
			}
		}
		if (endOfTime % 2 == 0) {
			TheUniverseSeq = TheUniverseSeqRed;
		} else {
			TheUniverseSeq = TheUniverseSeqBlack;
		}
	}

	/**
	 * Parallel Simulation of the game of life for endOfTime iterations
	 */
	public def BigBangPar(endOfTime:Int, numAsyncs:Int) {
		for (time in 0..(endOfTime - 1)) {
			/** Change me **/
		}
	}

	public def validate(seq:Array[Boolean](2), par:Array[Boolean](2)) : Boolean { 
		// compare seq vs parallel
		/** Change Me **/
		return false; 
	}

	/** Main **/
	public static def main(args:Array[String]) {
		if (args.size < 4) {
			Console.OUT.println("Usage: GameOfLife <universe_length> <universe_width> <num_iterations> <num_asycs>");
			return;
		}

		val m = Int.parseInt(args(0)); 
		val n = Int.parseInt(args(1)); 
		val endOfTime = Int.parseInt(args(2));
		val numAsyncs = Int.parseInt(args(3)); 

		Console.OUT.println("Create the Universe"); 
		val Universe = new GameOfLife(m,n);

		Console.OUT.println("Big Bang In Series ..."); 
		Universe.BigBangSeq(endOfTime);

		Console.OUT.println("Big Bang In Parallel ..."); 
		Universe.BigBangPar(endOfTime,numAsyncs);

		if (!Universe.validate(Universe.TheUniverseSeq, Universe.TheUniversePar)) { 
			Console.OUT.println("Paths should not diverge, try again! "); 
		}
	}
}
