package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for a function call.  Node type is {@link Token#CALL}.<p>
	 */
	public class FunctionCall extends AstNode
	{
		protected static const NO_ARGS:Vector.<AstNode> = new Vector.<AstNode>(0); 
		
		protected var target:AstNode;
		protected var arguments:Vector.<AstNode>;
		protected var lp:int = -1;
		protected var rp:int = -1;
		
		public function FunctionCall(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.CALL;
		}
		
		/**
		 * Returns node evaluating to the function to call
		 */
		public function getTarget():AstNode {
			return target;
		}
		
		/**
		 * Sets node evaluating to the function to call, and sets
		 * its parent to this node.
		 * @param target node evaluating to the function to call.
		 * @throws IllegalArgumentException} if target is {@code null}
		 */
		public function setTarget(target:AstNode):void {
			assertNotNull(target);
			this.target = target;
			target.setParent(this);
		}
		
		/**
		 * Returns function argument list
		 * @return function argument list, or an empty immutable list if
		 *         there are no arguments.
		 */
		public function getArguments():Vector.<AstNode> {
			return this.arguments !== null ? this.arguments : NO_ARGS;
		}
		
		/**
		 * Sets function argument list
		 * @param arguments function argument list.  Can be {@code null},
		 *        in which case any existing args are removed.
		 */
		public function setArguments(newArguments:Vector.<AstNode>):void {
			this.arguments = newArguments;
			if (this.arguments !== null) {
				for each (var arg:AstNode in this.arguments) {
					arg.setParent(this);
				}
			}
		}
		
		/**
		 * Adds an argument to the list, and sets its parent to this node.
		 * @param arg the argument node to add to the list
		 * @throws IllegalArgumentException} if arg is {@code null}
		 */
		public function addArgument(arg:AstNode):void {
			assertNotNull(arg);
			if (this.arguments === null) {
				this.arguments = new Vector.<AstNode>();
			}
			this.arguments.push(arg);
			arg.setParent(this);
		}
		
		/**
		 * Returns left paren position, -1 if missing
		 */
		public function getLp():int {
			return lp;
		}
		
		/**
		 * Sets left paren position
		 * @param lp left paren position
		 */
		public function setLp(lp:int):void {
			this.lp = lp;
		}
		
		/**
		 * Returns right paren position, -1 if missing
		 */
		public function getRp():int {
			return rp;
		}
		
		/**
		 * Sets right paren position
		 */
		public function setRp(rp:int):void {
			this.rp = rp;
		}
		
		/**
		 * Sets both paren positions
		 */
		public function setParens(lp:int, rp:int):void {
			this.lp = lp;
			this.rp = rp;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += (target.toSource(0)
					+ "("
					+ (arguments !== null) ? printList(this.arguments) : ""
					+ ")");
			return sb;
		}
		
		/**
		 * Visits this node, the target object, and the arguments.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				target.visit(v);
				for each (var arg:AstNode in this.arguments) {
					arg.visit(v);
				}
			}
		}
	}
}