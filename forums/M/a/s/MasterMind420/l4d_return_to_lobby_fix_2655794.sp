#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D/L4D2] Return To Lobby Fix",
	author = "MasterMind420",
	description = "Prevents all return to lobby requests other than from votes",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
    HookUserMessage(GetUserMessageId("DisconnectToLobby"), OnDisconnectToLobby, true);
}

public Action OnDisconnectToLobby(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int iVoteController = FindEntityByClassname(-1, "vote_controller");

	if (!IsValidEntity(iVoteController) || GetEntProp(iVoteController, Prop_Send, "m_activeIssueIndex") == 4)
		return Plugin_Continue;

	return Plugin_Handled;
}