#pragma semicolon 1
#pragma newdecls required
#include <sourcemod> 
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{ 
    name = "[L4D2] Replace Magnums", 
    author = "chinagreenelvis, McFlurry, BloodyBlade", 
    description = "Replaces magnums with normal pistol.", 
    version = PLUGIN_VERSION, 
    url = "http://forums.alliedmods.net"     
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

ConVar g_hCvarEnabled;
bool bHooked = false;

public void OnPluginStart()
{
	CreateConVar("l4d2_replace_magnums_version", PLUGIN_VERSION, "L4D2 Replace Magnums plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvarEnabled = CreateConVar("l4d2_replace_magnums_enabled", "1", "Enable/Disable the plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarEnabled.AddChangeHook(Cvar_Enabled);
	AutoExecConfig(true, "l4d2_replace_magnums");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void Cvar_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = g_hCvarEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("round_start", Event_Round_Start);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_Round_Start);
	}
}

Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(10.0, ReplaceMagnumDelay);
	return Plugin_Continue;
}

Action ReplaceMagnumDelay(Handle timer)
{
	int ent = -1, prev = 0, replacement = 0;
	float origin[3], angles[3];
	while ((ent = FindEntityByClassname(ent, "weapon_pistol")) != -1)
	{
		if (prev)
		{
			GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
			replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
			DispatchSpawn(replacement);
			//PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
			if (IsValidEdict(replacement))
			{
				TeleportEntity(replacement, origin, angles, NULL_VECTOR);
				//PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);				
				if (IsValidEdict(prev))
				{
					RemoveEdict(prev);
				}
			}
		}
		prev = ent;
	}
	if (prev)
	{
		GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);   
		replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
		DispatchSpawn(replacement);
		//PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
		if (IsValidEdict(replacement))
		{
			TeleportEntity(replacement, origin, angles, NULL_VECTOR);
			//PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);   
			if (IsValidEdict(prev))
			{
				RemoveEdict(prev);
			}
		}
	}
	while ((ent = FindEntityByClassname(ent, "weapon_spawn")) != -1)
	{
		if (prev)
		{
			GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
			replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
			DispatchSpawn(replacement);
			//PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
			if (IsValidEdict(replacement))
			{
				TeleportEntity(replacement, origin, angles, NULL_VECTOR);
				//PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
				if (IsValidEdict(prev))
				{
					RemoveEdict(prev);
				}
			}
		}
		char weptospawn[32];
		GetEntPropString(ent, Prop_Data, "m_iszWeaponToSpawn", weptospawn, sizeof(weptospawn));
		if(StrContains(weptospawn, "any_pistol", false) != -1 || StrContains(weptospawn, "weapon_pistol_magnum_spawn_magnum", false) != -1)
		{
			prev = ent;
		}
	}
	if (prev)
	{
		GetEntPropVector(prev, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(prev, Prop_Send, "m_angRotation", angles);
		replacement = CreateEntityByName("weapon_pistol_magnum_spawn");
		DispatchSpawn(replacement);
		//PrintToChatAll("Replacing weapon_pistol %i with weapon_pistol_magnum_spawn %i", prev, replacement);
		if (IsValidEdict(replacement))
		{
			TeleportEntity(replacement, origin, angles, NULL_VECTOR);
			//PrintToChatAll("Teleported weapon_pistol_magnum_spawn %i into position, removing weapon_pistol now", replacement);
			if (IsValidEdict(prev))
			{
				RemoveEdict(prev);
			}
		}
	}
	return Plugin_Stop;
}
