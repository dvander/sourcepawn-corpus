#pragma semicolon 1

#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.4.0"

public Plugin:myinfo =
{
	name = "TF2 Set Speed",
	author = "Tylerst",
	description = "Set the movement speed of the target(s)",
	version = PLUGIN_VERSION,
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new Float:g_flSpeed[MAXPLAYERS+1];
new bool:g_bSpeedSet[MAXPLAYERS+1] = false;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_setspeed_version", PLUGIN_VERSION, "Set the movement speed of the target(s)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hChat = CreateConVar("sm_setspeed_chat", "1", "Enable/Disable Showing setspeed changes in chat");
	hLog = CreateConVar("sm_setspeed_log", "1", "Enable/Disable Logging setspeed changes");
	RegAdminCmd("sm_setspeed", Command_SetSpeed, ADMFLAG_SLAY, "Set target(s) speed, Usage: sm_setspeed \"target\" \"speed\"");
	RegAdminCmd("sm_resetspeed", Command_ResetSpeed, ADMFLAG_SLAY, "Reset target(s) speed, Usage: sm_resetspeed \"target\"");
	RegAdminCmd("sm_unsetspeed", Command_ResetSpeed, ADMFLAG_SLAY, "Reset target(s) speed, Usage: sm_unsetspeed \"target\"");
	for(new client = 1; client <= MaxClients; client++)
	{
		OnClientPutInServer(client);
	}

}

public OnClientPutInServer(client)
{
	g_bSpeedSet[client] = false;
	if(IsValidClient(client, false)) SDKHook(client, SDKHook_PreThink, SDKHooks_OnPreThink);	
}

public SDKHooks_OnPreThink(client)
{
	if(IsValidClient(client) && g_bSpeedSet[client]) SetSpeed(client, g_flSpeed[client]);
}

public Action:Command_SetSpeed(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setspeed \"target\" \"speed\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strSpeed[32], Float:flSpeed, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


	GetCmdArg(2, strSpeed, sizeof(strSpeed));
	flSpeed = StringToFloat(strSpeed);
	
	if(flSpeed < 0.0 || flSpeed > 520.0)
	{
		ReplyToCommand(client, "[SM] Speed must be from 0 to 520");
		return Plugin_Handled;
	}	

	new bool:bLog  = GetConVarBool(hLog);
	for(new i = 0; i < target_count; i++)
	{
		g_flSpeed[target_list[i]] = flSpeed;
		g_bSpeedSet[target_list[i]] = true;
		if(bLog) LogAction(client, target_list[i], "\"%L\" set speed of  \"%L\" to (%f)", client, target_list[i], flSpeed);
	}
	if(GetConVarBool(hChat)) ShowActivity2(client, "[SM] ","Set speed of %s to %-0.2f", target_name, flSpeed);
	return Plugin_Handled;
}

public Action:Command_ResetSpeed(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_resetspeed \"target\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new bool:bLog  = GetConVarBool(hLog);
	for (new i = 0; i < target_count; i ++)
	{
		g_bSpeedSet[target_list[i]] = false;
		ResetSpeed(target_list[i]);
		if(bLog) LogAction(client, target_list[i], "\"%L\" reset speed of  \"%L\" to Normal", client, target_list[i]);	
	}
	if(GetConVarBool(hChat)) ShowActivity2(client, "[SM] ","Set speed of %s to Normal", target_name);
	return Plugin_Handled;
}

stock SetSpeed(client, Float:flSpeed)
{
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", flSpeed);
}

stock ResetSpeed(client)
{
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}

stock bool:IsValidClient(client, bool:bCheckAlive=true)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	if(bCheckAlive) return IsPlayerAlive(client);
	return true;
}