#define PLUGIN_VERSION "1.0"

#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "[AMY] Name Change Rules",
	author = "raziEiL [disawar1]",
	description = "Adds rules when name change massages should be blocked",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

native BaseComm_IsClientGagged(client);

static bool:g_bCvarSpectator, bool:g_bCvarGagged, bool:g_bBasecommLib, bool:g_bLoadLate, bool:g_bProtobuf;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLoadLate = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_ncr_version", PLUGIN_VERSION, "Name Change Rules plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	new Handle:hCvarSpectator = CreateConVar("sm_ncr_spectator", "1", "Blocks the name change message from being sent if player spectator.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	new Handle:hCvarGagged = CreateConVar("sm_ncr_gagged", "1", "Blocks the name change message from being sent if player gagged.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//AutoExecConfig(true, "sm_ncr"); /* If you need a cfg file you should uncomment this line // */

	g_bCvarSpectator = GetConVarBool(hCvarSpectator);
	g_bCvarGagged = GetConVarBool(hCvarGagged);

	HookConVarChange(hCvarSpectator, NC_OnCvarChanged_Spectator);
	HookConVarChange(hCvarGagged, NC_OnCvarChanged_Gagged);

	HookEvent("player_changename", NC_ev_PlayerChangename, EventHookMode_Pre);

	g_bProtobuf = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	HookUserMessage(GetUserMessageId("SayText2"), NC_mh_OnTextMsgFired, true);

	if (g_bLoadLate && GetFeatureStatus(FeatureType_Native, "BaseComm_IsClientGagged") == FeatureStatus_Available)
		g_bBasecommLib = true;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "basecomm"))
		g_bBasecommLib = true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "basecomm"))
		g_bBasecommLib = false;
}

public Action:NC_ev_PlayerChangename(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dontBroadcast){

		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsFailedRules(client))
			SetEventBroadcast(event, true);
	}
}

public Action:NC_mh_OnTextMsgFired(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (reliable){

		if (!g_bProtobuf){

			new author = BfReadByte(bf);

			if (BfReadByte(bf) || !author)
				return Plugin_Continue;

			decl String:sText[128];
			BfReadString(bf, sText, 128);

			if (StrContains(sText, "_Name_Change") != -1 && IsFailedRules(author))
				return Plugin_Handled;
		}
		else {

			new author = PbReadInt(bf, "ent_idx");

			if (!PbReadBool(bf, "chat") || !author)
				return Plugin_Continue;

			decl String:sText[128];
			PbReadString(bf, "msg_name", sText, 128);

			if (StrContains(sText, "_Name_Change") != -1 && IsFailedRules(author))
				return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

bool:IsFailedRules(client)
{
	return IsClientAndInGame(client) && ((g_bCvarSpectator && IsClientObserver(client)) || (g_bCvarGagged && g_bBasecommLib && BaseComm_IsClientGagged(client)));
}

bool:IsClientAndInGame(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public NC_OnCvarChanged_Spectator(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
		g_bCvarSpectator = GetConVarBool(convar);
}

public NC_OnCvarChanged_Gagged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
		g_bCvarGagged = GetConVarBool(convar);
}
