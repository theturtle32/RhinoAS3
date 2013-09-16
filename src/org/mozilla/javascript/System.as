package org.mozilla.javascript
{
	import flash.utils.ByteArray;

	public class System
	{
		public function System()
		{
		}
		
		public static function intVectorCopy
			(src:Vector.<int>,
			 srcPos:int,
			 dest:Vector.<int>,
			 destPos:int,
			 length:int):void
		{
			for (var i:int = 0; i < length; i++) {
				dest[destPos+i] = src[srcPos+i]; 
			}
		}
		
		public static function intVectorToString(src:Vector.<int>, offset:int, count:int):String {
			var end:int = offset + count;
			var ba:ByteArray = new ByteArray();
			for (var i:int = offset; i < end; i++) {
				ba.writeUTFBytes(String.fromCharCode(src[i]));
			}
			ba.position = 0;
			var result:String = ba.readUTFBytes(ba.bytesAvailable);
			ba.clear();
			return result;
		}
	}
}