package java.lang
{
	// http://docs.oracle.com/javase/7/docs/api/java/lang/Character.html
	public class Character
	{
		public static const UNASSIGNED:uint = 0;
		public static const UPPERCASE_LETTER:uint = 1;
		public static const LOWERCASE_LETTER:uint = 2;
		public static const TITLECASE_LETTER:uint = 3;
		public static const MODIFIER_LETTER:uint = 4;
		public static const OTHER_LETTER:uint = 5;
		public static const NON_SPACING_MARK:uint = 6;
		public static const ENCLOSING_MARK:uint = 7;
		public static const COMBINING_SPACING_MARK:uint = 8;
		public static const DECIMAL_DIGIT_NUMBER:uint = 9;
		public static const LETTER_NUMBER:uint = 10;
		public static const OTHER_NUMBER:uint = 11;
		public static const SPACE_SEPARATOR:uint = 12;
		public static const LINE_SEPARATOR:uint = 13;
		public static const PARAGRAPH_SEPARATOR:uint = 14;
		public static const CONTROL:uint = 15;
		public static const FORMAT:uint = 16;
		public static const PRIVATE_USE:uint = 18;
		public static const SURROGATE:uint = 19;
		public static const DASH_PUNCTUATION:uint = 20;
		public static const START_PUNCTUATION:uint = 21;
		public static const END_PUNCTUATION:uint = 22;
		public static const CONNECTOR_PUNCTUATION:uint = 23;
		public static const OTHER_PUNCTUATION:uint = 24;
		public static const MATH_SYMBOL:uint = 25;
		public static const CURRENCY_SYMBOL:uint = 26;
		public static const MODIFIER_SYMBOL:uint = 27;
		public static const OTHER_SYMBOL:uint = 28;
		public static const INITIAL_QUOTE_PUNCTUATION:uint = 29;
		public static const FINAL_QUOTE_PUNCTUATION:uint = 30;
		
		public static const ERROR:uint = 0xFFFFFFFF;

		public static const JAVA_UNICODE_MAP:Object = {
			'Cn': UNASSIGNED,
			'Lu': UPPERCASE_LETTER,
			'Ll': LOWERCASE_LETTER,
			'Lt': TITLECASE_LETTER,
			'Lm': MODIFIER_LETTER,
			'Lo': OTHER_LETTER,
			'Mn': NON_SPACING_MARK,
			'Me': ENCLOSING_MARK,
			'Mc': COMBINING_SPACING_MARK,
			'Nd': DECIMAL_DIGIT_NUMBER,
			'Nl': LETTER_NUMBER,
			'No': OTHER_NUMBER,
			'Zs': SPACE_SEPARATOR,
			'Zl': LINE_SEPARATOR,
			'Zp': PARAGRAPH_SEPARATOR,
			'Cc': CONTROL,
			'Cf': FORMAT,
			'Co': PRIVATE_USE,
			'Cs': SURROGATE,
			'Pd': DASH_PUNCTUATION,
			'Ps': START_PUNCTUATION,
			'Pe': END_PUNCTUATION,
			'Pc': CONNECTOR_PUNCTUATION,
			'Po': OTHER_PUNCTUATION,
			'Sm': MATH_SYMBOL,
			'Sc': CURRENCY_SYMBOL,
			'Sk': MODIFIER_SYMBOL,
			'So': OTHER_SYMBOL,
			'Pi': INITIAL_QUOTE_PUNCTUATION,
			'Pf': FINAL_QUOTE_PUNCTUATION
		};
		
		public static const ASCII_MAP:Array = ["Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Zs","Po","Po","Po","Sc","Po","Po","Po","Ps","Pe","Po","Sm","Po","Pd","Po","Po","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Po","Po","Sm","Sm","Sm","Po","Po","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Ps","Po","Pe","Sk","Pc","Sk","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ps","Sm","Pe","Sm","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Zs","Po","Sc","Sc","Sc","Sc","So","Po","Sk","So","Lo","Pi","Sm","Cf","So","Sk","So","Sm","No","No","Sk","Ll","Po","Po","Sk","No","Lo","Pf","No","No","No","Po","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Sm","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Sm","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll"];
		public static var map:Array = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,12,24,24,24,26,24,24,24,21,22,24,25,24,20,24,24,9,9,9,9,9,9,9,9,9,9,24,24,25,25,25,24,24,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,21,24,22,27,23,27,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,21,25,22,25,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,12,24,26,26,26,26,28,24,27,28,5,29,25,16,28,27,28,25,11,11,27,2,24,24,27,11,5,30,11,11,11,24,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,25,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,25,2,2,2,2,2,2,2,2];
		
		
		public function Character()
		{
		}
		
		public static function isLetter(codePoint:int):Boolean {
			switch (getType(codePoint)) {
				case UPPERCASE_LETTER:
				case LOWERCASE_LETTER:
				case TITLECASE_LETTER:
				case MODIFIER_LETTER:
				case OTHER_LETTER:
					return true;
				default:
					return false;
			}
		}
		
		public static function isDigit(codePoint:int):Boolean {
			return getType(codePoint) === DECIMAL_DIGIT_NUMBER;
		}
		
		// FIXME: Make real full-unicode implementation.
		// right now this only supports ASCII! (mostly)  :-(
		public static function getType(codePoint:int):int {
			if (codePoint <= 255) {
				return map[codePoint];
			}
			else if (codePoint === 0x20AC /* € */) {
				return CURRENCY_SYMBOL;
			}
			return OTHER_LETTER;
		}
		
		public static function isJavaIdentifierStart(codePoint:int):Boolean {
			if (isLetter(codePoint)) { return true; }
			var type:int = getType(codePoint);
			return type === LETTER_NUMBER || type === CURRENCY_SYMBOL || type === CONNECTOR_PUNCTUATION;
		}
		
		public static function isJavaIdentifierPart(codePoint:int):Boolean {
			switch (getType(codePoint)) {
				case UPPERCASE_LETTER:
				case LOWERCASE_LETTER:
				case TITLECASE_LETTER:
				case MODIFIER_LETTER:
				case OTHER_LETTER:
				case CURRENCY_SYMBOL:
				case CONNECTOR_PUNCTUATION:
				case DECIMAL_DIGIT_NUMBER:
				case LETTER_NUMBER:
				case COMBINING_SPACING_MARK:
					return true;
				default:
					return false;
			}
		}
		
		private static function classConstruct():Boolean {
			return true;
		}
		
		public static var classConstructed:Boolean = classConstruct();
	}
}