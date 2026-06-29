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

bool g_bEnabled;
int g_iTore;
int g_iBlockpenet;
bool g_bIsrealism;

int g_iCurrentPenetrationCount[MAXPLAYERS+1] = { 0, ... };

#define CVAR_FLAGS FCVAR_NONE|FCVAR_NOTIFY

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))


public Plugin:myinfo =
{
        name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,     
        version = PLUGIN_VERSION,
        url = PLUGIN_URL 
}

stock void Require_L4D2()
{
        char game[32];
        GetGameFolderName(game, sizeof(game));
        if (!StrEqual(game, "left4dead2", false))
        {
                SetFailState("Plugin supports Left 4 Dead 2 only.");
        }
}

public void OnPluginStart()
{
	Require_L4D2();
        ConVar cvarEnabled = CreateConVar("l4d2_RealismMagnum_Enabled", "1", "Enable this plugins?\n0 = Disable, 1 = Enable", CVAR_FLAGS);
	ConVar cvarTore = CreateConVar("l4d2_RealismMagnum_tore", "1", "Magnum will tore common infection to pieces?\n0 = Disable, 1 = Enable, 2 = Only enable in realism", CVAR_FLAGS);
	ConVar cvarBlockpenet = CreateConVar("l4d2_RealismMagnum_blockpenet", "1", "Block Magnum from penetrating the first common infection?\n0 = No, 1 = Yes, 2 = only Block in realism", CVAR_FLAGS);
		
	AutoExecConfig(true, "l4d2_realismMagnum");

	HookConVarChange(cvarEnabled, EnableChanged);
        HookConVarChange(cvarTore, ToreChanged);
        HookConVarChange(cvarBlockpenet, BlockpenetChanged);

	//Get cvars after AutoExecConfig
	g_bEnabled = GetConVarBool(cvarEnabled);
	g_iTore = GetConVarInt(cvarTore);
	g_iBlockpenet = GetConVarInt(cvarBlockpenet);

        ConVar gamemode = FindConVar("mp_gamemode");
	HookConVarChange(gamemode, OnGameModeChanged);

	HookEvent("weapon_fire", Event_WeaponFire)
}

public void EnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{	
	g_bEnabled = StringToInt(newVal) == 1; 
}

public void ToreChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{	
	g_iTore = StringToInt(newVal); 
}

public void BlockpenetChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{	
	g_iBlockpenet = StringToInt(newVal); 
}

public void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bEnabled)
	{
		char buffer_gamemode[32];
		ConVar gamemode = FindConVar("mp_gamemode");
		GetConVarString(gamemode, buffer_gamemode, sizeof(buffer_gamemode));
		if( StrContains(buffer_gamemode, "realism", false) != -1 )
		{
			g_bIsrealism = true;
		}
		g_bIsrealism = false;
	}
}

//Model name does not exist until after the uncommon is spawned
public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_bEnabled)
	{
	        if (entity <= MaxClients || entity > 2048) return;
	        if (StrEqual(classname, "infected"))
	        {
	                SDKHook(entity, SDKHook_SpawnPost, RealismMagnum_SpawnPost); 
		}
	}
}

public void RealismMagnum_SpawnPost(int entity)
{
//	SDKHook(entity, SDKHook_OnTakeDamage, eOnTakeDamage);
	SDKHook(entity, SDKHook_TraceAttack, eOnTraceAttack);
}

public Action:eOnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{

	if (!g_bEnabled)
		return Plugin_Continue;
	
	if (IS_SURVIVOR_ALIVE(attacker))
	{
                g_iCurrentPenetrationCount[attacker]++;

		if (damagetype == -2147483646 && ammotype == 2)
		{
			//Change damagetype to m60
			if ( (g_iTore == 1 || g_iTore == 2 && g_bIsrealism) && g_iCurrentPenetrationCount[attacker] == 1)
			{	
				damagetype = -2130706430;
				return Plugin_Changed;
			}
			//Block 
			else if ( (g_iBlockpenet == 1 || g_iBlockpenet == 2 && g_bIsrealism) && g_iCurrentPenetrationCount[attacker] > 1)
			{				
				SetEntProp(victim, Prop_Send, "m_iRequestedWound1", -1);
				SetEntProp(victim, Prop_Send, "m_iRequestedWound2", -1);
				return Plugin_Handled;   
			}

			return Plugin_Continue;
		}

	        return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        g_iCurrentPenetrationCount[client] = 0;
}
