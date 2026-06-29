#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Vote The BunnyHop",
	author = "YellowSwag",
	description = "type !bhop to Vote Enable/Disable BunnyHop",
	version = SOURCEMOD_VERSION,
	url = "www.gamix.com"
};
 
ConVar g_Cvar_Needed;
ConVar g_Cvar_MinPlayers;
ConVar g_Cvar_InitialDelay;
ConVar g_Cvar_BHOPPostVoteAction;
bool g_CanBHOP = false; 
bool g_BHOPAllowed = false;
int g_Voters = 0;             
int g_Votes = 0;            
int g_VotesNeeded = 0; 
bool g_Voted[MAXPLAYERS+1] = {false, ...};
bool g_bhopEnabled = false;
 
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("rockthevote.phrases");
	g_Cvar_Needed = CreateConVar("sm_bhop_needed", "0.70", "how much % from players need to Enable/disable bhop(deafult 70%)", 0, true, 0.05, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_bhop_minplayers", "3", "Mimimum players to Enable the Plugin", 0, true, 0.0, true, float(MAXPLAYERS));
	g_Cvar_InitialDelay = CreateConVar("sm_bhop_initialdelay", "30.0", "", 0, true, 0.00);
	g_Cvar_BHOPPostVoteAction = CreateConVar("sm_bhop_postvoteaction", "0", "", _, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_bhop", Command_BHOP);
	AutoExecConfig(true, "bhop");
}
 
public void OnVoteEnd()
{
	g_CanBHOP = false;  
	g_BHOPAllowed = false;
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			OnClientConnected(i);
	}
}
 
public void OnConfigsExecuted()
{  
	g_CanBHOP = true;
	g_BHOPAllowed = false;
	g_bhopEnabled = false;
	CreateTimer(g_Cvar_InitialDelay.FloatValue, Timer_DelayBHOP, _, TIMER_FLAG_NO_MAPCHANGE);
	ServerCommand("mp_maxrounds 6000");
	ServerCommand("abner_bhop 0");
	ServerCommand("sv_enablebunnyhopping 0");
	ServerCommand("sv_autobunnyhopping 0");
}
 
public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;
	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}
 
public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
		g_Votes--;
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	if (!g_CanBHOP)
		return;
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded && g_BHOPAllowed )
	{
		if (g_Cvar_BHOPPostVoteAction.IntValue == 1)
			return;
			
		StartBHOP();
	}
}
 
public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!g_CanBHOP || !client)
		return;
	
	if(!g_bhopEnabled)
	{
		if (strcmp(sArgs, "bhop", false) == 0 || strcmp(sArgs, "autobunnyhop", false) == 0)
		{
			ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
			AttemptBHOP(client);
			SetCmdReplySource(old);
		}
	}
	else if (strcmp(sArgs, "bhop", false) == 0 || strcmp(sArgs, "dautobunnyhop", false) == 0)
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		AttemptBHOP(client);
		SetCmdReplySource(old);
	}
}

public Action Command_BHOP(int client, int args)
{
	if (!g_CanBHOP || !client)
	{
		return Plugin_Handled;
	}
	
	if (GetRealClientCount() <= 3)
	{
		PrintToChatAll(" \x04[YellowSwag]\x01 Need\x07 4 \x01players minimum to %s \x01The BunnyHop", g_bhopEnabled ? " \x07Disable" : " \x04Enable");
		return Plugin_Handled;
	}
	
	AttemptBHOP(client);
	return Plugin_Handled;
}

void AttemptBHOP(int client)
{
	if (!g_BHOPAllowed  || g_Cvar_BHOPPostVoteAction.IntValue == 1)
	{
		ReplyToCommand(client, "", " \x04[YellowSwag]\x01 Need\x07 4 \x01players minimum to %s \x01The BunnyHop", g_bhopEnabled? " \x07Disable" : " \x04Enable");
		return;
	}
	
	if (GetRealClientCount() < g_Cvar_MinPlayers.IntValue)
	{
		ReplyToCommand(client, "", " \x04[YellowSwag]\x01 Need\x07 4 \x01players minimum to %s \x01The BunnyHop", g_bhopEnabled? " \x07Disable" : " \x04Enable");
		return;
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "", " \x04[YellowSwag] %s \x01BunnyHop Already Voted", g_Votes, g_VotesNeeded, g_bhopEnabled? " \x07Diable" : " \x04Enable");
		return;
	}  
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	if(g_bhopEnabled)
		PrintToChatAll("", " \x04[YellowSwag] %s \x01BunnyHop Requested", name, g_Votes, g_VotesNeeded, g_bhopEnabled? " \x07Diable" : " \x04Enable");
	else
		PrintToChatAll("", " \x04[YellowSwag] %s \x01BunnyHop Requested", name, g_Votes, g_VotesNeeded, g_bhopEnabled? " \x07Diable" : " \x04Enable");

	if (g_Votes >= g_VotesNeeded)
		StartBHOP();
	else
		PrintToChatAll(" \x04[YellowSwag] \x07%d \x01Requireds, Need more \x07%d \x01to %s \x01BunnyHop.", g_Votes, g_VotesNeeded - g_Votes, g_bhopEnabled ? " \x07Disabling" : " \x04Activating");

}
 
public Action Timer_DelayBHOP(Handle timer)
{
	g_BHOPAllowed = true;
	g_CanBHOP = true;
	PrintToChatAll(" \x04[YellowSwag]\x01 you can write \x07!bhop\x01 now to %s \x01 the BunnyHop!", g_bhopEnabled? " \x07Disabling" : " \x04Activating");
}
 
void StartBHOP()
{
	PrintToChatAll(" \x04[YellowSwag] %s\x01 the Auto BunnyHop in\x07 5 \x01seconds", g_bhopEnabled? " \x07Disabling" : "Activating");
	CreateTimer(5.0, Timer_AbActivation, _, TIMER_FLAG_NO_MAPCHANGE);
	
	ResetBHOP();
	g_BHOPAllowed = false;
}
 
void ResetBHOP()
{
	g_Votes = 0;
	
	for (int i = 1; i <= MaxClients; i++)
		g_Voted[i] = false;
}
 
public Action Timer_AbActivation(Handle hTimer)
{
	OnVoteEnd();
	
	if(g_bhopEnabled)
		ServerCommand("abner_bhop 0");
	else
		ServerCommand("abner_bhop 1");

	
	g_bhopEnabled = !g_bhopEnabled;
	CreateTimer(60.0, Timer_DelayBHOP, _, TIMER_FLAG_NO_MAPCHANGE);
}

int GetRealClientCount()
{
	int client;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			client++;
	}
	return client;
}