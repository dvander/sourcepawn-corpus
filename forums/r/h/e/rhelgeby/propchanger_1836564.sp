#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Equinox Prop Replacer",
	author = "Zephyrus",
	description = "Replaces prop_physics_multiplayer entities",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = -1;
	decl Float:pos[3];
	decl Float:angle[3];
	decl String:path[PLATFORM_MAX_PATH];
	while((ent=FindEntityByClassname(ent, "prop_physics_multiplayer"))!=-1)
	{
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		GetEntPropVector(ent, Prop_Data, "m_angAbsRotation", angle);
		GetEntPropString(ent, Prop_Data, "m_ModelName", path, sizeof(path));
		AcceptEntityInput(ent, "Kill");
		
		new entity = CreateEntityByName("prop_physics");
		
		DispatchKeyValue(entity, "physdamagescale", "0.0");
		DispatchKeyValue(entity, "model", path);
		SetEntProp(entity, Prop_Data, "m_takedamage", 2);
		DispatchSpawn(entity);
		
		TeleportEntity(entity, pos, angle, NULL_VECTOR);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}
}