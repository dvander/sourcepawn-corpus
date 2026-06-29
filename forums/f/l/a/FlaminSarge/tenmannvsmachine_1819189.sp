#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "[TF2] 10vM (Ten Mann vs Machine)",
	author = "FlaminSarge",
	description = "Allows MvM to support up to 10 people (less if Replay/STV)",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}
new Handle:hCvarSafety;
new Handle:hCvarEnabled;
public OnPluginStart()
{
	CreateConVar("tenmvm_version", PLUGIN_VERSION, "Allows up to 10 players (9/8 if Replay/STV are present) to join RED for MvM", FCVAR_NOTIFY|FCVAR_PLUGIN);
	hCvarEnabled = CreateConVar("tenmvm_enabled", "1", "Enable/disable cvar", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarSafety = CreateConVar("tenmvm_safety", "1", "Set 0 to disable the check against more than 10 people joining RED", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("sm_mvmred", Command_JoinRed, 0, "Usage: sm_mvmred to join RED team if on the spectator team");
	AddCommandListener(Cmd_JoinTeam, "jointeam");
	AddCommandListener(Cmd_JoinTeam, "autoteam");
}
public OnMapStart()
{
	IsMvM(true);
}
public Action:Cmd_JoinTeam(client, String:cmd[], args)
{
	new String:arg1[32];
	if (!GetConVarBool(hCvarEnabled)) return Plugin_Continue;
	if (!IsMvM()) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Continue;
	if (IsFakeClient(client)) return Plugin_Continue;	//Bots tend to join whatever team they want regardless of MvM limits
	if (!CheckCommandAccess(client, "sm_mvmred", 0)) return Plugin_Continue;
	if (DetermineTooManyReds()) return Plugin_Continue;
	if (args > 0) GetCmdArg(1, arg1, sizeof(arg1));
	if (StrEqual(cmd, "autoteam", false) || StrEqual(arg1, "auto", false) || StrEqual(arg1, "spectator", false) || StrEqual(arg1, "red", false))
	{
		if (!StrEqual(arg1, "spectator", false) || GetClientTeam(client) == _:TFTeam_Unassigned)
		{
			CreateTimer(0.0, Timer_TurnToRed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			//TurnToRed(client);	//this causes players to have 0 money, not good
			return Plugin_Continue;	//Let them join spec so their money is set properly, then a frame later swap 'em to red
		}
	}
	return Plugin_Continue;
}
public Action:Timer_TurnToRed(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	TurnToRed(client);
}
stock TurnToRed(client)
{
	if (GetClientTeam(client) == _:TFTeam_Red) return;
	new target[MAXPLAYERS + 1] = { -1, ... };
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == _:TFTeam_Red)
		{
			target[count] = i;
			count++;
		}
	}
	for (new i = 0; i < (count - 5); i++)
	{
		if (target[i] != -1) SetEntProp(target[i], Prop_Send, "m_iTeamNum", _:TFTeam_Blue);
	}
	ChangeClientTeam(client, _:TFTeam_Red);
	for (new i = 0; i < (count - 5); i++)
	{
		if (target[i] != -1)
		{
			SetEntProp(target[i], Prop_Send, "m_iTeamNum", _:TFTeam_Red);
			new flag = GetEntPropEnt(target[i], Prop_Send, "m_hItem");
			if (flag > MaxClients && IsValidEntity(flag))
			{
				if (GetEntProp(flag, Prop_Send, "m_iTeamNum") != _:TFTeam_Red) AcceptEntityInput(flag, "ForceDrop");
			}
		}
	}
	if (GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") == _:TFClass_Unknown) ShowVGUIPanel(client, GetClientTeam(client) == 3 ? "class_blue" : "class_red");
}
public Action:Command_JoinRed(client, args)
{
	if (!GetConVarBool(hCvarEnabled)) return Plugin_Continue;	//"Command not found" if Plugin_Continue. We want this if disabled/not MvM
	if (!IsMvM()) return Plugin_Continue;
	if (!IsValidClient(client)) return Plugin_Handled;
	if (IsFakeClient(client)) return Plugin_Continue;	//Bots tend to join whatever team they want regardless of MvM limits
	if (GetClientTeam(client) != _:TFTeam_Spectator) return Plugin_Handled;	//Don't let unassigned/blue/red use this command, it'll cause issues
	if (DetermineTooManyReds())
	{
		ReplyToCommand(client, "[10vM] Sorry, there's too many people already on RED for the robots to spawn properly if you join.");
		return Plugin_Handled;
	}
	TurnToRed(client);
	ReplyToCommand(client, "[10vM] You're no longer spectating.");
	return Plugin_Handled;
}
stock bool:DetermineTooManyReds()
{
	if (!GetConVarBool(hCvarSafety)) return false;
	new max = 10;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsClientReplay(i) || IsClientSourceTV(i)) max--;
		if (GetClientTeam(i) == _:TFTeam_Red) max--;
	}
	return (max <= 0);
}
stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return !(IsClientSourceTV(client) || IsClientReplay(client));
}

stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
