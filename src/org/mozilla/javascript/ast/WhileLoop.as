package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * While statement.  Node type is {@link Token#WHILE}.<p>
	 *
	 * <pre><i>WhileStatement</i>:
	 *     <b>while</b> <b>(</b> Expression <b>)</b> Statement</pre>
	 */
	public class WhileLoop extends Loop
	{
		private var condition:AstNode;

		public function WhileLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.WHILE;
		}
		
		/**
		 * Returns loop condition
		 */
		public function getCondition():AstNode {
			return condition;
		}
		
		/**
		 * Sets loop condition
		 * @throws ArgumentError if condition is {@code null}
		 */
		public function setCondition(condition:AstNode):void {
			assertNotNull(condition);
			this.condition = condition;
			condition.setParent(this);
		}
		
		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
				            "while (" +
							condition.toSource(0) +
							") ";
			if (body.getType() === Token.BLOCK) {
				sb += (trim(body.toSource(depth)) + "\n");
			} else {
				sb += ("\n" + body.toSource(depth+1));
			}
			return sb;
		}
		
		/**
		 * Visits this node, the condition, then the body.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				condition.visit(v);
				body.visit(v);
			}
		}

	}
}