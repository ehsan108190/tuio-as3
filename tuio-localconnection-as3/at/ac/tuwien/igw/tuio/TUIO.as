package at.ac.tuwien.igw.tuio {
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;	
	import flash.text.*;	
	import flash.utils.*;
	import at.ac.tuwien.igw.osc.*;
	
	/**
	 * TUIO class based on flash.events.TUIO 
	 * but partially rewritten for the new
	 * at.ac.tuwien.igw.tuio.TUIOReceiver
	 * 
	 * @author Immanuel Bauer
	 * 
	 */
	
	public class TUIO {		
		private static var targetStage:Stage;			
		private static var frameRate:Number;			
		private static var frameCount:Number;
		private static var tuioReceiver:TUIOReceiver;
		
		internal static var debug:Boolean;				
		private static var isInitialized:Boolean;					
		private static var idArray:Array; 	
		
		private static var eventArray:Array;		
		private static var objectArray:Array;		
		
		private static var swipeThreshold:Number = 1000;
		private static var holdThreshold:Number = 4000;
	
		public static function init (stage:DisplayObjectContainer, debugFlag:Boolean = true):void
		{
			if (isInitialized) { 
				trace("TUIO Already Initialized!"); 
				return;
			}	
			
			if(stage.stage){
				targetStage = stage.stage;
				targetStage.align = "TL";
				targetStage.scaleMode = "noScale";
			} else {
				trace("No Stage available!");
				return;
			}

			debug = debugFlag;				
			isInitialized = true;								
			objectArray = new Array();
			idArray = new Array();
			eventArray = new Array();			
			
			tuioReceiver = new TUIOReceiver();
			tuioReceiver.addReceiveListener(tuioReceiveListener);
			tuioReceiver.addDebugListener(tuioDebugReceiveListener);
			tuioReceiver.start();
		}

		//compatibility function
		public static function init (stage:DisplayObjectContainer, $HOST:String, $PORT:Number, $PLAYBACK_URL:String, $DEBUG:Boolean = true):void {
			init(stage, $DEBUG);				
		}

		public static function addObjectListener(id:Number, receiver:Object):void {
			var tmpObj:TUIOObject = getObjectById(id);			
			if(tmpObj){
				tmpObj.addListener(receiver);				
			}
		}

		public static function removeObjectListener(id:Number, receiver:Object):void {
			var tmpObj:TUIOObject = getObjectById(id);			
			if(tmpObj){
				tmpObj.removeListener(receiver);				
			}
		}		

		public static function getObjectById(id:Number):TUIOObject {
			if(id == 0){
				return new TUIOObject("mouse", 0, targetStage.mouseX, targetStage.mouseY, 0, 0, 0, 0, 10, 10, null);
			}
			for(var i:int=0; i<objectArray.length; i++)  {
				if(objectArray[i].id == id){
					return objectArray[i];
				}
			}
			return null;
		}
		
		public static function start():Boolean {
			if(tuioReceiver != null){
				return tuioReceiver.start();
			} else {
				trace("TUIO isn't initiated yet.");
				return false;
			}
		}
		
		public static function stop():Boolean {
			if(tuioReceiver != null){
				return tuioReceiver.stop();
			} else {
				trace("TUIO isn't initiated yet.");
				return false;
			}
		}

        private static function activateDebugMode():void {
  			debug = true;	
        }
			
		private static function tuioReceiveListener(msgList:Array) {

			var time:Number = getTimer();
			var fseq:String;
			
			//for each received OSCMessage check for embedded TUIO message
			
			for each(var msg:OSCMessage in msgList){

				if (msg.arguments[0] == "fseq") {
					
					fseq = msg.arguments[1];
					
				} else if (msg.arguments[0] == "alive") {
					
					//distribute alive msg to objects and remove "old" ones
					
					for each (var obj:TUIOObject in objectArray){
						obj.tuioAlive = false;
					}
					
					var newIdArray:Array = new Array();
					for (var c:int = 1; c < msg.arguments.length; c++) {
						if(getObjectById(msg.arguments[c])){
							getObjectById(msg.arguments[c]).tuioAlive = true;
						}
					}   
					idArray = newIdArray;
					
				} else if (msg.arguments[0] == "set"){
					
					var type:String = msg.arguments[0];	
					
					if(msg.head == "/tuio/2Dcur"){
						
						var id:int;
						
						var x:Number,
							y:Number,
							X:Number,
							Y:Number,
							m:Number;
						
						try {
							
							id = msg.arguments[1];
							x = Number(msg.arguments[2]) * targetStage.stageWidth;
							y = Number(msg.arguments[3]) * targetStage.stageHeight;
							X = Number(msg.arguments[4]);
							Y = Number(msg.arguments[5]);
							m = Number(msg.arguments[6]);

						} catch (e:Error) {
							trace("Error Reading TUIO Message");
						}
						
						var stagePoint:Point = new Point(x,y);					
						var displayObjArray:Array = targetStage.getObjectsUnderPoint(stagePoint);
						var dobj:DisplayObject = null;
						
						if(displayObjArray.length > 0){							
							dobj = displayObjArray[displayObjArray.length - 1];
						}
						
						//check if object with this id already exists
						var tuioObj:TUIOObject = getObjectById(id);
						
						if (tuioObj == null) {
							//object doesn't exist -> create a new one
							tuioObj = new TUIOObject("2Dcur", id, x, y, X, Y, -1, 0, 0, 0, dobj);
							targetStage.addChild(tuioObj.tuioCursor);								
							objectArray.push(tuioObj);
							tuioObj.notifyCreated();
						} else {
							//object exists -> update values
							tuioObj.tuioCursor.x = x;
							tuioObj.tuioCursor.y = y;
							tuioObj.oldX = tuioObj.x;
							tuioObj.oldY = tuioObj.y;
							tuioObj.x = x;
							tuioObj.y = y;

							tuioObj.width = 0;
							tuioObj.height = 0;
							tuioObj.area = 0;								
							tuioObj.dX = X;
							tuioObj.dY = Y;
							tuioObj.setObjOver(dobj);
							
							var d:Date = new Date();																
							if(!( int(Y*1000) == 0 && int(Y*1000) == 0) ){
								tuioObj.notifyMoved();
							}

							if( int(Y*250) == 0 && int(Y*250) == 0) {
								if(Math.abs(d.time - tuioObj.lastModifiedTime) > holdThreshold){
									for(var ndx:int=0; ndx < eventArray.length; ndx++){
										eventArray[ndx].dispatchEvent(tuioObj.getTouchEvent(TouchEvent.HOLD));
									}
									tuioObj.lastModifiedTime = d.time;																		
								}
							}								
						}

						try {
							if(tuioObj.tuioObject && tuioObj.tuioObject.parent){							
								var localPoint:Point = tuioObj.tuioObject.parent.globalToLocal(stagePoint);							
								tuioObj.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_MOVE, true, false, x, y, localPoint.x, localPoint.y, tuioobj.oldX, tuioobj.oldY, tuioobj.tuioObject, false,false,false, true, m, "2Dcur", id, 0, 0));
							}
						} catch (e:Error) {
							trace("(" + e + ") Dispatch event failed " + tuioObj.id);
						}
					}
				}
			}
			
			for (var i:int=0; i<objectArray.length; i++ ){	
				if(objectArray[i].tuioAlive == false) {
					objectArray[i].notifyRemoved();
					targetStage.removeChild(objectArray[i].tuioCursor);
					objectArray.splice(i, 1);
					i--;
				} else if (debug) {	
					
				}
			}
		}
		
		private static function tuioDebugReceiveListener(msg:String) {
			trace(msg);
		}
		
	}
	
}