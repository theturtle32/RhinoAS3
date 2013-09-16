package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;
	import org.mozilla.javascript.ast.AstNode;
	import org.mozilla.javascript.ast.NodeVisitor;
	
	public class DebugPrintVisitor implements NodeVisitor {
		private var buffer:String;
		private static const DEBUG_INDENT:int = 2;
		
		public function DebugPrintVisitor(buf:String="") {
			buffer = buf;
		}
		public function toString():String {
			return buffer;
		}
		private function makeIndent(depth:int):String {
			var sb:String = "";
			for (var i:int = 0; i < (DEBUG_INDENT * depth); i++) {
				sb += " ";
			}
			return sb;
		}
		public function visit(node:AstNode):Boolean {
			var tt:int = node.getType();
			var name:String = Token.typeToName(tt);
			buffer += (
				node.getAbsolutePosition() + "\t" +
				makeIndent(node.depth()) +
				name + " " +
				node.getPosition() + " " +
				node.getLength()
			);
			if (tt === Token.NAME) {
				buffer += (" " + Name(node).getIdentifier());
			}
			buffer += "\n";
			return true; // process kids
		}
	}
}