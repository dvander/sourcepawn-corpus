// **********************************************************************
// *********************** I	N	T	R	O ***************************
// **********************************************************************
// ===========================================================================================================================================
#pragma semicolon 1

#define PLUGIN_VERSION "2.4.3"

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_PLUGIN 
#include <autoupdate>

#define MAX_SOUNDS 200
#define MAPEND_MAX_SOUNDS 20

#define GAME_CSTRIKE 1
#define GAME_TF2 2
#define GAME_DOD 3
#define GAME_OTHER 4

//------------------------------------------------------------------------------------------------------------------------------------
new Handle:CvarEnabled,		 bool:enabled;
new Handle:RoundEndMsg,		 bool:endmsg;
new Handle:RoundStartMsg,	 bool:startmsg;
new Handle:PlayerConnectMsg, bool:connectmsg;
new Handle:MapEndSound,		 bool:mepenable;
new Handle:Timer;
new Handle:MsgCycle,		 Float:msgtime;
new Handle:RandomSound,		 bool:rndsnd;
new Handle:ClientPref,		 bool:clientpref;
new Handle:version;
new Handle:CommonSounds,	 bool:common;
new Handle:Debug,			 bool:debugsounds;
new Handle:SoundListPath,	 String:SndListPath[PLATFORM_MAX_PATH];
new Handle:DodCry,			 bool:blockcry;

new Handle:cookieResPref;

new bool:hasMEPSounds;
new bool:hasSounds;
new bool:roundEnded;
new bool:mapEnded;
new bool:loaded;
new bool:active;

new bool:roundendhooked;
new bool:roundstarthooked;
//------------------------------------------------------------------------------------------------------------------------------------

new String:g_soundsList[MAX_SOUNDS+1][PLATFORM_MAX_PATH],String:g_soundsList1[MAX_SOUNDS+1][PLATFORM_MAX_PATH],String:g_soundsList2[MAX_SOUNDS+1][PLATFORM_MAX_PATH],String:MapEndSoundList[MAPEND_MAX_SOUNDS+1][PLATFORM_MAX_PATH];

static String:Team1[4][6]   = {"T","RED","USA","TEAM1"};
static String:Team2[4][6]   = {"CT","BLU","GER","TEAM2"};
static String:MapEnd[3][7]  = {"MAPEND","MAP","END"};

new res_sound[MAXPLAYERS+1];

new Queue1;
new Queue2;
new CommonQueue;
new MapendQueue;
new MaxSounds;
new MaxSounds1;
new MaxSounds2;
new MapendMaxSounds;
new win_sound;
new win_sound_1;
new win_sound_2;
new TF2Team;
new winner;
new game;

//------------------------------------------------------------------------------------------------------------------------------------
// Colors
#define YELLOW               "\x01"
#define NAME_TEAMCOLOR       "\x02"
#define TEAMCOLOR            "\x03"
#define GREEN                "\x04"
//------------------------------------------------------------------------------------------------------------------------------------
// ===========================================================================================================================================







// ******************************************************************
// *********************** M	A	I	N ***************************
// ******************************************************************
// ===========================================================================================================================================
public Plugin:myinfo =
{
	name = "Round and Map End Sound",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Plays all sounds or sounds of the winner team in a queue or random at round end and at map end",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};


public OnPluginStart()
{
	CvarEnabled 	 = CreateConVar("sm_res_enable",				 "1", "Enables/disables the plugin", 0, true, 0.0, true, 1.0);
	version 		 = CreateConVar("sm_res_version",				 PLUGIN_VERSION, "Round End Sound version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RoundEndMsg		 = CreateConVar("sm_res_roundendannounce",		 "0", "Announcement at every round end", 0, true, 0.0, true, 1.0);
	RoundStartMsg 	 = CreateConVar("sm_res_roundstartannounce",	 "0", "Announcement at every round start", 0, true, 0.0, true, 1.0);
	PlayerConnectMsg = CreateConVar("sm_res_playerconnectannounce",	 "1", "Announcement to a player in 20 sec. after his connecting", 0, true, 0.0, true, 1.0);
	MsgCycle 		 = CreateConVar("sm_res_announceevery",			 "120", "Announcement repeater in seconds. 0=Disable", 0, true, 0.0);
	MapEndSound 	 = CreateConVar("sm_res_mapendsound",			 "1", "Enables/disables in-built map end sound", 0, true, 0.0, true, 1.0);
	ClientPref		 = CreateConVar("sm_res_client",				 "1", "If enabled, clients will be able to modify their ability to hear sounds. 0=Disable", 0, true, 0.0, true, 1.0);
	RandomSound		 = CreateConVar("sm_res_randomsound",			 "0", "If enabled, the sounds will be played randomly. If disabled the sounds will be played in a queue", 0, true, 0.0, true, 1.0);
	CommonSounds	 = CreateConVar("sm_res_commonsounds",			 "0", "If enabled, all sounds will be played in spite of the winner team", 0, true, 0.0, true, 1.0);
	Debug			 = CreateConVar("sm_res_debugsounds",			 "0", "Enables/disables debug", 0, true, 0.0, true, 1.0);
	SoundListPath	 = CreateConVar("sm_res_soundslist",			 "addons/sourcemod/configs/res_list.cfg", "Path to the sound list");
	DodCry			 = CreateConVar("sm_res_dod_blocklastcry",		 "1", "Blocks last capture point cry for dod", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_reloadsoundslist", ResReload, ADMFLAG_BAN, "Reloads sound list");

	LoadTranslations("common.phrases");
	LoadTranslations("RoundEndSound");
	
	HookConVarChange(CvarEnabled,	   ConVarChange_CvarEnabled);
	HookConVarChange(ClientPref, 	   ConVarChange_ClientPref);
	HookConVarChange(MsgCycle,		   ConVarChange_Timer);
	HookConVarChange(version,		   ConVarChanges);
	HookConVarChange(RoundEndMsg,	   ConVarChanges);
	HookConVarChange(RoundStartMsg,	   ConVarChanges);
	HookConVarChange(PlayerConnectMsg, ConVarChanges);
	HookConVarChange(MapEndSound, 	   ConVarChanges);
	HookConVarChange(RandomSound, 	   ConVarChanges);
	HookConVarChange(CommonSounds, 	   ConVarChanges);
	HookConVarChange(Debug, 		   ConVarChanges);
	HookConVarChange(SoundListPath,	   ConVarChanges);
	HookConVarChange(DodCry,		   ConVarChanges);
	
	AutoExecConfig(true, "RoundEndSound");
}

public OnPluginEnd()
{
	if(LibraryExists("pluginautoupdate"))
		AutoUpdate_RemovePlugin();
}

public OnMapStart()
{
	mapEnded = false;
	if (LibraryExists("pluginautoupdate"))
		ServerCommand("sm_autoupdate_download RoundEndSound.smx");
}

public OnMapEnd()
{
	mapEnded = true;
	if (active)
		DiactivatePlugin();
}
// ===========================================================================================================================================







// ******************************************************************************
// *********************** C	O	N	F	I	G	S ***************************
// ******************************************************************************
// ===========================================================================================================================================
public OnConfigsExecuted()
{
	enabled		 = GetConVarBool(CvarEnabled);
	endmsg		 = GetConVarBool(RoundEndMsg);
	startmsg	 = GetConVarBool(RoundStartMsg);
	connectmsg	 = GetConVarBool(PlayerConnectMsg);
	mepenable	 = GetConVarBool(MapEndSound);
	msgtime		 = GetConVarFloat(MsgCycle);
	rndsnd		 = GetConVarBool(RandomSound);
	clientpref	 = GetConVarBool(ClientPref);
	common		 = GetConVarBool(CommonSounds);
	debugsounds	 = GetConVarBool(Debug);
	blockcry	 = GetConVarBool(DodCry);
	
	GetConVarString(SoundListPath, SndListPath, sizeof(SndListPath));
	
	if (clientpref && !loaded)
	{
		RegConsoleCmd("sm_res", ResCmd, "On/Off Round End Sounds");
		cookieResPref = RegClientCookie("Round End Sound", "Round End Sound", CookieAccess_Private);
		new info;
		SetCookieMenuItem(ResPrefSelected, any:info, "Round End Sound");
		loaded = true;
	}
	
	SetConVarString(version, PLUGIN_VERSION);
	
	if (enabled)
	{
		if(msgtime > 0.0)
			Timer = CreateTimer(msgtime, AnnounceRepeater, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (!active)
			ActivatePlugin();
		
		LoadSounds();
	}
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
		AutoUpdate_AddPlugin("baha-all-stars.narod.ru", "/updates/RoundEndSound/version.xml", PLUGIN_VERSION);
	else
		LogMessage("Note: This plugin supports updating via Plugin Autoupdater. Install it if you want to enable auto-update functionality.");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{	
	MarkNativeAsOptional("AutoUpdate_AddPlugin");
	MarkNativeAsOptional("AutoUpdate_RemovePlugin");
	
	return APLRes_Success;
}
// ===========================================================================================================================================







// **********************************************************************************************************************
// *********************** C	L	I	E	N	T		P	R	E	F	E	R	E	N	C	E ***************************
// **********************************************************************************************************************
// ===========================================================================================================================================
public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		if(AreClientCookiesCached(client))
			loadClientCookiesFor(client);
			
		if(connectmsg && enabled)
			CreateTimer(20.0, TimerAnnounce, client);
	}
}

public OnClientCookiesCached(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
		loadClientCookiesFor(client);
}

loadClientCookiesFor(client)
{
	if(clientpref)
	{
		decl String:buffer[5];
		GetClientCookie(client, cookieResPref, buffer, 5);
		
		if(!StrEqual(buffer, ""))
			res_sound[client] = StringToInt(buffer);
			
		else
			res_sound[client] = 1;
	}
	else
		res_sound[client] = 1;
}

public ResPrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (clientpref && enabled)
	{
		if (action == CookieMenuAction_DisplayOption)
		{
			decl String:status[10];
			if (res_sound[client])
				Format(status, sizeof(status), "%T", "On", client);
			else
				Format(status, sizeof(status), "%T", "Off", client);
			Format(buffer, maxlen, "%T: %s", "Cookie Round End Sound", client, status);
		}
		else
		{
			if(res_sound[client])
				res_sound[client] = 0;
			else
				res_sound[client] = 1;
			ShowCookieMenu(client);
		}
	}
}

public Action:ResCmd(client, args)
{
	if(enabled)
	{
		if (clientpref)
		{
			if(res_sound[client])
			{
				res_sound[client] = 0;
				PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Res Off");
			}
			else
			{
				res_sound[client] = 1;
				PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Res On");
			}
		}
		decl String:buffer[PLATFORM_MAX_PATH];
		
		IntToString(res_sound[client], buffer, 5);
		SetClientCookie(client, cookieResPref, buffer);
	}
	return Plugin_Handled;
}
// ===========================================================================================================================================







// **************************************************************************************************************
// *********************** S	O	U	N	D		C	A	L	L	B	A	C	K	S ***************************
// **************************************************************************************************************
// ===========================================================================================================================================
PrepareSound(String:Sound[])
{
	decl String:ResFile[PLATFORM_MAX_PATH];
	Format(ResFile, sizeof(ResFile), "sound/%s", Sound);
	PrecacheSound(Sound, true);
	if(debugsounds)
		LogMessage("Sound precached - %s", Sound);
	AddFileToDownloadsTable(ResFile);
}

PlaySound(team, String:sound[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && !res_sound[client])
		{
			if (team && GetClientTeam(client) == team)
				EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			else 
				EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
}

bool:CheckMapEnd()
{
	new timeleft;
	new timelimit;
	
	GetMapTimeLeft(timeleft);
	GetMapTimeLimit(timelimit);
	
	if (timeleft > 0)
		return false;
		
	else if (timelimit == 0)
		return false;
		
	else if (mapEnded)
		return true;
		
	else
		return true;
}

LoadSounds()
{
	RemoveAndResetSounds();

	decl String:Line[PLATFORM_MAX_PATH];
	decl String:Text[2][PLATFORM_MAX_PATH];
	decl String:buf[4];
	
	new Handle:filehandle = OpenFile(SndListPath, "r");
	
	if (filehandle == INVALID_HANDLE)
		SetFailState("%s not parsed... file doesn't exist!", SndListPath);
		
	while(!IsEndOfFile(filehandle) && MaxSounds < MAX_SOUNDS)
	{
		ReadFileLine(filehandle,Line,sizeof(Line));
	
		new pos;
		pos = StrContains((Line), "//");
		if (pos != -1)
			Line[pos] = '\0';
	
		pos = StrContains((Line), "#");
		if (pos != -1)
			Line[pos] = '\0';
			
		pos = StrContains((Line), ";");
		if (pos != -1)
			Line[pos] = '\0';
	
		TrimString(Line);
		
		if (Line[0] == '\0')
			continue;
		
		GetExtension(Line, buf, sizeof(buf));
		
		if (!strcmp(buf, "mp3", false) || !strcmp(buf, "wav", false))
		{
			if (StrContains(Line,"=") != -1)
			{
				ExplodeString(Line,"=",Text,2,256);
				Format(Line, sizeof(Line), "sound/%s", Text[0]);
				if (!FileExists(Line, false) || !FileExists(Line, true))
				{
					LogError("Sound %s not found, file doesn't exist!", Line);
					continue;
				}
				for (new t = 0; t < sizeof(Team1); t++)
				{
					if (!strcmp(Text[1],Team1[t],false))
					{
						g_soundsList[++MaxSounds] = Text[0];
						g_soundsList1[++MaxSounds1] = Text[0];
						
						if(debugsounds)
							LogMessage("Sound loaded - %s", Text[0]);
					}
				}
				for (new t = 0; t < sizeof(Team2); t++)
				{
					if (!strcmp(Text[1],Team2[t],false))
					{
						g_soundsList[++MaxSounds] = Text[0];
						g_soundsList2[++MaxSounds2] = Text[0];
						
						if(debugsounds)
							LogMessage("Sound loaded - %s", Text[0]);
					}
				}
				if(!strcmp(Text[1],"BOTH",false) || !strcmp(Text[1],"",false))
				{
					g_soundsList[++MaxSounds] = Text[0];
					g_soundsList1[++MaxSounds1] = Text[0];
					g_soundsList2[++MaxSounds2] = Text[0];
					
					if(debugsounds)
						LogMessage("Sound loaded - %s", Text[0]);
				}
				for (new t = 0; t < sizeof(MapEnd); t++)
				{
					if (!strcmp(Text[1],MapEnd[t],false))
					{
						if(MapendMaxSounds < MAPEND_MAX_SOUNDS)
							MapEndSoundList[++MapendMaxSounds] = Text[0];
							
						if(debugsounds)
							LogMessage("MapEndSound loaded - %s", Text[0]);
					}
				}
				if(!strcmp(Text[1],"ALL",false))
				{
					g_soundsList[++MaxSounds] = Text[0];
					g_soundsList1[++MaxSounds1] = Text[0];
					g_soundsList2[++MaxSounds2] = Text[0];
					
					if(MapendMaxSounds < MAPEND_MAX_SOUNDS)
						MapEndSoundList[++MapendMaxSounds] = Text[0];
					
					if(debugsounds)
						LogMessage("Sound loaded for all events - %s", Text[0]);
				}
			}
			else 
			{
				Format(Text[1], PLATFORM_MAX_PATH, "sound/%s", Line);
				if(FileExists(Text[1]))
				{
					g_soundsList[++MaxSounds] = Line;
					g_soundsList1[++MaxSounds1] = Line;
					g_soundsList2[++MaxSounds2] = Line;
					
					if(debugsounds)
						LogMessage("Sound loaded - %s", Line);
				}
				else
					LogError("Sound %s not found, file doesn't exist!", Line);
			}
		}
		else if (!StrEqual(Line, ""))
		{
			LogError("Invalid extension - %s", buf);
			LogError("In the sound - %s", Line);
			LogError("The extension should be only \".mp3\" or \".wav\"");
		}
	}
	CloseHandle(filehandle);
	
	PrepareSounds();
}

public Action:ResReload(client, args)
{
	LoadSounds();
	
	Queue1=0;
	Queue2=0;
	
	CommonQueue=0;
	MapendQueue=0;
	
	LogMessage("The soundslist was reseted and reloaded");
	
	return Plugin_Handled;
}

RemoveAndResetSounds()
{
	decl String:ResFile[PLATFORM_MAX_PATH];
	
	for(new i = 1; i <= MaxSounds; i++)
	{
		Format(ResFile, sizeof(ResFile), "sound/%s", g_soundsList[i]);
		RemoveFileFromDownloadsTable(ResFile);
	}
	for(new i = 1; i <= MapendMaxSounds; i++)
	{
		Format(ResFile, sizeof(ResFile), "sound/%s", MapEndSoundList[i]);
		RemoveFileFromDownloadsTable(ResFile);
	}
	
	MaxSounds=0;
	MaxSounds1=0;
	MaxSounds2=0;
	
	MapendMaxSounds=0;
}

PrepareSounds()
{
	for(new i = 1; i <= MaxSounds; i++)
		PrepareSound(g_soundsList[i]);
		
	for(new i = 1; i <= MapendMaxSounds; i++)
		PrepareSound(MapEndSoundList[i]);
		
	if (MapendMaxSounds)
	{
		LogMessage("General %d MapEndSounds loaded", MapendMaxSounds);
		hasMEPSounds = true;
	}
		
	if (MaxSounds)
	{
		LogMessage("General %d RoundEndSounds loaded", MaxSounds);
		if(game == GAME_CSTRIKE)
		{
			LogMessage("%d of them loaded for Terrorist team", MaxSounds1);
			LogMessage("And %d loaded for Counter-Terrorist team", MaxSounds2);
		}
		else if(game == GAME_TF2)
		{
			LogMessage("%d of them loaded for Red team", MaxSounds1);
			LogMessage("And %d loaded for Blue team", MaxSounds2);
		}
		else if(game == GAME_DOD)
		{
			LogMessage("%d of them loaded for USA team", MaxSounds1);
			LogMessage("And %d loaded for German team", MaxSounds2);
		}
		else
		{
			LogMessage("%d of them loaded for team 1", MaxSounds1);
			LogMessage("And %d loaded for team 2", MaxSounds2);
		}
		hasSounds = true;
	}
	else if (MapendMaxSounds)
	{
		LogMessage("No RoundEndSounds found in the sounds list");
		hasSounds = false;
	}
	else
	{
		LogError("Neither RoundEndSounds nor MapEndSounds found in the sounds list");
		LogError("Diactivating...");
		
		if (active)
			DiactivatePlugin();
		
		hasSounds = false;
		hasMEPSounds = false;
	}
}

EmitResSounds(String:sound[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && res_sound[i])
		{
			if(game == GAME_CSTRIKE)
				StopSound(i, SNDCHAN_STATIC, winner == 2 ? "radio/terwin.wav":"radio/ctwin.wav");
				
			EmitSoundToClient(i, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
	if(debugsounds)
		WriteLogs(true);
}

EmitMapendSounds()
{
	if(MapendQueue == MapendMaxSounds)
		MapendQueue = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if(game == GAME_CSTRIKE)
				StopSound(i, SNDCHAN_STATIC, winner == 2 ? "radio/terwin.wav":"radio/ctwin.wav");
			
			EmitSoundToClient(i, MapEndSoundList[++MapendQueue], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
	if(debugsounds)
		WriteLogs(false);
}
// ===========================================================================================================================================







// **************************************************************************
// *********************** E	V	E	N	T	S ***************************
// **************************************************************************
// ===========================================================================================================================================
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = false;
	if (enabled)
	{
		if(startmsg && clientpref && hasSounds)
			PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = true;
	if (enabled)
	{
		if (mepenable && CheckMapEnd())
		{
			if (hasMEPSounds)
			{
				EmitMapendSounds();
				return;
			}
		}
				
		if (game == GAME_CSTRIKE || game == GAME_OTHER)
			winner = GetEventInt(event, "winner");
		
		else if (game == GAME_TF2 || game == GAME_DOD)
			winner = GetEventInt(event, "team");
			
		if (winner <= 1)
			return;
		
		decl String:sound[PLATFORM_MAX_PATH];
		
		if (rndsnd)
		{
			if (!common)
			{
				switch (winner)
				{
					case 2 :
					{
						win_sound_1 = Math_GetRandomInt(1, MaxSounds1);
						sound = g_soundsList1[win_sound_1];
					}
					case 3 :
					{
						win_sound_2 = Math_GetRandomInt(1, MaxSounds2);
						sound = g_soundsList2[win_sound_2];
					}
				}
			}
			else
			{
				win_sound = Math_GetRandomInt(1, MaxSounds);
				sound = g_soundsList[win_sound];
			}
		}
		
		else
		{
			if (Queue1 == MaxSounds1)
				Queue1 = 0;
				
			if (Queue2 == MaxSounds2)
				Queue2 = 0;
				
			if (CommonQueue == MaxSounds)
				CommonQueue = 0;
			
			if (!common)
			{
				switch (winner)
				{
					case 2 :
					{
						win_sound_1 = ++Queue1;
						sound = g_soundsList1[win_sound_1];
					}
					case 3 :
					{
						win_sound_2 = ++Queue2;
						sound = g_soundsList2[win_sound_2];
					}
				}
			}
			else
			{
				win_sound = ++CommonQueue;
				sound = g_soundsList[win_sound];
			}
		}
		if (hasSounds)
		{
			EmitResSounds(sound);
			if (endmsg && clientpref)
				PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
		}
	}
}

public Action:OnBroadCast(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(enabled && hasSounds)
	{
		decl String:sound[20];
		GetEventString(event, "sound", sound, sizeof(sound));
		if (game == GAME_TF2)
			TF2Team = GetEventInt(event, "team");
		
		if(!strcmp(sound, "Game.GermanWin", false))
		{
			PlaySound(TF2Team, "ambient/german_win.mp3");
			return Plugin_Handled;
		}
		else if(!strcmp(sound, "Game.USWin", false))
		{
			PlaySound(TF2Team, "ambient/us_win.mp3");
			return Plugin_Handled;
		}
		else if(!strcmp(sound, "Game.Stalemate", false))
		{
			PlaySound(TF2Team, "misc/your_team_stalemate.wav");
			return Plugin_Handled;
		}
		else if(!strcmp(sound, "Game.YourTeamWon", false))
		{
			PlaySound(TF2Team, "misc/your_team_won.wav");
			return Plugin_Handled;
		}
		else if(!strcmp(sound, "Game.SuddenDeath", false))
		{
			PlaySound(TF2Team, "misc/your_team_suddendeath.wav");
			return Plugin_Handled;
		}
		else if(!strcmp(sound, "Game.YourTeamLost", false))
		{
			PlaySound(TF2Team, "misc/your_team_lost.wav");
			return Plugin_Handled;
		}
		if(!strcmp(sound, "Voice.German_FlagCapture", false) || !strcmp(sound, "Voice.US_FlagCapture", false))
			if (roundEnded && blockcry)
				return Plugin_Handled;
	}
	return Plugin_Continue;
}

WriteLogs(bool:RoundEndLog)
{
	if (RoundEndLog)
	{
		if (!common)
		{
			switch (winner)
			{
				case 2 :
					LogMessage("Playing team1 sound �%d - %s", win_sound_1, g_soundsList1[win_sound_1]);
				case 3 :
					LogMessage("Playing team2 sound �%d - %s", win_sound_2, g_soundsList2[win_sound_2]);
			}
		}
		else
			LogMessage("Playing sound �%d - %s",win_sound, g_soundsList[win_sound]);
	}
	else
		LogMessage("Playing MapEnd sound �%d - %s", MapendQueue, MapEndSoundList[MapendQueue]);
}

// ===========================================================================================================================================







// **************************************************************************
// *********************** T	I	M	E	R	S ***************************
// **************************************************************************
// ===========================================================================================================================================
public Action:AnnounceRepeater(Handle:timer)
{
	if(!roundEnded && clientpref && enabled && hasSounds)
		PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client) && clientpref && enabled && hasSounds)
		PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}
// ===========================================================================================================================================







// **********************************************************************************************************
// *********************** H	O	O	K	E	D		C	O	N	V	A	R	S ***************************
// **********************************************************************************************************
// ===========================================================================================================================================
public ConVarChange_Timer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	msgtime = GetConVarFloat(MsgCycle);
	if(Timer != INVALID_HANDLE)
		KillTimer(Timer);

	if(msgtime > 0.0)
		Timer = CreateTimer(msgtime, AnnounceRepeater, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == RoundEndMsg)
		endmsg 		= GetConVarBool(RoundEndMsg);
	else if (convar == RoundStartMsg)
		startmsg 	= GetConVarBool(RoundStartMsg);
	else if (convar == PlayerConnectMsg)
		connectmsg 	= GetConVarBool(PlayerConnectMsg);
	else if (convar == MapEndSound)
		mepenable 	= GetConVarBool(MapEndSound);
	else if (convar == RandomSound)
		rndsnd 		= GetConVarBool(RandomSound);
	else if (convar == CommonSounds)
		common 		= GetConVarBool(CommonSounds);
	else if (convar == Debug)
		debugsounds = GetConVarBool(Debug);
	else if (convar == DodCry)
		blockcry 	= GetConVarBool(DodCry);
	else if (convar == SoundListPath)
		GetConVarString(SoundListPath, SndListPath, sizeof(SndListPath));
	else if (convar == version)
		SetConVarString(version, PLUGIN_VERSION);
}

public ConVarChange_ClientPref(Handle:convar, const String:oldValue[], const String:newValue[])
{
	clientpref = GetConVarBool(ClientPref);
	if(clientpref && cookieResPref == INVALID_HANDLE)
	{
		cookieResPref = RegClientCookie("Round End Sound", "Round End Sound", CookieAccess_Private);
		new info;
		SetCookieMenuItem(ResPrefSelected, any:info, "Round End Sound");
		loaded = true;
	}
	else
	{
		CloseHandle(cookieResPref);
		loaded = false;
	}
}

public ConVarChange_CvarEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Enable = StringToInt(newValue);
	if (!hasSounds && !hasMEPSounds && Enable)
	{
		SetConVarInt(CvarEnabled, 0);
		LogError("You have to load any sounds before activating the plugin");
		return;
	}
	switch (Enable)
	{
		case 0 :
		{
			if (active)
				DiactivatePlugin();
			enabled = false;
		}
			
		case 1 :
		{
			if (msgtime > 0)
				Timer = CreateTimer(msgtime, AnnounceRepeater, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
			if (!active)
				ActivatePlugin();
			enabled = true;
		}
	}
}
// ===========================================================================================================================================







// **********************************************************************************************************
// *********************** A	C	T	I	V	A	T	E		P	L	U	G	I	N ***********************
// **********************************************************************************************************
// ===========================================================================================================================================
ActivatePlugin()
{
	decl String:dir[15];
	GetGameFolderName(dir, sizeof(dir));
	
	if(!strcmp(dir,"cstrike",false) || !strcmp(dir,"cstrike_beta",false))
	{
		game = GAME_CSTRIKE;
		HookEvent("round_end", OnRoundEnd);
		HookEvent("round_start", OnRoundStart);
		PrecacheSound("radio/ctwin.wav", false);
		PrecacheSound("radio/terwin.wav", false);
	}
	else if(!strcmp(dir,"dod",false))
	{
		game = GAME_DOD;
		HookEvent("dod_round_win", OnRoundEnd);
		HookEvent("dod_round_start", OnRoundStart);
		HookEvent("dod_broadcast_audio", OnBroadCast, EventHookMode_Pre);
		PrecacheSound("ambient/german_win.mp3", false);
		PrecacheSound("ambient/us_win.mp3", false);
	}
	else if(!strcmp(dir,"tf",false))
	{
		game = GAME_TF2;
		HookEvent("teamplay_round_win", OnRoundEnd);
		HookEvent("teamplay_round_start", OnRoundStart);
		HookEvent("teamplay_broadcast_audio", OnBroadCast, EventHookMode_Pre);
		PrecacheSound("misc/your_team_lost.wav", false);
		PrecacheSound("misc/your_team_stalemate.wav", false);
		PrecacheSound("misc/your_team_suddendeath.wav", false);
		PrecacheSound("misc/your_team_won.wav", false);
	}
	else
	{
		game = GAME_OTHER;
		if(HookEventEx("round_end", OnRoundEnd))
			roundendhooked = true;
			
		else
		{
			LogError("RoundEndSounds won't work on this game! Only in-built MapEndSounds will!");
			roundendhooked = false;
		}
		
		if(HookEventEx("round_start", OnRoundStart))
			roundstarthooked = true;
			
		else
			roundstarthooked = false;
	}
	active = true;
}
// ===========================================================================================================================================







// ******************************************************************************************************************
// *********************** D	I	A	C	T	I	V	A	T	E		P	L	U	G	I	N ***********************
// ******************************************************************************************************************
// ===========================================================================================================================================
DiactivatePlugin()
{
	if(game == GAME_CSTRIKE)
	{
		UnhookEvent("round_end", OnRoundEnd);
		UnhookEvent("round_start", OnRoundStart);
	}
	else if(game == GAME_DOD)
	{
		UnhookEvent("dod_round_win", OnRoundEnd);
		UnhookEvent("dod_round_start", OnRoundStart);
		UnhookEvent("dod_broadcast_audio", OnBroadCast, EventHookMode_Pre);
	}
	else if(game == GAME_TF2)
	{
		UnhookEvent("teamplay_round_win", OnRoundEnd);
		UnhookEvent("teamplay_round_start", OnRoundStart);
		UnhookEvent("teamplay_broadcast_audio", OnBroadCast, EventHookMode_Pre);
	}
	else if(game == GAME_OTHER)
	{
		if (roundendhooked)
		{
			UnhookEvent("round_end", OnRoundEnd);
			roundendhooked = false;
		}
		if (roundstarthooked)
		{
			UnhookEvent("round_start", OnRoundStart);
			roundstarthooked = false;
		}
	}
	if(Timer != INVALID_HANDLE)
		KillTimer(Timer);
		
	active = false;
}
// ===========================================================================================================================================







// ****************************************************************************************************************************************************************
// *********************** S	T	O	C	K	S	(From SMBLIB by Berni and Chanz (http://forums.alliedmods.net/showthread.php?t=148387)) ***********************
// ****************************************************************************************************************************************************************
// ===========================================================================================================================================
stock GetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}

stock RemoveFileFromDownloadsTable(const String:szFileName[])
{
	static hTable = INVALID_STRING_TABLE;

	if (hTable == INVALID_STRING_TABLE)
		hTable = FindStringTable("downloadables");

	new iIndex = FindStringIndex2(hTable, szFileName);
	if (iIndex != INVALID_STRING_INDEX)
	{
		new bool:bOldState = LockStringTables(false);
		SetStringTableData(hTable, iIndex, "\0", 1);
		LockStringTables(bOldState);
	}
}

stock FindStringIndex2(iTable, const String:szFileName[], iStart=0)
{
	new iMax = GetStringTableNumStrings(iTable);

	decl String:szBuffer[PLATFORM_MAX_PATH];
	for (new i = iStart; i < iMax; i++)
	{
		GetStringTableData(iTable, i, szBuffer, sizeof(szBuffer));
		if (strcmp(szFileName, szBuffer, false) == 0)
			return i;
	}
	return INVALID_STRING_INDEX;
}

stock Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();
	
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}
// ===========================================================================================================================================