#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"

#define DEBUG

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_HUMAN(%1)		(IS_VALID_CLIENT(%1) && IsClientConnected(%1) && !IsFakeClient(%1))
#define IS_SPECTATOR(%1)        (GetClientTeam(%1) == TEAM_SPECTATOR)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == TEAM_SURVIVOR)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == TEAM_INFECTED)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_SPECTATOR(%1)  (IS_VALID_INGAME(%1) && IS_SPECTATOR(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))
#define IS_HUMAN_SURVIVOR(%1)   (IS_VALID_HUMAN(%1) && IS_SURVIVOR(%1))
#define IS_HUMAN_INFECTED(%1)   (IS_VALID_HUMAN(%1) && IS_INFECTED(%1))

#define CONFIG_FILENAME "l4d2_vote_blame"
#define CONFIG_FILE "l4d2_vote_blame.cfg"
#define PREFIX 		"\x04[Vote Blame]\x03"

#define L4D2_TEAM_ALL -1

public Plugin myinfo = 
{
	name = "Vote Blame", 
	author = "kahdeg", 
	description = "Vote to 'blame' someone, which if passed will made that someone got boomerbile status.", 
	version = PLUGIN_VERSION, 
	url = ""
};

ConVar g_bCvarAllow,g_bCvarPrintChat,g_iCvarVoteTime,g_iCvarVoteCooldown;

char g_ConfigPath[PLATFORM_MAX_PATH];

int g_iYesVotes;
int g_iNoVotes;
int g_iPlayersCount;
bool VoteInProgress;
bool CanPlayerVote[MAXPLAYERS + 1];
int g_iBlamingPlayer;
int g_iLastVoteTimeStamp;

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native void L4D_CTerrorPlayer_OnVomitedUpon(int client, int attacker);
#endif

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    //g_bL4D2 = (engine == Engine_Left4Dead2);

    #if !defined _l4dh_included
    MarkNativeAsOptional("L4D_CTerrorPlayer_OnVomitedUpon");
    #endif

    return APLRes_Success;
}
public void OnAllPluginsLoaded()
{
    //g_bLeft4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D_CTerrorPlayer_OnVomitedUpon") == FeatureStatus_Available);
}

public void OnPluginStart()
{
	//Make sure we are on left 4 dead 2!
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("This plugin only supports left 4 dead 2!");
		return;
	}
	
	BuildPath(Path_SM, g_ConfigPath, sizeof(g_ConfigPath), "configs/%s", CONFIG_FILE);
	
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("sm_voteblame_version", PLUGIN_VERSION, "Plugin Version.", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_bCvarAllow = CreateConVar("vote_blame_on", "1", "Enable plugin. 1=Plugin On. 0=Plugin Off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarPrintChat = CreateConVar("vote_blame_print_on", "0", "Enable plugin to print to chat. 1=Enable. 0=Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_iCvarVoteTime = CreateConVar("vote_blame_time", "10", "Vote time limit. (5-60)", FCVAR_NOTIFY, true, 5.0, true, 60.0);
	g_iCvarVoteCooldown = CreateConVar("vote_blame_cooldown", "10", "Vote cooldown. (5-600)", FCVAR_NOTIFY, true, 5.0, true, 600.0);
	g_iLastVoteTimeStamp = 0;
	
	AutoExecConfig(true, CONFIG_FILENAME);

	// Listen for when the callvote command is used
	RegConsoleCmd("Vote", vote);
	RegConsoleCmd("voteblame", voteblame);
}

/**
* Callback for Vote command.
*/
Action voteblame(int client, int args){
	if (IsPluginDisabled()){
		return Plugin_Handled;
	}
	
	if(VoteInProgress){
		PrintToChat(client,"A vote is already in progress!");
		return Plugin_Handled;
	}
	
	if (GetTime() - g_iLastVoteTimeStamp < g_iCvarVoteCooldown.IntValue){
		PrintToChat(client,"You must wait %i seconds before blaming someone",g_iCvarVoteCooldown.IntValue - (GetTime() - g_iLastVoteTimeStamp));
		return Plugin_Handled;
	}
	
	VoteMenu_Select(client);
	return Plugin_Handled;
}

void VoteMenu_Select(int client)
{
	Menu menu = new Menu(VoteMenuHandler_Select);
	menu.SetTitle("%s", "Blame who?", client);

	// Build menu
	int i = 1;
	char name[MAX_NAME_LENGTH];
	char userId[10];
	for( i = 1; i <= MaxClients; i++ )
	{
		if (IS_VALID_HUMAN(i)){
			strcopy(name, sizeof(name), "");
			strcopy(userId, sizeof(userId), "");  
			GetClientName(i, name, sizeof(name));
			int uid = GetClientUserId(i);
			Format(userId, sizeof(userId), "%i", uid);
			menu.AddItem(userId, name);
		}
	}

	// Display menu
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int VoteMenuHandler_Select(Menu menu, MenuAction action, int client, int param2)
{
	switch( action )
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char userId[10];
			menu.GetItem(param2, userId, sizeof(userId));
			
			DebugPrint("%s", userId);
			Callvote_Handler(StringToInt(userId));
		}
	}

	return 0;
}

void Callvote_Handler(int userId)
{
	int clientIndex = GetClientOfUserId(userId);
	char name[MAX_NAME_LENGTH];
	GetClientName(clientIndex, name, sizeof(name));
	char votemsg[60];
	Format(votemsg, sizeof(votemsg), "Blame '%s'?",name);
	g_iBlamingPlayer = userId;
	
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteStart", USERMSG_RELIABLE));
	bf.WriteByte(L4D2_TEAM_ALL);
	bf.WriteByte(0);
	bf.WriteString("#L4D_TargetID_Player");
	bf.WriteString(votemsg);
	bf.WriteString("Server");
	EndMessage();
 
	g_iYesVotes = 0;
	g_iNoVotes = 0;
	g_iPlayersCount = 0;
	VoteInProgress = true;
 
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IS_VALID_HUMAN(i))
		{
			CanPlayerVote[i] = true;
			g_iPlayersCount ++;
		}
	}
 
	UpdateVotes();
	CreateTimer(g_iCvarVoteTime.FloatValue, Timer_VoteCheck, TIMER_FLAG_NO_MAPCHANGE);
}
Action Timer_VoteCheck(Handle timer)
{
	if(VoteInProgress)
	{
		VoteInProgress = false;
		UpdateVotes();
	}
	return Plugin_Continue;
}

Action vote(int client, int args)
{
	if(VoteInProgress && CanPlayerVote[client] == true)
	{
		char arg[8];
		GetCmdArg(1, arg, sizeof arg);
 
		PrintToServer("Got vote %s from %i", arg, client);
 
		if (strcmp(arg, "Yes", true) == 0)
		{
			g_iYesVotes++;
		}
		else if (strcmp(arg, "No", true) == 0)
		{
			g_iNoVotes++;
		}
 
		UpdateVotes();
	}
 
	return Plugin_Continue;
}

void UpdateVotes()
{
	Event event = CreateEvent("vote_changed");
	event.SetInt("yesVotes", g_iYesVotes);
	event.SetInt("noVotes", g_iNoVotes);
	event.SetInt("potentialVotes", g_iPlayersCount);
	event.Fire();
 
	if ((g_iYesVotes + g_iNoVotes == g_iPlayersCount) || !VoteInProgress)
	{
		PrintToServer("voting complete!");
 
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IS_VALID_HUMAN(i))
			{
				CanPlayerVote[i] = false;
			}
		}
 
		VoteInProgress = false;
		
		//g_iYesVotes = g_iNoVotes + 1;
		if (g_iYesVotes == g_iNoVotes){
			if((GetURandomInt() % 100) < 50){
				g_iYesVotes = g_iNoVotes + 1;
			}
		}
 
		if (g_iYesVotes > g_iNoVotes)
		{
			BfWrite bf = UserMessageToBfWrite(StartMessageAll("VotePass"));
			bf.WriteByte(L4D2_TEAM_ALL);
			bf.WriteString("#L4D_TargetID_Player");
			char name[MAX_NAME_LENGTH];
			int blamingClientId = GetClientOfUserId(g_iBlamingPlayer);
			GetClientName(blamingClientId, name, sizeof(name));
			char votemsg[60];
			Format(votemsg, sizeof(votemsg), "'%s' got blamed!",name);
			bf.WriteString(votemsg);
			EndMessage();
			
			PrintToChat(blamingClientId, "You got blamed!");
			
			L4D_CTerrorPlayer_OnVomitedUpon(blamingClientId, blamingClientId);
		}
		else
		{
			BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteFail"));
			bf.WriteByte(L4D2_TEAM_ALL);
			EndMessage();
		}
		
		g_iLastVoteTimeStamp = GetTime();
		g_iBlamingPlayer = 0;
	}
}

void DebugPrint(const char[] format, any...) {
	#if defined DEBUG
	if (!g_bCvarPrintChat.BoolValue) return;
	
	char buffer[254];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, "%s", buffer);
		}
	}
	#endif
}

stock bool IsPluginDisabled() {
	return !g_bCvarAllow.BoolValue;
}

stock bool IsClientAdmin(int client)
{
	// If the client has the ban flag, return true
	if (CheckCommandAccess(client, "admin_ban", ADMFLAG_BAN, false))
	{
		return true;
	}

	// If the client does not, return false
	else
	{
		return false;
	}
}