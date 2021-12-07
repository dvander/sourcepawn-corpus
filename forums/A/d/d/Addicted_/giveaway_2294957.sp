#include <sourcemod>
#include <sdktools>
#include <emitsoundany>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

EngineVersion g_Game;

bool g_bCS = false;

char g_szChatTag[120];
char g_szWinnerSound[PLATFORM_MAX_PATH];

Handle g_hRemoveClutter = INVALID_HANDLE;
Handle g_hMin_players = INVALID_HANDLE;
Handle g_hClanTag = INVALID_HANDLE;
Handle g_hChatTag = INVALID_HANDLE;
Handle g_hDelayStart = INVALID_HANDLE;
Handle g_hDelayEnd = INVALID_HANDLE;
Handle g_hWinnerSound = INVALID_HANDLE;

public Plugin myinfo = { 
    name = "Giveaway", 
    author = "Addicted", 
    description = "Picks a random client to win a giveaway and displays a message with their name.", 
    version = "1.4",
    url = "addict.services" 
} 

public OnPluginStart() {

	g_Game = GetEngineVersion();
	if(g_Game == Engine_CSGO || g_Game == Engine_CSS)
		g_bCS = true;

	RegAdminCmd("sm_giveaway", CMD_Giveaway, ADMFLAG_ROOT);

	g_hRemoveClutter = CreateConVar("sm_giveaway_tidychat", "1", "Remove excess chat messages");
	g_hMin_players = CreateConVar("sm_giveaway_minplayers", "2", "Minimum amount of players to do a giveaway at");
	g_hClanTag = CreateConVar("sm_giveaway_clantag", "", "Only allow winners with this clan tag (Empty for disabled)");
	g_hChatTag = CreateConVar("sm_giveaway_chattag", "[SM]", "Tag to use in chat messages");
	g_hDelayStart = CreateConVar("sm_giveaway_delay_start", "1", "How long until the giveaway will start");
	g_hDelayEnd = CreateConVar("sm_giveaway_delay_end", "2", "How long until a winner should be announced after starting");
	g_hWinnerSound = CreateConVar("sm_giveaway_winner_sound", "ui/coin_pickup_01.wav", "Sound to play once a winner is selected (Default sound 'ui/coin_pickup_01.wav' is already included in csgo)");
	
	HookConVarChange(g_hChatTag, OnConvarChanged);
	HookConVarChange(g_hWinnerSound, OnConvarChanged);
	
	GetConVarString(g_hChatTag, g_szChatTag, sizeof(g_szChatTag));
	GetConVarString(g_hWinnerSound, g_szWinnerSound, sizeof(g_szWinnerSound));
	
	AutoExecConfig(true, "giveaways");

}

public OnConvarChanged(Handle cvar, const char[] oldVal, const char[] newVal) {

	if (cvar == g_hChatTag)
		GetConVarString(g_hChatTag, g_szChatTag, sizeof(g_szChatTag));
	else if (cvar == g_hWinnerSound)
		GetConVarString(g_hWinnerSound, g_szWinnerSound, sizeof(g_szWinnerSound));

}

public void OnMapStart() {

	if (FileExists(g_szWinnerSound))
		AddFileToDownloadsTable(g_szWinnerSound);
	
	PrecacheSound(g_szWinnerSound);

}

public Action CMD_Giveaway(int client, int args) { 

	if (!IsValidClient(client))
		return Plugin_Handled;

	if (args < 1) {

		PrintToChat(client, "%s Usage: sm_giveaway <giveaway item>", g_szChatTag)
		return Plugin_Handled;

	}
	
	if (GetTeamClientCount(1) + GetTeamClientCount(2) + GetTeamClientCount(3) < GetConVarInt(g_hMin_players))  { 

        PrintToChat(client, "%s There are not enough players for the giveaway. You need \x02%i\x01.", g_szChatTag, GetConVarInt(g_hMin_players)); 
        return Plugin_Handled;

    }
    
	char argString[32];
	GetCmdArgString(argString, sizeof(argString));

	Handle giveawayData;
	CreateDataTimer(GetConVarInt(g_hDelayStart) * 1.0, StartGiveaway, giveawayData);
	
	WritePackCell(giveawayData, GetClientUserId(client));
	WritePackString(giveawayData, argString);

	return Plugin_Handled; 
}

public Action StartGiveaway(Handle timer, Handle data) {

	char giveawayItem[32];

	ResetPack(data);
	int client = GetClientOfUserId(ReadPackCell(data));
	ReadPackString(data, giveawayItem, sizeof(giveawayItem));

	if (!IsValidClient(client))
		return Plugin_Stop;
	
	PrintToChatAll("%s Starting giveaway for item: \x02%s", g_szChatTag, giveawayItem)
	
	Handle giveawayData;
	CreateDataTimer(GetConVarInt(g_hDelayEnd) * 1.0, EndGiveaway, giveawayData);
	
	WritePackCell(giveawayData, GetClientUserId(client));
	WritePackString(giveawayData, giveawayItem);
	
	return Plugin_Handled;

}

public Action EndGiveaway(Handle timer, Handle data) {

	char giveawayItem[32];

	ResetPack(data);
	int client = GetClientOfUserId(ReadPackCell(data));
	ReadPackString(data, giveawayItem, sizeof(giveawayItem));

	if (!IsValidClient(client))
		return Plugin_Stop;

	int winner = GetRandomPlayer();
	
	if (!IsValidClient(winner)) {

		PrintToChatAll("%s Failed to find a winner", g_szChatTag);
		return Plugin_Stop;

	}

	if (!GetConVarBool(g_hRemoveClutter)) {

		PrintToChatAll("--");
		PrintToChatAll("--");
		PrintToChatAll("--");
		PrintToChatAll("--");
		PrintToChatAll("%s \x06Picking random client...\x01", g_szChatTag);
		PrintToChatAll("%s \x06Found random client...\x01", g_szChatTag);

	}
	
	EmitSoundToAll(g_szWinnerSound);

	PrintToChatAll("%s \x06Winner\x01 of \x02%s\x01 is \x02%N\x01!", g_szChatTag, giveawayItem, winner);

	return Plugin_Handled;

}

stock int GetRandomPlayer() {

	int clients[MAXPLAYERS+1];
	int clientCount;

	bool checkClan = false;

	char requiredClanTag[180], clantag[180];
	GetConVarString(g_hClanTag, requiredClanTag, sizeof(requiredClanTag));

	if (g_bCS && !StrEqual(requiredClanTag, ""))
		checkClan = true;
	else
		checkClan = false;

	for(int i; i < MaxClients; i++)
    {
		if (!IsValidClient(i))
    		continue;

		if (checkClan) {
		
			CS_GetClientClanTag(i, clantag, sizeof(clantag));
			if (!StrEqual(requiredClanTag, clantag))
				continue;

		}	

		clients[clientCount++] = i; 
    }

	return clients[GetRandomInt(0, clientCount - 1)]; 
}

stock bool IsValidClient(int client, bool noBots=true)
{
	if (client < 1 || client > MaxClients)
		return false;
		
	if (!IsClientInGame(client))
		return false;
		
	if (!IsClientConnected(client))
		return false;

	if (noBots)
		if (IsFakeClient(client))
			return false;

	if (IsClientSourceTV(client))
		return false;

	return true;
}