package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for a single name:value entry in an Object literal.
	 * For simple entries, the node type is {@link Token#COLON}, and
	 * the name (left side expression) is either a {@link Name}, a
	 * {@link StringLiteral} or a {@link NumberLiteral}.<p>
	 *
	 * This node type is also used for getter/setter properties in object
	 * literals.  In this case the node bounds include the "get" or "set"
	 * keyword.  The left-hand expression in this case is always a
	 * {@link Name}, and the overall node type is {@link Token#GET} or
	 * {@link Token#SET}, as appropriate.<p>
	 *
	 * The {@code operatorPosition} field is meaningless if the node is
	 * a getter or setter.<p>
	 *
	 * <pre><i>ObjectProperty</i> :
	 *       PropertyName <b>:</b> AssignmentExpression
	 * <i>PropertyName</i> :
	 *       Identifier
	 *       StringLiteral
	 *       NumberLiteral</pre>
	 */
	public class ObjectProperty extends InfixExpression
	{
		public function ObjectProperty(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.COLON;
		}
		
		public function setNodeType(nodeType:int):void {
			if (nodeType !== Token.COLON
				&& nodeType !== Token.GET
				&& nodeType !== Token.SET)
				throw new ArgumentError("invalid node type: " + nodeType);
			setType(nodeType);
		}
		
		/**
		 * Marks this node as a "getter" property.
		 */
		public function setIsGetter():void {
			type = Token.GET;
		}
		
		/**
		 * Returns true if this is a getter function.
		 */
		public function isGetter():Boolean {
			return type === Token.GET;
		}
		
		/**
		 * Marks this node as a "setter" property.
		 */
		public function setIsSetter():void {
			type = Token.SET;
		}
		
		/**
		 * Returns true if this is a setter function.
		 */
		public function isSetter():Boolean {
			return type === Token.SET;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			if (isGetter()) {
				sb += ("get ");
			} else if (isSetter()) {
				sb += ("set ");
			}
			sb += left.toSource(0);
			if (type === Token.COLON) {
				sb += ": ";
			}
			sb += right.toSource(0);
			return sb;
		}
	}
}