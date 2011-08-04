package org.tuio.adapters
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	import org.tuio.TuioClient;
	import org.tuio.TuioContainer;
	import org.tuio.TuioCursor;
	import org.tuio.TuioManager;
	import org.tuio.debug.TuioDebug;
	import org.tuio.util.DisplayListHelper;

	/**
	 * Listens on <em>native</em> TouchEvents. All touch devices supported by Adobe AIR (e.g., Windows 7 touch
	 * and Android touch devices) can be used with <code>NativeTuioAdapter</code>. Native touch events will be translated to
	 * <code>TuioTouchEvent</code>s. Hence, applications created with TUIO AS3 can be used with native touch 
	 * hardware by employing <code>NativeTuioAdapter</code>. 
	 * 
	 * @author Johannes Luderschmidt
	 * 
	 */
	public class NativeTuioAdapter extends AbstractTuioAdapter{
		
		private var stage:Stage;
		private var useTuioManager:Boolean;
		private var useTuioDebug:Boolean;
		private var lastPos:Array;
		private var frameId:uint = 0;
		private var sessionID:uint = 0;
		private var sessionIDMap:Array = [];
		
		private var src:String = "_native_tuio_adapter_";
		
		public function NativeTuioAdapter(stage:Stage){
			super(this);
			
			if (!this._tuioBlobs[this.src]) this._tuioBlobs[this.src] = [];
			if (!this._tuioCursors[this.src]) this._tuioCursors[this.src] = [];
			if (!this._tuioObjects[this.src]) this._tuioObjects[this.src] = [];
			
			this.stage = stage;
			
			this.lastPos = new Array();
			
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, dispatchTouchMove);
			stage.addEventListener(TouchEvent.TOUCH_END, dispatchTouchUp);
			
			stage.addEventListener(TouchEvent.TOUCH_TAP, dispatchTap);
		}
		
		private function dispatchTap(event:TouchEvent):void{
			var stagePos:Point = new Point(event.stageX, event.stageY);
			var target:DisplayObject = DisplayListHelper.getTopDisplayObjectUnderPoint(stagePos, stage);
			var local:Point = target.globalToLocal(new Point(stagePos.x, stagePos.y));
			
			target.dispatchEvent(new TuioTouchEvent(TuioTouchEvent.TAP, true, false, local.x, local.y, stagePos.x, stagePos.y, target, _tuioCursors[this.src][event.touchPointID]));
		}
		
		private function touchBegin(event:TouchEvent):void{
			this.frameId = this.frameId + 1;
			var tuioCursor:TuioCursor = createTuioCursor(event);
			_tuioCursors[this.src][event.touchPointID] = tuioCursor;
			dispatchAddCursor(tuioCursor);
			lastPos[event.touchPointID] = new Point(event.stageX, event.stageY);
		}
		
		private function dispatchTouchMove(event:TouchEvent):void{
			this.frameId = this.frameId + 1;
			var tuioCursor:TuioCursor = _tuioCursors[this.src][event.touchPointID]; 
			updateTuioCursor(tuioCursor, event);
			dispatchUpdateCursor(tuioCursor);
			lastPos[event.touchPointID] = new Point(event.stageX, event.stageY);
		}
		
		private function dispatchTouchUp(event:TouchEvent):void{
			this.frameId = this.frameId + 1;
			dispatchRemoveCursor(_tuioCursors[this.src][event.touchPointID]);
			lastPos[event.touchPointID] = null;
			delete lastPos[event.touchPointID];
			
			var i:Number = 0;
			for each(var tuioCursor:TuioCursor in _tuioCursors[this.src]){
				if(tuioCursor.sessionID == event.touchPointID){
					_tuioCursors[this.src].splice(i, 1);
				}
				i = i+1;
			}
		}

		private function createTuioCursor(event:TouchEvent):TuioCursor{
			var diffX:Number = 0, diffY:Number = 0;
			if (lastPos[event.touchPointID]) {
				diffX = (event.stageX - lastPos[event.touchPointID].x);
				diffY = (event.stageY - lastPos[event.touchPointID].y);
			}
			sessionIDMap[event.touchPointID] = sessionID;
			sessionID++;
			return new TuioCursor("2Dcur",sessionIDMap[event.touchPointID],event.stageX/stage.stageWidth, event.stageY/stage.stageHeight,0,diffX/stage.stageWidth,diffY/stage.stageHeight,0,0,frameId,'NativeTuioAdapter');
		}
		
		private function updateTuioCursor(tuioCursor:TuioCursor, event:TouchEvent):void{
			var diffX:Number = 0, diffY:Number = 0;
			if (lastPos[event.touchPointID]) {
				diffX = (event.stageX - lastPos[event.touchPointID].x);
				diffY = (event.stageY - lastPos[event.touchPointID].y);
			}
			tuioCursor.update(event.stageX/stage.stageWidth, event.stageY/stage.stageHeight,0,diffX/stage.stageWidth,diffY/stage.stageHeight,0,0,this.frameId);
		}
		
	}
}