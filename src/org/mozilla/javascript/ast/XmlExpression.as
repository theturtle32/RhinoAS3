package org.mozilla.javascript.ast
{
	/**
	 * AST node for an embedded JavaScript expression within an E4X XML literal.
	 * Node type, like {@link XmlLiteral}, is {@link Token#XML}.  The node length
	 * includes the curly braces.
	 */
	public class XmlExpression extends XmlFragment
	{
		private var expression:AstNode;
		private var _isXmlAttribute:Boolean;
		
		public function XmlExpression(pos:int=-1, len:int=-1, expr:AstNode=null)
		{
			super(pos, len);
			if (expr !== null) {
				setExpression(expr);
			}
		}
		
		/**
		 * Returns the expression embedded in {}
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets the expression embedded in {}, and sets its parent to this node.
		 * @throws ArgumentError if {@code expression} is {@code null}
		 */
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			this.expression = expression;
			expression.setParent(this);
		}
		
		/**
		 * Returns whether this is part of an xml attribute value
		 */
		public function isXmlAttribute():Boolean {
			return _isXmlAttribute;
		}
		
		/**
		 * Sets whether this is part of an xml attribute value
		 */
		public function setIsXmlAttribute(isXmlAttribute:Boolean):void {
			this._isXmlAttribute = isXmlAttribute;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + "{" + expression.toSource(depth) + "}";
		}
		
		/**
		 * Visits this node, then the child expression.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expression.visit(v);
			}
		}
	}
}