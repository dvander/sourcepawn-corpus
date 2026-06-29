#include <sourcemod>
#include <builtinvotes>
#pragma semicolon 1

new Handle:g_hVote;
#define PLUGIN_VERSION "0.01"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports Left 4 Dead 2 only.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Kick The Voter!",
	author = "linux_canadajeff",
	description = "Make It So The Person Calling The Kick Gets Kicked!",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("sm_kickthekicker_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!",	FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AddCommandListener(callvoteListener, "callvote");
}

public Action callvoteListener(int client, const char[] command, int argc)
{
	if (!(0 < client <= MaxClients && IsClientInGame(client)))
	{
		return Plugin_Continue;
	}
	
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		PrintToServer("Admin Called The Vote Let It Go");
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "Voting isn't allowed for spectators.");
		return Plugin_Continue;
	}
	
	char sType[32];
	GetCmdArg(1, sType, sizeof sType);
	
	PrintToServer("Vote Called Type: %s", sType);
	
	new iNumPlayers;
	decl iPlayers[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
		{
			continue;
		}
		iPlayers[iNumPlayers++] = i;
	}
	
	new String:sBuffer[64];
	g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	
	if (strcmp(sType, "kick", false) || strcmp(sType, "returntolobby", false) || strcmp(sType, "changealltalk", false) == 0)
	{
		PrintToServer("Kicking The Kicker Init");
		Format(sBuffer, sizeof(sBuffer), "Kick Player: %N?", client);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		if (client > 0)
		{
			SetBuiltinVoteInitiator(g_hVote, client);
			FakeClientCommand(client, "Vote Yes");
		}
		SetBuiltinVoteResultCallback(g_hVote, CallVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		KickClient(client, "You have been voted off.");
	}
	
	return Plugin_Continue;
}

public void CallVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	DisplayBuiltinVotePass(vote, "Kicking Player: unnamed");
	return;
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
	}
}