#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#tryinclude <updater>
#tryinclude <saxtonhale>
#tryinclude <freak_fortress_2>
#define REQUIRE_PLUGIN

#if SOURCEMOD_V_MINOR > 7
	#pragma newdecls required
#endif

// Version Number
#define MAJOR_REVISION "1"
#define MINOR_REVISION "0"
//#define PATCH_REVISION "0"

#if !defined PATCH_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...PATCH_REVISION
#endif

public Plugin myinfo = {
	name = "[VSH/FF2]: Streaker",
	author = "SHADoW NiNE TR3S",
	description="Killstreak count increaser for VS Saxton Hale & Freak Fortress 2",
	version=PLUGIN_VERSION,
};


#if defined _updater_included
#define UPDATE_URL "http://www.shadow93.info/tf2/tf2plugins/streaker/update.txt"
#endif

#if defined _VSH_included
bool isVSH=false;
#endif

#if defined _FF2_included
bool isFF2=false;
#endif

Handle cvarKStreakDmg;
Handle cvarKStreak;
Handle cvarUpdater;

public void OnPluginStart()
{	
	CreateConVar("streaker_version", PLUGIN_VERSION, "Streaker Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	cvarUpdater=CreateConVar("streaker_updater", "0", "0-Disable Updater support, 1-Enable automatic updating (requires Updater)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarKStreakDmg=CreateConVar("streaker_kstreak_dmg", "200", "Amount of damage required to increase killstreak count", FCVAR_PLUGIN);
	cvarKStreak=CreateConVar("streaker_kstreak", "1", "Increases your killstreak count by this amount", FCVAR_PLUGIN);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookConVarChange(cvarUpdater, CvarChange);
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _updater_included
	if (StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	#if defined _VSH_included
	if (StrEqual(name, "saxtonhale"))
	{
		isVSH=true;
	}
	#endif
	
	#if defined _FF2_included
	if (StrEqual(name, "freak_fortress_2"))
	{
		isFF2=true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _updater_included
	if(StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_RemovePlugin();
	}
	#endif
	
	#if defined _VSH_included
	if (StrEqual(name, "saxtonhale"))
	{
		isVSH=false;
	}
	#endif
	
	#if defined _FF2_included
	if (StrEqual(name, "freak_fortress_2"))
	{
		isFF2=false;
	}
	#endif
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client) || IsFakeClient(client)) return false;
	return true;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker=GetClientOfUserId(event.GetInt("attacker"));
	int damage=event.GetInt("damageamount");
	
	if(IsValidClient(attacker))
	{
		#if defined _VSH_included
		if(isVSH)
		{
			if(GetClientTeam(attacker)==VSH_GetSaxtonHaleTeam())
				return;
		}
		#endif
		
		#if defined _FF2_included
		if(isFF2)
		{
			if(GetClientTeam(attacker)==FF2_GetBossTeam())
				return;
		}
		#endif 
		
		static int kStreakCount;
		kStreakCount+=damage;
		if(kStreakCount>=GetConVarInt(cvarKStreakDmg))
		{
			SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks")+GetConVarInt(cvarKStreak));
			kStreakCount-=GetConVarInt(cvarKStreakDmg);
		}
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarUpdater)
	{
		#if defined _updater_included
		GetConVarInt(cvarUpdater) ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
		#endif
	}
}