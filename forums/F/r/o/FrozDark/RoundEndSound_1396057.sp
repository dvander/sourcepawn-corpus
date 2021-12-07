#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define MAX_SOUNDS 100
#define PLUGIN_VERSION "2.3.5"

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
new Handle:Timer;
new Handle:AnnounceEvery;
new Handle:RandomSound;
new Handle:cookieResPref;
new Handle:version;
new Handle:ClientPref;

new bool:roundEnded = false;
new bool:loaded = false;

new String:g_soundsListCT[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:g_soundsListT[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:g_soundsList[MAX_SOUNDS][PLATFORM_MAX_PATH];
new String:SoundList[PLATFORM_MAX_PATH];

static String:Team1[4][6]  = {"T","RED","GER","TEAM1"};
static String:Team2[4][6]  = {"CT","BLU","USA","TEAM2"};

new res_sound[MAXPLAYERS + 1];

new MaxSounds;
new MaxSoundsT;
new MaxSoundsCT;
new rnd_sound;
new rnd_sound_t;
new rnd_sound_ct;
new ev_winner;
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


public OnPluginStart(){
	g_CvarEnabled = CreateConVar("sm_res_enable", "1", "Enable/disable round end sound");
	version = CreateConVar("sm_res_version", PLUGIN_VERSION, "Round End Sound version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AtRoundEnd = CreateConVar("sm_res_roundendannounce", "0", "Announcement at every round end");
	AtRoundStart = CreateConVar("sm_res_roundstartannounce", "0", "Announcement at every round start");
	OnPlayerConnect = CreateConVar("sm_res_playerconnectannounce", "1", "Announcement in 20 sec. after player connect");
	AnnounceEvery = CreateConVar("sm_res_announceevery", "120", "How often in seconds it will display the message every time. 0=Disable");
	ClientPref = CreateConVar("sm_res_client", "1", "If enabled, clients will be able to modify their ability to hear sounds. 0=Disable");
	RandomSound = CreateConVar("sm_res_randomsound", "0", "If disabled it will play sounds of the winner team, if enabled all sounds will be random");
	
	decl String:dir[15];
	GetGameFolderName(dir, sizeof(dir));
	
	if (StrEqual(dir,"cstrike",false) || StrEqual(dir,"cstrike_beta",false))
	{
		game = GAME_CSTRIKE;
		HookEvent("round_end", OnRoundEnd);
		HookEvent("round_start", OnRoundStart);
	}
	if (StrEqual(dir,"dod",false))
	{
		game = GAME_DOD;
		HookEvent("dod_round_win", OnRoundEnd);
		HookEvent("dod_round_start", OnRoundStart);
	}
	if (StrEqual(dir,"tf",false))
	{
		game = GAME_TF2;
		HookEvent("teamplay_round_win", OnRoundEnd);
		HookEvent("teamplay_round_start", OnRoundStart);
	}
	else
	{
		game = GAME_OTHER;
		HookEvent("round_end", OnRoundEnd);
		HookEvent("round_start", OnRoundStart);
	}

	LoadTranslations("common.phrases");
	LoadTranslations("plugin.res");
	LoadResSounds();
	
	HookConVarChange(AnnounceEvery, ConVarChange_Timer);
	HookConVarChange(version, ConVarChange_Version);
	
	AutoExecConfig(true, "plugin.res");
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
	if (LibraryExists("pluginautoupdate"))
		AutoUpdate_RemovePlugin();
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_AddPlugin("all-stars.comule.com", "/svn/version.xml", PLUGIN_VERSION);
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

public OnMapStart() {	
	if(GetConVarBool(g_CvarEnabled))
	{
		for(new i = 1; i <= MaxSounds; i++) PrepareSound(i);
		Timer = CreateTimer(GetConVarFloat(AnnounceEvery), TimerEvery, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	if (LibraryExists("pluginautoupdate"))
	{
		InsertServerCommand("sm_autoupdate_download");
	}
}

public ConVarChange_Timer(Handle:convar, const String:oldValue[], const String:newValue[]) {
    if (Timer != INVALID_HANDLE) KillTimer(Timer);
    
    Timer = CreateTimer(GetConVarFloat(AnnounceEvery), TimerEvery, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChange_Version(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(version, PLUGIN_VERSION);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarBool(g_CvarEnabled))
	{
		roundEnded = false;
		if(GetConVarBool(AtRoundStart) && GetConVarBool(ClientPref)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarBool(g_CvarEnabled))
	{
		if(game == GAME_CSTRIKE || game == GAME_OTHER) ev_winner = GetEventInt(event, "winner");
		else if(game == GAME_TF2 || game == GAME_DOD) ev_winner = GetEventInt(event, "team");
		roundEnded = true;
		rnd_sound_t = GetRandomInt(1, MaxSoundsT);
		rnd_sound_ct = GetRandomInt(1, MaxSoundsCT);
		rnd_sound = GetRandomInt(1, MaxSounds);
		for (new i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && res_sound[i] != 0)
			{
				if(game == GAME_CSTRIKE)
				{
					StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
					StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");
				}
			
				if(!GetConVarBool(RandomSound))
				{
					if(ev_winner == 2) EmitSoundToClient(i, g_soundsListT[rnd_sound_t]);
					else if(ev_winner == 3) EmitSoundToClient(i, g_soundsListCT[rnd_sound_ct]);
				}
				else if(ev_winner != 1) EmitSoundToClient(i, g_soundsList[rnd_sound]);
			}
		}
		if(GetConVarBool(AtRoundEnd) && GetConVarBool(ClientPref)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
	}
}

LoadResSounds()
{
	if(GetConVarBool(g_CvarEnabled))
	{
		decl String:Line[PLATFORM_MAX_PATH];
		decl String:Text[2][PLATFORM_MAX_PATH];
		BuildPath(Path_SM,SoundList,sizeof(SoundList),"configs/res_list.cfg");
		if(!FileExists(SoundList))
		{
			LogMessage("res_list.cfg not parsed... file doesn't exist! Unloading...");
			InsertServerCommand("sm plugins unload RoundEndSound.smx");
		}
		new Handle:filehandle = OpenFile(SoundList, "r");

		while(!IsEndOfFile(filehandle))
		{
			ReadFileLine(filehandle,Line,sizeof(Line));
			TrimString(Line);
			if(Line[0] == '/' || Line[0] == '\0') continue;
			if (StrContains(Line,".mp3",false) != -1 || StrContains(Line,".wav",false) != -1)
			{
				if (StrContains(Line,"=") != -1)
				{
					ExplodeString(Line,"=",Text,2,256);
					for (new t = 0; t < sizeof(Team1); t++) {
						if (StrEqual(Text[1],Team1[t],false)) {
							MaxSounds++;
							g_soundsList[MaxSounds] = Text[0];
		
							MaxSoundsT++;
							g_soundsListT[MaxSoundsT] = Text[0];
						}
					}
					for (new t = 0; t < sizeof(Team2); t++) {
						if (StrEqual(Text[1],Team2[t],false)) {
							MaxSounds++;
							g_soundsList[MaxSounds] = Text[0];
		
							MaxSoundsCT++;
							g_soundsListCT[MaxSoundsCT] = Text[0];
						}
					}
					if(StrEqual(Text[1],"BOTH",false) || StrEqual(Text[1],"",false))
					{
						MaxSounds++;
						g_soundsList[MaxSounds] = Text[0];
		
						MaxSoundsT++;
						g_soundsListT[MaxSoundsT] = Text[0];
				
						MaxSoundsCT++;
						g_soundsListCT[MaxSoundsCT] = Text[0];
					}
				}
				else
				{
					MaxSounds++;
					g_soundsList[MaxSounds] = Line;
		
					MaxSoundsT++;
					g_soundsListT[MaxSoundsT] = Line;
				
					MaxSoundsCT++;
					g_soundsListCT[MaxSoundsCT] = Line;
				}
			}
			else if (!StrEqual(Line, ""))
			{
				LogError("Invalid sound - %s", Line);
				LogError("The sounds should be only \".mp3\" or \".wav\"");
			}
		}
		CloseHandle(filehandle);
		LogMessage("General %d sounds loaded", MaxSounds);
		if (game == GAME_CSTRIKE)
		{
			LogMessage("%d of them loaded for Terrorist team", MaxSoundsT);
			LogMessage("And %d loaded for Counter-Terrorist team", MaxSoundsCT);
		}
		if (game == GAME_TF2)
		{
			LogMessage("%d of them loaded for Red team", MaxSoundsT);
			LogMessage("And %d loaded for Blue team", MaxSoundsCT);
		}
		if (game == GAME_DOD)
		{
			LogMessage("%d of them loaded for German team", MaxSoundsT);
			LogMessage("And %d loaded for USA team", MaxSoundsCT);
		}
		else
		{
			LogMessage("%d of them loaded for team 1", MaxSoundsT);
			LogMessage("And %d loaded for team 2", MaxSoundsCT);
		}
	}
}

public Action:ResCmd(client, args) {
	if(GetConVarBool(g_CvarEnabled))
	{
		if (GetConVarBool(ClientPref))
		{
			if(res_sound[client] != 0) {
				res_sound[client] = 0;
				PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Res Off");
			}
			else {
				res_sound[client] = 1;
				PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Res On");
			}
		}
		decl String:buffer[PLATFORM_MAX_PATH];
		
		IntToString(res_sound[client], buffer, 5);
		SetClientCookie(client, cookieResPref, buffer);
	}
}

public Action:TimerEvery(Handle:timer) {
	if(!roundEnded && GetConVarBool(AnnounceEvery) && GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled)) PrintToChatAll("\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}

public ResPrefSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) {
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

public OnClientPutInServer(client) {
	if(!IsFakeClient(client) && GetConVarBool(g_CvarEnabled)) {
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
			new String:buffer[5];
			GetClientCookie(client, cookieResPref, buffer, 5);
			if(!StrEqual(buffer, "")) res_sound[client] = StringToInt(buffer);
			else res_sound[client] = 1;
		}
		else res_sound[client] = 1;
	}
}

public PrepareSound(sound) {
	if(GetConVarBool(g_CvarEnabled))
	{
		new String:downloadFile[PLATFORM_MAX_PATH];

		Format(downloadFile, sizeof(downloadFile), "sound/%s", g_soundsList[sound]);
		if(!FileExists(downloadFile,true) && !FileExists(downloadFile,false))
		{
			LogError("File doesn't exist - %s" , g_soundsList[sound]);
			return;
		}
		PrecacheSound(g_soundsList[sound], true);
		AddFileToDownloadsTable(downloadFile);
	}
}

public Action:TimerAnnounce(Handle:timer, any:client) {
	if(IsClientInGame(client) && GetConVarBool(ClientPref) && GetConVarBool(g_CvarEnabled)) PrintToChat(client, "\x04[\x01RoundEndSound\x04] %t", "Announce Message", YELLOW, GREEN, YELLOW, GREEN);
}

public OnClientCookiesCached(client) {
	if(IsClientInGame(client) && !IsFakeClient(client)) loadClientCookiesFor(client);
}