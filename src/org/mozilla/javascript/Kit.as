package org.mozilla.javascript
{
	import org.mozilla.javascript.exception.IllegalStateError;

	public class Kit
	{
		public function Kit()
		{
		}
		
		public static function codeBug(msg:String = null):void {
			if (msg) {
				throw new IllegalStateError("FAILED ASSERTION: " + msg);
			}
			throw new IllegalStateError("FAILED ASSERTION");
		}
		
		public static function xDigitToInt(c:int, accumulator:int):int {
			check: {
				// Use 0..9 < A..Z < a..z
				if (c <= 0x39 /* 9 */) {
					c -= 0x30; /* 0 */
					if (0 <= c) { break check; }
				} else if (c <= 0x46 /* F */) {
					if (0x41 /* A */ <= c) {
						c -= (0x41 /* A */ - 10);
						break check;
					}
				} else if (c <= 0x66 /* f */) {
					if (0x61 /* a */ <= c) {
						c -= (0x61 /* a */ - 10);
						break check;
					}
				}
				return -1;
			}
			return (accumulator << 4) | c;
		}
	}
}