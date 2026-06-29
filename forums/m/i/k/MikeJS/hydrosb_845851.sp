#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"
new entone;
new enttwo;
new bool:g_bHydro;
public Plugin:myinfo = 
{
	name = "Hydro Skywalk Blocker",
	author = "MikeJS",
	description = "Fix hydro skywalking exploits.",
	version = PLUGIN_VERSION,
	url = "http://www.mikejsavage.com/"
}
public OnPluginStart() {
	CreateConVar("sm_hydrosb_version", PLUGIN_VERSION, "Hydro Skywalk Blocker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnPluginEnd() {
	if(g_bHydro) {
		if(IsValidEntity(entone))
			AcceptEntityInput(entone, "Kill");
		if(IsValidEntity(enttwo))
			AcceptEntityInput(enttwo, "Kill");
	}
}
public OnMapStart() {
	decl String:map[32];
	GetCurrentMap(map, sizeof(map));
	if(StrEqual(map, "tc_hydro")) {
		decl Float:vecOrigin[3], Float:vecAngles[3];
		g_bHydro = true;
		entone = CreateEntityByName("prop_physics_override");
		if(IsValidEntity(entone)) {
			PrecacheModel("models/props_2fort/spytech_roofbeam02.mdl", true);
			SetEntityModel(entone, "models/props_2fort/spytech_roofbeam02.mdl");
			SetEntityMoveType(entone, MOVETYPE_NONE);
			SetEntProp(entone, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(entone, Prop_Data, "m_usSolidFlags", 28);
			SetEntProp(entone, Prop_Data, "m_nSolidType", 6);
			DispatchSpawn(entone);
			AcceptEntityInput(entone, "DisableMotion");
			AcceptEntityInput(entone, "DisableShadow");
			vecOrigin[0] = -1994.0;
			vecOrigin[1] = -600.0;
			vecOrigin[2] = 1080.0;
			vecAngles[0] = 0.0;
			vecAngles[1] = 0.0;
			vecAngles[2] = 0.0;
			TeleportEntity(entone, vecOrigin, vecAngles, NULL_VECTOR);
			SetEntityRenderMode(entone, RENDER_ENVIRONMENTAL);
		}
		enttwo = CreateEntityByName("prop_physics_override");
		if(IsValidEntity(enttwo)) {
			PrecacheModel("models/props_2fort/spytech_roofbeam01.mdl", true);
			SetEntityModel(enttwo, "models/props_2fort/spytech_roofbeam01.mdl");
			SetEntityMoveType(enttwo, MOVETYPE_NONE);
			SetEntProp(enttwo, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(enttwo, Prop_Data, "m_usSolidFlags", 28);
			SetEntProp(enttwo, Prop_Data, "m_nSolidType", 6);
			DispatchSpawn(enttwo);
			AcceptEntityInput(enttwo, "DisableMotion");
			AcceptEntityInput(enttwo, "DisableShadow");
			vecOrigin[0] = -1000.0;
			vecOrigin[1] = -980.0;
			vecOrigin[2] = 860.0;
			vecAngles[0] = 0.0;
			vecAngles[1] = 90.0;
			vecAngles[2] = -15.0;
			TeleportEntity(enttwo, vecOrigin, vecAngles, NULL_VECTOR);
			SetEntityRenderMode(enttwo, RENDER_ENVIRONMENTAL);
		}
	} else {
		g_bHydro = false;
	}
}