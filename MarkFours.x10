import x10.util.*;
import x10.lang.Math;

public class MarkFours {

	static val Meg = 1000 * 1000;

	public class TreeNode { 
		var key:Int;
		var left:TreeNode;
		var right:TreeNode;
		var mark:Boolean;
		def this(inKey: Int) {
			key = inKey;
			left = right = null;
			mark = false;
		}
	}

	public var treeDepth:Int = 0;
	public var serialTime:Long = 0;
	public var parallelTime:Long = 0;
	public var nodePoolLeft:Array[TreeNode] = null; // had to use a pool to speed up initial tree creation
	public var nodePoolRight:Array[TreeNode] = null;

	public def this() {	}

	public def timerReset() {
		serialTime = 0;
		parallelTime = 0;
	}

	public def serialTime() : Long {
		return serialTime;
	}

	public def parallelTime() : Long {
		return parallelTime;
	}

	public def allocateTreeNodes(depth:Int) { 
		// *2 because we need to allocate for both seraial and parallel tree
		val numNodes = (Math.pow2(depth) + 1) * ((depth + 2) / 2); // more than we need 
		Console.OUT.println("Allocating numNodes = " + numNodes);
		nodePoolLeft = new Array[TreeNode](numNodes, (i:Int) => (new TreeNode(0)));
		nodePoolRight = new Array[TreeNode](numNodes, (i:Int) => (new TreeNode(0)));

		Console.OUT.println("Done Allocating ... ");		
	}

	/**
	 * Creates a balanced random binary tree with the specified depth. 	 
	 */
	public def randomBinTree(var rootS:TreeNode, var rootP:TreeNode, ran:Random, depth:Int, var head:Int): Int{
		var newhead:Int = head;
		val key = ran.nextInt(5);
		rootS.key = rootP.key = key;

		if ( depth > 0 ) {
			rootS.left =  nodePoolLeft(head); rootP.left = nodePoolLeft(head+1);
			rootS.right = nodePoolRight(head); rootP.right = nodePoolRight(head+1);
			newhead += 2;
			newhead = randomBinTree(rootS.left, rootP.left,ran,depth-1,newhead);
			newhead = randomBinTree(rootS.right, rootP.right,ran,depth-1,newhead);
		}

		return newhead;
	}

	/** Prints the tree in dfs style **/
	public def printTree(x:TreeNode,var str:String) {
		Console.OUT.println(str + ".key = " + x.key + ", mark = " + x.mark );

		var str2:String = null;

		if ( x.left != null ) {
			str2 = str + ".left";
			printTree(x.left,str2);
		}

		if ( x.right != null ) {
			str2 = str + ".right";
			printTree(x.right, str2);
		}
	}

	/**
	 * Marks all the nodes as false
	 */
	public def unmarkNodes(root:TreeNode) {
		if(root == null)
			return;
		root.mark = false;
		unmarkNodes(root.left);
		unmarkNodes(root.right);
	}

	/**
	 * Sequential Recursive Code
	 * Marks the nodes with a value of 4 as true and gives the total count
	 */
	public def MarkFoursSeq(root:TreeNode) {
		if(root != null) {
			if(root.key == 4) {
				root.mark = true;
			}

			MarkFoursSeq(root.left);
			MarkFoursSeq(root.right);
		}
	}

	/**
	 * Parallel Code to Count Fours
	 */
	public def MarkFoursPar(root:TreeNode, depth:Int) {
		if(root != null) {
			if(root.key == 4) {
				root.mark = true;
			}

			if (depth > treeDepth - 15) {
				finish {
					async MarkFoursSeq(root.left);
					MarkFoursSeq(root.right);
				}
				return;
			}

			finish {
				async MarkFoursPar(root.left, depth + 1);
				MarkFoursPar(root.right, depth + 1);
			}
		}
	}

	/** validate in dfs fashion **/
	public def validate (rootA:TreeNode, rootB:TreeNode) {
		if ((rootA == null) || (rootB == null)) {
			if (rootA != rootB) return false;
			return true;
		}
		
		if (rootA.mark != rootB.mark) { 
			return false;
		} else { 
			return (validate(rootA.left,rootB.left) && validate(rootA.right,rootB.right));
		}
	}

	/** main **/
	public static def main(args:Array[String]) {
		if (args.size < 3) {
			Console.OUT.println("Usage: MarkFours <treeDepth:Int> <seed:Int> <num_trials> ");
			return;
		}

		val tree_depth = Int.parseInt(args(0));
		val seed = Int.parseInt(args(1));
		val num_trials = Int.parseInt(args(2));

		Console.OUT.println("tree_depth = " + tree_depth);
		if (tree_depth > 20) {
			Console.OUT.println("Sorry. Try a smaller tree depth. ");
		}

		val cf:MarkFours = new MarkFours();
		cf.treeDepth = tree_depth;
		
		// Allocate pool of tree nodes, one "new" lot more efficient than a million "new"'s
		cf.allocateTreeNodes(tree_depth);

		// Create a random binary tree
		val ran = new Random(seed);
		val rootS = cf.nodePoolLeft(0);
		val rootP = cf.nodePoolLeft(1);
		cf.randomBinTree(rootS,rootP,ran,tree_depth,2);

		// Warmup Runs
		Console.OUT.println(" Warmup Run, serial ... ");
		cf.MarkFoursSeq(rootS);

		Console.OUT.println(" Warmup Run, parallel ... ");
		finish cf.MarkFoursPar(rootP, 0);

		// Console.OUT.println("finished warmups");
		// cf.printTree(rootS,"rootS"); 
		// Console.OUT.println();
		// cf.printTree(rootP,"rootP");

		if (cf.validate(rootS,rootP)) {
			Console.OUT.println(" Warmup Correctness test PASSED ! ");
		} else {
			Console.OUT.println(" Warmup Correctness test FAILED. Bye! ");
			return;
		}

		Console.OUT.println(" Performance Runs ... ");
		
		for (t in 0..(num_trials-1)) {
			Console.OUT.println("Unmarking prev results ... ");
			cf.unmarkNodes(rootS);
			cf.unmarkNodes(rootP);
			
			Console.OUT.println("Trial " + t + "...");
			val time = System.nanoTime();
			cf.MarkFoursSeq(rootS);
			cf.serialTime += (System.nanoTime() - time) / Meg;
			
			val time2 = System.nanoTime();
			cf.MarkFoursPar(rootP, 0);
			cf.parallelTime += (System.nanoTime() - time2) / Meg;
		}

		if (cf.validate(rootS,rootP)) {
			Console.OUT.println(" Correctness test PASSED ! ");
		} else {
			Console.OUT.println(" Correctness test FAILED. Bye! ");
			return;
		}

		var serialNumber:Long = cf.serialTime() / (num_trials as Long);
		var parallelNumber:Long = cf.parallelTime() / (num_trials as Long);

		Console.OUT.println("[Done.] Over " + num_trials + " trials, average time" 
				+ " to compute serially is " + serialNumber
				+ ", and to compute in parallel is " + parallelNumber );
	}
}
