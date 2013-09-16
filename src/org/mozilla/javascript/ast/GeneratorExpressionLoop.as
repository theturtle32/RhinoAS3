package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.exception.UnsupportedOperationError;

	public class GeneratorExpressionLoop extends ForInLoop
	{
		public function GeneratorExpressionLoop(pos:int=-1, len:int=-1)
		{
			super(pos, len);
		}
		
		/**
		 * Returns whether the loop is a for-each loop
		 */
		override public function isForEach():Boolean {
			return false;
		}
		
		/**
		 * Sets whether the loop is a for-each loop
		 */
		override public function setIsForEach(isForEach:Boolean):void {
			throw new UnsupportedOperationError("this node type does not support for each");
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