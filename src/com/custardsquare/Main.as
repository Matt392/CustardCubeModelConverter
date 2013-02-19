package com.custardsquare
{
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.Stage3DEvent;
	import away3d.tools.serialize.Serialize;
	import away3d.tools.serialize.TraceSerializer;
	import com.custardsquare.battlesystem.KeyHandler;
	import com.custardsquare.core.CustardSquareStage;
	import com.custardsquare.core.DefaultDirectories;
	import com.custardsquare.core.DefaultDisplay;
	import com.custardsquare.custardcube.iso.IsoActor3D;
	import com.custardsquare.custardcube.render2D.ImageExt;
	import com.custardsquare.custardcube.render2D.Scene;
	import com.custardsquare.custardcube.render3D.CompositeModel;
	import com.custardsquare.custardcube.render3D.Custard3DStage;
	import com.custardsquare.custardcube.render3D.ModelAsset;
	import com.custardsquare.custardcube.render3D.ModelAssetLibrary;
	import com.custardsquare.custardcube.utils.asset.AssetLoader;
	import com.custardsquare.custardcube.utils.asset.AsyncManager;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filesystem.StorageVolume;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.text.TextField;
	
	/**
	 * ...
	 * @author Matt Dalzell
	 */
	public class Main extends Sprite 
	{
		
		public function Main():void 
		{
			if (stage) initProxies();
			else addEventListener(Event.ADDED_TO_STAGE, initProxies);
		}
		
		public var starling:Starling;
		private var stage3DManager:Stage3DManager;
		private var stage3DProxy:Stage3DProxy;
		
		private var _model:CompositeModel;
		private var _modelLight:CompositeModel;
		
		private var _keyHandeler:KeyHandler;
		
		private var _scale:Number;
		private var _depth:Number;
		
		private var _rotX:Number;
		private var _rotY:Number;
		private var _rotZ:Number;
		
		private var _info:TextField;
		private var _animInfo:TextField;
		
		private var _assetsLoader:AssetLoader;
		
		private var _actor:IsoActor3D;
		
		public var image:ImageExt;
		private var scene:Scene;

		private var _anims:Vector.<String>;
		
		private var _currentAnim:uint = 0;
		
		private var _file:File;
		
		private function initProxies(e:Event = null):void
		{
			// Define a new Stage3DManager for the Stage3D objects
			stage3DManager = Stage3DManager.getInstance(stage);
		  
			// Create a new Stage3D proxy to contain the separate views
			stage3DProxy = stage3DManager.getFreeStage3DProxy();
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextCreated);
			stage3DProxy.antiAlias = 8;
			stage3DProxy.color = 0x0;
			
			
			
			_scale = 1;
			_depth = 10;
			
			_rotX = 90;
			_rotY = 0;
			_rotZ = 0;
		}
		
		private function onContextCreated(event : Stage3DEvent) : void 
		{
			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextCreated);
			
			initAway3D();
			initStarling();
			
			_info = new TextField(400, 2000, "##Model Info##", "Verdana", 13, 0x00ffff);
			_animInfo = new TextField(400, 2000, "##Anim Info##", "Verdana", 13, 0x00ffff);
			
			_info.x = 0;
			_info.y = 80;
			_info.pivotX = 0;
			_info.pivotY = 0;
			_info.vAlign = "top";
			_info.hAlign = "left";
			_info.touchable = false;
			
			_animInfo.x = 1024;
			_animInfo.y = 80;
			_animInfo.pivotX = 400;
			_animInfo.pivotY = 0;
			_animInfo.vAlign = "top";
			_animInfo.hAlign = "right";
			_animInfo.touchable = false;
			
			starling.stage.addChild(_info);
			starling.stage.addChild(_animInfo);
			
			KeyHandler.instance.init(starling.stage);
			KeyHandler.instance.debugInfo = false;
			
			//_keyHandeler = new KeyHandler();
			
			ModelAssetLibrary.library.localDir = true;
			
			_assetsLoader = new AssetLoader(AsyncManager.PRIORETY_HIGHEST, "");
			//_assetsLoader.queueXML(new AssetID("Model", "Model.xml"));
			//_assetsLoader.dispatcher.addEventListener(AssetLoader.ASSETS_LOADED, onAssetsLoaded);
			//_assetsLoader.load();
			
			
			//_model.root.scale(0.05);
		
			_file = new File();
			//_file.browseForDirectory("Pick Folder");
			_file.browseForOpen("Pick Folder");
			
			_file.addEventListener(Event.SELECT, onDirectoryChoosen);
		}
		
		private function onDirectoryChoosen(e:Event):void 
		{
			while (_file.extension != null)
			{
				_file = _file.parent;
			}
			DefaultDirectories.assets = _file.nativePath + "/";
			
			var files:Array = _file.getDirectoryListing();
			var validFiles:Vector.<String> = new Vector.<String>();
			for (var i:uint = 0 ; i < files.length; ++i)
			{
				if ((files[i] as File).extension == "dae")
				{
					validFiles.push( (files[i] as File).name );
				}
			}
			
			ModelAssetLibrary.library.addFolderAsset(validFiles);
			ModelAssetLibrary.library.loadAssets();
			
			ModelAssetLibrary.library.addEventListener(ModelAssetLibrary.MODEL_ASSETS_LOADED, onAssetsLoaded);
		}
		
		private function onAssetsLoaded(e:Event):void 
		{
			var assetsIDs:Vector.<String> = ModelAssetLibrary.library.modelIDs();
			var path:String = "";
			var parts:Array = [];
			
			var modelBase:ModelAsset = ModelAssetLibrary.library.getModelBase( assetsIDs[0] );
			if (modelBase)
			{
				
				
				var outFileName:String = DefaultDirectories.assets.replace("export", "avatar") + assetsIDs[0] + ".ccm";
				var outXmlFileName:String = DefaultDirectories.assets.replace("export", "avatar");// + assetsIDs[0] + ".xml";
				
				outXmlFileName = outXmlFileName.replace(outXmlFileName.substr(outXmlFileName.indexOf("avatar")), "avatar/parts");
				if (outFileName.indexOf("unisex") > 0)
				{
					outXmlFileName += "/unisex/";
				}
				else if (outFileName.indexOf("loading") > 0)
				{
					outXmlFileName += "/loading/";
				}
				else if (outFileName.indexOf("female") > 0)
				{
					outXmlFileName += "/female/";
				}
				else if (outFileName.indexOf("male") > 0)
				{
					outXmlFileName += "/male/";	
				}
				else if (outFileName.indexOf("npc") > 0)
				{
					outXmlFileName += "/npc/";	
				}
				outXmlFileName += assetsIDs[0] + ".xml";
				
				modelBase.fileID = outXmlFileName.substring(outXmlFileName.indexOf("avatar"));
				modelBase.fileID = modelBase.fileID.replace(".xml", "");
				var newID:String = modelBase.fileID + "-new";
				
				CSLogger.log.info("\nWriting File");
				
				var byteArray:ByteArray = modelBase.toByteArray();
				
				byteArray.compress();
				CSLogger.log.info("Size bytes: " + byteArray.length);
				CSLogger.log.info("\n");
				
				var outFile:File = new File(outFileName);
				var fileStream:FileStream = new FileStream();
				
				fileStream.addEventListener(Event.CLOSE, fileWritten);
				
				fileStream.openAsync(outFile, FileMode.WRITE);   

				// write the bytearray to it
				fileStream.writeBytes(byteArray);

				// close the file
				fileStream.close();
				
				var xmlID:String = "<ID>" + outXmlFileName.substring(outXmlFileName.indexOf("avatar"));
				xmlID = xmlID.replace(".xml", "</ID>");
				
				var targetFile:String = modelBase.fileID;
				while (targetFile.indexOf("/") > 0)
				{
					targetFile = targetFile.substr(targetFile.indexOf("/") + 1);
				}
				
				var xmlTargetFile:String = "<File>" + srcDir() + targetFile + ".ccm</File>";
				
				while (outXmlFileName.indexOf("\\") > 0)
				{
					outXmlFileName = outXmlFileName.replace("\\", "/");
				}
				
				var document:XML = new XML("<Model/>");
				document.appendChild(new XML(xmlID));
				document.appendChild(new XML("<FrameRate>24</FrameRate>"));
				document.appendChild(new XML("<Type>CCM</Type>"));
				document.appendChild(new XML(xmlTargetFile));
				
				
				
				var xmlFile:File =  new File(outXmlFileName);
				
				var xmlByteArray:ByteArray = new ByteArray();
				xmlByteArray.writeUTFBytes(document);
				
				var fileXmlStream:FileStream = new FileStream();
				
				fileXmlStream.addEventListener(Event.CLOSE, fileWritten);
				
				fileXmlStream.openAsync(xmlFile, FileMode.WRITE);   

				// write the bytearray to it
				fileXmlStream.writeBytes(xmlByteArray);

				// close the file
				fileXmlStream.close();
				
				
				byteArray.position = 0;
				byteArray.uncompress();
				var newModel:ModelAsset = ModelAsset.fromBinary(byteArray);
				newModel.fileID = newID;
				ModelAssetLibrary.library.addModelBase(newModel);
			}
			/*
			byteArray.position = 0;
			var newModelBase:ModelAsset = byteArray. as ModelAsset;
			newModelBase.fileID = "TEST";
			
			ModelAssetLibrary.library.addModelBase(newModelBase);
			*/
			parts.push( newID );
			//parts.push( assetsIDs[0] );
			
			trace("Original model\n")
			Serialize.serializeObjectContainer(modelBase.container, new TraceSerializer());
			
			trace("\n\n\n");
			
			trace("New model\n")
			Serialize.serializeObjectContainer(newModel.container, new TraceSerializer());
			

			
			_actor = new IsoActor3D(3, parts, path);
			
			_model = _actor.compositeModel;
			_modelLight = _actor.compositeModelLighting;
			
			
			image = _actor.isoSprite.sprite;
			image.scaleX = 1;
			image.scaleY = 1;
			image.pivotX = 0;
			image.pivotY = 0;
			image.x = 512 - (image.width / 2) / image.scaleX;
			image.y = 384 - (image.height / 2) / image.scaleY;
			
			image.specialShader = null;
			
			scene = new Scene(1024, 768);
			scene.x = 0;
			scene.y = 0;
			starling.stage.addChild(scene);
			
			scene.addChild(image);
			
			
			
		}
		
		private function srcDir():String 
		{
			var strRet:String = DefaultDirectories.assets.replace("export", "avatar");
			
			strRet = strRet.substring(strRet.indexOf("avatar"));
			while (strRet.indexOf("\\") > 0)
			{
				strRet = strRet.replace("\\", "/");
			}
			
			return strRet;
		}
		
		private function fileWritten(e:Event):void 
		{
			CSLogger.log.info("Finished writing file");
		}
		
		private function initAway3D():void
		{
			Custard3DStage.instance.init(this, stage3DProxy, true, true, true);
		}
		
		private function initStarling():void
		{
			//removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			
			starling = new Starling(CustardSquareStage, this.stage, stage3DProxy.viewPort, stage3DProxy.stage3D, "auto", "baseline");
			starling.start();
			
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			//AnimationController.instance.initialize(this.starling.stage);
			//ApplicationFacade.getInstance().startup(this);
			
			CSLogger.log.manualInit(this);
			
		}
		
		private function findAnims():void
		{
			_anims = _model.getAnimNames();
			_currentAnim = 0;
			if (_anims.length > 0)
			{
				_actor.playAnim(_anims[_currentAnim]);
			}
		}
		
		private function update():void
		{
			_animInfo.text = "##Anim Info##\n\nPrevious Anim - F1\nNext Anim - F2\nFind Anims - F3\n\nAnims\n";
			if (_anims)
			{
				for (var i:uint = 0; i < _anims.length; ++i)
				{
					if (_currentAnim == i)
					{
						_animInfo.text += "PLAYING - ";
					}
					_animInfo.text += _anims[i] + "\n";
				}
			}
			
			if (image)
			{
				image.pivotX = image.width / 2;
				image.pivotY = image.height / 2;
				image.x = 512;
				image.y = 384;
			}
			if (_actor)
			{
				_actor.update(1 / 48);
			}
			if (_model)
			{
				_info.text = "##Model Info##\n" + _model.info();
				if (KeyHandler.isKeyPressed(Keyboard.F1, true))
				{
					if (_anims.length > 0)
					{
						if (_currentAnim == 0)
						{
							_currentAnim = _anims.length - 1;
						}
						else
						{
							--_currentAnim;
						}
						_actor.playAnim(_anims[_currentAnim]);
					}
				}
				if (KeyHandler.isKeyPressed(Keyboard.F2, true))
				{
					if (_anims.length > 0)
					{
						if (_currentAnim >= _anims.length-1)
						{
							_currentAnim = 0
						}
						else
						{
							++_currentAnim;
						}
						_actor.playAnim(_anims[_currentAnim]);
					}
				}
				if (KeyHandler.isKeyPressed(Keyboard.F3))
				{
					findAnims();
				}
				
				if (KeyHandler.isKeyDown(Keyboard.F5))
				{
					_scale -= 0.05;
					_model.root.scaleX = _scale;
					_model.root.scaleY = _scale;
					_model.root.scaleZ = _scale;
					_modelLight.root.scaleX = _scale;
					_modelLight.root.scaleY = _scale;
					_modelLight.root.scaleZ = _scale;
					CSLogger.log.info("Scale: " + _scale);
				}
				if (KeyHandler.isKeyDown(Keyboard.F6))
				{
					_scale += 0.05;
					_model.root.scaleX = _scale;
					_model.root.scaleY = _scale;
					_model.root.scaleZ = _scale;
					_modelLight.root.scaleX = _scale;
					_modelLight.root.scaleY = _scale;
					_modelLight.root.scaleZ = _scale;
					CSLogger.log.info("Scale: " + _scale);
				}
				
				
				if (KeyHandler.isKeyDown(Keyboard.F7))
				{
					_depth -= 10;
					_model.root.z = _depth;
					_modelLight.root.z = _depth;
					CSLogger.log.info("Depth: " + _depth);
				}
				if (KeyHandler.isKeyDown(Keyboard.F8))
				{
					_depth += 10;
					_model.root.z = _depth;
					_modelLight.root.z = _depth;
					CSLogger.log.info("Depth: " + _depth);
				}
				
				
				if (KeyHandler.isKeyDown(Keyboard.W))
				{
					_rotX -= 5;
					_model.root.rotationX = _rotX;
					_modelLight.root.rotationX = _rotX;
					CSLogger.log.info("Rot X: " + _rotX);
				}
				if (KeyHandler.isKeyDown(Keyboard.S))
				{
					_rotX += 5;
					_model.root.rotationX = _rotX;
					_modelLight.root.rotationX = _rotX;
					CSLogger.log.info("Rot X: " + _rotX);
				}
				
				
				if (KeyHandler.isKeyDown(Keyboard.A))
				{
					_rotY -= 5;
					_model.root.rotationY = _rotY;
					_modelLight.root.rotationY = _rotY;
					CSLogger.log.info("Rot Y: " + _rotY);
				}
				if (KeyHandler.isKeyDown(Keyboard.D))
				{
					_rotY += 5;
					_model.root.rotationY = _rotY;
					_modelLight.root.rotationY = _rotY;
					CSLogger.log.info("Rot Y: " + _rotY);
				}
				
				
				if (KeyHandler.isKeyDown(Keyboard.Q))
				{
					_rotZ -= 5;
					_model.root.rotationZ = _rotZ;
					_modelLight.root.rotationZ = _rotZ;
					CSLogger.log.info("Rot Z: " + _rotZ);
				}
				if (KeyHandler.isKeyDown(Keyboard.E))
				{
					_rotZ += 5;
					_model.root.rotationZ = _rotZ;
					_modelLight.root.rotationZ = _rotZ;
					CSLogger.log.info("Rot Z: " + _rotZ);
				}
			}
		}
		
		/**
		 * The main rendering loop
		 */
		private function onEnterFrame(event : Event) : void 
		{
			update();
			
		 
			// Clear the Context3D object
			stage3DProxy.clearExt(0x8888ff);

			// Render the Starling animation layer
			//starlingCheckerboard.nextFrame();
			Custard3DStage.instance.renderRTTElements(1/30);
			starling.nextFrame();

			// Render the Away3D layer
			//Custard3DStage.instance.render();

			// Render the Starling stars layer
			//starlingStars.nextFrame();

			// Present the Context3D object to Stage3D
			stage3DProxy.present();
		}
	}
	
}