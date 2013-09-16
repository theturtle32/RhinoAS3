package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.NodeIterator;
	import org.mozilla.javascript.Token;

	public class Block extends AstNode
	{
		public function Block(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.BLOCK;
		}
		
		/**
		 * Alias for {@link #addChild}.
		 */
		public function addStatement(statement:AstNode):void {
			addChild(statement);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += "{\n";
			var i:NodeIterator = iterator();
			while (i.hasNext()) {
				var kid:Node = i.next();
				sb += AstNode(kid).toSource(depth+1);
			}
			sb += "}\n";
			return sb;
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				var i:NodeIterator = iterator();
				while (i.hasNext()) {
					var kid:Node = i.next();
					AstNode(kid).visit(v);
				}
			}
		}
	}
}