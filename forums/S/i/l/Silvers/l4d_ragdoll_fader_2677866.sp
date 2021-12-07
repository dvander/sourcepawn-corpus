#define PLUGIN_VERSION 		"1.9"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Ragdoll Fader
*	Author	:	SilverShot
*	Descrp	:	Fades common infected ragdolls.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=306789
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (24-Dec-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

int g_iRagdollFader, g_iPlayerSpawn, g_iRoundStart;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Ragdoll Fader",
	author = "SilverShot",
	description = "Fades common infected ragdolls.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306789"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_ragdoll_fader", PLUGIN_VERSION, "Ragdoll Fader plugin version.", FCVAR_DONTRECORD);

	HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	ResetPlugin();
}



// ====================================================================================================
//					LOAD RAGDOLL FADER
// ====================================================================================================
void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	DeleteFader();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(2.0, tmrLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrLoad(Handle timer)
{
	CreateFader();
}

// Old method when chance 100% and dissolving all infected to always remove ragdoll. New method prevents ragdoll removal if dissolve visual effects have reached the max active limit.
void CreateFader()
{
	if( g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE )
		return;

	g_iRagdollFader = CreateEntityByName("func_ragdoll_fader");
	if( g_iRagdollFader != -1 )
	{
		DispatchSpawn(g_iRagdollFader);
		SetEntPropVector(g_iRagdollFader, Prop_Send, "m_vecMaxs", view_as<float>({ 999999.0, 999999.0, 999999.0 }));
		SetEntPropVector(g_iRagdollFader, Prop_Send, "m_vecMins", view_as<float>({ -999999.0, -999999.0, -999999.0 }));
		SetEntProp(g_iRagdollFader, Prop_Send, "m_nSolidType", 2);
		g_iRagdollFader = EntIndexToEntRef(g_iRagdollFader);
	}
}

void DeleteFader()
{
	if( g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(g_iRagdollFader, "Kill");
		g_iRagdollFader = 0;
	}
}