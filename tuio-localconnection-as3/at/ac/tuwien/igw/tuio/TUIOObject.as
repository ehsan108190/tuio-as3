﻿package at.ac.tuwien.igw.tuio {		import flash.display.DisplayObject;		import flash.geom.Point;	public class TUIOObject {						private var isNew:Boolean;			private var eventArray:Array;							internal var tuioAlive:Boolean;				internal var tuioType:String;				internal var tuioCursor:TUIOCursor;				internal var tuioObject:DisplayObject;				internal var x:Number;		internal var y:Number;		internal var oldX:Number;		internal var oldY:Number;				internal var dX:Number;		internal var dY:Number;							internal var id:int;		internal var sID:int;		internal var area:Number = 0;			internal var width:Number = 0;		internal var height:Number = 0;				internal var angle:Number;				internal var pressure:Number;				internal var startTime:Number;		internal var lastModifiedTime:Number;						internal var downX:Number;		internal var downY:Number;			public function TUIOObject (type:String, id:int, x:Number, y:Number, dX:Number, dY:Number, sID:int = -1, angle:Number = 0, height:Number=0.0, width:Number=0.0, tuioObject:DisplayObject = null) {			this.eventArray = new Array();			this.tuioType = type;			this.id = id;			this.x = x;			this.y = y;			this.oldX = x;			this.oldY = y;			this.dX = dX;			this.dY = dY;			this.sID = sID;			this.angle = angle;						this.width = width;			this.height = height;			this.area = width * height;						this.tuioAlive = true;								this.tuioCursor = new TUIOCursor(id, 0xFFFFFF, int(this.area), int(width), int(height));					this.tuioCursor.x = x;			this.tuioCursor.y = y;  								try { 	 			this.tuioObject = tuioObject;			} catch (e:Error)			{				this.tuioObject = null;			}						this.isNew = true;						var d:Date = new Date();			this.startTime = d.time;			this.lastModifiedTime = this.startTime;		}		// FIXME: we could use this function to replace a bunch of the stuff above.. 		public function getTouchEvent(event:String):TouchEvent {			var localPoint:Point;						if(this.tuioObject && this.tuioObject.parent) {				localPoint = this.tuioObject.parent.globalToLocal(new Point(this.x, this.y));										} else {				localPoint = new Point(this.x, this.y);			}			return new TouchEvent(event, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle);		}		internal function notifyCreated():void {			if(this.tuioObject){				try{					var localPoint:Point = this.tuioObject.parent.globalToLocal(new Point(this.x, this.y));									this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_DOWN, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0,this.tuioType, this.id, this.sID, this.angle));														this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_OVER, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0,this.tuioType, this.id, this.sID, this.angle));																						this.downX = this.x;					this.downY = this.y;								} catch (e:Error) {					trace("Notify Created Failed : " + e);					this.tuioObject = null;				}			}					}		internal function notifyMoved():void{			var localPoint:Point;			for(var i:int=0; i < this.eventArray.length; i++){				localPoint = this.eventArray[i].parent.globalToLocal(new Point(this.x, this.y));							this.eventArray[i].dispatchEvent(new TouchEvent(TouchEvent.MOUSE_MOVE, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.eventArray[i], false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));				}					}		internal function notifyRemoved():void{			this.tuioAlive = false;			var localPoint:Point;									if(this.tuioObject && this.tuioObject.parent){								localPoint = this.tuioObject.parent.globalToLocal(new Point(this.x, this.y));								this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_OUT, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));				 							    var dx:Number = this.x - this.downX;			    var dy:Number = this.y - this.downY;			    var dist:Number = Math.sqrt(dx*dx + dy*dy);										    if(dist < 20){					this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.CLICK, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));												    }						}							for(var i:int=0; i < this.eventArray.length; i++){				if(this.eventArray[i] != this.tuioObject) {					localPoint = this.eventArray[i].parent.globalToLocal(new Point(this.x, this.y));									this.eventArray[i].dispatchEvent(new TouchEvent(TouchEvent.MOUSE_UP, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.eventArray[i], false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));												}			}						this.eventArray = new Array();						this.tuioObject = null;				}		internal function setObjOver(o:DisplayObject):void {				var localPoint:Point;				try {								if(this.tuioObject == null)				{					this.tuioObject = o;									if(this.tuioObject) {						localPoint = this.tuioObject.parent.globalToLocal(new Point(this.x, this.y));										this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_OVER, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));										}				} else if(this.tuioObject != o) {					localPoint = tuioObject.parent.globalToLocal(new Point(this.x, this.y));					this.tuioObject.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_OUT, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));					if(o){						localPoint = this.tuioObject.parent.globalToLocal(new Point(this.x, this.y));						o.dispatchEvent(new TouchEvent(TouchEvent.MOUSE_OVER, true, false, this.x, this.y, localPoint.x, localPoint.y, 0, 0, this.tuioObject, false,false,false, true, 0, this.tuioType, this.id, this.sID, this.angle));					}					this.tuioObject = o;				}			} catch (e:Error) {			}		}				internal function addListener(receiver:Object):void {			for(var i:int = 0; i < this.eventArray.length; i++) {				if(this.eventArray[i] == receiver){								return;				}			}			eventArray.push(receiver);		}		internal function removeListener(receiver:Object):void {			for(var i:int = 0; i < this.eventArray.length; i++) {				if (eventArray[i] == receiver) {					eventArray.splice(i, 1);				}			}		}	} }