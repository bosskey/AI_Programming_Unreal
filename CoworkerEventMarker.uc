class CoworkerEventMarker extends Actor
	placeable;
	//need a sprite that works
	defaultproperties {
	   begin object Class=SpriteComponent Name=Image2D
		  Sprite = EditorResources.AIScript
		  HiddenGame = true
	   end object
		
	   Components.add(Image2D);
	}