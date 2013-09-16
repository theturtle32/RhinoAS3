package org.mozilla.javascript.ast
{
	/**
	 * Abstract base type for loops.
	 */
	public class Loop extends Scope
	{
		protected var body:AstNode;
		protected var lp:int = -1;
		protected var rp:int = -1;
		
		public function Loop(pos:int = -1, len:int = -1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns loop body
		 */
		public function getBody():AstNode {
			return body;
		}
		
		/**
		 * Sets loop body.  Sets the parent of the body to this loop node,
		 * and updates its offset to be relative.  Extends the length of this
		 * node to include the body.
		 */
		public function setBody(body:AstNode):void {
			this.body = body;
			var end:int = body.getPosition() + body.getLength();
			this.setLength(end - this.getPosition());
			body.setParent(this);
		}
		
		/**
		 * Returns left paren position, -1 if missing
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
		 * Returns right paren position, -1 if missing
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
	}
}