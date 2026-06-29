#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <voiceannounce_ex>
#include <sourcecomms>

IsSpeaking[MAXPLAYERS+1] = 0;
HLDJ[MAXPLAYERS+1] = 0;

public Plugin myinfo = 
{
	name = "HLDJ Vote Mute",
	author = "Mr.Derp",
	description = "Votemutes HLDJ Players",
	version = "1.0",
	url = "skynetgaming.net"
};

public void OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Post);
	CreateConVar("hldjvote_version", "1.0", "HLDJ Vote Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapEnd()
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		HLDJ[i] = 0;
	}
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new clientid = GetEventInt(event,"userid"); 
	new client = GetClientOfUserId(clientid); 
	IsSpeaking[client] = 0;
	HLDJ[client] = 0;
}

public bool:OnClientSpeakingEx(client)
{
	if (HLDJ[client] != -1)
	{
		if (SourceComms_GetClientMuteType(client) == bNot)
		{
			if (IsSpeaking[client] == 0)
			{
				QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
				IsSpeaking[client] = 1;
			} else if (HLDJ[client] == 0) {
				if (GetRandomInt(0,100) == 100)
				{
					QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
				}
			}
		}
	}
	return true;
}

public OnClientSpeakingEnd(client)
{
	if (IsValidClient(client))
	{
		IsSpeaking[client] = 0;
	}
}

public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {    
	
	decl String:nick[64];
	GetClientName(client, nick, sizeof(nick));
	new Value = StringToInt(cvarValue);
	if (Value == 1 && IsClientSpeaking(client) && SourceComms_GetClientMuteType(client) == bNot)
    {
    	if (HLDJ[client] == 0)
    	{
    		//Set 5 Second Timer
    		CreateTimer(10.0, ReCheck, client);
    		PrintToChat(client, " \x01\x0B\x07We've detected you're playing HLDJ, you have 10 seonds to stop before a vote appears");
    		HLDJ[client] = 1;
    	} else if (HLDJ[client] == 1) {
    		HLDJ[client] = 2;
    		DoVoteMenu(client);
    	}
	} else if (SourceComms_GetClientMuteType(client) == bNot){
    	HLDJ[client] = 0;
    }
}

public Action ReCheck(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
	}
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			for (new i = 1; i <= MAXPLAYERS; i++)
			{
				if (HLDJ[i] == 2)
				{
					new clientid = GetClientUserId(i);
					ServerCommand("sm_mute #%i 30 HLDJ", clientid);
					PrintToChat(i," \x01\x0B\x07You've been muted for 30 minutes", clientid);
					HLDJ[i] = 3;
				}
			}
		} else if (param1 == 1) {
			for (new i = 1; i <= MAXPLAYERS; i++)
			{
				if (HLDJ[i] == 2)
				{
					HLDJ[i] = -1;
					PrintToChatAll(" \x01\x0B\x07Vote has failed! If his music gets worse remember you can always votemute");
				}
			}
		}
		
	}
}

public Action ReDoVote(Handle timer, any client)
{
	DoVoteMenu(client);
}
 
void DoVoteMenu(any client)
{
	if (IsVoteInProgress())
	{
		CreateTimer(10.0, ReDoVote, client);
		return;
	}
 
 	decl String:nick[64];
	GetClientName(client, nick, sizeof(nick));
	
	Menu menu = new Menu(Handle_VoteMenu);
	new count = 0;
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (HLDJ[i] == 2)count++;
	}
	if (count > 1)
	{
		menu.SetTitle("Mute HLDJ Spammers?");
	} else {
		menu.SetTitle("Mute %s?", nick);
	}
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  