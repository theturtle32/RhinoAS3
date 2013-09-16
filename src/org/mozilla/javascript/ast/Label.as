package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;
	
	public class Label extends Jump
	{
		private var name:String;
		
		public function Label(pos:int=-1, len:int=-1, name:String = null)
		{
			super();
			type = Token.LABEL;
			if (pos !== -1) {
				this.position = pos;
			}
			if (len !== -1) {
				this.length = len;
			}
			if (name !== null) {
				setName(name);
			}
		}
		
		public function getName():String {
			return name;
		}
		
		/**
		 * Sets the label text
		 * @throws ArgumentError if name is {@code null} or the
		 * empty string.
		 */
		public function setName(name:String):void {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			name = (name === null) ? null : name.replace(/^\s+|\s+$/g, '');
			if (name === null || name === "")
				throw new ArgumentError("invalid label name");
			this.name = name;
		}
		
		override public function toSource(depth:int = 0):String {
			return makeIndent(depth) + name + ":\n";
		}
		
		/**
		 * Visits this label.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}