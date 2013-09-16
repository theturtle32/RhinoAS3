package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Return statement.  Node type is {@link Token#RETURN}.<p>
	 *
	 * <pre><i>ReturnStatement</i> :
	 *      <b>return</b> [<i>no LineTerminator here</i>] [Expression] ;</pre>
	 */
	public class ReturnStatement extends AstNode
	{
		private var returnValue:AstNode;
		
		public function ReturnStatement(pos:int=-1, len:int=-1, returnValue:AstNode=null)
		{
			super(pos, len);
			type = Token.RETURN;
			if (returnValue !== null) {
				setReturnValue(returnValue);
			}
		}
		
		/**
		 * Returns return value, {@code null} if return value is void
		 */
		public function getReturnValue():AstNode {
			return returnValue;
		}
		
		/**
		 * Sets return value expression, and sets its parent to this node.
		 * Can be {@code null}.
		 */
		public function setReturnValue(returnValue:AstNode):void {
			this.returnValue = returnValue;
			if (returnValue !== null) {
				returnValue.setParent(this);
			}
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) + "return";
			if (returnValue !== null) {
				sb += (" " + returnValue.toSource(0));
			}
			sb += ";\n";
			return sb;
		}
		
		/**
		 * Visits this node, then the return value if specified.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this) && returnValue !== null) {
				returnValue.visit(v);
			}
		}
	}
}