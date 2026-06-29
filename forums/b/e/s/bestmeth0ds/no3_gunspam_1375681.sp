#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#define PLUGIN_VERSION "1.5"
#define MAX_PLAYERS 256

new g_offsCollisionGroup;

public Plugin:myinfo =
{
   name = "NO3_GunSpam",
   author = "ri0t",
   description = "Fixes a glitch which allows users to crash/lag a server.",
   version = PLUGIN_VERSION,
   url = "www.nitrategaming.com"
};

public OnPluginStart()
{
	CreateConVar("sm_gunspam_version", PLUGIN_VERSION, "NO3_GunSpam Version.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
    {
        SetFailState("[NO3] Failed to get offset for CBaseEntity::m_CollisionGroup.");
    }

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:sClassName[32], String:TargetEntity[32];
    new iMaxEntities = GetMaxEntities();

    for (new iEntity = MaxClients + 1; iEntity < iMaxEntities; iEntity++)
    {
        if (IsValidEntity(iEntity) || IsValidEdict(iEntity))
		{
			GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
			Format(TargetEntity, 7, "%s", sClassName);
			if (!StrEqual("weapon_knife", sClassName) && StrEqual("weapon", TargetEntity) || StrEqual("hegren", TargetEntity)
			|| StrEqual("smokeg", TargetEntity))
			{
				SetEntData(iEntity, g_offsCollisionGroup, 2, 4, true);
			}
		}
    }
}

public OnEntityCreated(entity, const String:classname[])
{
	if (IsValidEntity(entity) || IsValidEdict(entity))
	{
		new String:TargetEntity[32];
		Format(TargetEntity, 7, "%s", classname);

		if (!StrEqual("weapon_knife", classname) && StrEqual("weapon", TargetEntity) || StrEqual("hegren", TargetEntity)
		|| StrEqual("smokeg", TargetEntity))
		{
			CreateTimer(0.0, ProcessEdict, entity, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
	}
}

public Action:ProcessEdict(Handle:timer, any:edict)
{
	if (IsValidEdict(edict))
	{
		SetEntData(edict, g_offsCollisionGroup, 2, 4, true);
	}
	return Plugin_Handled;
}