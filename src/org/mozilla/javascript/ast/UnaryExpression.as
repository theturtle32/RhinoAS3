package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node representing unary operators such as {@code ++},
	 * {@code ~}, {@code typeof} and {@code delete}.  The type field
	 * is set to the appropriate Token type for the operator.  The node length spans
	 * from the operator to the end of the operand (for prefix operators) or from
	 * the start of the operand to the operator (for postfix).<p>
	 *
	 * The {@code default xml namespace = &lt;expr&gt;} statement in E4X
	 * (JavaScript 1.6) is represented as a {@code UnaryExpression} of node
	 * type {@link Token#DEFAULTNAMESPACE}, wrapped with an
	 * {@link ExpressionStatement}.
	 */
	public class UnaryExpression extends AstNode
	{
		private var operand:AstNode;
		private var _isPostfix:Boolean;
		
		/**
		 * Constructs a new UnaryExpression with the specified operator
		 * and operand.  It sets the parent of the operand, and sets its own bounds
		 * to encompass the operator and operand.
		 * @param operator the node type
		 * @param operatorPosition the absolute position of the operator.
		 * @param operand the operand expression
		 * @param postFix true if the operator follows the operand.  Int
		 * @throws IllegalArgumentException} if {@code operand} is {@code null}
		 */
		public function UnaryExpression(pos:int=-1, len:int=-1, operator:int=-1, operatorPosition:int=-1, operand:AstNode=null, postFix:Boolean=false)
		{
			if (pos === -1 && len === -1) {
				assertNotNull(operand);
				var beg:int = postFix ? operand.getPosition() : operatorPosition;
				// JavaScript only has ++ and -- postfix operators, so length is 2
				var end:int = postFix
							  ? operatorPosition + 2
							  : operand.getPosition() + operand.getLength();
				setBounds(beg, end);
				setOperator(operator);
				setOperand(operand);
				_isPostfix = postFix;
			}
			else if (pos !== -1 && len !== -1) {
				super(pos, len);
			}
			else {
				throw new ArgumentError("Illegal invocation");
			}
		}

		/**
		 * Returns operator token &ndash; alias for {@link #getType}
		 */
		public function getOperator():int {
			return type;
		}
		
		/**
		 * Sets operator &ndash; same as {@link #setType}, but throws an
		 * exception if the operator is invalid
		 * @throws IllegalArgumentException if operator is not a valid
		 * Token code
		 */
		public function setOperator(operator:int):void {
			if (!Token.isValidToken(operator))
				throw new ArgumentError("Invalid token: " + operator);
			setType(operator);
		}
		
		public function getOperand():AstNode {
			return operand;
		}
		
		/**
		 * Sets the operand, and sets its parent to be this node.
		 * @throws IllegalArgumentException} if {@code operand} is {@code null}
		 */
		public function setOperand(operand:AstNode):void {
			assertNotNull(operand);
			this.operand = operand;
			operand.setParent(this);
		}
		
		/**
		 * Returns whether the operator is postfix
		 */
		public function isPostfix():Boolean {
			return _isPostfix;
		}
		
		/**
		 * Returns whether the operator is prefix
		 */
		public function isPrefix():Boolean {
			return !_isPostfix;
		}
		
		/**
		 * Sets whether the operator is postfix
		 */
		public function setIsPostfix(isPostfix:Boolean):void {
			_isPostfix = isPostfix;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			if (!isPostfix()) {
				sb += operatorToString(type);
				if (type === Token.TYPEOF || type === Token.DELPROP || type === Token.VOID) {
					sb += " ";
				}
			}
			sb += operand.toSource();
			if (isPostfix) {
				sb += operatorToString(type);
			}
			
			return sb;
		}
		
		/**
		 * Visits this node, then the operand.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				operand.visit(v);
			}
		}
	}
}