package org.mozilla.javascript
{
	// Mirrors functionality of java.io.Reader
	public class Reader
	{
		public function Reader()
		{
		}
		
		public function read(cbuf:Vector.<int>, off:int, len:int):int {
			throw new Error("Unimplemented: Reader.read");
			return -1;
		}
		
		public function close():void {
			throw new Error("Unimplemented: Reader.close");
		}
	}
}