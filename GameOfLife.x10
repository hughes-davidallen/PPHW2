import x10.util.Random;

public class GameOfLife {
	public val TheUniverseSeqRed:Array[Boolean](2);
	public val TheUniverseSeqBlack:Array[Boolean](2);
	public val TheUniverseParRed:Array[Boolean](2);
	public val TheUniverseParBlack:Array[Boolean](2);
	
	public var TheUniverseSeq:Array[Boolean](2);
	public var TheUniversePar:Array[Boolean](2);

	public val width:Int;
	public val height:Int;

	/**
	 * Creates an m x n 0 based array with true or false. 
	 * false indicate dead cells, true indicates live ones 
	 * This m x n array is wrapped in a border of false cells
	 * that will always be false.  This is how we handle the boundaries.
	 */
	public def this(m:Int, n:Int) { 
		width = m;
		height = n;

		val rand = new Random();
		val reg = (0..(width + 1)) * (0..(height + 1));
		TheUniverseSeqRed = new Array[Boolean](reg, false);
		TheUniverseSeqBlack = new Array[Boolean](reg, false);
		TheUniverseParRed = new Array[Boolean](reg, false);
		TheUniverseParBlack = new Array[Boolean](reg, false);
		for (i in 1..width) {
			for (j in 1..height) {
				TheUniverseSeqRed(i, j) = rand.nextBoolean();
				if (TheUniverseSeqRed(i, j)) {
					TheUniverseParRed(i, j) = true;
				} 
			}
		}
	}

	/**
	 * Computes one step of the sequential algorithm
	 */
	private def SeqStep(source:Array[Boolean](2), dest:Array[Boolean](2)) {
		for (i in 1..width) {
			for (j in 1..height) {
				var neighbors:Int = 0;
				if (source(i-1, j-1)) neighbors++;
				if (source(i-1, j)) neighbors++;
				if (source(i-1, j+1)) neighbors++;
				if (source(i, j-1)) neighbors++;
				if (source(i, j+1)) neighbors++;
				if (source(i+1, j-1)) neighbors++;
				if (source(i+1, j)) neighbors++;
				if (source(i+1, j+1)) neighbors++;

				if (source(i, j)) {
					if (neighbors < 2) dest(i, j) = false;
					else if (neighbors > 3) dest(i, j) = false;
					else dest(i, j) = true;
				} else {
					if (neighbors == 3) dest(i, j) = true;
					else dest(i, j) = false;
				}
			}
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
	 * Computes one step of the parallel algorithm
	 */
	private def ParStep(source:Array[Boolean](2), dest:Array[Boolean](2), numAsyncs:Int) {
		finish for (a in 1..numAsyncs) async {
			for (var i:Int = a; i <= width; i += numAsyncs) {
				for (j in 1..height) {
					var neighbors:Int = 0;
					if (source(i-1, j-1)) neighbors++;
					if (source(i-1, j)) neighbors++;
					if (source(i-1, j+1)) neighbors++;
					if (source(i, j-1)) neighbors++;
					if (source(i, j+1)) neighbors++;
					if (source(i+1, j-1)) neighbors++;
					if (source(i+1, j)) neighbors++;
					if (source(i+1, j+1)) neighbors++;

					if (source(i, j)) {
						if (neighbors < 2) dest(i, j) = false;
						else if (neighbors > 3) dest(i, j) = false;
						else dest(i, j) = true;
					} else {
						if (neighbors == 3) dest(i, j) = true;
						else dest(i, j) = false;
					}
				}
			}
		}
	}

	/**
	 * Parallel Simulation of the game of life for endOfTime iterations
	 */
	public def BigBangPar(endOfTime:Int, numAsyncs:Int) {
		for (time in 0..(endOfTime - 1)) {
			if (time % 2 == 0) {
				ParStep(TheUniverseParRed, TheUniverseParBlack, numAsyncs);
			} else {
				ParStep(TheUniverseParBlack, TheUniverseParRed, numAsyncs);
			}
		}
		if (endOfTime % 2 == 0) {
			TheUniversePar = TheUniverseParRed;
		} else {
			TheUniversePar = TheUniverseParBlack;
		}
	}

	public def validate(seq:Array[Boolean](2), par:Array[Boolean](2)) : Boolean { 
		var match:Boolean = true;
		
		for ([i,j] in TheUniverseSeq) {
			if (TheUniversePar(i, j) != TheUniverseSeq(i, j)) {
				match = false;
				break;
			}
		}

		return match; 
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
		val seqStart = System.nanoTime();
		Universe.BigBangSeq(endOfTime);
		val seqTime = (System.nanoTime() - seqStart) / 1000000;

		Console.OUT.println("Big Bang In Parallel ...");
		val parStart = System.nanoTime(); 
		Universe.BigBangPar(endOfTime,numAsyncs);
		val parTime = (System.nanoTime() - parStart) / 1000000;

		if (!Universe.validate(Universe.TheUniverseSeq, Universe.TheUniversePar)) { 
			Console.OUT.println("Paths should not diverge, try again! "); 
		} else {
			Console.OUT.println("Sequential execution time: " + seqTime);
			Console.OUT.println("Parallel execution time: " + parTime);
		}
	}
}
