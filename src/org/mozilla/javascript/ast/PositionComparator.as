package org.mozilla.javascript.ast
{
	import org.as3commons.collections.framework.IComparator;
	
	public class PositionComparator implements IComparator
	{
		public function compare(item1:*, item2:*):int
		{
			var n1:AstNode = AstNode(item1);
			var n2:AstNode = AstNode(item2);
			return n1.getPosition() - n2.getPosition();
		}
	}
}