package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * With statement.  Node type is {@link Token#WITH}.<p>
	 *
	 * <pre><i>WithStatement</i> :
	 *      <b>with</b> ( Expression ) Statement ;</pre>
	 */
	public class WithStatement extends AstNode
	{
		private var expression:AstNode;
		private var statement:AstNode;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function WithStatement(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.WITH;
		}
		
		/**
		 * Returns object expression
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets object expression (and its parent link)
		 * @throws IllegalArgumentException} if expression is {@code null}
		 */
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			this.expression = expression;
			expression.setParent(this);
		}
		
		/**
		 * Returns the statement or block
		 */
		public function getStatement():AstNode {
			return statement;
		}
		
		/**
		 * Sets the statement (and sets its parent link)
		 * @throws IllegalArgumentException} if statement is {@code null}
		 */
		public function setStatement(statement:AstNode):void {
			assertNotNull(statement);
			this.statement = statement;
			statement.setParent(this);
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
		 * Returns right paren offset
		 */
		public function getRp():int {
			return rp;
		}
		
		/**
		 * Sets right paren offset
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
			var sb:String = makeIndent(depth) +
							"with (" +
							expression.toSource(0) +
							") ";
			if (statement.getType() === Token.BLOCK) {
				sb += (trim(statement.toSource(depth)) + "\n");
			} else {
				sb += ("\n" + statement.toSource(depth + 1));
			}
			return sb;
		}
		
		/**
		 * Visits this node, then the with-object, then the body statement.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expression.visit(v);
				statement.visit(v);
			}
		}
	}
}