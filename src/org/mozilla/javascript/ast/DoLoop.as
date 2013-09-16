package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Do statement.  Node type is {@link Token#DO}.<p>
	 *
	 * <pre><i>DoLoop</i>:
	 * <b>do</b> Statement <b>while</b> <b>(</b> Expression <b>)</b> <b>;</b></pre>
	 */
	public class DoLoop extends Loop
	{
		private var condition:AstNode;
		private var whilePosition:int = -1;
		
		public function DoLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.DO;
		}
		
		/**
		 * Returns loop condition
		 */
		public function getCondition():AstNode {
			return condition;
		}
		
		/**
		 * Sets loop condition, and sets its parent to this node.
		 * @throws IllegalArgumentException if condition is null
		 */
		public function setCondition(condition:AstNode):void {
			assertNotNull(condition);
			this.condition = condition;
			condition.setParent(this);
		}
		
		/**
		 * Returns source position of "while" keyword
		 */
		public function getWhilePosition():int {
			return whilePosition;
		}
		
		/**
		 * Sets source position of "while" keyword
		 */
		public function setWhilePosition(whilePosition:int):void {
			this.whilePosition = whilePosition;
		}
		
		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) +
				   "do " +
				   trim(body.toSource(depth)) +
				   " while (" +
				   condition.toSource(0) +
				   ");\n";
		}
		
		/**
		 * Visits this node, the body, and then the while-expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				body.visit(v);
				condition.visit(v);
			}
		}

	}
}