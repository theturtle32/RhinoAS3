package org.mozilla.javascript.ast
{
	/**
	 * AST node representing the ternary operator.  Node type is
	 * {@link Token#HOOK}.
	 *
	 * <pre><i>ConditionalExpression</i> :
	 *        LogicalORExpression
	 *        LogicalORExpression ? AssignmentExpression
	 *                            : AssignmentExpression</pre>
	 *
	 * <i>ConditionalExpressionNoIn</i> :
	 *        LogicalORExpressionNoIn
	 *        LogicalORExpressionNoIn ? AssignmentExpression
	 *                                : AssignmentExpressionNoIn</pre>
	 */
	public class ConditionalExpression extends AstNode
	{
		private var testExpression:AstNode;
		private var trueExpression:AstNode;
		private var falseExpression:AstNode;
		private var questionMarkPosition:int = -1;
		private var colonPosition:int = -1;
		
		public function ConditionalExpression(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns test expression
		 */
		public function getTestExpression():AstNode {
			return testExpression;
		}
		
		/**
		 * Sets test expression, and sets its parent.
		 * @param testExpression test expression
		 * @throws IllegalArgumentException if testExpression is {@code null}
		 */
		public function setTestExpression(testExpression:AstNode):void {
			assertNotNull(testExpression);
			this.testExpression = testExpression;
			testExpression.setParent(this);
		}
		
		/**
		 * Returns expression to evaluate if test is true
		 */
		public function getTrueExpression():AstNode {
			return trueExpression;
		}
		
		/**
		 * Sets expression to evaluate if test is true, and
		 * sets its parent to this node.
		 * @param trueExpression expression to evaluate if test is true
		 * @throws IllegalArgumentException if expression is {@code null}
		 */
		public function setTrueExpression(trueExpression:AstNode):void {
			assertNotNull(trueExpression);
			this.trueExpression = trueExpression;
			trueExpression.setParent(this);
		}
		
		/**
		 * Returns expression to evaluate if test is false
		 */
		public function getFalseExpression():AstNode {
			return falseExpression;
		}
		
		/**
		 * Sets expression to evaluate if test is false, and sets its
		 * parent to this node.
		 * @param falseExpression expression to evaluate if test is false
		 * @throws IllegalArgumentException if {@code falseExpression}
		 * is {@code null}
		 */
		public function setFalseExpression(falseExpression:AstNode):void {
			assertNotNull(falseExpression);
			this.falseExpression = falseExpression;
			falseExpression.setParent(this);
		}
		
		/**
		 * Returns position of ? token
		 */
		public function getQuestionMarkPosition():int {
			return questionMarkPosition;
		}
		
		/**
		 * Sets position of ? token
		 * @param questionMarkPosition position of ? token
		 */
		public function setQuestionMarkPosition(questionMarkPosition:int):void {
			this.questionMarkPosition = questionMarkPosition;
		}
		
		/**
		 * Returns position of : token
		 */
		public function getColonPosition():int {
			return colonPosition;
		}
		
		/**
		 * Sets position of : token
		 * @param colonPosition position of : token
		 */
		public function setColonPosition(colonPosition:int):void {
			this.colonPosition = colonPosition;
		}
		
		override public function hasSideEffects():Boolean {
			if (testExpression == null
				|| trueExpression == null
				|| falseExpression == null) codeBug();
			return trueExpression.hasSideEffects()
				&& falseExpression.hasSideEffects();
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) +
				   testExpression.toSource(depth);
				   " ? " +
				   trueExpression.toSource(0) +
				   " : " +
				   falseExpression.toSource(0);
		}
		
		/**
		 * Visits this node, then the test-expression, the true-expression,
		 * and the false-expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				testExpression.visit(v);
				trueExpression.visit(v);
				falseExpression.visit(v);
			}
		}

	}
}