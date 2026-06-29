#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_NAME		"[L4D2] Realism .50AE warhead"
#define PLUGIN_DESCRIPTION	"Magnum will tore common infection to pieces, just like m60, which also prevents its piercing effect"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_AUTHOR		"Iciaria"
#define PLUGIN_URL		"https://forums.alliedmods.net/showthread.php?t=340579"

/*
-------------------------------------------------------------------------------
Change Logs:

1.0 (26-Nov-2022)
	- Initial release.

-------------------------------------------------------------------------------
*/

ConVar cvarEnabled, cvarTore, cvarBlockpenet, cvarAllowAWP, cvarAllowScout, gamemode;
bool bHooked = false, g_bIsrealism = false, g_bAllowAWP = false, g_bAllowScout = false;
int g_iTore = 0, g_iBlockpenet = 0, g_iCurrentPenetrationCount[MAXPLAYERS + 1] = { 0, ... };

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
    name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,     
    version = PLUGIN_VERSION,
    url = PLUGIN_URL 
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_realismMagnum_version", PLUGIN_VERSION, "[L4D2] Realism .50AE warhead plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("l4d2_RealismMagnum_Enabled", "1", "Enable this plugins?\n0 = Disable, 1 = Enable", CVAR_FLAGS);
	cvarTore = CreateConVar("l4d2_RealismMagnum_tore", "1", "Magnum will tore common infection to pieces?\n0 = Disable, 1 = Enable, 2 = Only enable in realism", CVAR_FLAGS);
	cvarBlockpenet = CreateConVar("l4d2_RealismMagnum_blockpenet", "1", "Block Magnum from penetrating the first common infection?\n0 = No, 1 = Yes, 2 = only Block in realism", CVAR_FLAGS);
	cvarAllowAWP = CreateConVar("l4d2_RealismMagnum_allow_awp", "1", "Allow for awp?\n0 = No, 1 = Yes", CVAR_FLAGS);
	cvarAllowScout = CreateConVar("l4d2_RealismMagnum_allow_scout", "1", "Allow for scout?\n0 = No, 1 = Yes", CVAR_FLAGS);

	cvarEnabled.AddChangeHook(EnableChanged);
	cvarTore.AddChangeHook(ConVarsChanged);
	cvarBlockpenet.AddChangeHook(ConVarsChanged);
	gamemode = FindConVar("mp_gamemode");
	gamemode.AddChangeHook(OnGameModeChanged);
	cvarAllowAWP.AddChangeHook(ConVarsChanged);
	cvarAllowScout.AddChangeHook(ConVarsChanged);

	AutoExecConfig(true, "l4d2_realismMagnum");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = cvarEnabled.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		OnGameModeChanged(null, "", "");
		HookEvent("weapon_fire", Event_WeaponFire);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("weapon_fire", Event_WeaponFire);
	}
}

void EnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{	
	IsAllowed(); 
}

void ConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_iTore = cvarTore.IntValue;
	g_iBlockpenet = cvarBlockpenet.IntValue;
	g_bAllowAWP = cvarAllowAWP.BoolValue;
	g_bAllowScout = cvarAllowScout.BoolValue;
}

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (bHooked)
	{
		char buffer_gamemode[32];
		gamemode.GetString(buffer_gamemode, sizeof(buffer_gamemode));
		if(StrContains(buffer_gamemode, "realism", false) != -1)
		{
			g_bIsrealism = true;
		}
		else
		{
			g_bIsrealism = false;
		}
	}
}

//Model name does not exist until after the uncommon is spawned
public void OnEntityCreated(int entity, const char[] classname)
{
	if (bHooked)
	{
	    if (entity > MaxClients && entity <= 2048)
		{
	        if (StrEqual(classname, "infected"))
	        {
	            SDKHook(entity, SDKHook_SpawnPost, RealismMagnum_SpawnPost);
			}
		}
	}
}

void RealismMagnum_SpawnPost(int entity)
{
	SDKHook(entity, SDKHook_TraceAttack, eOnTraceAttack);
}

Action eOnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (bHooked)
	{
		if (IsValidSurv(attacker))
		{
			char Weapon[64];
			GetClientWeapon(attacker, Weapon, sizeof(Weapon));
			if((!g_bAllowAWP && StrEqual(Weapon, "weapon_sniper_awp")) || (!g_bAllowScout && StrEqual(Weapon, "weapon_sniper_scout")))
			{
				return Plugin_Continue;
			}

			g_iCurrentPenetrationCount[attacker]++;
			if (damagetype == -2147483646 && ammotype == 2)
			{
				//Change damagetype to m60
				if ((g_iTore == 1 || (g_iTore == 2 && g_bIsrealism)) && g_iCurrentPenetrationCount[attacker] == 1)
				{	
					damagetype = -2130706430;
					return Plugin_Changed;
				}
				//Block 
				else if ((g_iBlockpenet == 1 || (g_iBlockpenet == 2 && g_bIsrealism)) && g_iCurrentPenetrationCount[attacker] > 1)
				{				
					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", -1);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", -1);
					return Plugin_Handled;   
				}
			}
		}
	}
	return Plugin_Continue;
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidSurv(client))
    {
    	g_iCurrentPenetrationCount[client] = 0;
    }
}

bool IsValidSurv(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
