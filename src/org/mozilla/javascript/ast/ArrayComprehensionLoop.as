package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.exception.UnsupportedOperationError;

	public class ArrayComprehensionLoop extends ForInLoop
	{
		public function ArrayComprehensionLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns {@code null} for loop body
		 * @return loop body (always {@code null} for this node type)
		 */
		override public function getBody():AstNode {
			return null;
		}
		
		/**
		 * Throws an exception on attempts to set the loop body.
		 * @param body loop body
		 * @throws UnsupportedOperationException
		 */
		override public function setBody(body:AstNode):void {
			throw new UnsupportedOperationError("this node type has no body");
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth)
					+ " for "
					+ (isForEach()?"each ":"")
					+ "("
					+ iterator.toSource(0)
					+ " in "
					+ iteratedObject.toSource(0)
					+ ")";
		}
		
		/**
		 * Visits the iterator expression and the iterated object expression.
		 * There is no body-expression for this loop type.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				iterator.visit(v);
				iteratedObject.visit(v);
			}
		}
	}
}