/*
top10hlxce-announce.sp

Plays a announcement when a top10 ranked player of hlstats ce comes into your server and plays it to all.
    
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.03"
#define MAX_FILE_LEN 256
#pragma semicolon 1

new Handle:cvarSoundName;
new Handle:cvarGameName;
new Handle:cvarTextLoc;
new Handle:hDatabase = INVALID_HANDLE;
new String:soundFileName[MAX_FILE_LEN], String:gameType[30], String:strGame[10];
new text_loc;

public Plugin:myinfo =
{
	name = "Top 10 hlstats ce announcer",
	author = "Snelvuur",
	description = "Plays sound when a player top 10 ranked player of hlstats ce connects.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()	{
	CheckGame();
	CreateConVar("sm_top10_hlstatsce_version", PLUGIN_VERSION, "Top10_Hlstatsce_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarSoundName = CreateConVar("sm_top10_sound", "lethalzone/top10player.mp3", "The sound to play when a top10 hlstats player joins the game");
	cvarGameName = CreateConVar("sm_top10_game", "tf2all", "The shortname found after the game settings for particular servers on admin page");
	cvarTextLoc = CreateConVar("sm_top10_text", "2", "Location on where to show the message. 1 = Center, 2 = Hint text, 3 = Regular text. Leave empty for center");
	HookConVarChange(cvarGameName, OnSettingChanged);
	HookConVarChange(cvarTextLoc, OnSettingChanged);
	GetCvars();
	ConnectToDatabase();
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])	{
	GetCvars();
}

GetCvars()	{
	GetConVarString(cvarGameName, gameType, sizeof(gameType));
	text_loc = GetConVarInt(cvarTextLoc);
}

public OnMapStart() {	
	GetConVarString(cvarSoundName, soundFileName, MAX_FILE_LEN);
	if (strlen(soundFileName) > 1) { 
		Precache();
	}
}

Precache() {
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(soundFileName, true);
	Format(buffer, MAX_FILE_LEN, "sound/%s", soundFileName);
	AddFileToDownloadsTable(buffer);
}

ConnectToDatabase()	{
    SQL_TConnect(GotDatabase, "top10");
}


public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)    {
		LogError("Database failure: %s", error);
		return;
    }
	hDatabase = hndl;
	PrintToServer("[top10_hlstatsce] Database connected for %s", PLUGIN_VERSION);
}

CheckTop10(userid, const String:auth[])	{
	decl String:query[500];
	Format(query, sizeof(query), "SELECT COUNT(*) AS rank FROM hlstats_Players WHERE hlstats_Players.game = '%s' AND hideranking = 0 AND skill > (SELECT skill from hlstats_Players JOIN hlstats_PlayerUniqueIds ON hlstats_Players.playerId = hlstats_PlayerUniqueIds.playerId WHERE uniqueID = MID('%s', 9) AND hlstats_PlayerUniqueIds.game = '%s') -1", gameType, auth, gameType);
	SQL_TQuery(hDatabase, T_CheckTop10, query, userid);
}	

CheckGame()	{
	GetGameFolderName(strGame, sizeof(strGame));
	if(StrEqual(strGame, "tf"))	{ PrintToServer("[top10_hlstatsce] Found TF2 game, plugin v%s loaded..", PLUGIN_VERSION); }
	else if(StrEqual(strGame, "cstrike"))	{ PrintToServer("[top10_hlstatsce] Found Counter Strike game, plugin v%s loaded..", PLUGIN_VERSION); }
	else if(StrEqual(strGame, "left4dead"))	{ PrintToServer("[top10_hlstatsce] Found Left 4 dead. Sounds dont work, only center text, plugin v%s loaded..", PLUGIN_VERSION); }
	else if(StrEqual(strGame, "l4d2"))	{ PrintToServer("[top10_hlstatsce] Found Left 4 dead 2. Sounds dont work, only center text, plugin v%s loaded..", PLUGIN_VERSION); }
	else {
	SetFailState("[top10_hlstatsce] hlstatsce top 10 is only known to work with Counterstrike/TF2/L4D(2) for now, plugin disabled.");
	}
}

public OnClientPostAdminCheck(client)	{
	decl String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));
	CheckTop10(client,steamid);
}

public T_CheckTop10(Handle:owner, Handle:hndl, const String:error[], any:client)	{
 	if (!IsClientConnected(client))    {
        return;
    }
	if (hndl == INVALID_HANDLE)	{
		LogError("Query failed! %s", error);
	}
	else if (SQL_FetchRow(hndl))	{
		new ranknr = SQL_FetchInt(hndl, 0);
		if (ranknr < 11 && ranknr > 0)
		{
			decl String:name[32];
			GetClientName(client, name, 32);
			switch(text_loc) {
				case 1:
				{	PrintCenterTextAll("Top 10 player  %s connected, currently rank %i",name,ranknr); }
				case 2:
				{	PrintHintTextToAll("Top 10 player  %s connected, currently rank %i",name,ranknr); }
				case 3:
				{	PrintToChatAll("Top 10 player  %s connected, currently rank %i",name,ranknr); }
				default:
				{	PrintCenterTextAll("Top 10 player  %s connected, currently rank %i",name,ranknr); }
			}
			
			if (strlen(soundFileName) > 1) { 
				if (!StrEqual(strGame, "left4dead") || !StrEqual(strGame, "l4d2"))
					EmitSoundToAll(soundFileName);
			}
			LogMessage("Top 10 player %s joined the game",name); // Turned on for debug sometimes..
		}
	}
}