#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "[AMY] Name Change Rules",
	author = "raziEiL [disawar1]",
	description = "Adds rules when name change massages should be blocked",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

native void BaseComm_IsClientGagged(int client);

static bool g_bCvarSpectator, g_bCvarGagged, g_bCvarOnOffChatMassage, g_bBasecommLib, g_bLoadLate, g_bProtobuf;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLoadLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_ncr_version", PLUGIN_VERSION, "Name Change Rules plugin version", FCVAR_NONE|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	ConVar hCvarSpectator = CreateConVar("sm_ncr_spectator", "1", "Blocks the name change message from being sent if player spectator.", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCvarGagged = CreateConVar("sm_ncr_gagged", "1", "Blocks the name change message from being sent if player gagged.", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCvarOnOffChatMassage = CreateConVar("sm_ncr_massage", "0", "Full blocks the name change message from being sent.", FCVAR_NONE, true, 0.0, true, 1.0);
	//AutoExecConfig(true, "sm_ncr"); /* If you need a cfg file you should uncomment this line // */

	g_bCvarSpectator = GetConVarBool(hCvarSpectator);
	g_bCvarGagged = GetConVarBool(hCvarGagged);
	g_bCvarOnOffChatMassage = GetConVarBool(hCvarOnOffChatMassage);

	HookConVarChange(hCvarSpectator, NC_OnCvarChanged_Spectator);
	HookConVarChange(hCvarGagged, NC_OnCvarChanged_Gagged);
	HookConVarChange(hCvarOnOffChatMassage, NC_OnCvarChanged_Massage);

	HookEvent("player_changename", NC_ev_PlayerChangename, EventHookMode_Pre);

	g_bProtobuf = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	HookUserMessage(GetUserMessageId("SayText2"), NC_mh_OnTextMsgFired, true);

	if (g_bLoadLate && GetFeatureStatus(FeatureType_Native, "BaseComm_IsClientGagged") == FeatureStatus_Available)
		g_bBasecommLib = true;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "basecomm"))
		g_bBasecommLib = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "basecomm"))
		g_bBasecommLib = false;
}

public Action NC_ev_PlayerChangename(Event event, const char[] name, bool dontBroadcast)
{
	if (!dontBroadcast)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsFailedRules(client))
			SetEventBroadcast(event, true);
	}
}

public Action NC_mh_OnTextMsgFired(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (reliable)
	{
		if (!g_bProtobuf)
		{
			int author = BfReadByte(bf);
			if (BfReadByte(bf) || !author)
				return Plugin_Continue;

			char sText[128];
			BfReadString(bf, sText, 128);

			if (StrContains(sText, "_Name_Change") != -1 && IsFailedRules(author))
				return Plugin_Handled;
		}
		else
		{
			int author = PbReadInt(bf, "ent_idx");
			if (!PbReadBool(bf, "chat") || !author)
				return Plugin_Continue;

			char sText[128];
			PbReadString(bf, "msg_name", sText, 128);

			if (StrContains(sText, "_Name_Change") != -1 && IsFailedRules(author))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

bool IsFailedRules(int client)
{
	return IsClientAndInGame(client) && ((g_bCvarSpectator && IsClientObserver(client)) || (g_bCvarGagged && g_bBasecommLib && BaseComm_IsClientGagged(client) || g_bCvarOnOffChatMassage));
}

bool IsClientAndInGame(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public void NC_OnCvarChanged_Spectator(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
		g_bCvarSpectator = GetConVarBool(convar);
}

public void NC_OnCvarChanged_Gagged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
		g_bCvarGagged = GetConVarBool(convar);
}

public void NC_OnCvarChanged_Massage(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
		g_bCvarOnOffChatMassage = GetConVarBool(convar);
}
