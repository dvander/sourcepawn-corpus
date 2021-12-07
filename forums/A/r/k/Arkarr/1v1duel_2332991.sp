#include <morecolors>
#include <sourcemod>
#include <sdktools>
#include <chat-processor>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.1"

#define PLUGIN_TAG 		"{purple}[1v1 Duel]{default}"

#define MENU_OPTION_YES 0
#define MENU_OPTION_NO	1

#define ARENA_SETLEVEL  0
#define ARENA_SETPOS1   1
#define ARENA_SETPOS2	2
#define ARENA_SETNAME   3
#define ARENA_DONE   	4

int arenaCreationState[MAXPLAYERS+1];

bool pluginEnabled;
bool hookChat[MAXPLAYERS+1];
bool processing[MAXPLAYERS+1];
bool isInDuel[MAXPLAYERS+1];

int ennemy[MAXPLAYERS+1];
int killCount[MAXPLAYERS+1];

Handle ARRAY_Arena;
Handle TRIE_TempArena[MAXPLAYERS+1];
Handle CVAR_NumberOfFrag;

public Plugin myinfo = 
{
	name = "[ANY] 1v1 Duel Maker",
	author = PLUGIN_AUTHOR,
	description = "A simple plugin to help player to fight in 1v1 arena.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_createarena", CMD_CreateArena, ADMFLAG_CONFIG, "Configure a arena");
	RegAdminCmd("sm_viewarena", CMD_ViewArena, ADMFLAG_CONFIG, "View all set arrena on a map");
	
	RegConsoleCmd("sm_duel", CMD_CreateDuel, "Display the menu to pickup a player to duel.");
	RegConsoleCmd("sm_1v1", CMD_CreateDuel, "Display the menu to pickup a player to duel.");
	
	CVAR_NumberOfFrag = CreateConVar("sm_1v1duel_number_of_frag", "3", "How much frag to do to win a duel ?", _, true, 1.0);
	
	HookEvent("player_death", Event_PlayerDeath);

	ARRAY_Arena = CreateArray(); 
}

public void OnMapStart()
{
	char mapName[45];
	GetCurrentMap(mapName, sizeof(mapName));
	pluginEnabled = LoadConfiguration(mapName);
}

public void OnPluginEnd()
{
	SaveConfiguration();	
}

public void OnMapEnd()
{
	SaveConfiguration();	
}

public OnClientConnected(client)
{
	hookChat[client] = false;	
	arenaCreationState[client] = 0;
	isInDuel[client] = false;
	ennemy[client] = -1;
	killCount[client] = 0;
}

public Action CMD_CreateArena(client, args)
{
	hookChat[client] = true;
	arenaCreationState[client] = ARENA_SETLEVEL;
	
	TRIE_TempArena[client] = CreateTrie();
	
	ProcessArenaCreation(client);
}

public Action CMD_ViewArena(client, args)
{
	for(int i = 0; i < GetArraySize(ARRAY_Arena); i++)
	{
		char ArenaName[45];	    
		Handle trie = GetArrayCell(ARRAY_Arena, i);
		GetTrieString(trie, "ArenaName", ArenaName, sizeof(ArenaName));
		PrintToChat(client, "%i - %s", (i+1), ArenaName);
	}
	
	return Plugin_Handled;
}

public Action CMD_CreateDuel(client, args)
{
	if(!pluginEnabled)
		return;
		
	CPrintToChat(client, "%s Please, select a opponent...", PLUGIN_TAG);
	DisplayPlayerSelectionMenu(client);
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if(!hookChat[author] || processing[author])
		return Plugin_Continue;
		
	processing[author] = true;
	
	char strPosition[250];
	
	if(arenaCreationState[author] == ARENA_SETPOS1 || arenaCreationState[author] == ARENA_SETPOS2)
	{
		float position[3];
		char tmp[50];
		GetEntPropVector(author, Prop_Send, "m_vecOrigin", position);
		for(int i = 0; i < 3; i++)
		{
			Format(tmp, sizeof(tmp), "%f|", position[i]);
			StrCat(strPosition, sizeof(strPosition), tmp);
		}
	}
	
	switch(arenaCreationState[author])
	{
		case ARENA_SETLEVEL:
		{
			char bit[1][12];
			ExplodeString(message, " ", bit, sizeof bit, sizeof bit[]);
			SetTrieString(TRIE_TempArena[author], "ArenaLevel", bit[0]);
		}
		case ARENA_SETPOS1:
		{
			SetTrieString(TRIE_TempArena[author], "ArenaPos1", strPosition);
		}
		case ARENA_SETPOS2:
		{
			SetTrieString(TRIE_TempArena[author], "ArenaPos2", strPosition);
		}
		case ARENA_SETNAME:
		{
			SetTrieString(TRIE_TempArena[author], "ArenaName", message);
		}
	}
	
	arenaCreationState[author]++;
	CreateTimer(0.3, TMR_ProcessNextStep, author);
	
	return Plugin_Handled;
}

//Timers

public Action TMR_ProcessNextStep(Handle tmr, any client)
{
	processing[client] = false;
	ProcessArenaCreation(client);
}

//Events

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!isInDuel[attacker])
		return;
	
	if(victim == ennemy[attacker])
		killCount[attacker]++;
		
	if(killCount[attacker] >= GetConVarInt(CVAR_NumberOfFrag))
		EndDuel(attacker, victim);
		
	CPrintToChatAll("%s %N made another kill on %N (%i vs %i)!", PLUGIN_TAG, attacker, victim, killCount[attacker], killCount[victim]);
}


//Menu Handler

public MenuHandle_PlayerSelection(Handle menu, MenuAction action, int client, int itemIndex)
{
	if(action == MenuAction_Select)
	{	
		char description[15]
		if(GetMenuItem(menu, itemIndex, description, sizeof(description)))
		{
			ReplaceString(description, sizeof(description), "PLAYER", "");
			DisplayYesNoMenu(client, StringToInt(description));
		}
		else
		{
			CPrintToChat(client, "%s Hahahah, not enough brave ?", PLUGIN_TAG);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandle_YesNo(Handle menu, MenuAction action, int client, int itemIndex)
{
	if(action == MenuAction_Select)
	{	
		char enemy[15];
		GetMenuItem(menu, itemIndex, enemy, sizeof(enemy));
		if(itemIndex == MENU_OPTION_YES)
		{
			CPrintToChatAll("%s %N said {fullred}YES{default} to the duel request of %N ! Let the duel begin !", PLUGIN_TAG, client, StringToInt(enemy));
			StartDuel(client, StringToInt(enemy));
		}
		else
		{
			CPrintToChatAll("%s %N said {fullred}NO{default} to the duel request of %N ! What a coward !", PLUGIN_TAG, client, StringToInt(enemy));
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// functions

public void ProcessArenaCreation(client)
{
	switch(arenaCreationState[client])
	{
		case ARENA_SETLEVEL:
			CPrintToChat(client, "%s Please, enter the stage of the arena in the chat :", PLUGIN_TAG);
		case ARENA_SETPOS1:
			CPrintToChat(client, "%s Please, enter 'pos1' in the chat to save the position of {fullred}player 1{default} :", PLUGIN_TAG);
		case ARENA_SETPOS2:
			CPrintToChat(client, "%s Please, enter 'pos2' in the chat to save the position of {fullred}player 2{default} :", PLUGIN_TAG);
		case ARENA_SETNAME:
			CPrintToChat(client, "%s Please, enter the name of the arena in the chat :", PLUGIN_TAG);
		case ARENA_DONE:
			SaveAndReloadConfig(client);
	}
}

public void SaveAndReloadConfig(int client)
{
	SetTrieString(TRIE_TempArena[client], "ArenaBusy", "0");
	PushArrayCell(ARRAY_Arena, TRIE_TempArena[client]);
	hookChat[client] = false;
	
	CPrintToChat(client, "%s Arena sucessfully created !", PLUGIN_TAG);
	SaveConfiguration();
	OnMapStart();
}

public void DisplayPlayerSelectionMenu(client)
{
	Handle menu = CreateMenu(MenuHandle_PlayerSelection);
	SetMenuTitle(menu, "Select a player to fight :");
	for (new i = MaxClients; i > 0; --i)
	{
		if (IsValidClient(i))// && i != client)
		{
			char description[15], text[25];
			Format(description, sizeof(description), "PLAYER%i", i);
			Format(text, sizeof(text), "%N", i);
			AddMenuItem(menu, description, text);
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public void DisplayYesNoMenu(int client, int enemy)
{
	char clientIndex[4];
	IntToString(enemy, clientIndex, sizeof(clientIndex));
	Handle menu = CreateMenu(MenuHandle_YesNo);
	SetMenuTitle(menu, "%N want to fight you in a 1v1 duel !", enemy);
	AddMenuItem(menu, clientIndex, "Yes - I'm a true Warrior");
	AddMenuItem(menu, clientIndex, "No - I'm a coward");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


//Stocks

stock void StartDuel(player1, player2)
{
	Handle tmpArray = ARRAY_Arena;
	char ArenaBusy[45], ArenaPos1[100], ArenaPos2[100];
	int arena = 0;
	while(GetArraySize(tmpArray) != 0)
	{
		for(int i = 0; i < GetArraySize(tmpArray); i++)
		{
			Handle trie = GetArrayCell(tmpArray, i);
			GetTrieString(trie, "ArenaBusy", ArenaBusy, sizeof(ArenaBusy));
			if(StringToInt(ArenaBusy) == 0)
			{
				char c_pos1[3][20];
				char c_pos2[3][20];

				GetTrieString(trie, "ArenaPos1", ArenaPos1, sizeof(ArenaPos1));
				GetTrieString(trie, "ArenaPos2", ArenaPos2, sizeof(ArenaPos2));
				ExplodeString(ArenaPos1, "|", c_pos1, sizeof c_pos1, sizeof c_pos1[]);
				ExplodeString(ArenaPos2, "|", c_pos2, sizeof c_pos2, sizeof c_pos2[]);
				
				float pos1[3];
				pos1[0] = StringToFloat(c_pos1[0]);
				pos1[1] = StringToFloat(c_pos1[1]);
				pos1[2] = StringToFloat(c_pos1[2]);
				
				float pos2[3];
				pos2[0] = StringToFloat(c_pos1[0]);
				pos2[1] = StringToFloat(c_pos1[1]);
				pos2[2] = StringToFloat(c_pos1[2]);
				
				TeleportEntity(player1, pos1, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(player2, pos2, NULL_VECTOR, NULL_VECTOR);
				
				isInDuel[player1] = true;
				isInDuel[player2] = true;
				
				ennemy[player1] = player2;
				ennemy[player2] = player1;
				
				killCount[player1] = 0;
				killCount[player2] = 0;
				
				SetTrieString(GetArrayCell(ARRAY_Arena, arena), "ArenaBusy", "1");
			}
		}
		RemoveFromArray(tmpArray, GetArraySize(tmpArray)-1);
		arena++;
	}
}

stock void EndDuel(int winner, int looser)
{
	CPrintToChatAll("%s %N won against %N !", PLUGIN_TAG, winner, looser);
	CPrintToChatAll("%s Scores : %i vs %i kills !", PLUGIN_TAG, killCount[winner], killCount[looser]);
	
	isInDuel[winner] = false;
	isInDuel[looser] = false;
	
	if(IsPlayerAlive(winner))
		SlapPlayer(winner, 99999, false);
		
	if(IsPlayerAlive(looser))
		SlapPlayer(looser, 99999, false);
}

stock bool LoadConfiguration(const char[] mapName)
{
		
	char path[75];
	BuildPath(Path_SM, path, sizeof(path), "configs/1v1duel/%s.cfg", mapName);
	
	if(!DirExists("addons/sourcemod/configs/1v1duel"))
		 CreateDirectory("/addons/sourcemod/configs/1v1duel", 777);
		 
	if(!FileExists(path))
		OpenFile(path,"w");
	
	Handle kv = CreateKeyValues("1v1Duel_Configuration");	
	FileToKeyValues(kv, path);
	
	if (!KvGotoFirstSubKey(kv)) {
		PrintToServer("[1v1 Duel] NO CONFIGURATION FOUND !");
		PrintToServer("[1v1 Duel] Create your arean using the command sm_createarena !");
		return false;
	}
	
	ClearArray(ARRAY_Arena);
	
	char ArenaName[255];
	char ArenaLevel[255];
	char ArenaPos1[255];
	char ArenaPos2[255];
	
	do {
	    KvGetSectionName(kv, ArenaName, sizeof(ArenaName));
	    KvGetString(kv, "ArenaLevel", ArenaLevel, sizeof(ArenaLevel));
	    KvGetString(kv, "ArenaPos1", ArenaPos1, sizeof(ArenaPos1));
	    KvGetString(kv, "ArenaPos2", ArenaPos2, sizeof(ArenaPos2));
	    
	    Handle trie = CreateTrie();
	    SetTrieString(trie, "ArenaName", ArenaName);
	    SetTrieString(trie, "ArenaLevel", ArenaLevel);
	    SetTrieString(trie, "ArenaPos1", ArenaPos1); 
	    SetTrieString(trie, "ArenaPos2", ArenaPos2);
	    SetTrieString(trie, "ArenaBusy", "0");
	    
	    PushArrayCell(ARRAY_Arena, trie);
	    
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);  
	
	int nbrArena = GetArraySize(ARRAY_Arena)
	if(nbrArena < 1)
	{
		PrintToServer("[1v1 Duel] ZERO ARENA FOUND !");
		return false;
	}
	
	PrintToServer("[1v1 Duel] LOADED %i ARENA !", nbrArena);
	return true;
}

stock bool SaveConfiguration()
{
	char path[75], mapName[45];
	GetCurrentMap(mapName, sizeof(mapName));	
	
	BuildPath(Path_SM, path, sizeof(path), "configs/1v1duel/%s.cfg", mapName);
	
	Handle fileHandle = OpenFile(path,"w");
	WriteFileLine(fileHandle,"\"1v1Duel_Configuration\"");
	WriteFileLine(fileHandle,"{");
	
	PrintToServer("nbr arena : %i", GetArraySize(ARRAY_Arena));
	
	for(int i = 0; i < GetArraySize(ARRAY_Arena); i++)
	{
		char ArenaName[45], ArenaLevel[45], ArenaPos1[45], ArenaPos2[45];	    
		Handle trie = GetArrayCell(ARRAY_Arena, i);
		GetTrieString(trie, "ArenaName", ArenaName, sizeof(ArenaName));
		GetTrieString(trie, "ArenaLevel", ArenaLevel, sizeof(ArenaLevel));
		GetTrieString(trie, "ArenaPos1", ArenaPos1, sizeof(ArenaPos1));
		GetTrieString(trie, "ArenaPos2", ArenaPos2, sizeof(ArenaPos2));
		
		WriteFileLine(fileHandle,"\t\"%s\"", ArenaName);
		WriteFileLine(fileHandle,"\t{");
		WriteFileLine(fileHandle,"\t\t\"%s\"\t\"%s\"", "ArenaLevel", ArenaLevel);
		WriteFileLine(fileHandle,"\t\t\"%s\"\t\"%s\"", "ArenaPos1", ArenaPos1);
		WriteFileLine(fileHandle,"\t\t\"%s\"\t\"%s\"", "ArenaPos2", ArenaPos2);
		WriteFileLine(fileHandle,"\t}");
	}
	
	WriteFileLine(fileHandle,"}");
	CloseHandle(fileHandle);
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}
