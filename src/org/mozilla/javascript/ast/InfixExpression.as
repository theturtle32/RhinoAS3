package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node representing an infix (binary operator) expression.
	 * The operator is the node's {@link Token} type.
	 */
	public class InfixExpression extends AstNode
	{
		protected var left:AstNode;
		protected var right:AstNode;
		protected var operatorPosition:int = -1;
		
		public function InfixExpression(pos:int=-1, len:int=-1, operator:int=-1, left:AstNode=null, right:AstNode=null, operatorPos:int=-1)
		{
			super(pos, len);
			if (operator !== -1) {
				setType(operator);
			}
			if (left !== null && right !== null) {
				setLeftAndRight(left, right);
				if (operatorPos !== -1) {
					setOperatorPosition(operatorPos - left.getPosition());
				}
			}
			else if (left !== null) setLeft(left);
			else if (right !== null) setRight(right);
		}
		
		public function setLeftAndRight(left:AstNode, right:AstNode):void {
			assertNotNull(left);
			assertNotNull(right);
			// compute our bounds while children have absolute positions
			var beg:int = left.getPosition();
			var end:int = right.getPosition() + right.getLength();
			setBounds(beg, end);
			
			// this updates thier positions to be parent-relative
			setLeft(left);
			setRight(right);
		}
		
		/**
		 * Returns operator token &ndash; alias for {@link #getType}
		 */
		public function getOperator():int {
			return getType();
		}
		
		/**
		 * Sets operator token &ndash; like {@link #setType}, but throws
		 * an exception if the operator is invalid.
		 * @throws IllegalArgumentException if operator is not a valid token
		 * code
		 */
		public function setOperator(operator:int):void {
			if (!Token.isValidToken(operator))
				throw new ArgumentError("Invalid token: " + operator);
			setType(operator);
		}
		
		/**
		 * Returns the left-hand side of the expression
		 */
		public function getLeft():AstNode {
			return left;
		}

		/**
		 * Sets the left-hand side of the expression, and sets its
		 * parent to this node.
		 * @param left the left-hand side of the expression
		 * @throws IllegalArgumentException} if left is {@code null}
		 */
		public function setLeft(left:AstNode):void {
			assertNotNull(left);
			this.left = left;
			// line number should agree with source position
			setLineno(left.getLineno());
			left.setParent(this);
		}
		
		/**
		 * Returns the right-hand side of the expression
		 * @return the right-hand side.  It's usually an
		 * {@link AstNode} node, but can also be a {@link FunctionNode}
		 * representing Function expressions.
		 */
		public function getRight():AstNode {
			return right;
		}
		
		/**
		 * Sets the right-hand side of the expression, and sets its parent to this
		 * node.
		 * @throws IllegalArgumentException} if right is {@code null}
		 */
		public function setRight(right:AstNode):void {
			assertNotNull(right);
			this.right = right;
			right.setParent(this);
		}
		
		/**
		 * Returns relative offset of operator token
		 */
		public function getOperatorPosition():int {
			return operatorPosition;
		}
		
		/**
		 * Sets operator token's relative offset
		 * @param operatorPosition offset in parent of operator token
		 */
		public function setOperatorPosition(operatorPosition:int):void {
			this.operatorPosition = operatorPosition;
		}
		
		override public function hasSideEffects():Boolean {
			// the null-checks are for malformed expressions in IDE-mode
			switch (getType()) {
				case Token.COMMA:
					return right !== null && right.hasSideEffects();
				case Token.AND:
				case Token.OR:
					return left !== null && left.hasSideEffects()
							|| (right !== null && right.hasSideEffects());
				default:
					return super.hasSideEffects();
			}
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) +
				   left.toSource() + " " +
				   operatorToString(getType()) + " " +
				   right.toSource();
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				left.visit(v);
				right.visit(v);
			}
		}
	}
}