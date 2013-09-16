package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node representing a parse error or a warning.  Node type is
	 * {@link Token#ERROR}.<p>
	 */
	public class ErrorNode extends AstNode
	{
		private var message:String;
		
		public function ErrorNode(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.ERROR;
		}
		
		/**
		 * Returns error message key
		 */
		public function getMessage():String {
			return message;
		}
		
		/**
		 * Sets error message key
		 */
		public function setMessage(message:String):void {
			this.message = message;
		}
		
		override public function toSource(depth:int=0):String {
			return "";
		}
		
		/**
		 * Error nodes are not visited during normal visitor traversals,
		 * but comply with the {@link AstNode#visit} interface.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}