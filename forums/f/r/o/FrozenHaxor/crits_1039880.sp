#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Dmg = INVALID_HANDLE;

new cvarenabled;
new cvardmg;

new String:crit_sounds[][] = {
	"crits/crit1.wav",
	"crits/crit2.wav",
	"crits/crit3.wav",
	"crits/crit4.wav",
	"crits/crit5.wav"
};

public Plugin:myinfo = 
{
	name = "Crit sounds",
	author = "FrozenHaxor",
	description = "A portion of crit sounds from TF2",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1039880"
}

public OnPluginStart()
{
	g_Cvar_Enabled = CreateConVar("sm_crit_sounds_enabled", "1", "Enable or disable crit sounds.");
	g_Cvar_Dmg = CreateConVar("sm_crit_sounds_dmg", "50", "Minimum damage required to play crit sound.");
	
	CreateConVar("sm_crit_sounds_version", PLUGIN_VERSION, "Crits version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_hurt", Event_player_hurt);
	
	HookConVarChange(g_Cvar_Enabled, Cvar_Change);
	HookConVarChange(g_Cvar_Dmg, Cvar_Change);
}

public OnMapStart()
{
	if (cvarenabled == 1)
	{
		for (new i = 0; i < 5; i++)
		{
			decl String:fullPath[PLATFORM_MAX_PATH];
			Format(fullPath, sizeof(fullPath), "sound/%s", crit_sounds[i]);
			AddFileToDownloadsTable(fullPath);
			PrecacheSound(crit_sounds[i], true);
		}
	}
}

public OnConfigsExecuted()
{
	cvarenabled = GetConVarInt(g_Cvar_Enabled);
	cvardmg = GetConVarInt(g_Cvar_Dmg);
}

public Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (cvarenabled == 1)
	{
		new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
		new damage = GetEventInt(event,"dmg_health")
	
		if (damage >= cvardmg)
		{
			new Float:vecPos[3];
			GetClientAbsOrigin(iClient, vecPos);
		
			EmitSoundToAll(crit_sounds[GetRandomInt(0,4)], iClient, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
		}
	}
}

public Cvar_Change(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == g_Cvar_Enabled)
	{
		cvarenabled = StringToInt(newValue);
	}
	else if (cvar == g_Cvar_Dmg)
	{
		cvardmg = StringToInt(newValue);
	}
}