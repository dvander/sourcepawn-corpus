#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1"

#define SPR_VOICE_VMT	"materials/sprites/minimap_icons/voiceicon.vmt"
#define SPR_VOICE_VTF	"materials/sprites/minimap_icons/voiceicon.vtf"

public Plugin:myinfo = 
{
	name = "SetTransmit Example",
	author = "Nut",
	description = "SDKHook_SetTransmit example plugin",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}


new bool:g_TrackArray[33][33];
new g_TrackEnt[33];
new g_EntityArray[2048];

public OnPluginStart()
{
	RegConsoleCmd("track", setsprite);
}

public Action:setsprite(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
		TrackTarget(client, i, true);
	return Plugin_Handled;
}

public TrackTarget(client, target, bool:track)
{
	if (track)
	{
		if (!g_TrackEnt[target])
			CreateSprite(target, SPR_VOICE_VMT, 8.0);
		PrintToConsole(client, "TRACKING %N", target);
	}
	else
		DistroySprite(target);
	g_TrackArray[client][target] = track;
}

public OnEntityCreated(entity, const String:classname[])
	if (StrEqual(classname, "env_sprite_oriented"))
		SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);

public Hook_OnEntitySpawn(entity)
{
	decl String:parentname[32];
	GetEntPropString(entity, Prop_Data, "m_iParent", parentname, sizeof(parentname));
	if (StrContains(parentname, "track") != -1)
	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		PrintToServer("%s created [%i] %i", parentname, entity, GetMaxEntities());
	}
}

public OnEntityDestroyed(entity)
	g_EntityArray[entity] = 0;

public Action:Hook_SetTransmit(entity, client)
{
	if (!g_TrackArray[client][g_EntityArray[entity]])
		return Plugin_Handled;
	return Plugin_Continue;
}

stock CreateSprite(client, String:sprite[], Float:offset)
{
	new String:szTarget[16]; 
	Format(szTarget, sizeof(szTarget), "track%i", client);
	DispatchKeyValue(client, "targetname", szTarget);

	new Float:vOrigin[3]
	GetClientAbsOrigin(client, vOrigin);
	
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented")
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite)
		DispatchKeyValue(ent, "classname", "env_sprite_oriented")
		DispatchKeyValue(ent, "spawnflags", "1")
		DispatchKeyValue(ent, "scale", "0.1")
		DispatchKeyValue(ent, "rendermode", "1")
		DispatchKeyValue(ent, "rendercolor", "255 255 255")
		DispatchKeyValue(ent, "parentname", szTarget);
		DispatchSpawn(ent)
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR)
		
		SetSpriteParent(ent, szTarget);
		g_TrackEnt[client] = ent
		g_EntityArray[ent] = client;
	}
}

stock SetSpriteParent(ent, String:szTargetName[])
{
	SetVariantString(szTargetName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	SetVariantString("head");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

stock DistroySprite(client)
{
	new ent = g_TrackEnt[client];
	if (g_TrackEnt[client] > 0 && IsValidEntity(g_TrackEnt[client]))
	{
		AcceptEntityInput(ent, "kill");
		g_EntityArray[ent] = 0;
		g_TrackEnt[client] = 0;
		
		for (new i = 1; i <= MaxClients; i++)
			g_TrackArray[i][client] = false;
	}
}