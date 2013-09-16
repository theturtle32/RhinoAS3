package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * If-else statement.  Node type is {@link Token#IF}.<p>
	 *
	 * <pre><i>IfStatement</i> :
	 *       <b>if</b> ( Expression ) Statement <b>else</b> Statement
	 *       <b>if</b> ( Expression ) Statement</pre>
	 */
	public class IfStatement extends AstNode
	{
		private var condition:AstNode;
		private var thenPart:AstNode;
		private var elsePosition:int = -1;
		private var elsePart:AstNode;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function IfStatement(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.IF;
		}
		
		/**
		 * Returns if condition
		 */
		public function getCondition():AstNode {
			return condition;
		}
		
		/**
		 * Sets if condition.
		 * @throws IllegalArgumentException if {@code condition} is {@code null}.
		 */
		public function setCondition(condition:AstNode):void {
			assertNotNull(condition);
			this.condition = condition;
			condition.setParent(this);
		}
		
		/**
		 * Returns statement to execute if condition is true
		 */
		public function getThenPart():AstNode {
			return thenPart;
		}
		
		/**
		 * Sets statement to execute if condition is true
		 * @throws IllegalArgumentException if thenPart is {@code null}
		 */
		public function setThenPart(thenPart:AstNode):void {
			assertNotNull(thenPart);
			this.thenPart = thenPart;
			thenPart.setParent(this);
		}
		
		/**
		 * Returns statement to execute if condition is false
		 */
		public function getElsePart():AstNode {
			return elsePart;
		}
		
		/**
		 * Sets statement to execute if condition is false
		 * @param elsePart statement to execute if condition is false.
		 * Can be {@code null}.
		 */
		public function setElsePart(elsePart:AstNode):void {
			this.elsePart = elsePart;
			if (elsePart != null)
				elsePart.setParent(this);
		}
		
		/**
		 * Returns position of "else" keyword, or -1
		 */
		public function getElsePosition():int {
			return elsePosition;
		}
		
		/**
		 * Sets position of "else" keyword, -1 if not present
		 */
		public function setElsePosition(elsePosition:int):void {
			this.elsePosition = elsePosition;
		}
		
		/**
		 * Returns left paren offset
		 */
		public function getLp():int {
			return lp;
		}
		
		/**
		 * Sets left paren offset
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
		 * Sets right paren position, -1 if missing
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
		
		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			var pad:String = makeIndent(depth);
			var sb:String = pad +
							"if (" +
							condition.toSource(0) +
							") ";
			if (thenPart.getType() !== Token.BLOCK) {
				sb += ("\n" + makeIndent(depth + 1));
			}
			sb += (trim(thenPart.toSource(depth)));
			if (elsePart !== null) {
				if (thenPart.getType() !== Token.BLOCK) {
					sb += ("\n" + pad + "else ");
				} else {
					sb += " else ";
				}
				if (elsePart.getType() !== Token.BLOCK
					&& elsePart.getType() !== Token.IF) {
					sb += ("\n" + makeIndent(depth + 1));
				}
				sb += trim(elsePart.toSource(depth));
			}
			sb += "\n";
			return sb;
		}
		
		/**
		 * Visits this node, the condition, the then-part, and
		 * if supplied, the else-part.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				condition.visit(v);
				thenPart.visit(v);
				if (elsePart !== null) {
					elsePart.visit(v);
				}
			}
		}

	}
}