package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Node representing a catch-clause of a try-statement.
	 * Node type is {@link Token#CATCH}.
	 *
	 * <pre><i>CatchClause</i> :
	 *        <b>catch</b> ( <i><b>Identifier</b></i> [<b>if</b> Expression] ) Block</pre>
	 */
	public class CatchClause extends AstNode
	{
		private var varName:Name;
		private var catchCondition:AstNode;
		private var body:Block;
		private var ifPosition:int = -1;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function CatchClause(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.CATCH;
		}
		
		/**
		 * Returns catch variable node
		 * @return catch variable
		 */
		public function getVarName():Name {
			return varName;
		}
		
		/**
		 * Sets catch variable node, and sets its parent to this node.
		 * @param varName catch variable
		 * @throws IllegalArgumentException if varName is {@code null}
		 */
		public function setVarName(varName:Name):void {
			assertNotNull(varName);
			this.varName = varName;
			varName.setParent(this);
		}
		
		/**
		 * Returns catch condition node, if present
		 * @return catch condition node, {@code null} if not present
		 */
		public function getCatchCondition():AstNode {
			return catchCondition;
		}
		
		/**
		 * Sets catch condition node, and sets its parent to this node.
		 * @param catchCondition catch condition node.  Can be {@code null}.
		 */
		public function setCatchCondition(catchCondition:AstNode):void {
			this.catchCondition = catchCondition;
			if (catchCondition != null)
				catchCondition.setParent(this);
		}
		
		/**
		 * Returns catch body
		 */
		public function getBody():Block {
			return body;
		}
		
		/**
		 * Sets catch body, and sets its parent to this node.
		 * @throws IllegalArgumentException if body is {@code null}
		 */
		public function setBody(body:Block):void {
			assertNotNull(body);
			this.body = body;
			body.setParent(this);
		}
		
		/**
		 * Returns left paren position
		 */
		public function getLp():int {
			return lp;
		}
		
		/**
		 * Sets left paren position
		 */
		public function setLp(lp:int):void {
			this.lp = lp;
		}
		
		/**
		 * Returns right paren position
		 */
		public function getRp():int {
			return rp;
		}
		
		/**
		 * Sets right paren position
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
		
		/**
		 * Returns position of "if" keyword
		 * @return position of "if" keyword, if present, or -1
		 */
		public function getIfPosition():int {
			return ifPosition;
		}
		
		/**
		 * Sets position of "if" keyword
		 * @param ifPosition position of "if" keyword, if present, or -1
		 */
		public function setIfPosition(ifPosition:int):void {
			this.ifPosition = ifPosition;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"catch (" +
							varName.toSource(0);
			if (catchCondition !== null) {
				sb += (" if " + catchCondition.toSource(0));
			}
			sb += (") " + body.toSource(0));
			return sb;
		}
		
		/**
		 * Visits this node, the catch var name node, the condition if
		 * non-{@code null}, and the catch body.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				varName.visit(v);
				if (catchCondition !== null) {
					catchCondition.visit(v);
				}
				body.visit(v);
			}
		}
	}
}