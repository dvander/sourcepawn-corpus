#include <sourcemod>
#include <sdktools>
	#include <sdkhooks>
	
	public Plugin:myinfo = {
	        name = "[TF2] Halloween Health Packs",
	        author = "Dr. McKay",
	        description = "Changes regular health packs to Halloween health packs",
	        version = "1.0.0",
	        url = "http://www.doctormckay.com"
	}
	
	new bool:ignoreNextEntity = false;
	new bool:mapRunning = false;
	
	public OnMapStart() {
	        PrecacheModel("models/props_halloween/halloween_medkit_large.mdl");
	        PrecacheModel("models/props_halloween/halloween_medkit_medium.mdl");
	        PrecacheModel("models/props_halloween/halloween_medkit_small.mdl");
	        mapRunning = true;
	}
	
	public OnMapEnd() {
	        mapRunning = false;
	}
	
	public OnEntityCreated(entity, const String:classname[]) {
	        if(ignoreNextEntity) {
	                ignoreNextEntity = false;
	                LogMessage("Ignored entity");
	                return;
	        }
	        if(!mapRunning) {
	                return;
	        }
	        decl String:model[128];
	       
	        if(StrEqual(classname, "item_healthkit_full")) {
	                Format(model, sizeof(model), "models/props_halloween/halloween_medkit_large.mdl");
	        } else if(StrEqual(classname, "item_healthkit_medium")) {
	                Format(model, sizeof(model), "models/props_halloween/halloween_medkit_medium.mdl");
	        } else if(StrEqual(classname, "item_healthkit_small")) {
	                Format(model, sizeof(model), "models/props_halloween/halloween_medkit_small.mdl");
	        } else {
	                return; // not a healthpack
	        }
	       
	        new Float:pos[3];
	        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	        AcceptEntityInput(entity, "kill");
	       
	        ignoreNextEntity = true;
	        entity = CreateEntityByName(classname);
	        DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
	        DispatchKeyValue(entity, "powerup_model", model);
	        DispatchSpawn(entity);
	        SetEntProp(entity, Prop_Send, "m_iTeamNum", 0, 4);
	        TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	}