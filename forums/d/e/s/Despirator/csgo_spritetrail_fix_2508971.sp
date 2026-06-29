#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name		= "[CS:GO] Spritetrail fix",
	author		= "FrozDark",
	description	= "",
	version		= PLUGIN_VERSION,
	url			= "www.hlmod.ru"
}

public OnPluginStart()
{
	CreateConVar("sm_spritetrail_fix_version", PLUGIN_VERSION, "[CS:GO] SpriteTrails Fix version", FCVAR_DONTRECORD|FCVAR_CHEAT|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	new index = -1;
	while ((index = FindEntityByClassname(index, "env_spritetrail")) != -1)
	{
		if (IsValidEdict(index))
		{
			FixSpriteTrail(index);
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	OnMapStart();
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "env_spritetrail", false))
	{	
		FixSpriteTrail(entity);
	}
}

FixSpriteTrail(entity)
{
	SetVariantString("OnUser1 !self:SetScale:1:0.5:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}