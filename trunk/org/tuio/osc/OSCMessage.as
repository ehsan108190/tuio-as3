﻿package org.tuio.osc {
	
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	
	/**
	 * An OSCMessage
	 * @author Immanuel Bauer
	 */
	public class OSCMessage extends OSCPacket {
		
		private var addressPattern:String;
		private var pattern:String;
		private var action:String;
		private var argumentArray:Array;
		
		/**
		 * Creates a OSCMessage from the given ByteArray containing a binarycoded OSCMessage
		 * 
		 * @param	bytes A ByteArray containing an OSCMessage
		 */
		public function OSCMessage(bytes:ByteArray = null) {
			super(bytes);
			
			if(bytes != null){
				//read the OSCMessage head
				this.addressPattern = this.readString();
				
				//read the parsing pattern for the following OSCMessage bytes
				this.pattern = this.readString();
				
				this.argumentArray = new Array();
				
				//read the remaining bytes according to the parsing pattern
				var innerArray:Array;
				var openArray:Array = this.argumentArray;
				var l:int = this.pattern.length;
				try{
					for(var c:int = 0; c < l; c++){
						switch(this.pattern.charAt(c)){
							case "s": openArray.push(this.readString()); break;
							case "f": openArray.push(this.bytes.readFloat()); break;
							case "i": openArray.push(this.bytes.readInt()); break;
							case "b": openArray.push(this.readBlob()); break;
							case "h": openArray.push(this.read64BInt()); break;
							case "t": openArray.push(this.readTimetag()); break;
							case "d": openArray.push(this.bytes.readDouble()); break;
							case "S": openArray.push(this.readString()); break;
							case "c": openArray.push(this.bytes.readMultiByte(4, "US-ASCII")); break;
							case "r": openArray.push(this.bytes.readUnsignedInt()); break;
							case "T": openArray.push(true); break;
							case "F": openArray.push(false); break;
							case "N": openArray.push(null); break;
							case "I": openArray.push(Infinity); break;
							case "[": innerArray = new Array(); openArray = innerArray; break;
							case "]": this.argumentArray.push(innerArray.concat()); openArray = this.argumentArray; break;
							default: break;
						}
					}
				} catch (e:EOFError) {
					trace("corrupt");
					this.argumentArray = new Array();
					this.argumentArray.push("Corrupted OSCMessage");
					openArray = null;
				}
			} else {
				this.pattern = ",";
				this.argumentArray = []; 
			}
		}
		
		/**
		 * Adds a single argument value to the OSCMessage
		 * For special oscTypes like booleans or infinity there is no value needed
		 * 
		 * @param	oscType The OSCType of the argument.
		 * @param	value The value of the argument.
		 */
		public function addArgument(oscType:String, value:Object = null):void {
			if (oscType.length == 1) {
				if (oscType == "s" && value is String) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "f" && value is Number) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "i" && value is int) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "b" && value is ByteArray) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "h" && value is ByteArray) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "t" && value is OSCTimetag) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else if (oscType == "d" && value is Number) {
					this.pattern += oscType; 
					this.argumentArray.push(value);
				} else {
					throw new Error("Invalid or unknown OSCType or invalid value for given OSCType: " + oscType);
				}
			} else {
				throw new Error("The oscType has to be one character.");
			}
		}
		
		/**
		 * Add multiple argument values to the OSCMessage at once.
		 * 
		 * @param	oscTypes The OSCTypes of the arguments
		 * @param	values The values of the arguments
		 */
		public function addArguments(oscTypes:String, values:Array):void {
			var l:int = oscTypes.length;
			var oscType:String = "";
			var vc:int = 0;
			
			for (var c:int = 0; c < l; c++) {
				oscType = oscTypes.charAt(c);
				if(oscType.charCodeAt(0) < 60){ //isn't a small letter
					if (oscType == "[") {
						this.pattern += oscType;
					} else if (oscType== "]") {
						this.pattern += oscType;
					} else {
						addArgument(oscType);
					}
				} else {
					addArgument(oscType, values[vc]);
					vc++;
				}
			}
		}
		
		/**
		 * @return The address pattern of the OSCMessage
		 */
		public function get address():String {
			return addressPattern;
		}
		
		/**
		 * Sets the address of the Message
		 */
		public function set address(address:String):void {
			this.addressPattern = address;
		}
		
		/**
		 * @return The arguments/content of the OSCMessage
		 */
		public function get arguments():Array {
			return argumentArray;
		}
		
		/**
		 * Generates a String representation of this OSCMessage for debugging purposes
		 * 
		 * @return A traceable String.
		 */
		public override function getPacketInfo():String {
			var out:String = new String();
			out += "\nMessagehead: " + this.addressPattern + " | " + this.pattern + " | ->  (" + this.argumentArray.length + ") \n" + this.argumentsToString() ;
			return out;
		}
		
		/**
		 * Generates a String representation of this OSCMessage's content for debugging purposes
		 * 
		 * @return A traceable String.
		 */
		public function argumentsToString():String{
			var out:String = "arguments: ";
			out += this.argumentArray[0].toString();
			for(var c:int = 1; c < this.argumentArray.length; c++){
				out += " | " + this.argumentArray[c].toString();
			}
			return out;
		}
		
		/**
		 * Checks if the given ByteArray is an OSCMessage
		 * 
		 * @param	bytes The ByteArray to be checked.
		 * @return true if the ByteArray contains an OSCMessage
		 */
		public static function isMessage(bytes:ByteArray):Boolean {
			if (bytes != null) {
				//bytes.position = 0;
				var header:String = bytes.readUTFBytes(1);
				bytes.position -= 1;
				if (header == "/") {
					return true;
				} else {
					return false;
				}
			} else {
				return false;
			}
		}
		
	}
	
}