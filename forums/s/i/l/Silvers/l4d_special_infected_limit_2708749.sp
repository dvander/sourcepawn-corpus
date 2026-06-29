#define PLUGIN_VERSION		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Special Infected Limit
*	Author	:	SilverShot
*	Descrp	:	Uses the z_*_limit cvar values to limit the maximum number of each Special Infected type allowed to be alive.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (05-Jul-2020)
	- Initial release.

1.0 (30-Feb-2020)
	- Originally created.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

bool g_bLeft4Dead2;
ConVar g_hCvarWho;
ConVar g_hCvars[6];
int g_iCvars[6];
int g_iTotal;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Limit",
	author = "SilverShot",
	description = "Uses the z_*_limit cvar values to limit the maximum number of each Special Infected type allowed to be alive.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321696"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
	if( g_bLeft4Dead2 )
	{
		g_iTotal = 6;
		g_hCvars[0] = FindConVar("z_smoker_limit");
		g_hCvars[1] = FindConVar("z_boomer_limit");
		g_hCvars[2] = FindConVar("z_hunter_limit");
		g_hCvars[3] = FindConVar("z_spitter_limit");
		g_hCvars[4] = FindConVar("z_jockey_limit");
		g_hCvars[5] = FindConVar("z_charger_limit");
	}
	else
	{
		g_iTotal = 3;
		g_hCvars[0] = FindConVar("z_gas_limit");
		g_hCvars[1] = FindConVar("z_exploding_limit");
		g_hCvars[2] = FindConVar("z_hunter_limit");
	}

	for( int i = 0; i < g_iTotal; i++ )
	{
		g_hCvars[i].AddChangeHook(ConVarChanged_Cvars);
		g_iCvars[i] = g_hCvars[i].IntValue;
	}

	HookEvent("player_spawn", Event_PlayerSpawn);

	CreateConVar("l4d_special_infected_limit_version",	PLUGIN_VERSION,	"Special Infected Limit plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarWho = CreateConVar("l4d_special_infected_limit_who",	"3",	"1=Bots. 2=Players. 3=Both. Who should be blocked from spawning when the limit is reached.", FCVAR_NOTIFY);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_hCvarWho.IntValue & (1<<1) )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client && IsClientInGame(client) && GetClientTeam(client) == 3 && IsFakeClient(client) && LimitReached(GetEntProp(client, Prop_Send, "m_zombieClass"), true) )
		{
			// Twice, once to die, once to return to ghost.
			L4D_BecomeGhost(client);
			L4D_BecomeGhost(client);
		}
	}
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	for( int i = 0; i < g_iTotal; i++ )
		g_iCvars[i] = g_hCvars[i].IntValue;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	if( g_hCvarWho.IntValue & (1<<0) && LimitReached(zombieClass, false) )
		return Plugin_Handled;
	return Plugin_Continue;
}

bool LimitReached(int zombieClass, bool real)
{
	if( zombieClass > 6 ) return false;

	int total;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == zombieClass )
			total++;
	}

	if( real ) total--; // Because clients have already spawned.

	if( total >= g_iCvars[zombieClass - 1] )
		return true;
	return false;
}