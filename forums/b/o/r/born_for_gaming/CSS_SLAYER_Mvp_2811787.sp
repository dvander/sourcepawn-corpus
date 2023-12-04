#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <morecolors>

#pragma semicolon 1

#define MAX_FILE_LEN 1024 // Maximum Lenght of file path
#define MAX_MVP_COUNT 1000 // Maximum Numbers of Mvps
#define MAX_MVP_PLAYLIST_COUNT 20 // Maximum Numbers of Mvps Playlist

// ConVars
ConVar sEnable;
ConVar sVolume;
ConVar sMessage;
ConVar sPreview;
ConVar sPreviewTime;
ConVar sBotMvp;
ConVar sAllowBot;
ConVar sShowPremium;
ConVar sShowFound;
ConVar sAlreadyUsedMVPs;
ConVar sEnablePlayersMvp;
ConVar sEnablePlaylist;
ConVar sTotalPlaylist;

// Ints
int MVPCount,
	MVPPlaylistCount[MAXPLAYERS+1],
	MVPPlaylistMVPCount[MAXPLAYERS+1][MAX_MVP_PLAYLIST_COUNT+1],
	PlayedMVPFromPlaylistCount[MAXPLAYERS+1][MAX_MVP_PLAYLIST_COUNT+1],
	SelectedMvp[MAXPLAYERS+1],
	menu_selection[MAXPLAYERS+1][2],
	MenuSelect[MAXPLAYERS+1];
	
int kills[MAXPLAYERS+1];
int AlreadyUsed = 1;

// Bools
bool IsPremiumMVP[MAX_MVP_COUNT+1];
bool EnterPlaylistName[MAXPLAYERS + 1];
bool EnteredPlaylistName[MAXPLAYERS + 1];

// Chars
char ConfigfilePath[1024], 
	MVPName[MAX_MVP_COUNT + 1][200],
	MVPPlaylistName[MAXPLAYERS + 1][MAX_MVP_PLAYLIST_COUNT+1][100],
	MVPPlaylistMVPName[MAXPLAYERS + 1][MAX_MVP_PLAYLIST_COUNT+1][51][200],
	MVPFile[MAX_MVP_COUNT + 1][1024],
	MVPAlreadyUsed[101][200],
	MVPFlag[MAX_MVP_COUNT + 1][AdminFlags_TOTAL],
	MVPLink[MAX_MVP_COUNT + 1][200],
	NameMVP[MAXPLAYERS + 1][200],
	MVPPlaylist[MAXPLAYERS + 1][200],
	TempPlaylistName[MAXPLAYERS + 1][200];

// Arrays
ArrayList MVPSteamID[MAX_MVP_COUNT + 1];

// Floats
float VolMVP[MAXPLAYERS + 1];
float damage[MAXPLAYERS+1];
float mvp_defaultVol;

// Handles
Handle mvp_cookie, mvp_cookie2, mvp_cookie3;
Handle MvpPreviewTimer[MAXPLAYERS+1];

Database db;

public Plugin myinfo =
{
	name = "[CSS] Custom MVP Anthem",
	author = "SLAYER",
	version = "1.5",
	description = "Allow player to set Custom MVP Anthem",
	url = "https://forums.alliedmods.net/member.php?u=293943"
};

public void OnPluginStart()
{
	// Cookies
	mvp_cookie = RegClientCookie("mvp_name", "Player's MVP Anthem", CookieAccess_Private);
	mvp_cookie2 = RegClientCookie("mvp_vol", "Player MVP volume", CookieAccess_Private);
	mvp_cookie3 = RegClientCookie("mvp_playlist", "Player's' MVP Playlsit", CookieAccess_Private);
	
	// Convars
	sEnable = CreateConVar("mvp_enabled", "1", "Enable/Disable SLAYER MVP plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sVolume = CreateConVar("mvp_defaultvol", "1.0", "Default MVP anthem volume.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sMessage = CreateConVar("mvp_announce_type", "3", "Announcement of playing MVP Anthem in (1 = Chat, 2 = Hint, 3 = Both)", FCVAR_NOTIFY);
	sPreview = CreateConVar("mvp_preview", "1", "Allow player to Preview MVP? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sPreviewTime = CreateConVar("mvp_preview_time", "10.0", "MVP Anthem Preview Time in Seconds", FCVAR_NOTIFY, true, 1.0);
	sBotMvp = CreateConVar("mvp_bot", "1", "Play Random MVP Anthem if bot becomes MVP? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sAllowBot = CreateConVar("mvp_bot_allow", "1", "Allow Bots to use Premium MVPs? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sShowPremium = CreateConVar("mvp_show_premium", "1", "Show Premium MVPs (as Disabled) to which Client don't have Access? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sShowFound = CreateConVar("mvp_show_found", "1", "Show MVPs name in server console which are founded in given directory by using 'sm_mvp_load' cmd? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sAlreadyUsedMVPs =  CreateConVar("mvp_already_played", "5", "How many recent Random MVPs can't play which are already played? (0 = Play any Random Mvp)", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	sEnablePlayersMvp = CreateConVar("mvp_player_enable", "1", "Allow players to Choose other players MVP? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sEnablePlaylist = CreateConVar("mvp_playlist_enable", "1", "Allow players to Create MVP Playlist? (0 = No, 1 = Yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sTotalPlaylist =   CreateConVar("mvp_playlist_max", "5", "How many Playlist a Player Can Make?", FCVAR_NOTIFY, true, 1.0, true, 20.0);
	
	sEnable.AddChangeHook(OnConVarChanged);
	sVolume.AddChangeHook(OnConVarChanged);
	sEnablePlaylist.AddChangeHook(OnConVarChanged);
	sEnablePlayersMvp.AddChangeHook(OnConVarChanged);
	
	// Events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	
	// Cmds
	RegConsoleCmd("sm_mvp", Command_MVP, "Select Your MVP Anthem");
	RegConsoleCmd("sm_mvpvol", Command_MVPVol, "MVP Volume");
	RegAdminCmd("sm_mvp_refresh", CommandRefresh, ADMFLAG_RCON);
	RegAdminCmd("sm_mvp_load", CommandLoad, ADMFLAG_RCON);
	AddCommandListener(Command_PlaylistName, "say");  
	AddCommandListener(Command_PlaylistName, "say_team");  
	
	// Load Config File
	LoadConfig(false);
	
	// Database
	InitializeDB();
	
	// Translation
	LoadTranslations("SLAYER_Mvp.phrases");
	
	// Config
	AutoExecConfig(true, "SLAYER_Mvp");
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i) && !IsFakeClient(i))OnClientCookiesCached(i);
	}
}

public void OnConfigsExecuted()
{
	mvp_defaultVol = sVolume.FloatValue;
	LoadConfig(true);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == sVolume)	mvp_defaultVol = sVolume.FloatValue;
	if(convar == sEnable) 
	{
		if(convar.BoolValue){sEnable.BoolValue = true;CPrintToChatAll("%t {green}Plugin is now Enabled!", "Tag");}
		else{sEnable.BoolValue = false;CPrintToChatAll("%t {darkred}Plugin is now Disabled!", "Tag");}
	}
	if(convar == sEnablePlaylist)
	{
		if(convar.BoolValue)sEnablePlaylist.BoolValue = true;
		else sEnablePlaylist.BoolValue = false;
	}
	if(convar == sEnablePlayersMvp)
	{
		if(convar.BoolValue)sEnablePlayersMvp.BoolValue = true;
		else sEnablePlayersMvp.BoolValue = false;
	}
}
// ------------------------------------------------------------------------------------------------------
// Create Sqlite Database with 3 fields if not Exists
// ------------------------------------------------------------------------------------------------------
public void InitializeDB()
{
	char error[255];
	KeyValues kv = CreateKeyValues("");
	kv.SetString("driver", "sqlite");
	kv.SetString("database", "slayer_mvp");
	
	db = SQL_ConnectCustom(kv, error, sizeof(error), true);
	if(db == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	SQL_LockDatabase(db);
	SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS slayer_mvp (steam_id TEXT, playlist TEXT, mvps TEXT);");
	SQL_UnlockDatabase(db);
}

public void OnClientPostAdminCheck(int client)
{
	if (sEnable.BoolValue && IsValidClient(client) && !IsFakeClient(client))
	{
		OnClientCookiesCached(client);
		kills[client] = 0;
		damage[client] = 0.0;
	}
}
public void  OnClientCookiesCached(int client)
{
	if(!IsValidClient(client) && IsFakeClient(client))	return;
	LoadData(client, 0);
	// Adding a Delay so data can load fine, otherwise it will delete players premium mvps from there playlists
	CreateTimer(5.0, LoadDataTimer, GetClientSerial(client)); 
}
public Action LoadDataTimer(Handle timer, any clientSerial)
{
	int client = GetClientFromSerial(clientSerial);
	if(!IsValidClient(client))return Plugin_Stop; // Stop timer if player was disconnected
	LoadData(client, 4, true);
	return Plugin_Stop;
}
// ------------------------------------------------------------------------------------------------------
// Load Client's Cookies
// ------------------------------------------------------------------------------------------------------
stock bool LoadData(int client, int data=0, bool CheckData=false)
{
	char sbuffer[500];
	Format(sbuffer, sizeof(sbuffer), "%t", "Random MVP");
	char scookie[10000];
	if(data == 0 || data == 1) // Load Client Selected MVP Cookie
	{
		GetClientCookie(client, mvp_cookie, scookie, sizeof(scookie));
		if(!StrEqual(scookie, "")) // if cookie found
		{
			if(StrEqual(scookie, sbuffer))strcopy(NameMVP[client], sizeof(NameMVP[]), sbuffer);
			else
			{
				int id = FindMVPIDByName(scookie);
			
				if(id > 0)
		        {
		            SelectedMvp[client] = id;
		            strcopy(NameMVP[client], sizeof(NameMVP[]), scookie);
		        }
				else 
		        {
		            Format(NameMVP[client], sizeof(NameMVP[]), "");
		            SetClientCookie(client, mvp_cookie, "");
		        }
		    }
		}
		else if(StrEqual(scookie,"")) // if cookie not found then set random mvp
		{
			SelectedMvp[client] = -1;
			strcopy(NameMVP[client], sizeof(NameMVP[]), sbuffer);
		}
	}	
	
	if(data == 0 || data == 2)  // Load Client MVP Volume Cookie
	{
		GetClientCookie(client, mvp_cookie2, scookie, sizeof(scookie));
		if(!StrEqual(scookie, "")) // if cookie found
		{
			VolMVP[client] = StringToFloat(scookie);
		}
		else if(StrEqual(scookie,""))VolMVP[client] = mvp_defaultVol; // if cookie not found then set default volume
	}	
	if(data == 0 || data == 3 && sEnablePlaylist.BoolValue) // Load Client Selecte MVP playlist
	{
		GetClientCookie(client, mvp_cookie3, scookie, sizeof(scookie));
		if(!StrEqual(scookie, "")) // if cookie found
		{
	        strcopy(MVPPlaylist[client], sizeof(MVPPlaylist[]), scookie);
		}
		else if(StrEqual(scookie,"")) // if cookie not found then set no selected playlist
		{
			strcopy(MVPPlaylist[client], sizeof(MVPPlaylist[]), "");
		}
	}
	if(data == 0 || data == 4 && sEnablePlaylist.BoolValue) // Load client Data from Sqlite Database
	{
		char clientid[40];
		GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid));
		if(CheckData && LoadClientMVPPlaylistData(client, clientid)) // Check this only when client join server or plugin load/reload
		{
			for(int k = 0; k < MVPPlaylistCount[client]; k++) // Loop All Client's MVPs Playlist Found in Database 
			{
				for(int s = 0; s < MVPPlaylistMVPCount[client][k]; s++) // Loop All MVPs in Clinet's Specifc Playlist Found in Database 
				{
					bool IsFound = false;
					for(int i = 1; i <= MVPCount; i++) // Loop All MVPs Exists in CFG File
					{
						// Check, Is MVP Saved in Client Database Found in MVPs CFG File or not
						if(StrEqual(MVPPlaylistMVPName[client][k][s], MVPName[i], false))
						{
							if(CanUseMVP(client, i)) // Select Only those MVPs which client can use
							{
								IsFound = true; // if found then true the bool
								break; // And break the loop
							}
							else break;
						}					
					}
					if(!IsFound) // if MVP Saved in Client Database isn't Found in MVPs CFG file then it means Server Owner has Updated MVP CFG file
					{
						// So, Now we have to remove that MVP Sound from Client Database
						Format(sbuffer, sizeof(sbuffer), "UPDATE slayer_mvp SET mvps = REPLACE(mvps, '%s;', '') WHERE steam_id = '%s' AND playlist = '%s'", MVPPlaylistMVPName[client][k][s], clientid, MVPPlaylistName[client][k]);
						SQL_TQuery(db, Callback, sbuffer, GetClientSerial(client));
					}
				}
			}
			if(LoadClientMVPPlaylistData(client, clientid)) // After Updating Database We will reload Database to update variables
			{
				for(int k = 0; k < MVPPlaylistCount[client]; k++) // then we will Loop All Client's MVPs Playlist Found in Database 
				{
					// After that we check if any playlist has less then 2 mvps and that playlist is client currently selected playlist
					if(MVPPlaylistMVPCount[client][k] < 2 && StrEqual(MVPPlaylist[client], MVPPlaylistName[client][k]))
					{
						// Then we will remove that playlist as client selected playlist
						MVPPlaylist[client] = "";
						SetClientCookie(client, mvp_cookie3, "");
					}
				}
			}
		}
		else return LoadClientMVPPlaylistData(client, clientid);
	}
	return true;
}
// ------------------------------------------------------------------------------------------------------
// Load Player's all MVP Playlists and MVPs in Playlists from Database
// ------------------------------------------------------------------------------------------------------
stock bool LoadClientMVPPlaylistData(int client, const char[] steam_id)
{
	char query[255];
	Format(query, sizeof(query), "SELECT * FROM slayer_mvp WHERE steam_id = '%s'", steam_id);
	Handle hndl = SQL_Query(db, query);
	if(hndl == INVALID_HANDLE)
    {
    	char error[255];
    	SQL_GetError(db, error, sizeof(error));
        ThrowError("SQL error: %s", error);
        return false;
    }
	char playlistName[50], mvpData[10000];
	MVPPlaylistCount[client] = SQL_GetRowCount(hndl);
	if(MVPPlaylistCount[client] > 0) // if playlist available
	{
		for(int i = 0; i < MVPPlaylistCount[client]; i++)
		{
			if(SQL_FetchRow(hndl)) // Fetching Row
			{
				SQL_FetchString(hndl, 1, playlistName, sizeof(playlistName)); // Fetching the playlist name
				SQL_FetchString(hndl, 2, mvpData, sizeof(mvpData)); // Fetching mvps in that playlist
				strcopy(MVPPlaylistName[client][i], sizeof(MVPPlaylistName[][]), playlistName); // Store the playlist name in the MVPPlaylistName array
				// Now Store all MVPs Found in Playlist in a variable
				MVPPlaylistMVPCount[client][i] = ExplodeString(mvpData, ";", MVPPlaylistMVPName[client][i], sizeof(MVPPlaylistMVPName[][]), sizeof(MVPPlaylistMVPName[][][]));
				MVPPlaylistMVPCount[client][i]--; // 1 Minus because ExplodeString will find extra ';' at the end of the string
			}
		}
		return true;
	}
	else // If no playlist available
	{
		MVPPlaylist[client] = ""; // Set no mvp playlist selected
		SetClientCookie(client, mvp_cookie3, "");
		return true;
	}
}
// --------------------------------------------------------------------------------------------------------
// Find Specific Player's Playlist in Database. If MVP Playlist Found then return 'true' otherwise 'false'
// --------------------------------------------------------------------------------------------------------
stock bool FindMVPPlaylist(const char[] steam_id, const char[] playlist_name)
{
    char query[255];
    Format(query, sizeof(query), "SELECT * FROM slayer_mvp WHERE steam_id = '%s' AND playlist = '%s'", steam_id, playlist_name);
    Handle hndl = SQL_Query(db, query);
    if(hndl == INVALID_HANDLE)
    {
    	char error[255];
    	SQL_GetError(db, error, sizeof(error));
        ThrowError("SQL error: %s", error);
        return false;
    }
    if(SQL_GetRowCount(hndl) == 0) // if playlist with a specific name(given playlist name) isn't exists then return false
    {
        return false;
    }
    else return true; // if found then return true
}
// -----------------------------------------------------------------------------------------------------------------
// Find Specific MVP from Player's Specific Playlist in Database. If MVP Found then return 'true' otherwise 'false'
// -----------------------------------------------------------------------------------------------------------------
stock bool FindMVPInPlaylist(const char[] steam_id, const char[] playlist_name, const char[] mvp_name)
{
    char query[255];
    Format(query, sizeof(query), "SELECT * FROM slayer_mvp WHERE steam_id = '%s' AND playlist = '%s'", steam_id, playlist_name);
    Handle hndl = SQL_Query(db, query);
    if(hndl == INVALID_HANDLE)
    {
    	char error[255];
    	SQL_GetError(db, error, sizeof(error));
        ThrowError("SQL error: %s", error);
        return false;
    }
    if(SQL_GetRowCount(hndl) == 0) // if mvp playlist not found
    {
        return false;
    }
    char mvps[10000];
    if(SQL_FetchRow(hndl))SQL_FetchString(hndl, 2, mvps, sizeof(mvps)); // if found then fetch mvp field
    if(StrEqual(mvps, "", false)) // if mvp field empty then return false
    {
    	return false;
    }
    if(StrContains(mvps, mvp_name, false) != -1) // if mvp field isn't empty and given mvp name is found in mvp field then return true
    {
        return true;
    }
    return false;
}
public void Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(!StrEqual("", error))
	{
		PrintToServer("[SLAYER MVP] SQL Error: %s", error);
	}
}
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(sEnable.BoolValue)
	{
		for(new i = 1; i < MaxClients; i++)
		{
			kills[i] = 0;
			damage[i] = 0.0;
		}
	}
}
// ------------------------------------------------------------------------------------------------------
// Here we will Play MVP of the Player
// ------------------------------------------------------------------------------------------------------
public Action Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(sEnable.BoolValue)
	{
		int mostkills = 0;
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsValidClient(i) && kills[i] > 0) // Check which players kills more enemies and give more damage
			{
				if(kills[i] > kills[mostkills] || kills[i] == kills[mostkills] && damage[i] > damage[mostkills])
				{
					mostkills = i;
				}
			}
		}
		if(mostkills > 0 && IsValidClient(mostkills))
		{
			int mvp;
			if(StrEqual(MVPPlaylist[mostkills], "") || StrEqual(MVPPlaylist[mostkills], " ")) // If No Playlist Selected
			{
				char random_mvp[1024];
				Format(random_mvp, sizeof(random_mvp), "%t", "Random MVP");
				if(IsFakeClient(mostkills) && sBotMvp.BoolValue)strcopy(NameMVP[mostkills], sizeof(NameMVP[]), random_mvp); // Play random mvp anthem for if bot becomes MVP
				if(StrEqual(NameMVP[mostkills], random_mvp) || SelectedMvp[mostkills] == -1) // If Random MVP is selected
				{
					if(sAlreadyUsedMVPs.IntValue > 0 && sAlreadyUsedMVPs.IntValue >= MVPCount)
					{
						LogError("Error: 'mvp_already_played %d' Convar can't be equal/greater than your Total MVPs (%d). Please decrease the value of 'mvp_already_played' from config file.", sAlreadyUsedMVPs.IntValue, MVPCount);
						PrintToServer("[SLAYER-MVP] Error: 'mvp_already_played %d' Convar can't be equal/greater than your Total MVPs (%d). Please decrease the value of 'mvp_already_played' from config file.", sAlreadyUsedMVPs.IntValue, MVPCount);
						return;
					}
					do
					{
						do 
						{
							mvp = GetRandomInt(1,MVPCount); // Select a Random MVP
						} while(!CheckIsMvpAlreadyUsed(mvp)); // if mvp is already used then select another random mvp again
					} while(!CanUseMVP(mostkills, mvp)); // If client don't have access to that random MVP then Select another random mvp again
					
					if(sAlreadyUsedMVPs.IntValue > 0 && AlreadyUsed > sAlreadyUsedMVPs.IntValue)AlreadyUsed = 1; // Reset the Counter
					if(sAlreadyUsedMVPs.IntValue > 0)
					{
						MVPAlreadyUsed[AlreadyUsed] = MVPName[mvp]; // Save the name of the MVP in String Array
						AlreadyUsed++; // Increase the Counter
					}
				}
				else {mvp = SelectedMvp[mostkills];} // If Random MVP is not Selceted
				if(StrEqual(NameMVP[mostkills], "") || mvp == 0)return; // If MVP is not selected then return
			}
			else // If Playlist Selected
			{
				// Getting Client's Selected Playlist ID by giving Playlist Name
				int playlist_id = FindMVPPlaylistIDByName(mostkills, MVPPlaylist[mostkills]); 
				// Now we Get MVP ID by Giving Specific MVP Name from Player's Selected Playlist
				mvp = FindMVPIDByName(MVPPlaylistMVPName[mostkills][playlist_id][PlayedMVPFromPlaylistCount[mostkills][playlist_id]]); 
				// Increasing Counter by 1
				PlayedMVPFromPlaylistCount[mostkills][playlist_id]++; 
				// If 'PlayedMVPFromPlaylistCount' Counter becomes Equal to Total MVPs in Player's Selected Playlist 
				if(PlayedMVPFromPlaylistCount[mostkills][playlist_id] >= MVPPlaylistMVPCount[mostkills][playlist_id])
				{
					PlayedMVPFromPlaylistCount[mostkills][playlist_id] = 0; // then Reset Counter
				}
				if(mvp == 0)return; // If MVP is not Found then return
			}
			char sound[1024];
			Format(sound, sizeof(sound), "%s", MVPFile[mvp]);
			for(int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && !IsFakeClient(i)) // Play Sound to Every Vaild Player except BOT
				{
					// Announce MVP
					if(sMessage.IntValue == 2 || sMessage.IntValue == 3)PrintHintText(i, "%t", "MVP_Hint", mostkills, MVPName[mvp]);
					if(sMessage.IntValue == 1 || sMessage.IntValue == 3)CPrintToChat(i, "%t %t", "Tag","MVP_Chat", mostkills, MVPName[mvp]);
						
					// Mute game sound
					//ClientCommand(i, "playgamesound Music.StopAllMusic");
					//StopPlayingMVPs(i);
					
					// Play MVP Anthem
					EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, VolMVP[i]);
				}	
			}
		}
	}
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(sEnable.BoolValue)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if(attacker == 0)return;
		if(IsValidClient(attacker) && GetClientTeam(attacker) != GetClientTeam(victim))
		{
			float dmg = GetEventFloat(event, "dmg_health");
			damage[attacker] += dmg;
		}
	}		
}
public Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(sEnable.BoolValue)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if(attacker == 0)return;
		if(IsValidClient(attacker) && GetClientTeam(attacker) != GetClientTeam(victim))kills[attacker]++;
	}
}

int FindMVPIDByName(char [] name)
{
	int id = 0;
	
	for(int i = 1; i <= MVPCount; i++)
	{
		if(StrEqual(MVPName[i], name))	id = i;
	}
	
	return id;
}
stock int FindMVPPlaylistIDByName(int client, char [] name)
{
	int id = 0;
	
	for(int i = 0; i < MVPPlaylistCount[client]; i++)
	{
		if(StrEqual(MVPPlaylistName[client][i], name))	id = i;
	}
	
	return id;
}
public Action CommandRefresh(int client, int args)
{   
	LoadConfig();
	ReplyToCommand(client, "[SLAYER MVP] MVP Sounds and Settings are Refreshed!");
	return Plugin_Handled;
}
public Action CommandLoad(int client, int args)
{
	// If less than 2 arguments given then give error and return
	if(args < 1)
	{
		ReplyToCommand(client, "[SLAYER MVP] Usage: sm_mvp_load \"mvps_folder_path\" \"number_of_mvps\" \"mvp_name_prefix\" \"preimum_mvp_flag\"");
		return Plugin_Handled;
	}
	
	// Get and Save Client Given Arguments
	char FolderPath[PLATFORM_MAX_PATH];
	char MvpsToLoad[4];
	char MvpsPrefix[50];
	char MvpsFlag[50];
	GetCmdArg(1, FolderPath, sizeof(FolderPath));
	GetCmdArg(2, MvpsToLoad, sizeof(MvpsToLoad));
	GetCmdArg(3, MvpsPrefix, sizeof(MvpsPrefix));
	GetCmdArg(4, MvpsFlag, sizeof(MvpsFlag));
	
	// Checking if the given Path is Vaild or Not
	if (!DirExists(FolderPath))
	{
		// If path is INVALID then print error to client
		ReplyToCommand(client, "[SLAYER MVP] Given Path is INVAILD \"%s\"! Please Enter the VAILD Path", FolderPath);
		return Plugin_Handled;
	}
	AddSoundsInConfig(FolderPath, StringToInt(MvpsToLoad), MvpsPrefix, MvpsFlag);
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------------------------------
// Function which Load Sounds From Config File
// ------------------------------------------------------------------------------------------------------
void LoadConfig(bool print=true)
{
	// Config File Path
	BuildPath(Path_SM, ConfigfilePath, MAX_FILE_LEN, "configs/SLAYER_Mvp.cfg");
	// Check is Config File Exist or not
	if(!FileExists(ConfigfilePath))
		SetFailState("Can not find config file \"%s\"!", ConfigfilePath);
	
	char SoundFilePath[PLATFORM_MAX_PATH];
	
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(ConfigfilePath);
	
	MVPCount = 1;
	// Reseting Variables
	for(int i = 0; i < MAX_MVP_COUNT; i++)
	{
		IsPremiumMVP[i] = false;
		delete MVPSteamID[i];
		MVPSteamID[i] = new ArrayList(ByteCountToCells(1024));
	}
	// Reading Config File
	if(kv.GotoFirstSubKey())
	{
		do
		{
			// Getting and Saving the Information of MVP Sound 
			kv.GetSectionName(MVPName[MVPCount], sizeof(MVPName[]));
			kv.GetString("file", MVPFile[MVPCount], sizeof(MVPFile[]));
			kv.GetString("flag", MVPFlag[MVPCount], sizeof(MVPFlag[]), "");
			kv.GetString("link", MVPLink[MVPCount], sizeof(MVPLink[]), "");
			// If MVP sound have any admin flag then it will be a Premium MVP
			if(!StrEqual(MVPFlag[MVPCount], "") && !StrEqual(MVPFlag[MVPCount], " "))IsPremiumMVP[MVPCount] = true;
			// Checking that the given sound file path shouldn't be empty.
			if(StrEqual(MVPFile[MVPCount], "") && StrEqual(MVPFile[MVPCount], " "))
			{
				LogError("Error: Given File Path of the Sound '%s' is Empty!", MVPName[MVPCount]);
				PrintToServer("[SLAYER MVP] Error: Given File Path of the Sound '%s' is Empty!", MVPName[MVPCount]);
			}
			// Checking that is the Given Sound File Path is Vaild or not. If not vaild then give error otherwise continue
			Format(SoundFilePath, sizeof(SoundFilePath), "%s%s", "sound/", MVPFile[MVPCount]);
			if(!FileExists(SoundFilePath))
			{
				LogError("Failed to load %s from '%s'. Please Enter a Vaild Sound Path", MVPName[MVPCount], SoundFilePath);
				PrintToServer("[SLAYER MVP] Failed to load %s from '%s'. Please Enter a Vaild Sound Path", MVPName[MVPCount], SoundFilePath);
			}
			if(kv.JumpToKey("steamid"))
			{
				char steamid[32][32];
				int i = 0;
				do
				{
					FormatEx(steamid[0], sizeof(steamid[]), "%i", ++i);
					kv.GetString(steamid[0], steamid[1], sizeof(steamid[]), "");
					MVPSteamID[MVPCount].PushString(steamid[1]);
				} while(steamid[1][0]);
				MVPSteamID[MVPCount].Erase(MVPSteamID[MVPCount].Length-1); // Remove the last entry since it should be empty due to the check above.
				if(MVPSteamID[MVPCount].Length)IsPremiumMVP[MVPCount] = true;
				kv.GoBack(); // We need to go back since we used KeyValue.JumpToKey()
			}
			// The Precaches all the sounds and adds them to the downloads table so that clients can automatically download them
			char downloadFile[MAX_FILE_LEN];
			if(!StrEqual(MVPFile[MVPCount], ""))
			{
				PrecacheSound(MVPFile[MVPCount], true);
				Format(downloadFile, MAX_FILE_LEN, "sound/%s", MVPFile[MVPCount]);
				AddFileToDownloadsTable(downloadFile);
			}
			MVPCount++;
			
		}
		while (kv.GotoNextKey());
		kv.Rewind();
		delete kv;
	}
	if(sAlreadyUsedMVPs.IntValue > 0 && sAlreadyUsedMVPs.IntValue >= MVPCount)
	{
		LogError("Error: 'mvp_already_played %d' Convar can't be equal/greater than your Total MVPs (%d). Please decrease the value of 'mvp_already_played' from config file.", sAlreadyUsedMVPs.IntValue, MVPCount);
		PrintToServer("[SLAYER-MVP] Error: 'mvp_already_played %d' Convar can't be equal/greater than your Total MVPs (%d). Please decrease the value of 'mvp_already_played' from config file.", sAlreadyUsedMVPs.IntValue, MVPCount);
	}
	MVPCount--;
	if(print)PrintToServer("[SLAYER MVP] Total '%i' MVP Sounds are now loaded!", MVPCount);
}
void AddSoundsInConfig(char[] SoundFolderPath, int TotalSoundsToLoad=0, char[] SoundsNamePrefix="", char[] PremiumSoundsFlag="")
{
	int fileCounter = 1;
	char fileBuffer[512][PLATFORM_MAX_PATH];
	char fileExtension[10];
	
	// ------------------------------------------------------------------------------------------------------
	// Getting and Saving the names of the sound files in an array which are founded in the given directory
	// ------------------------------------------------------------------------------------------------------
	PrintToServer("------------------------------------------------------------");
	DirectoryListing dL = OpenDirectory(SoundFolderPath);
	while (dL.GetNext(fileBuffer[fileCounter], sizeof(fileBuffer))) 
	{
		// Geting File Extension
		GetFileExtension(fileBuffer[fileCounter], fileExtension, sizeof(fileExtension));
		// File should have vaild name
		if(StrEqual(fileBuffer[fileCounter], ".", true) == true || StrEqual(fileBuffer[fileCounter], "..", true) == true)continue;
		// Sound File should have 'mp3' or 'wav' extension otherwise will not be added
		if(!StrEqual(fileExtension, "mp3", false) && !StrEqual(fileExtension, "wav", false))continue;
		// Break the While loop if Sounds of a given amount are loaded
		if(TotalSoundsToLoad > 0 && fileCounter >= TotalSoundsToLoad){fileCounter++;break;}
		else fileCounter++;
	}
	fileCounter--;
	
	
	// ---------------------------------------------------
	// Now Adding Founded Sound Files in MVP Config File
	// ---------------------------------------------------
	
	// Creating the Path of the Config file
	BuildPath(Path_SM, ConfigfilePath, MAX_FILE_LEN, "configs/SLAYER_Mvp.cfg");
	// If Config file not exists then give error
	if(!FileExists(ConfigfilePath))
		SetFailState("Can not find config file \"%s\"!", ConfigfilePath);
	
	int AddedSounds = 1;
	int SoundCounter = 1;
	char SoundPath[PLATFORM_MAX_PATH];
	char SoundName[PLATFORM_MAX_PATH];
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(ConfigfilePath);
	kv.Rewind();
	// Creating a While Loop
	while(SoundCounter <= fileCounter)
	{
		// 
		if(StrEqual(fileBuffer[SoundCounter], "", false) || StrEqual(fileBuffer[SoundCounter], " ", false))continue;
		// Copying the Name of the Current Sound File
		strcopy(SoundName, sizeof(SoundName), fileBuffer[SoundCounter]);
		// Saving the Extension of the Current Sound File
		GetFileExtension(SoundName, fileExtension, sizeof(fileExtension));
		// Check if the Extension is "mp3" then replace the ".mp3" with "" to get Exact file name
		if(StrEqual(fileExtension, "mp3", false))ReplaceString(SoundName, sizeof(SoundName), ".mp3", "", false);
		// Check if the Extension is "wav" then replace the ".wav" with "" to get Exact file name
		if(StrEqual(fileExtension, "wav", false))ReplaceString(SoundName, sizeof(SoundName), ".wav", "", false);
		// If any Prefix is given then add it at the start of the Sound Name
		if(!StrEqual(SoundsNamePrefix, "", false) && !StrEqual(SoundsNamePrefix, " ", false))
			Format(SoundName, sizeof(SoundName), "%s %s", SoundsNamePrefix, SoundName);
		// Check if the given folder path ends with '/' or not. if not then add '/' on the end of the given path and then also add song name.
		if(CheckPathEndsWithSlash(SoundFolderPath))Format(SoundPath, sizeof(SoundPath), "%s%s", SoundFolderPath, fileBuffer[SoundCounter]);
		if(!CheckPathEndsWithSlash(SoundFolderPath))Format(SoundPath, sizeof(SoundPath), "%s/%s", SoundFolderPath, fileBuffer[SoundCounter]);
		// Now remove the 'sound/' from the start of the path
		ReplaceString(SoundPath, sizeof(SoundPath), "sound/", "", false);
		// Now Check, is this Sound already exists in the Config file or not.
		if(!IsSoundExistInCfgFile(ConfigfilePath, SoundPath))
		{
			kv.Rewind();
			// If the Sound Name doen't exists then add the new key value
			if(kv.JumpToKey(SoundName, true))
			{
				// Set the path of the Sound file to newly created key value
				kv.SetString("file", SoundPath);
				// if any admin flag is given then also add flag it in key value
				if(!StrEqual(PremiumSoundsFlag, "", false) && !StrEqual(PremiumSoundsFlag, " ", false))kv.SetString("flag", PremiumSoundsFlag);
				kv.SetString("link", " ");
			}
			if(sShowFound.BoolValue)PrintToServer("[SLAYER MVP] %d. MVP Added: %s", SoundCounter, fileBuffer[SoundCounter]);
			AddedSounds++;
		}
		else
		{
			if(sShowFound.BoolValue)PrintToServer("[SLAYER MVP] %d. MVP already Exists: %s", SoundCounter, fileBuffer[SoundCounter]);
		}
		kv.Rewind();
		SoundCounter++;
	}
	kv.Rewind();
	kv.ExportToFile(ConfigfilePath);
	delete kv;
	AddedSounds--;SoundCounter--;
	PrintToServer("------------------------------------------------------------");
	PrintToServer("[SLAYER MVP] '%d' MVPs Found in the given Directory", fileCounter);
	PrintToServer("[SLAYER MVP] '%d' MVPs are now added in the Config file", AddedSounds);
	PrintToServer("[SLAYER MVP] '%d' MVPs already exist in the Config file", fileCounter-AddedSounds);
	LoadConfig();
	PrintToServer("------------------------------------------------------------");
}

public Action Command_MVP(int client,int args)
{
	if(sEnable.BoolValue)
	{
			
		EnterPlaylistName[client] = false;
		if (IsValidClient(client) && !IsFakeClient(client))
		{
			ShowMainMenu(client);
		}
	}
	else
	{
		CPrintToChat(client, "%t %t","Tag", "Disabled");
	}
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------------------------------
// MVP Main Menu which will show by typing '!mvp' in chat
// ------------------------------------------------------------------------------------------------------
void ShowMainMenu(int client)
{
	
	Menu settings_menu = new Menu(SettingsMenuHandler);
	
	char name[200];
	if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%T", "No MVP", client);
	else Format(name, sizeof(name), NameMVP[client]);
	
	char menutitle[200];
	Format(menutitle, sizeof(menutitle), "%T", "Setting Menu Title", client, name, VolMVP[client]);
	settings_menu.SetTitle(menutitle);
	
	char mvpmenu[200], volmenu[200];
	Format(mvpmenu, sizeof(mvpmenu), "%T", "MVP Menu Title", client);
	Format(volmenu, sizeof(volmenu), "%T", "Vol Menu Title", client);
	
	settings_menu.AddItem("mvp", mvpmenu);
	settings_menu.AddItem("vol", volmenu);
	
	settings_menu.Display(client, 0);
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char select[200];
		GetMenuItem(menu, param, select, sizeof(select));
		
		if(StrEqual(select, "mvp"))
		{
			DisplayMVPMenu(client, 0);
		}
		else if(StrEqual(select, "vol"))
		{
			DisplayVolMenu(client);
		}
	}
}
// ------------------------------------------------------------------------------------------------------
// MVP Main Menu where all mvp category will be shown
// ------------------------------------------------------------------------------------------------------
void DisplayMVPMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu mvp_menu = new Menu(MVPMenuHandler);
		EnterPlaylistName[client] = false;
		char name[200];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%t", "Not Selected Menu");
		else Format(name, sizeof(name), NameMVP[client]);
		
		char mvpmenutitle[200];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%t", "MVP Menu Title 2", name);
		mvp_menu.SetTitle(mvpmenutitle);
		
		char sbuffer[200];
		Format(sbuffer, sizeof(sbuffer), "%t", "No MVP");
		mvp_menu.AddItem("", sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Random MVP");
		mvp_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Common MVP");
		mvp_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Premium MVP");
		mvp_menu.AddItem(sbuffer, sbuffer);
		if(sEnablePlaylist.BoolValue)
		{
			Format(sbuffer, sizeof(sbuffer), "%t", "MVP Playlist");
			mvp_menu.AddItem(sbuffer, sbuffer);
		}
		if(sEnablePlayersMvp.BoolValue)
		{
			Format(sbuffer, sizeof(sbuffer), "%t", "Player MVP");
			mvp_menu.AddItem(sbuffer, sbuffer);
		}
		mvp_menu.ExitBackButton = true;
		mvp_menu.DisplayAt(client, start, 0);
	}
}

public int MVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[200], common_mvp[200], premium_mvp[200], player_mvp[200], random_mvp[200], mvp_playlist[200];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		
		Format(common_mvp, sizeof(common_mvp), "%t", "Common MVP");
		Format(premium_mvp, sizeof(premium_mvp), "%t", "Premium MVP");
		Format(player_mvp, sizeof(player_mvp), "%t", "Player MVP");
		Format(mvp_playlist, sizeof(mvp_playlist), "%t", "MVP Playlist");
		Format(random_mvp, sizeof(random_mvp), "%t", "Random MVP");
		if(StrEqual(mvp_name, ""))
        {
            CPrintToChat(client, "%t %t", "Tag","Not Selected");
            SelectedMvp[client] = 0;
            NameMVP[client] = "";
            SetClientCookie(client, mvp_cookie, "");
            DisplayMVPMenu(client, menu.Selection);
        }
		else if(StrEqual(mvp_name, common_mvp)) // If Client Select Premium Mvp Option
        {
        	DisplayCommonMvpMenu(client, 0);
        }
		else if(StrEqual(mvp_name, premium_mvp)) // If Client Select Premium Mvp Option
        {
        	DisplayPremiumMvpMenu(client, 0);
        }
		else if(StrEqual(mvp_name, player_mvp)) // If Client Select other player MVP Option
        {
        	DisplayClientMenu(client, 0);
        }
		else if(StrEqual(mvp_name, mvp_playlist))// If Client Select MVP Playlist Option
		{
			DisplayMvpPlaylistMenu(client, 0);
		}
		else if(StrEqual(mvp_name, random_mvp)) // if Client Select Random Mvp Option
        {
        	SelectedMvp[client] = -1;
        	CPrintToChat(client, "%t %t", "Tag","Selected", random_mvp);
        	strcopy(NameMVP[client], sizeof(NameMVP[]), random_mvp);
        	SetClientCookie(client, mvp_cookie, random_mvp);
        	DisplayMVPMenu(client, menu.Selection);
        }
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack) {
    ShowMainMenu(client);
  }
}
// ------------------------------------------------------------------------------------------------------
// Player MVP Menu from where a player can select other players MVP
// ------------------------------------------------------------------------------------------------------
void DisplayClientMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu player_menu = new Menu(PlayerMenuHandler);
		char mvpmenutitle[200];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%t", "Player MVP");
		player_menu.SetTitle(mvpmenutitle);
		// Add all the names of the players who are currently playing in the server in menu expect BOTS
		AddTargetsToMenu2(player_menu, 0,COMMAND_FILTER_NO_BOTS); 
		player_menu.ExitBackButton = true;
		player_menu.DisplayAt(client, start, 0);
	}
}

public int PlayerMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char Item[50];
		int target;
		
		GetMenuItem(menu, param, Item, sizeof(Item));
		int userid = StringToInt(Item);
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			CPrintToChat(client, "%t {white}Player no longer {darkred]Available","Tag");
		}
		else
		{
			int id = SelectedMvp[target];
			if(id == -1) // Means Random MVP
			{
				char random_mvp[200];
				Format(random_mvp, sizeof(random_mvp), "%t", "Random MVP");
				SelectedMvp[client] = -1;
				CPrintToChat(client, "%t %t", "Tag","Selected", random_mvp);
				strcopy(NameMVP[client], sizeof(NameMVP[]), random_mvp);
				SetClientCookie(client, mvp_cookie, random_mvp);
			}
			else if(id == 0) // Means No MVP
			{
				CPrintToChat(client, "%t %t", "Tag","Not Selected");
				SelectedMvp[client] = 0;
				NameMVP[client] = "";
				SetClientCookie(client, mvp_cookie, "");
				DisplayMVPMenu(client, menu.Selection);
			}
			else if(CanUseMVP(client, id))
			{
				CPrintToChat(client, "%t %t", "Tag", "Selected", MVPName[id]);
				SelectedMvp[client] = id;
				strcopy(NameMVP[client], sizeof(NameMVP[]), MVPName[id]);
				SetClientCookie(client, mvp_cookie, MVPName[id]);
			}
			else 
			{
				CPrintToChat(client, "%t %t", "Tag", "No Flag", MVPName[id]);
			}
		}
		DisplayClientMenu(client, menu.Selection);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMVPMenu(client, 0);
}
// ------------------------------------------------------------------------------------------------------
// Common MVP Menu from where a player can select normal MVPs
// ------------------------------------------------------------------------------------------------------
void DisplayCommonMvpMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu common_mvp_menu = new Menu(CommonMVPMenuHandler);
		
		char name[200];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%t", "No MVP");
		else Format(name, sizeof(name), NameMVP[client]);
		char mvpmenutitle[200];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%t", "MVP Menu Title 2", name);
		int count_mvp = 0;
		for(int i = 1; i <= MVPCount; i++)
		{
			if(StrEqual(MVPFlag[i], "") || StrEqual(MVPFlag[i], " ")) // Add Only Those MVPs which don't have any admin flag and steamid
			{
				if(!MVPSteamID[i].Length)
				{
					common_mvp_menu.AddItem(MVPName[i], MVPName[i]);
					count_mvp++;
				}
			}
		}
		if(count_mvp == 0) // If no common mvps found
		{
			char no_mvp[100];
			Format(no_mvp, sizeof(no_mvp), "%t", "No MVP");
			common_mvp_menu.AddItem(no_mvp, no_mvp, ITEMDRAW_DISABLED);
		}
		else common_mvp_menu.SetTitle(mvpmenutitle);
		common_mvp_menu.ExitBackButton = true;
		common_mvp_menu.DisplayAt(client, start, 0);
	}
}
public int CommonMVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[200];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		if(sPreview.BoolValue)
		{
			menu_selection[client][0] = menu.Selection;
			menu_selection[client][1] = -1;
			MenuSelect[client] = FindMVPIDByName(mvp_name);
			PreviewMVP(client);
		}
		else
		{
			int id = FindMVPIDByName(mvp_name);
			if(CanUseMVP(client, id))
			{
				CPrintToChat(client, "%t %t", "Tag", "Selected", mvp_name);
				SelectedMvp[client] = id;
				strcopy(NameMVP[client], sizeof(NameMVP[]), mvp_name);
				SetClientCookie(client, mvp_cookie, mvp_name);
			}
			else CPrintToChat(client, "%t %t", "Tag", "No Flag", mvp_name);
			DisplayCommonMvpMenu(client, menu.Selection);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMVPMenu(client, 0);
}
// ------------------------------------------------------------------------------------------------------
// Premium MVP Menu from where a player can select Premium MVPs
// ------------------------------------------------------------------------------------------------------
void DisplayPremiumMvpMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu premium_mvp_menu = new Menu(PremiumMVPMenuHandler);
		
		char name[200];
		if(StrEqual(NameMVP[client], ""))	Format(name, sizeof(name), "%t", "No MVP");
		else Format(name, sizeof(name), NameMVP[client]);
		char mvpmenutitle[200];
		Format(mvpmenutitle, sizeof(mvpmenutitle), "%t", "MVP Menu Title 2", name);
		int count_mvp = 0;
		for(int i = 1; i <= MVPCount; i++)
		{
			if(CanUsePremiumMVP(client, i)) // Show Only those Premium MVPs to which Client have Access by admin flags/steamid
			{
				premium_mvp_menu.AddItem(MVPName[i], MVPName[i]);
				count_mvp++;
			}
			else
			{
				if(sShowPremium.BoolValue && IsPremiumMVP[i])
				{
					premium_mvp_menu.AddItem(MVPName[i], MVPName[i], ITEMDRAW_DISABLED);
					count_mvp++;
				}
			}			
		}
		if(count_mvp == 0) // If Client don't have access to any premium MVPs
		{
			char no_mvp[100];
			Format(no_mvp, sizeof(no_mvp), "%t", "No Premium MVP");
			premium_mvp_menu.AddItem(no_mvp, no_mvp, ITEMDRAW_DISABLED);
		}
		else premium_mvp_menu.SetTitle(mvpmenutitle);
		premium_mvp_menu.ExitBackButton = true;
		premium_mvp_menu.DisplayAt(client, start, 0);
	}
}
public int PremiumMVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char mvp_name[200];
		GetMenuItem(menu, param, mvp_name, sizeof(mvp_name));
		if(sPreview.BoolValue)
		{
			menu_selection[client][0] = -1;
			menu_selection[client][1] = menu.Selection;
			MenuSelect[client] = FindMVPIDByName(mvp_name);
			PreviewMVP(client);
		}
		else
		{
			int id = FindMVPIDByName(mvp_name);
			if(CanUseMVP(client, id))
			{
				CPrintToChat(client, "%t %t", "Tag", "Selected", mvp_name);
				SelectedMvp[client] = id;
				strcopy(NameMVP[client], sizeof(NameMVP[]), mvp_name);
				SetClientCookie(client, mvp_cookie, mvp_name);
			}
			else 
			{
				CPrintToChat(client, "%t %t", "Tag", "No Flag", mvp_name);
			}
			DisplayPremiumMvpMenu(client, menu.Selection);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMVPMenu(client, 0);
}
// ------------------------------------------------------------------------------------------------------
// MVP Playlist Menu from where a player can create/select there own MVP playlist
// ------------------------------------------------------------------------------------------------------
void DisplayMvpPlaylistMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client) && LoadData(client, 4))
	{
		EnterPlaylistName[client] = false;
		TempPlaylistName[client] = "";
		EnteredPlaylistName[client] = false;
		
		Menu mvp_playlist_menu = new Menu(MVPPlaylistMenuHandler);
		
		char sbuffer[1024], mvpplaylistmenutitle[200];
		if(StrEqual(MVPPlaylist[client], "") || MVPPlaylistCount[client] == 0)
		{
			Format(sbuffer, sizeof(sbuffer), "%t", "No MVP Playlist");
			SetClientCookie(client, mvp_cookie3, "");
		}
		else Format(sbuffer, sizeof(sbuffer), MVPPlaylist[client]);
		Format(mvpplaylistmenutitle, sizeof(mvpplaylistmenutitle), "%t", "MVP Playlist Menu Title", sbuffer);
		mvp_playlist_menu.SetTitle(mvpplaylistmenutitle);
		
		
		Format(sbuffer, sizeof(sbuffer), "%t", "Create Playlist");
		if(MVPPlaylistCount[client] < sTotalPlaylist.IntValue)mvp_playlist_menu.AddItem(sbuffer, sbuffer);
		else mvp_playlist_menu.AddItem(sbuffer, sbuffer, ITEMDRAW_DISABLED);
		
		Format(sbuffer, sizeof(sbuffer), "%t\n \n", "Disable Playlist");
		if(!StrEqual(MVPPlaylist[client], ""))mvp_playlist_menu.AddItem(sbuffer, sbuffer);
		else mvp_playlist_menu.AddItem(sbuffer, sbuffer, ITEMDRAW_DISABLED);
		
		int count_mvp_playlist = 0;
		for(int i = 0; i < MVPPlaylistCount[client]; i++)
		{
			if(!StrEqual(MVPPlaylistName[client][i], ""))
			{
				mvp_playlist_menu.AddItem(MVPPlaylistName[client][i], MVPPlaylistName[client][i]);
				count_mvp_playlist++;
			}
		}
		if(count_mvp_playlist == 0)
		{
			char no_mvp_playlist[100];
			Format(no_mvp_playlist, sizeof(no_mvp_playlist), "%t", "No MVP Playlist");
			mvp_playlist_menu.AddItem(no_mvp_playlist, no_mvp_playlist, ITEMDRAW_DISABLED);
		}
		mvp_playlist_menu.ExitBackButton = true;
		mvp_playlist_menu.DisplayAt(client, start, 0);
	}
}
public int MVPPlaylistMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char option[200];
		GetMenuItem(menu, param, option, sizeof(option));
		char Create[200], Disable[200];
		Format(Create, sizeof(Create), "%t", "Create Playlist");
		Format(Disable, sizeof(Disable), "%t\n \n", "Disable Playlist");
		if(StrEqual(option, Create))
		{
			EnterPlaylistName[client] = true;
			DisplayMvpPlaylistNameMenu(client);
		}
		else if(StrEqual(option, Disable))
		{
			MVPPlaylist[client] = "";
			SetClientCookie(client, mvp_cookie3, "");
			DisplayMvpPlaylistMenu(client, 0);
		}
		else
		{
			strcopy(TempPlaylistName[client], sizeof(TempPlaylistName[]), option);
			DisplayMvpPlaylistSettingMenu(client);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMVPMenu(client, 0);
}
void DisplayMvpPlaylistNameMenu(int client)
{
	Menu playlist_name_menu = new Menu(MVPPlaylistNameMenuHandler);
	
	char sbuffer[200], mvpplaylistmenutitle[200];
	if(!StrEqual(TempPlaylistName[client], ""))Format(sbuffer, sizeof(sbuffer), "%s", TempPlaylistName[client]);
	else Format(sbuffer, sizeof(sbuffer), "");
	Format(mvpplaylistmenutitle, sizeof(mvpplaylistmenutitle), "%t", "MVP Playlist Name Menu Title", sbuffer);
	playlist_name_menu.SetTitle(mvpplaylistmenutitle);
		
	if(EnteredPlaylistName[client])
	{
		Format(sbuffer, sizeof(sbuffer), "%t", "Yes");
		playlist_name_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "No");
		playlist_name_menu.AddItem(sbuffer, sbuffer);
	}
	else 
	{
		Format(sbuffer, sizeof(sbuffer), "%t", "Yes");
		playlist_name_menu.AddItem(sbuffer, sbuffer, ITEMDRAW_DISABLED);
		Format(sbuffer, sizeof(sbuffer), "%t", "No");
		playlist_name_menu.AddItem(sbuffer, sbuffer, ITEMDRAW_DISABLED);
	}
	Format(sbuffer, sizeof(sbuffer), "%t", "Cancel");
	playlist_name_menu.AddItem(sbuffer, sbuffer);
	playlist_name_menu.ExitBackButton = false;
	playlist_name_menu.ExitButton = false;
	playlist_name_menu.Display(client, 0);
}
public int MVPPlaylistNameMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char sbuffer[500], sYes[50], sNo[50], sCancel[50];
		GetMenuItem(menu, param, sbuffer, sizeof(sbuffer));
		Format(sYes, sizeof(sYes), "%t", "Yes");
		Format(sNo, sizeof(sNo), "%t", "No");
		Format(sCancel, sizeof(sCancel), "%t", "Cancel");
		if(StrEqual(sbuffer, sYes))
		{
			char clientid[40];
			GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid)); // Get client Steam ID
			if(!FindMVPPlaylist(clientid, TempPlaylistName[client]))
			{
				Format(sbuffer, sizeof(sbuffer), "INSERT INTO slayer_mvp (steam_id, playlist, mvps) VALUES ('%s', '%s', '%s')", clientid, TempPlaylistName[client], "");
				SQL_TQuery(db, Callback, sbuffer, GetClientSerial(client));
				LoadData(client, 4);
			}
			CreateTimer(0.5, MenuTimer, client);
		}
		else if(StrEqual(sbuffer, sNo))
		{
			TempPlaylistName[client] = "";
			EnteredPlaylistName[client] = false;
			EnterPlaylistName[client] = true;
			DisplayMvpPlaylistNameMenu(client);
		}
		else if(StrEqual(sbuffer, sCancel))DisplayMvpPlaylistMenu(client, 0);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMvpPlaylistMenu(client, 0);
}
public Action MenuTimer(Handle timer, any client)
{
	DisplayMvpPlaylistMenu(client, 0);
}
public Action Command_PlaylistName(int client, const char[] sCommand, int args) 
{
	if (sEnable.BoolValue && IsValidClient(client) && !IsFakeClient(client) && EnterPlaylistName[client] == true)
	{
		char Said[200];
		GetCmdArgString(Said, sizeof(Said));
		StripQuotes(Said);
		TrimString(Said);
		if(!IsStringEmpty(Said))
		{
			EnterPlaylistName[client] = false;
			EnteredPlaylistName[client] = true;
			strcopy(TempPlaylistName[client], sizeof(TempPlaylistName[]), Said);
		}
		else
		{
			CPrintToChat(client, "%t %t", "Tag", "Invalid Name");
		}
		DisplayMvpPlaylistNameMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
void DisplayMvpPlaylistSettingMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && LoadData(client, 4))
	{
		Menu playlist_setting_menu = new Menu(MvpPlaylistSettingMenuHandler);
		char sbuffer[200], mvpplaylistmenutitle[200];
		if(!StrEqual(TempPlaylistName[client], ""))Format(sbuffer, sizeof(sbuffer), "%s", TempPlaylistName[client]);
		else Format(sbuffer, sizeof(sbuffer), "Invalid Playlist");
		Format(mvpplaylistmenutitle, sizeof(mvpplaylistmenutitle), "%t", "MVP Playlist Setting Menu Title", sbuffer);
		playlist_setting_menu.SetTitle(mvpplaylistmenutitle);
		
		Format(sbuffer, sizeof(sbuffer), "%t", "Select");
		playlist_setting_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Edit");
		playlist_setting_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Delete");
		playlist_setting_menu.AddItem(sbuffer, sbuffer);
		playlist_setting_menu.ExitBackButton = true;
		playlist_setting_menu.Display(client, 0);
	}
}
public int MvpPlaylistSettingMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char sbuffer[200], sSelect[50], sEdit[50], sDelete[50];
		GetMenuItem(menu, param, sbuffer, sizeof(sbuffer));
		Format(sSelect, sizeof(sSelect), "%t", "Select");
		Format(sEdit, sizeof(sEdit), "%t", "Edit");
		Format(sDelete, sizeof(sDelete), "%t", "Delete");
		if(StrEqual(sbuffer, sSelect))
		{
			int playlist_id = FindMVPPlaylistIDByName(client, TempPlaylistName[client]);
			if(MVPPlaylistMVPCount[client][playlist_id] > 1)
			{
				SetClientCookie(client, mvp_cookie3, TempPlaylistName[client]);
				strcopy(MVPPlaylist[client], sizeof(MVPPlaylist[]), TempPlaylistName[client]);
				DisplayMvpPlaylistMenu(client, 0);
			}
			else
			{
				CPrintToChat(client, "%t %t", "Tag", "Not Enough MVPs");
				DisplayMvpPlaylistSettingMenu(client);
			}
		}
		else if(StrEqual(sbuffer, sEdit))
		{
			PlaylistEditMenu(client, 0);
		}
		else if(StrEqual(sbuffer, sDelete))
		{
			PlaylistConfirmMemu(client);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)DisplayMvpPlaylistMenu(client, 0);
}
void PlaylistEditMenu(int client, int start)
{
	if (IsValidClient(client) && !IsFakeClient(client) && LoadData(client, 4))
	{
		for(int k = 0; k < MVPPlaylistCount[client]; k++) // after loading data then we will Loop All Client's MVPs Playlist Found in Database 
		{
			// After that we check if any playlist has less then 2 mvps and that playlist is client currently selected playlist
			if(MVPPlaylistMVPCount[client][k] < 2 && StrEqual(MVPPlaylist[client], MVPPlaylistName[client][k]))
			{
				// Then we will remove that playlist as client selected playlist
				MVPPlaylist[client] = "";
				SetClientCookie(client, mvp_cookie3, "");
			}
		}
		Menu edit_menu = new Menu(PlaylistEditMenuHandler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DisplayItem);
		char sbuffer[200];
		Format(sbuffer, sizeof(sbuffer), "%t\n \n", "Reset");
		edit_menu.AddItem(sbuffer, sbuffer);
		
		for(int i = 1; i <= MVPCount; i++)
		{
			if(CanUsePremiumMVP(client, i))
			{
				edit_menu.AddItem(MVPName[i], MVPName[i]);
			}			
		}
		for(int i = 1; i <= MVPCount; i++)
		{
			if(StrEqual(MVPFlag[i], "") || StrEqual(MVPFlag[i], " "))
			{
				if(!MVPSteamID[i].Length)edit_menu.AddItem(MVPName[i], MVPName[i]);
			}
		}
		edit_menu.ExitBackButton = true;
		edit_menu.ExitButton = true;
		edit_menu.DisplayAt(client, start, 0);
	}
}
public int PlaylistEditMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			if(LoadData(client, 4))
			{
				int Total_MVPs = MVPPlaylistMVPCount[client][FindMVPPlaylistIDByName(client, TempPlaylistName[client])];
				char sbuffer[200], mvpplaylistmenutitle[200];
				Format(sbuffer, sizeof(sbuffer), "%d", Total_MVPs);
				Format(mvpplaylistmenutitle, sizeof(mvpplaylistmenutitle), "%t", "MVP Edit Menu Title", sbuffer);
				menu.SetTitle(mvpplaylistmenutitle);
			}
		}
		case MenuAction_Select:
		{
			char sbuffer[300], sbuffer1[500];
			GetMenuItem(menu, param, sbuffer, sizeof(sbuffer));
			Format(sbuffer1, sizeof(sbuffer1), "%t\n \n", "Reset");
			char clientid[40];
			GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid)); // Get client Steam ID
			if(StrEqual(sbuffer, sbuffer1))
			{
				Format(sbuffer1, sizeof(sbuffer1), "UPDATE slayer_mvp SET mvps = '%s' WHERE steam_id = '%s' AND playlist = '%s'", "", clientid, TempPlaylistName[client]);
				SQL_TQuery(db, Callback, sbuffer1, GetClientSerial(client));
				if(StrEqual(MVPPlaylist[client], TempPlaylistName[client])) // IF Playlist is Client's Current Selected Playlist
				{
					MVPPlaylist[client] = "";
					SetClientCookie(client, mvp_cookie3, "");
				}
			}
			else
			{
				if(!FindMVPInPlaylist(clientid, TempPlaylistName[client], sbuffer)) // If Selected MVP (Item) not found in Client's Specific Playlist then Add it
				{
					Format(sbuffer1, sizeof(sbuffer1), "UPDATE slayer_mvp SET mvps = mvps || '%s;' WHERE steam_id = '%s' AND playlist = '%s'", sbuffer, clientid, TempPlaylistName[client]);
					SQL_TQuery(db, Callback, sbuffer1, GetClientSerial(client));
				}
				else // If Selected MVP (Item) found in Client's Specific Playlist then Delete it
				{
					Format(sbuffer1, sizeof(sbuffer1), "UPDATE slayer_mvp SET mvps = REPLACE(mvps, '%s;', '') WHERE steam_id = '%s' AND playlist = '%s'", sbuffer, clientid, TempPlaylistName[client]);
					SQL_TQuery(db, Callback, sbuffer1, GetClientSerial(client));
				}
			}
			PlaylistEditMenu(client, GetMenuSelectionPosition());
		}
		case MenuAction_DisplayItem:
		{
			char sbuffer[300];
			char clientid[40];
			GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid)); // Get client Steam ID
			GetMenuItem(menu, param, sbuffer, sizeof(sbuffer));
			if(FindMVPInPlaylist(clientid, TempPlaylistName[client], sbuffer)) // If the mvp (current item) found in the specific Playlist
			{
				Format(sbuffer, sizeof(sbuffer), "★ %s", sbuffer); // ♥, ❥, ❤, ☑, ❧, ✓, ✔, ❎, ✖, ☓, X, ✗, ✘, ✦, ★, ✶, ✷, ☆
				return RedrawMenuItem(sbuffer);
			}
			else // if not found then use same format for every item
			{
				Format(sbuffer, sizeof(sbuffer), "    %s", sbuffer);
				return RedrawMenuItem(sbuffer);
			}
		}
		case MenuAction_Cancel:
		{
			if(param == MenuCancel_ExitBack)DisplayMvpPlaylistSettingMenu(client);
		}
	}
	return 0;
}
void PlaylistConfirmMemu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu confirm_menu = new Menu(PlaylistConfirmMenuHandler);
		char sbuffer[200];
		Format(sbuffer, sizeof(sbuffer), "%t", "MVP Confirm Menu Title");
		confirm_menu.SetTitle(sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "Yes");
		confirm_menu.AddItem(sbuffer, sbuffer);
		Format(sbuffer, sizeof(sbuffer), "%t", "No");
		confirm_menu.AddItem(sbuffer, sbuffer);
		confirm_menu.ExitBackButton = false;
		confirm_menu.ExitButton = false;
		confirm_menu.Display(client, 0);
	}
}
public int PlaylistConfirmMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char sbuffer[500], sYes[50], sNo[50];
		GetMenuItem(menu, param, sbuffer, sizeof(sbuffer));
		Format(sYes, sizeof(sYes), "%t", "Yes");
		Format(sNo, sizeof(sNo), "%t", "No");
		if(StrEqual(sbuffer, sYes))
		{
			char clientid[40];
			GetClientAuthId(client, AuthId_Engine, clientid, sizeof(clientid)); // Get client Steam ID
			Format(sbuffer, sizeof(sbuffer), "DELETE FROM slayer_mvp WHERE steam_id = '%s' AND playlist = '%s'", clientid, TempPlaylistName[client], "");
			SQL_TQuery(db, Callback, sbuffer, GetClientSerial(client));
			LoadData(client, 4);
			MVPPlaylist[client] = "";
			SetClientCookie(client, mvp_cookie3, "");
			CreateTimer(0.5, MenuTimer, client);
		}
		else if(StrEqual(sbuffer, sNo))
		{
			DisplayMvpPlaylistSettingMenu(client);
		}
	}
}
void PreviewMVP(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu preview_mvp_menu = new Menu(PreviewMVPMenuHandler);
		char preview[50];
		Format(preview, sizeof(preview), "%t", "Preview Menu");
		char select[50];
		Format(select, sizeof(select), "%t", "Select Menu");
		char link[50];
		Format(link, sizeof(link), "%t", "Link Menu");
		int id = MenuSelect[client];
		preview_mvp_menu.AddItem(select, select);
		preview_mvp_menu.AddItem(preview, preview);
		if(!StrEqual(MVPLink[id], "") && !StrEqual(MVPLink[id], " "))preview_mvp_menu.AddItem(link, link);
		preview_mvp_menu.ExitBackButton = true;
		preview_mvp_menu.Display(client, 0);
	}
}
public int PreviewMVPMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char option[50], preview[50], select[50], link[50];
		GetMenuItem(menu, param, option, sizeof(option));
		Format(preview, sizeof(preview), "%t", "Preview Menu");
		Format(select, sizeof(select), "%t", "Select Menu");
		Format(link, sizeof(link), "%t", "Link Menu");
		int id = MenuSelect[client];
		if(StrEqual(option, select))
        {
			if(CanUseMVP(client, id)) // If client Selecte 'Selecte Mvp' Option
			{
				CPrintToChat(client, "%t %t", "Tag", "Selected", MVPName[id]);
				SelectedMvp[client] = id;
				strcopy(NameMVP[client], sizeof(NameMVP[]), MVPName[id]);
				SetClientCookie(client, mvp_cookie, MVPName[id]);
			}
			else {
				CPrintToChat(client, "%t %t", "Tag", "No Flag", MVPName[id]);
			}
			if(menu_selection[client][0] != -1)DisplayCommonMvpMenu(client, menu_selection[client][0]);
			if(menu_selection[client][1] != -1)DisplayPremiumMvpMenu(client, menu_selection[client][1]);
        }
		else if(StrEqual(option, preview)) // if Client Select Preview Mvp Option
        {
			char sound[1024];
			Format(sound, sizeof(sound), "%s", MVPFile[id]);
        	// Stop MVPs from Playing if they are playing
			StopPlayingMVPs(client);
			// Play MVP Anthem
			EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, VolMVP[client]);
			if(MvpPreviewTimer[client] != null)delete MvpPreviewTimer[client]; // Check is there already Auto stop MVP timer is running if then delete it
			MvpPreviewTimer[client] = CreateTimer(sPreviewTime.FloatValue, MvpPreviewTimerHandle, client, TIMER_FLAG_NO_MAPCHANGE);// Create Auto Stop MVP Anthem Timer
			PreviewMVP(client);
        }
		else if(StrEqual(option, link)) // if Client Select Mvp Link Option
		{
			CPrintToChat(client, "%t {default}Link: %s", "Tag", MVPLink[id]);
			PreviewMVP(client);
		}
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		if(menu_selection[client][0] != -1)DisplayCommonMvpMenu(client, menu_selection[client][0]);
		if(menu_selection[client][1] != -1)DisplayPremiumMvpMenu(client, menu_selection[client][1]);
	}
}
public Action MvpPreviewTimerHandle(Handle timer, any client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		char sound[1024];
		Format(sound, sizeof(sound), "%s", MVPFile[MenuSelect[client]]);
		StopSound(client, SNDCHAN_STATIC, sound); // Mute sound
	}
	MvpPreviewTimer[client] = null;
}
// Stop All MVPs file which are playing
void StopPlayingMVPs(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		char sound[1024];
		for(int i = 1; i <= MVPCount; i++)
		{
			Format(sound, sizeof(sound), "%s", MVPFile[i]);
			StopSound(client, SNDCHAN_STATIC, sound); // Mute sound
		}
	}
}
void DisplayVolMenu(int client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		Menu vol_menu = new Menu(VolMenuHandler);
		
		char vol[1024];
		if(VolMVP[client] > 0.00)	Format(vol, sizeof(vol), "%.2f", VolMVP[client]);
		else Format(vol, sizeof(vol), "%T", "Mute", client);
		
		char menutitle[1024];
		Format(menutitle, sizeof(menutitle), "%T", "Vol Menu Title 2", client, vol);
		vol_menu.SetTitle(menutitle);
		
		char mute[1024];
		Format(mute, sizeof(mute), "%T", "Mute", client);
		
		vol_menu.AddItem("0", mute);
		vol_menu.AddItem("0.1", "10%");
		vol_menu.AddItem("0.2", "20%");
		vol_menu.AddItem("0.4", "40%");
		vol_menu.AddItem("0.6", "60%");
		vol_menu.AddItem("0.8", "80%");
		vol_menu.AddItem("1.0", "100%");
		vol_menu.ExitBackButton = true;
		vol_menu.Display(client, 0);
	}
}

public int VolMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	if(action == MenuAction_Select)
	{
		char vol[1024];
		GetMenuItem(menu, param, vol, sizeof(vol));
		
		VolMVP[client] = StringToFloat(vol);
		CPrintToChat(client, "%t %t", "Tag", "Volume 2", VolMVP[client]);
		
		SetClientCookie(client, mvp_cookie2, vol);

		DisplayVolMenu(client);
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack) {
    ShowMainMenu(client);
  }
}

public Action Command_MVPVol(int client,int args)
{
	if(sEnable.BoolValue)
	{
		if (IsValidClient(client))
		{
			char arg[20];
			float volume;
			
			if (args < 1)
			{
				CPrintToChat(client, "%t %t", "Tag", "Volume 1", client);
				return Plugin_Handled;
			}
				
			GetCmdArg(1, arg, sizeof(arg));
			volume = StringToFloat(arg);
			
			if (volume < 0.0 || volume > 1.0)
			{
				CPrintToChat(client, "%t %t", "Tag", "Volume 1", client);
				return Plugin_Handled;
			}
			
			VolMVP[client] = StringToFloat(arg);
			CPrintToChat(client, "%t %t", "Tag", "Volume 2", VolMVP[client]);
			
			SetClientCookie(client, mvp_cookie2, arg);
		}
	}
	else
	{
		CPrintToChat(client, "%t %t","Tag", "Disabled");
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

// Return True if MVP is not already Used
stock bool CheckIsMvpAlreadyUsed(int id)
{
	if(sAlreadyUsedMVPs.IntValue > 0)
	{
		for(int i = 1; i <= sAlreadyUsedMVPs.IntValue; i++)
		{
			if(StrEqual(MVPAlreadyUsed[i], MVPName[id]))return false;
		}
		return true;
	}
	else return true;
}

bool CanUseMVP(int client, int id)
{
	if(!IsPremiumMVP[id])return true;
	else
	{
		if(IsFakeClient(client) && !sAllowBot.BoolValue)return false;
		else if(IsFakeClient(client) && sAllowBot.BoolValue)return true;
		if(CanUsePremiumMVP(client, id))return true;
		else return false; // If he has nothing he was a totally normal player then he can't use this mvp
	}
}
stock bool CanUsePremiumMVP(int client, int id)
{
	if(!IsPremiumMVP[id])return false;
	if(ClientHaveSteamIDAccess(client, id))return true; // Check is Client have MVP access by Steam ID
	else if(!StrEqual(MVPFlag[id], "") && !StrEqual(MVPFlag[id], " ")) // If there not any admin flag restriction then check client have those flags or not
	{
		if(CheckCommandAccess(client, "mvp", ReadFlagString(MVPFlag[id]), true))return true;
		else return false;
	}
	else return false;
}

stock bool ClientHaveSteamIDAccess(int client, int id)
{
	if(MVPSteamID[id].Length) // If the MVP has any steam id restrictions
	{
		char steamid[64];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		if(!IsFakeClient(client) && MVPSteamID[id].FindString(steamid) != -1)return true;
		else return false;
	}
	else return false; // If the MVP has not any steam id restrictions then return
}

stock GetFileExtension(char[] file_name, char[] extension, int len)
{
    int i, j, k;

    for (i = strlen(file_name) - 1; i >= 0; i--)
    {
        if (file_name[i] == '.')
        {
            if (j == 0)
                j = i + 1;
            else
                break;
        }
    }

    k = 0;
    for (i = j; i < strlen(file_name) && k < len - 1; i++)
    {
        extension[k++] = file_name[i];
    }

    extension[k] = '\0';
}
stock bool CheckPathEndsWithSlash(char[] str)
{
    char[] slash = "/";
    int len = strlen(str);
    if (len == 0)
    {
        return false; // Empty string
    }
    else if (StrEqual(str[len - 1], slash))
    {
        return true; // String ends with a slash
    }
    else
    {
        return false; // String does not end with a slash
    }
}

stock bool IsSoundExistInCfgFile(char[] CfgFilePath, char[] SoundPath)
{
	if(!FileExists(CfgFilePath))
	{
		SetFailState("Can not find config file \"%s\"!", CfgFilePath);
		return false;
	}
	char CfgSoundPath[100];
	
	KeyValues kv = CreateKeyValues("MVP");
	kv.ImportFromFile(CfgFilePath);
	
	// Now Reading Config File
	if(kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("file", CfgSoundPath, sizeof(CfgSoundPath));
			// Check is Sound Exist by Path in CFG File
			if(StrEqual(CfgSoundPath, SoundPath, false))
			{
				return true;
			}
		}
		while (kv.GotoNextKey());
		kv.Rewind();
		delete kv;
	}
	return false;
}

stock bool IsStringEmpty(char[] GivenString)
{
    for(int i = 0; i < strlen(GivenString); i++)
    {
        if (GivenString[i] != ' ')
        {
            return false;
        }
    }
    return true;
}