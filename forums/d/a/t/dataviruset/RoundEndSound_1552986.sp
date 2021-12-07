#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define MAX_SOUNDS 100
#define PLUGIN_VERSION "2.3.9"

#undef REQUIRE_PLUGIN 
#include <autoupdate>

#define GAME_CSTRIKE 1
#define GAME_TF2 2
#define GAME_DOD 3
#define GAME_OTHER 4

new Handle:g_CvarEnabled = INVALID_HANDLE;
new Handle:AtRoundEnd = INVALID_HANDLE;
new Handle:AtRoundStart = INVALID_HANDLE;
new Handle:OnPlayerConnect = INVALID_HANDLE;
new Handle:Timer = INVALID_HANDLE;
new Handle:AnnounceEvery = INVALID_HANDLE;
new Handle:RandomSound = INVALID_HANDLE;
new Handle:cookieResPref = INVALID_HANDLE;
new Handle:version = INVALID_HANDLE;
new Handle:ClientPref = INVALID_HANDLE;
new Handle:CommonSounds = INVALID_HANDLE;
new Handle:Debug = INVALID_HANDLE;
new Handle:SoundListPath = INVALID_HANDLE;
new Handle:DodCry = INVALID_HANDLE;

new bool:roundEnded = false;
new bool:loaded = false;

new String:g_soundsListCT[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:g_soundsListT[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:g_soundsList[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:SoundList[PLATFORM_MAX_PATH];

static String:Team1[4][6]  = {"T","RED","USA","TEAM1"};
static String:Team2[4][6]  = {"CT","BLU","GER","TEAM2"};

new res_sound[MAXPLAYERS+1];

new QueueT=1;
new QueueCt=1;
new CommonQueue=1;
new MaxSounds;
new MaxSoundsT;
new MaxSoundsCT;
new win_sound_common;
new win_sound_t;
new win_sound_ct;
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

public Plugin:myinfo =
{
	name = "Round End Sound",
	author = "FrozDark",
	description = "Plays a random sound or the sound of the winner team at round end",
	version = PLUGIN_VERSION,
	url = "http://all-stars.sytes.net/"
};


public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_res_enable", "1", "Enable/disable round end sound");
	version = CreateConVar("sm_res_version", PLUGIN_VERSION, "Round End Sound version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AtRoundEnd = CreateConVar("sm_res_roundendannounce", "0", "Announcement at every round end");
	AtRoundStart = CreateConVar("sm_res_roundstartannounce", "0", "Announcement at every round start");
	OnPlayerConnect = CreateConVar("sm_res_playerconnectannounce", "1", "Announcement in 20 sec. after player connect");
	AnnounceEvery = CreateConVar("sm_res_announceevery", "120", "How often in seconds it will display the message every time. 0=Disable");
	ClientPref = CreateConVar("sm_res_client", "1", "If enabled, clients will be able to modify their ability to hear sounds. 0=Disable");
	RandomSound = CreateConVar("sm_res_randomsound", "0", "If enabled, the sounds will be random. If disabled the sounds will be played in a queue");
	CommonSounds = CreateConVar("sm_res_commonsounds", "0", "If enabled, all sounds will be played in spite of the winner team");
	Debug = CreateConVar("sm_res_debug", "0", "Enables debug");
	SoundListPath = CreateConVar("sm_res_soundlist", "addons/sourcemod/configs/res_list.cfg", "Path to the sound list");
	DodCry = CreateConVar("sm_res_dod_crysound", "0", "Enables or Disables last capture point cry for dod");
		
	decl String:dir[15];
	GetGameFolderName(dir, sizeof(dir));
	
	if(!strcmp(dir,"cstrike",false) || !strcmp(dir,"cstrike_beta",false))
	{
		game = GAME_CSTRIKE;
		PrecacheSound("radio/ctwin.wav", false);
		PrecacheSound("radio/terwin.wav", false);
		HookEvent("round_end", OnRoundEnd);
		HookEvent("round_start", OnRoundStart);
	}
	else if(!strcmp(dir,"dod",false))
	{
		game = GAME_DOD;
		PrecacheSound("ambient/german_win.mp3", false);
		PrecacheSound("ambient/us_win.mp3", false);
		HookEvent("dod_round_win", OnRoundEnd);
		HookEvent("dod_round_start", OnRoundStart);
		HookEvent("dod_broadcast_audio", OnBroadCast, EventHookMode_Pre);
	}
	else if(!strcmp(dir,"tf",false))
	{
		game = GAME_TF2;
		PrecacheSound("misc/your_team_lost.wav", false);
		PrecacheSound("misc/your_team_stalemate.wav", false);
		PrecacheSound("misc/your_team_suddendeath.wav", false);
		PrecacheSound("misc/your_team_won.wav", false);
		HookEvent("teamplay_round_win", OnRoundEnd);
		HookEvent("teamplay_round_start", OnRoundStart);
		HookEvent("teamplay_broadcast_audio", OnBroadCast, EventHookMode_Pre);
	}
	else
	{
		game = GAME_OTHER;
		HookEventEx("round_end", OnRoundEnd);
		HookEventEx("round_start", OnRoundStart);
	}

	LoadTranslations("common.phrases");
	LoadTranslations("RoundEndSound");
	LoadResSounds();
	
	HookConVarChange(AnnounceEvery, ConVarChange_Timer);
	HookConVarChange(version, ConVarChange_Version);
	
	AutoExecConfig(true, "RoundEndSound");
}

public OnConfigsExecuted()
{
	if (GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled) && !loaded)
	{
		RegConsoleCmd("sm_res", ResCmd, "On/Off Round End Sounds");
		cookieResPref = RegClientCookie("Round End Sound", "Round End Sound", CookieAccess_Private);
		new info;
		SetCookieMenuItem(ResPrefSelected, any:info, "Round End Sound");
		loaded = true;
	}
	SetConVarString(version, PLUGIN_VERSION);
}

public OnPluginEnd()
{
	if(LibraryExists("pluginautoupdate")) AutoUpdate_RemovePlugin();
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_AddPlugin("baha-all-stars.narod.ru", "/updates/RoundEndSound/version.xml", PLUGIN_VERSION);
	}
	else
	{
		LogMessage("Note: This plugin supports updating via Plugin Autoupdater. Install it if you want to enable auto-update functionality.");
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{	
	MarkNativeAsOptional("AutoUpdate_AddPlugin");
	MarkNativeAsOptional("AutoUpdate_RemovePlugin");
	
	return APLRes_Success;
}

public OnMapStart()
{	
	if (GetConVarBool(g_CvarEnabled))
	{
		for(new i = 1; i <= MaxSounds; i++) PrepareSound(i);
		if(GetConVarInt(AnnounceEvery) != 0) Timer = CreateTimer(GetConVarFloat(AnnounceEvery), TimerEvery, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		if (LibraryExists("pluginautoupdate")) InsertServerCommand("sm_autoupdate_download");
	}
}

public ConVarChange_Timer(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (Timer != INVALID_HANDLE) KillTimer(Timer);
    
    if(GetConVarInt(AnnounceEvery) != 0) Timer = CreateTimer(GetConVarFloat(AnnounceEvery), TimerEvery, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChange_Version(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(version, PLUGIN_VERSION);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_CvarEnabled))
	{
		roundEnded = false;
		if(GetConVarBool(AtRoundStart) && GetConVarBool(ClientPref)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_CvarEnabled))
	{
		roundEnded = true;
		
		if (game == GAME_CSTRIKE || game == GAME_OTHER) winner = GetEventInt(event, "winner");
		else if (game == GAME_TF2 || game == GAME_DOD) winner = GetEventInt(event, "team");
		
		if (GetConVarBool(RandomSound))
		{
			if(!GetConVarBool(CommonSounds))
			{
				if(winner == 2) win_sound_t = GetRandomInt(1, MaxSoundsT);
				else if(winner == 3) win_sound_ct = GetRandomInt(1, MaxSoundsCT);
			}
			else win_sound_common = GetRandomInt(1, MaxSounds);
		}
		
		else
		{
			if(QueueT == MaxSoundsT+1) QueueT = 1;
			if(QueueCt == MaxSoundsCT+1) QueueCt = 1;
			if(CommonQueue == MaxSounds+1) CommonQueue = 1;
			
			if(!GetConVarBool(CommonSounds))
			{
				if(winner == 2) win_sound_t = QueueT++;
				else if(winner == 3) win_sound_ct = QueueCt++;
			}
			else if(winner != 1) win_sound_common = CommonQueue++;
		}
		
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && res_sound[i] != 0)
			{
				if(game == GAME_CSTRIKE)
				{
					StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
					StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");
				}
				
				if (!GetConVarBool(CommonSounds))
				{
					if (winner == 2)
					{
						EmitSoundToClient(i, g_soundsListT[win_sound_t], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						if(GetConVarBool(Debug)) LogMessage("Playing team1 sound ¹%d - %s", win_sound_t, g_soundsListT[win_sound_t]);
					}
					else if (winner == 3)
					{
						EmitSoundToClient(i, g_soundsListCT[win_sound_ct], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						if(GetConVarBool(Debug)) LogMessage("Playing team2 sound ¹%d - %s", win_sound_ct, g_soundsListCT[win_sound_ct]);
					}
				}
				else if (winner != 1)
				{
					EmitSoundToClient(i, g_soundsList[win_sound_common], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
					if(GetConVarBool(Debug)) LogMessage("Playing sound ¹%d - %s",win_sound_common, g_soundsList[win_sound_common]);
				}
			}
		}
		if (GetConVarBool(AtRoundEnd) && GetConVarBool(ClientPref)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
	}
}

public Action:OnBroadCast(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_CvarEnabled))
	{
		decl String:sound[20];
		GetEventString(event, "sound", sound, sizeof(sound));
		if (game == GAME_TF2) TF2Team = GetEventInt(event, "team");
		
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
			if (roundEnded && GetConVarBool(DodCry)) 
				return Plugin_Handled;
	}
	return Plugin_Continue;
}

LoadResSounds()
{
	if(GetConVarBool(g_CvarEnabled))
	{
		decl String:Line[PLATFORM_MAX_PATH];
		decl String:Text[2][PLATFORM_MAX_PATH];
		decl String:buf[4];
		
		GetConVarString(SoundListPath, SoundList, sizeof(SoundList));
		
		if(!FileExists(SoundList))
		{
			SetFailState("%s not parsed... file doesn't exist!", SoundList);
		}
		
		new Handle:filehandle = OpenFile(SoundList, "r");
		
		if (filehandle  == INVALID_HANDLE)
		{
			return;
		}

		while(!IsEndOfFile(filehandle) && MaxSounds <= MAX_SOUNDS)
		{
			ReadFileLine(filehandle,Line,sizeof(Line));
		
			new pos;
			pos = StrContains((Line), "//");
			if (pos != -1)
			{
				Line[pos] = '\0';
			}
		
			pos = StrContains((Line), "#");
			if (pos != -1)
			{
				Line[pos] = '\0';
			}

			pos = StrContains((Line), ";");
			if (pos != -1)
			{
				Line[pos] = '\0';
			}
		
			TrimString(Line);
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
							MaxSounds++;
							g_soundsList[MaxSounds] = Text[0];
		
							MaxSoundsT++;
							g_soundsListT[MaxSoundsT] = Text[0];
							
							if(GetConVarBool(Debug)) LogMessage("Sound loaded - %s", Text[0]);
						}
					}
					for (new t = 0; t < sizeof(Team2); t++)
					{
						if (!strcmp(Text[1],Team2[t],false))
						{
							MaxSounds++;
							g_soundsList[MaxSounds] = Text[0];
		
							MaxSoundsCT++;
							g_soundsListCT[MaxSoundsCT] = Text[0];
							
							if(GetConVarBool(Debug)) LogMessage("Sound loaded - %s", Text[0]);
						}
					}
					if(!strcmp(Text[1],"BOTH",false) || !strcmp(Text[1],"",false))
					{
						MaxSounds++;
						g_soundsList[MaxSounds] = Text[0];
		
						MaxSoundsT++;
						g_soundsListT[MaxSoundsT] = Text[0];
				
						MaxSoundsCT++;
						g_soundsListCT[MaxSoundsCT] = Text[0];
						
						if(GetConVarBool(Debug)) LogMessage("Sound loaded - %s", Text[0]);
					}
				}
				else 
				{
					Format(Text[1], PLATFORM_MAX_PATH, "sound/%s", Line);
					if(FileExists(Text[1]))
					{
						MaxSounds++;
						g_soundsList[MaxSounds] = Line;
		
						MaxSoundsT++;
						g_soundsListT[MaxSoundsT] = Line;
				
						MaxSoundsCT++;
						g_soundsListCT[MaxSoundsCT] = Line;
						
						if(GetConVarBool(Debug)) LogMessage("Sound loaded - %s", Line);
					}
					else LogError("Sound %s not found, file doesn't exist!", Line);
				}
			}
			else if (!StrEqual(Line, ""))
			{
				LogError("Invalid sound - %s", buf);
				LogError("The sounds should be only \".mp3\" or \".wav\"");
			}
		}
		CloseHandle(filehandle);
		LogMessage("General %d sounds loaded", MaxSounds);
		if(game == GAME_CSTRIKE)
		{
			LogMessage("%d of them loaded for Terrorist team", MaxSoundsT);
			LogMessage("And %d loaded for Counter-Terrorist team", MaxSoundsCT);
		}
		else if(game == GAME_TF2)
		{
			LogMessage("%d of them loaded for Red team", MaxSoundsT);
			LogMessage("And %d loaded for Blue team", MaxSoundsCT);
		}
		else if(game == GAME_DOD)
		{
			LogMessage("%d of them loaded for USA team", MaxSoundsT);
			LogMessage("And %d loaded for German team", MaxSoundsCT);
		}
		else
		{
			LogMessage("%d of them loaded for team 1", MaxSoundsT);
			LogMessage("And %d loaded for team 2", MaxSoundsCT);
		}
	}
}

public Action:ResCmd(client, args)
{
	if(GetConVarBool(g_CvarEnabled))
	{
		if (GetConVarBool(ClientPref))
		{
			if(res_sound[client] != 0)
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

public Action:TimerEvery(Handle:timer)
{
	if(!roundEnded && GetConVarBool(AnnounceEvery) && GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}

public ResPrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled))
	{
		if (action == CookieMenuAction_DisplayOption)
		{
			decl String:status[10];
			if (res_sound[client] != 0) Format(status, sizeof(status), "%T", "On", client);
			else Format(status, sizeof(status), "%T", "Off", client);
			Format(buffer, maxlen, "%T: %s", "Cookie Round End Sound", client, status);
		}
		else
		{
			if(res_sound[client] != 0) res_sound[client] = 0;
			else res_sound[client] = 1;
			ShowCookieMenu(client);
		}
	}
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client) && GetConVarBool(g_CvarEnabled))
	{
		if(AreClientCookiesCached(client)) loadClientCookiesFor(client);
		if(GetConVarBool(OnPlayerConnect)) CreateTimer(20.0, TimerAnnounce, client);
	}
}

loadClientCookiesFor(client)
{
	if(GetConVarBool(g_CvarEnabled))
	{
		if(GetConVarBool(ClientPref))
		{
			decl String:buffer[5];
			GetClientCookie(client, cookieResPref, buffer, 5);
			if(!StrEqual(buffer, "")) res_sound[client] = StringToInt(buffer);
			else res_sound[client] = 1;
		}
		else res_sound[client] = 1;
	}
}

PrepareSound(sound)
{
	if(GetConVarBool(g_CvarEnabled))
	{
		decl String:downloadFile[PLATFORM_MAX_PATH];
		Format(downloadFile, sizeof(downloadFile), "sound/%s", g_soundsList[sound]);
		PrecacheSound(g_soundsList[sound], true);
		if(GetConVarBool(Debug)) LogMessage("Sound precached - %s", g_soundsList[sound]);
		AddFileToDownloadsTable(downloadFile);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(IsClientInGame(client) && GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled)) PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}

public OnClientCookiesCached(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client)) loadClientCookiesFor(client);
}

PlaySound(team, String:sound[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && res_sound[client] == 0)
		{
			if (team != 0 && GetClientTeam(client) == team)
				EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			else 
				EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
		}
	}
}

GetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1) {
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}