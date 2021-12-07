/*
*	SM Nextmap Info
* 
* 	Version: 1.7
* 	Author: SWAT_88
* 
* 	1.0 First version, should work on basically any mod.
* 	1.1 Added RoundEnd support.
* 	1.2 Added Cvar for number of repetitions.
* 	1.3 Added Timeleft-Check.
*   1.4 Fixed some bugs.
* 	1.5 Added some features:
* 		countdown
* 		different text locations
* 	1.6 Added support for GunGame & Co
* 	1.7 Fixed a small bug.
* 	1.8 Fixed a bug, should now work on any mod.
* 
* 	Description:
* 		Sends to every Player the nextmap on map end.
* 
* 	Commands:
* 		None.
* 
* 	Cvars:
* 		sm_nextmapinfo_enabled		"1"		- 0: disables the plugin - 1: enables the plugin
* 		sm_nextmapinfo_loop			"5"		- x: How often the message should be repeated. SideNote: Only available if msgtype = chat.
* 		sm_nextmapinfo_roundend		"1"		- 1: Displays the message after the last round OR after GunGame Ends - 0: Displays the message after the time expires.
* 		sm_nextmapinfo_msgtype		"1"		- MsgType for Nextmap Msg - 0: disable - 1: Chat - 2: Panel - 3: BottomCenter - 4: left upper corner
* 		sm_nextmapinfo_ctype		"3"		- MsgType for Countdown	- 0: disable - 1: Chat - 2: Panel - 3: BottomCenter
* 		sm_nextmapinfo_countdown	"0"		- 0: disables the countdown - 1: enables it. SideNote: Use exec 1 or teame06's EnforceTheTimeLimit, otherwise this option makes no sense ...
* 		sm_nextmapinfo_exec			"0"		- 0: don't execute MapEnd after time expired - 1: execute MapEnd after time expired -  Use roundend 1, otherwise you get no msg.
*
*	Setup (SourceMod):
* 		Install the smx file to addons\sourcemod\plugins.
* 		(Re)Load Plugin or change Map.
* 
* 	TO DO:
* 		Nothing make a request.
* 
*	Copyright:
* 		Everybody can edit this plugin and copy this plugin.
* 
* 	Thanks to:
*		teame06 for EnforceTheTimeLimit.
* 		BAILOPAN for tsay and timebomb.
* 		
* 	HAVE FUN!!!
*/

#include <sourcemod>
#include <sdktools>

#define NEXTMAPINFO_VERSION	"1.8"

new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_version = INVALID_HANDLE;
new Handle:g_nextmap = INVALID_HANDLE;
new Handle:g_timelimit = INVALID_HANDLE;
new Handle:g_restartgame = INVALID_HANDLE;
new Handle:g_loop = INVALID_HANDLE;
new Handle:g_roundend = INVALID_HANDLE;
new Handle:g_msgtype = INVALID_HANDLE;
new Handle:g_ctype = INVALID_HANDLE;
new Handle:g_countdown = INVALID_HANDLE;
new Handle:g_exec = INVALID_HANDLE;

new Handle:EndMultiplayerGame;

new timeleft;

new Handle:timer_check = INVALID_HANDLE;
new Handle:timer_nextmap = INVALID_HANDLE;

//Timebomb
new Handle:g_TimeBombTimers;
new g_TimeBombTracker;
new g_TimeBombTicks;

// Sounds
#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define SOUND_FINAL		"weapons/cguard/charging.wav"
#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

public Plugin:myinfo = 
{
	name = "SM Nextmap Info",
	author = "SWAT_88",
	description = "Sends to every Player on map end the nextmap.",
	version = NEXTMAPINFO_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_enabled = CreateConVar("sm_nextmapinfo_enabled","1");
	g_timelimit = FindConVar("mp_timelimit");
	g_restartgame = FindConVar("mp_restartgame");
	g_loop = CreateConVar("sm_nextmapinfo_loop","5");
	g_roundend = CreateConVar("sm_nextmapinfo_roundend","1");
	g_msgtype = CreateConVar("sm_nextmapinfo_msgtype","1");
	g_ctype = CreateConVar("sm_nextmapinfo_ctype","3");
	g_countdown = CreateConVar("sm_nextmapinfo_countdown","0");
	g_exec = CreateConVar("sm_nextmapinfo_exec","0");
	g_version = CreateConVar("sm_nextmapinfo_version", NEXTMAPINFO_VERSION,	"SM Nextmap Info Version", FCVAR_NOTIFY);
	SetConVarString(g_version, NEXTMAPINFO_VERSION);
	
	HookConVarChange(g_restartgame, CvarChange_RestartGame);
	HookConVarChange(g_timelimit,CvarChange_Timelimit);
}

public OnMapTimeLeftChanged(){
	InitTimer();
}

public OnAllPluginsLoaded(){
	g_nextmap = FindConVar("sm_nextmap");
}

public OnPluginEnd(){
	CloseHandle(g_enabled);
	CloseHandle(g_version);
	CloseHandle(g_nextmap);
	CloseHandle(g_timelimit);
	CloseHandle(g_restartgame);
	CloseHandle(g_loop);
	CloseHandle(g_roundend);
	CloseHandle(g_msgtype);
	CloseHandle(g_ctype);
	CloneHandle(g_countdown);
	CloseHandle(g_exec);
	if(EndMultiplayerGame != INVALID_HANDLE) CloseHandle(EndMultiplayerGame);
}

public Action:CheckMapEndThread(Handle:timer){
	if(CheckEnd() && GetConVarInt(g_roundend) == 1){
		PrintInfo();
		
		//Kill Timer
		KillTimer(timer_check);
		timer_check = INVALID_HANDLE;
	}
}

public bool:CheckEnd(){
	new frozen = 0;
	new unfrozen = 0;
	
	for(new id = 1; id < GetMaxClients(); id++){
		if(IsClientInGame(id)){
			if(GetEntityFlags(id) & FL_FROZEN){
				frozen++;
			}
			else{
				unfrozen++;
			}
		}
	}
	
	if(frozen == 0 && unfrozen == 0)
		return false;
	
	if(frozen >= unfrozen){
		return true;
	}
	else{
		return false;
	}
}

public Action:Nextmapinfo(Handle:timer){
	GetMapTimeLeft(timeleft);
	
	if(timeleft > 1){
		timer_nextmap = CreateTimer (float(timeleft), Nextmapinfo);
	}
	else if(GetConVarInt(g_roundend) == 0){
		PrintInfo();
		
		//Kill Timer
		KillTimer(timer_nextmap);
		timer_nextmap = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:Countdowninfo(Handle:timer){
	GetMapTimeLeft(timeleft);
	
	if((timeleft - 10) > 1){
		CreateTimer (float(timeleft - 10), Countdowninfo);
	}
	else if(timeleft > 0){
		g_TimeBombTicks = 10;
		PerformTimeBomb(1);
	}
	return Plugin_Continue;
}

public PrintInfo(){
	new String:nextmap[256];
	
	if(GetConVarInt(g_msgtype) == 0) return;
	
	GetConVarString(g_nextmap,nextmap,255)
	
	if(GetConVarInt(g_msgtype) == 1){
		for(new i=0; i < GetConVarInt(g_loop);i++){
			PrintToChatAll("\x04Next Map: %s",nextmap);
		}
	}
	else{
		Format(nextmap, sizeof(nextmap),"Next Map: %s",nextmap);
		for(new id=1; id <= GetMaxClients(); id++){
			if(IsClientInGame(id)){
				PrintMsg(id,nextmap,GetConVarInt(g_msgtype));
			}
		}
	}
}

public PrintMsg(client,String:msg[],type){
	if(GetConVarInt(g_enabled) == 0) return;

	if(type == 1){		
		PrintToChat(client,msg);
	}
	else if(type == 2) {
		new Handle:panel = CreatePanel();
		DrawPanelText(panel,msg);
		SendPanelToClient(panel,client,PanelHandle,5);
	}
	else if(type == 3){
		PrintHintText(client,msg);
	}
	else if(type == 4){
		SendDialogToClient(client, msg);
	}
}

public PanelHandle(Handle:menu, MenuAction:action, param1, param2){
}

SendDialogToClient(client, String:text[], any:...)
{
	new String:message[100];
	VFormat(message, sizeof(message), text, 3);	
	
	if(IsClientInGame(client))
	{
		new Handle:kv = CreateKeyValues("Stuff", "title", message);
		KvSetColor(kv, "color", 0, 255, 0, 255);
		KvSetNum(kv, "level", 1);
		KvSetNum(kv, "time", 10);
		
		CreateDialog(client, kv, DialogType_Msg);
		
		CloseHandle(kv);
	}
}

public CvarChange_Timelimit(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if(StringToInt(newvalue) > 0){
		InitTimer();
	}
}

public CvarChange_RestartGame(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if(StringToInt(newvalue) == 1){
		InitTimer();
	}
}

public InitTimer(){
	GetMapTimeLeft(timeleft);

	if(GetConVarInt(g_enabled) == 1 && GetConVarInt(g_timelimit) > 0){
		//Kill Timers
		if(timer_nextmap != INVALID_HANDLE){
			KillTimer(timer_nextmap);
			timer_nextmap = INVALID_HANDLE;
		}
	
		if(timer_check != INVALID_HANDLE){
			KillTimer(timer_check);
			timer_check = INVALID_HANDLE;
		}
		
		if(GetConVarInt(g_roundend) == 0){
			timer_nextmap = CreateTimer(float(timeleft), Nextmapinfo);
		}
		else if(GetConVarInt(g_roundend) == 1){
			timer_check = CreateTimer(1.0, CheckMapEndThread,_,TIMER_REPEAT);
		}
		
		if(GetConVarInt(g_countdown) == 1 && GetConVarInt(g_ctype) != 0 && (timeleft - 10) >= 0){
			CreateTimer(float(timeleft - 10), Countdowninfo);
		}
	}
}

//Timebomb by AlliedModders LLC

public CreateTimeBomb()
{
	g_TimeBombTimers = CreateTimer(1.0, Timer_TimeBomb, _, TIMER_REPEAT);
	g_TimeBombTracker = g_TimeBombTicks;
	
	PrintCountdown();
}

public KillTimeBomb()
{
	KillTimer(g_TimeBombTimers);
	g_TimeBombTimers = INVALID_HANDLE;
}

public PerformTimeBomb(toggle)
{
	switch (toggle)
	{
		case (2):
		{
			if (g_TimeBombTimers == INVALID_HANDLE)
			{
				CreateTimeBomb();
			}
			else
			{
				KillTimeBomb();
			}			
		}

		case (1):
		{
			if (g_TimeBombTimers == INVALID_HANDLE)
			{
				CreateTimeBomb();
			}			
		}
		
		case (0):
		{
			if (g_TimeBombTimers != INVALID_HANDLE)
			{
				KillTimeBomb();
			}			
		}
	}
}

public Action:Timer_TimeBomb(Handle:timer)
{
	g_TimeBombTracker--;
	
	if (g_TimeBombTracker > 0)
	{
		PrintCountdown();
	}
	else
	{
		KillTimeBomb();
		if(GetConVarInt(g_ctype) == 3 && GetConVarInt(g_roundend) == 1) PrintHintTextToAll("");
		if(GetConVarInt(g_exec) == 1) HACK_EndMultiplayerGame();
	}
	
	return Plugin_Handled;
}

public PrintCountdown(){
	new String:msg[30];
	for(new id=1; id <= GetMaxClients(); id++){
		if(IsClientInGame(id)){
			EmitSoundToClient(id,SOUND_BEEP, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);

			Format(msg,sizeof(msg),"%d Seconds till mapchange", g_TimeBombTracker);
			PrintMsg(id,msg,GetConVarInt(g_ctype));
		}
	}
}

//EnforceTheTimeLimit by teame06

CreateEndMultiplayerGame()
{
	new Handle:GameConf = LoadGameConfigFile("EnforceTimeLimit.games");

	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(GameConf, SDKConf_Virtual, "EndMultiplayerGame");
	EndMultiplayerGame = EndPrepSDKCall();

	if(EndMultiplayerGame == INVALID_HANDLE)
	{
		SetFailState("Virtual CGameRules::EndMultiplayerGame Failed. Please contact the author.");
	}

	CloseHandle(GameConf);
}

HACK_EndMultiplayerGame()
{
	if(EndMultiplayerGame == INVALID_HANDLE) CreateEndMultiplayerGame();
	
	if(EndMultiplayerGame != INVALID_HANDLE) SDKCall(EndMultiplayerGame);
}
