/*
	This is the source code of Freak Fortress 2: Pause Ability
	Version: 0.4
	Description: Pause the entire server. 
	To-do:
	1) Remove "PAUSED" overlay
	2) Fix prediction for the weapons
	3) Clean up the plugin

*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2>

//Defines
#define PLUGIN_VERSION "0.5.1"
#define ABILITY "ff2_pause"

//Declarations
new Handle:pauseCVar;
new bool:paused;
new bool:IsProxy[MAXPLAYERS+1];
new Handle:rageTM[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Freak Fortress 2: Pause Ability", 
	author = "Naydef",
	description = "Subplugin, which can pause the whole server!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/forumdisplay.php?f=154"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(!IsTF2())
	{
		strcopy(error, err_max, "This subplugin is only for Team Fortress 2. Remove the subplugin!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart2()
{
	pauseCVar=FindConVar("sv_pausable");
	if(pauseCVar==INVALID_HANDLE)
	{
		SetFailState("sv_pausable convar not found. Subplugin disabled!!!");
	}
	AddCommandListener(Listener_PauseCommand, "pause");
	AddCommandListener(Listener_PauseCommand, "unpause"); // For safety
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], action)
{
	if(StrEqual(ability_name, ABILITY, false))
	{
		new client=GetClientOfUserId(FF2_GetBossUserId(boss));
		new Float:time=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ABILITY, 1, 0.0);
		PauseRage(client, time);
	}
	return Plugin_Continue;
}

public PauseRage(client, Float:time)
{
	if(IsValidClient(client))
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				SetNextAttack(i, time);
			}
		}
		SilentCvarChange(pauseCVar, true);
		SetConVarBool(pauseCVar, true);
		SilentCvarChange(pauseCVar, false);
		if(!paused)
		{
			IsProxy[client]=true;
			FakeClientCommand(client, "pause");
			IsProxy[client]=false;
		}
		paused=true;
		//CreateTimer(1.0, Timer_RemOverlay, _, TIMER_FLAG_NO_MAPCHANGE);
		new Handle:packet=CreateDataPack();
		WritePackCell(packet, GetClientUserId(client));
		rageTM[client]=CreateTimer(time, Timer_UnPause, packet, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	if(rageTM[client]!=INVALID_HANDLE)
	{
		TriggerTimer(rageTM[client]);
		rageTM[client]=INVALID_HANDLE;
	}
	IsProxy[client]=false;
}

public Action:Listener_PauseCommand(client, const String:command[], argc)
{
	if(!IsProxy[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Timer_UnPause(Handle:htimer, Handle:packet)
{
	ResetPack(packet);
	new client=GetClientOfUserId(ReadPackCell(packet));
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	SilentCvarChange(pauseCVar, true);
	SetConVarBool(pauseCVar, true);
	SilentCvarChange(pauseCVar, false);
	IsProxy[client]=true;
	if(paused)
	{
		FakeClientCommand(client, "pause");
	}
	paused=false;
	IsProxy[client]=false;
	rageTM[client]=INVALID_HANDLE;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SetNextAttack(i, 0.1);
		}
	}
	CloseHandle(packet);
	return Plugin_Continue;
}

/*
public Action:Timer_RemOverlay(Handle:htimer)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			DoOverlay(i, "");
		}
	}
	return Plugin_Continue;
}
*/

/*                                   Stocks                                            */
bool:IsValidClient(client, bool:replaycheck=true) //From Freak Fortress 2
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}


SilentCvarChange(Handle:cvar, setsilent=true)
{
	new flags=GetConVarFlags(cvar);
	(setsilent) ? (flags^=FCVAR_NOTIFY) : (flags|=FCVAR_NOTIFY);
	SetConVarFlags(cvar, flags);
}

bool:IsTF2()
{
	return (GetEngineVersion()==Engine_TF2) ?  true : false;
}

SetNextAttack(client, Float:time) // Fix prediction
{
	if(IsValidClient(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+time);
		for(new i=0; i<=2; i++)
		{
			new weapon=GetPlayerWeaponSlot(client, i);
			if(IsValidEntity(weapon))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+time);
			}
		}
	}
}

/*
DoOverlay(client, const String:overlay[]) //Copied from FF2
{
	PrintToChatAll("Removing overlay for %N", client);
	new flags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags);
}
*/
