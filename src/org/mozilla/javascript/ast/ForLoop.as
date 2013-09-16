package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * C-style for-loop statement.
	 * Node type is {@link Token#FOR}.<p>
	 *
	 * <pre><b>for</b> ( ExpressionNoInopt; Expressionopt ; Expressionopt ) Statement</pre>
	 * <pre><b>for</b> ( <b>var</b> VariableDeclarationListNoIn; Expressionopt ; Expressionopt ) Statement</pre>
	 */
	public class ForLoop extends Loop
	{
		private var initializer:AstNode;
		private var condition:AstNode;
		private var increment:AstNode;
		
		public function ForLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.FOR;
		}
		
		/**
		 * Returns loop initializer variable declaration list.
		 * This is either a {@link VariableDeclaration}, an
		 * {@link Assignment}, or an {@link InfixExpression} of
		 * type COMMA that chains multiple variable assignments.
		 */
		public function getInitializer():AstNode {
			return initializer;
		}
		
		/**
		 * Sets loop initializer expression, and sets its parent
		 * to this node.  Virtually any expression can be in the initializer,
		 * so no error-checking is done other than a {@code null}-check.
		 * @param initializer loop initializer.  Pass an
		 * {@link EmptyExpression} if the initializer is not specified.
		 * @throws IllegalArgumentException if condition is {@code null}
		 */
		public function setInitializer(initializer:AstNode):void {
			assertNotNull(initializer);
			this.initializer = initializer;
			initializer.setParent(this);
		}
		
		/**
		 * Returns loop condition
		 */
		public function getCondition():AstNode {
			return condition;
		}
		
		/**
		 * Sets loop condition, and sets its parent to this node.
		 * @param condition loop condition.  Pass an {@link EmptyExpression}
		 * if the condition is missing.
		 * @throws IllegalArgumentException} if condition is {@code null}
		 */
		public function setCondition(condition:AstNode):void {
			assertNotNull(condition);
			this.condition = condition;
			condition.setParent(this);
		}
		
		/**
		 * Returns loop increment expression
		 */
		public function getIncrement():AstNode {
			return increment;
		}
		
		/**
		 * Sets loop increment expression, and sets its parent to
		 * this node.
		 * @param increment loop increment expression.  Pass an
		 * {@link EmptyExpression} if increment is {@code null}.
		 * @throws IllegalArgumentException} if increment is {@code null}
		 */
		public function setIncrement(increment:AstNode):void {
			assertNotNull(increment);
			this.increment = increment;
			increment.setParent(this);
		}
		
		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"for (" +
							initializer.toSource(0) +
							"; " +
							condition.toSource(0) +
							"; " +
							increment.toSource(0) +
							") ";
			if (body.getType() === Token.BLOCK) {
				sb += trim(body.toSource(depth)) + "\n";
			} else {
				sb += "\n" + body.toSource(depth+1);
			}
			return sb;
		}
		
		/**
		 * Visits this node, the initializer expression, the loop condition
		 * expression, the increment expression, and then the loop body.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				initializer.visit(v);
				condition.visit(v);
				increment.visit(v);
				body.visit(v);
			}
		}
	}
}