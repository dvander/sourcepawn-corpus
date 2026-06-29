

#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
#include <sdktools>
#include "sdkhooks"
#include <tf2>
#include <tf2_stocks>

new Handle:HudMessage;
new Handle:cvarEnabled;
new Handle:cvarAlert;
new Handle:cvarAlertdivide;
new Handle:cvarAlertchoice;
new Handle:cvarAlertvolume
new Handle:cvarAlertplaying;
new Handle:cvarTimeoverplayed;
new Handle:cvarRoundtime;
new Handle:roundtime;
new Handle:roundend;
//new stealth[MAXPLAYERS+1];
new Handle:alert;
new String:alertstring[64];
new Handle:stealth;
new bool:CanHUD;
new String:detected[64];
new Handle:g_Cvar_Gauge = INVALID_HANDLE;
new String:g_sCharGauge[32];
//new Handle:g_hTimer;

/*
new Handle:g_Cvar_Flag = INVALID_HANDLE;
new String:g_sCharAdminFlag[32];
*/
public Plugin:myinfo =
{
	name = "[TF2] Metal Gear Online",
	author = "TommY",
	description = "Team Sneaking mode for Team Fortress 2",
	version = PLUGIN_VERSION,
	url = "tommy.or.kr"
};


public OnPluginStart()
{
	//RegAdminCmd("sm_replenish", Command_Replenish, ADMFLAG_RCON, "sm_replenish <#userid|name> - replenish users");
	cvarEnabled = CreateConVar("sm_mgo_enable", "0.0", "0 : Disable 1 : all 2 : red  3 : blue", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarAlert = CreateConVar("sm_mgo_alert", "4.0", "Duration", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvarAlertdivide = CreateConVar("sm_mgo_alert_divide", "0.2", "Divide by", FCVAR_PLUGIN, true, 0.1, true, 1.0);  // =0.325  /0.2
	cvarAlertchoice = CreateConVar("sm_mgo_alert_choice", "1.0", "Choice", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	cvarAlertvolume = CreateConVar("sm_mgo_alert_volume", "1.0", "Volume", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAlertplaying = CreateConVar("sm_mgo_alert_playing", "0.0", "Playing Sound?", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarTimeoverplayed = CreateConVar("sm_mgo_timeover_played", "0.0", "Played timeover sound this round?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRoundtime = CreateConVar("sm_mgo_roundtime", "210.0", "Round Time", FCVAR_PLUGIN, true, 0.0, true, 1200.0);
	alert = CreateConVar("sm_mgo_alerted", "0.0", "Alert?", FCVAR_PLUGIN, false, 0.0, false, 0.0);
	stealth = CreateConVar("sm_mgo_stealthed", "0.0", "Stealth?", FCVAR_PLUGIN, false, 0.0, false, 0.0);
	roundtime = CreateConVar("sm_mgo_currentroundtime", "0.0", "Round time?", FCVAR_PLUGIN, false, 0.0, false, 0.0);
	roundend = CreateConVar("sm_mgo_roundend", "0.0", "Round ended?", FCVAR_PLUGIN, false, 0.0, false, 0.0);
	g_Cvar_Gauge = CreateConVar("sm_mgo_gauge", "/", "Text to be used for Gauge");
	CreateConVar("sm_mgo_version", PLUGIN_VERSION, "[TF2] Metal Gear Online Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
	/*
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_death", event_player_death, EventHookMode_Post);
	*/
	HookEvent("player_hurt", PlayerHurtEvent);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_game_over", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("player_death", EventPlayerDeath);		
	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));	
	CanHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if(CanHUD)	HudMessage = CreateHudSynchronizer();
	
	
	//CreateTimer(1.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
}
public OnMapStart() {
	CreateTimer(0.1, Timer_Calc, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	/*
	decl String:buffer1[64], String:bufferh[64],  String:buffers[64], String:buffer2[64], String:buffer3[64], String:buffer4[64], String:buffer5[64], String:buffer6[64], String:buffer7[64];
	PrecacheSound("tommy/alert.mp3", true);
	PrecacheSound("tommy/headshot.mp3", true);
	PrecacheSound("tommy/snakedead.mp3", true);
	PrecacheSound("tommy/alertmusic1.mp3", true);
	PrecacheSound("tommy/alertmusic2.mp3", true);
	PrecacheSound("tommy/alertmusic3.mp3", true);
	PrecacheSound("tommy/cautionmusic1.mp3", true);
	PrecacheSound("tommy/cautionmusic2.mp3", true);
	PrecacheSound("tommy/cautionmusic3.mp3", true);
	Format(buffer1, sizeof(buffer1), "sound/tommy/alert.mp3");
	Format(bufferh, sizeof(bufferh), "sound/tommy/headshot.mp3");
	Format(buffers, sizeof(buffers), "sound/tommy/snakedead.mp3");
	Format(buffer2, sizeof(buffer2), "sound/tommy/alertmusic1.mp3");
	Format(buffer3, sizeof(buffer3), "sound/tommy/alertmusic2.mp3");
	Format(buffer4, sizeof(buffer4), "sound/tommy/alertmusic3.mp3");
	Format(buffer5, sizeof(buffer5), "sound/tommy/cautionmusic1.mp3");
	Format(buffer6, sizeof(buffer6), "sound/tommy/cautionmusic2.mp3");
	Format(buffer7, sizeof(buffer7), "sound/tommy/cautionmusic3.mp3");
	AddFileToDownloadsTable(buffer1);
	AddFileToDownloadsTable(bufferh);
	AddFileToDownloadsTable(buffers);
	AddFileToDownloadsTable(buffer2);
	AddFileToDownloadsTable(buffer3);
	AddFileToDownloadsTable(buffer4);
	AddFileToDownloadsTable(buffer5);
	AddFileToDownloadsTable(buffer6);
	AddFileToDownloadsTable(buffer7);
	*/
	Addsounds("tommy/alert.mp3");
	Addsounds("tommy/headshot.mp3");
	Addsounds("tommy/alertmusic1.mp3");
	Addsounds("tommy/alertmusic2.mp3");
	Addsounds("tommy/alertmusic3.mp3");
	Addsounds("tommy/alertmusic4.mp3");
	Addsounds("tommy/alertmusic5.mp3");
	Addsounds("tommy/alertmusic6.mp3");
	Addsounds("tommy/alertmusic7.mp3");
	Addsounds("tommy/cautionmusic1.mp3");
	Addsounds("tommy/cautionmusic2.mp3");
	Addsounds("tommy/cautionmusic3.mp3");
	Addsounds("tommy/cautionmusic4.mp3");
	Addsounds("tommy/cautionmusic5.mp3");
	Addsounds("tommy/cautionmusic6.mp3");
	Addsounds("tommy/cautionmusic7.mp3");
	Addsounds("tommy/rounddefeat1.mp3");
	Addsounds("tommy/rounddefeat2.mp3");
	Addsounds("tommy/roundstart.mp3");
	Addsounds("tommy/roundwin.mp3");
	Addsounds("tommy/snakedead.mp3");
	Addsounds("tommy/timeover.mp3");
	Addsounds("tommy/stealth.mp3");
}

public Addsounds(const String:snd[])
{
	PrecacheSound(snd, true);
	new String:sound[64];
	Format(sound,64,"sound/%s",snd);
	AddFileToDownloadsTable(sound);
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SetConVarFloat(cvarAlertchoice, GetRandomInt(1,7) * 1.0, true, false);
	SetConVarFloat(roundtime, GetConVarFloat(cvarRoundtime));
	SetConVarFloat(roundend, 0.0);
	SetConVarFloat(cvarTimeoverplayed, 0.0);
	new String:cautionmusic[64];
	Format(cautionmusic,64,"tommy/cautionmusic%d.mp3",GetConVarInt(cvarAlertchoice));
	EmitSoundToAll(cautionmusic, SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, _, _, GetConVarFloat(cvarAlertvolume));
	EmitSoundToAll("tommy/roundstart.mp3", _, _, _, _, GetConVarFloat(cvarAlertvolume));
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new String:cautionmusic[64];
	Format(cautionmusic,64,"tommy/cautionmusic%d.mp3",GetConVarInt(cvarAlertchoice));
	StopSound(SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, cautionmusic);
	SetConVarFloat(roundend, 1.0);
}
public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast) {

	new winteam = GetEventInt(event, "team");
	new String:cautionmusic[64];
	Format(cautionmusic,64,"tommy/cautionmusic%d.mp3",GetConVarInt(cvarAlertchoice));
	StopSound(SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, cautionmusic);
	SetConVarFloat(roundend, 1.0);
	PerformRoundWinSound(winteam);
}
stock bool:IsValidAdmin(client, const String:flags[])
{
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

public Action:PlayerHurtEvent(Handle:event,  const String:name[], bool:dontBroadcast)   
{
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	//new health   = GetEventInt(event, "health");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victeam =  GetClientTeam(victim);
	new team = GetConVarInt(cvarEnabled);

	if ((victeam == team || team == 1) && team != 0 && attacker != 0 && GetConVarFloat(roundend) < 1) {
		if (GetConVarFloat(alert) < 0.11) {
			PerformAlert(victim, victeam, attacker);
			EmitSoundToAll("tommy/alert.mp3", _, _, _, _, GetConVarFloat(cvarAlertvolume));
		}
		if (GetConVarInt(stealth) > 0.0) {
			PerformUnStealth(victeam);
		}
		SetConVarFloat(alert, GetConVarFloat(cvarAlert), true, false);
		GetClientName(victim,detected,sizeof(detected));
	}	
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	//new attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	//new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));
	//new soundId = -1;
	//new killsValue = 0;
	new customkill = GetEventInt(event, "customkill");
	new bool:headshot = (customkill == 1);
	if (headshot) {
		EmitSoundToAll("tommy/headshot.mp3", _, _, _, _, GetConVarFloat(cvarAlertvolume));
	}
}
	
public Action:Timer_Calc(Handle:timer) {
	Format(alertstring,64,"");
	if (GetConVarFloat(alert) > 0.0) { // Alert 상태인가??
		SetConVarFloat(alert, GetConVarFloat(alert) - 0.1, true, false);
		GetConVarString(g_Cvar_Gauge, g_sCharGauge, sizeof(g_sCharGauge)); // 게이지 문자 불러오기
		//for 구문은 Alert 게이지 만드는부분
		for (new ii = 0; ii <= (GetConVarFloat(alert)/GetConVarFloat(cvarAlertdivide)); ii++) {
			Format(alertstring,64,"%s%s", alertstring, g_sCharGauge);
		}
		
		new String:alertmusic[64], String:cautionmusic[64];
		Format(cautionmusic,64,"tommy/cautionmusic%d.mp3",GetConVarInt(cvarAlertchoice));
		//Format(cautionmusic,64,"tommy/cautionmusic2.mp3");
		StopSound(SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, cautionmusic);
		if (GetConVarFloat(cvarAlertplaying) < 1) {

			Format(alertmusic,64,"tommy/alertmusic%d.mp3",GetConVarInt(cvarAlertchoice));
			//Format(alertmusic,64,"tommy/alertmusic2.mp3");
			EmitSoundToAll(alertmusic, SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, _, _, GetConVarFloat(cvarAlertvolume));
			SetConVarFloat(cvarAlertplaying, 1.0, true, false);
			//PrintToChat(victim, "\x04[TommY] \x01Playing sound %s!", alertmusic);
		}
	}
	else { // Alert 상태가 아닐때
		if (GetConVarInt(stealth) == 0) {
			PerformStealth(GetConVarInt(cvarEnabled));
		}
		new String:alertmusic[64], String:cautionmusic[64];
		Format(alertmusic,64,"tommy/alertmusic%d.mp3",GetConVarInt(cvarAlertchoice));
		Format(cautionmusic,64,"tommy/cautionmusic%d.mp3",GetConVarInt(cvarAlertchoice));
		//Format(alertmusic,64,"tommy/alertmusic2.mp3");
		//Format(cautionmusic,64,"tommy/cautionmusic2.mp3");
		StopSound(SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, alertmusic);

		if (GetConVarFloat(cvarAlertplaying) > 0) {
			EmitSoundToAll(cautionmusic, SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, _, _, GetConVarFloat(cvarAlertvolume));
			SetConVarFloat(cvarAlertplaying, 0.0, true, false);
		}
		if (GetConVarFloat(roundend) < 1) {
			StopSound(SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, cautionmusic);
		}
		
	}
	if (GetConVarFloat(roundtime) > 0.0 && GetConVarFloat(roundend) == 0.0) {
		if (GetConVarInt(cvarTimeoverplayed) == 0 && GetConVarFloat(roundtime) < 2) {
			EmitSoundToAll("tommy/timeover.mp3", _, _, _, _, GetConVarFloat(cvarAlertvolume));
			SetConVarFloat(cvarTimeoverplayed, 1.0);
		}
		SetConVarFloat(roundtime, GetConVarFloat(roundtime) - 0.1, true, false);
	}
	else {
		if (GetConVarFloat(roundend) == 0.0) PerformWin(GetConVarInt(cvarEnabled));
	}
	//CreateTimer(0.1, Timer_Calc, _, TIMER_FLAG_NO_MAPCHANGE);
}

public OnGameFrame()
{
	new team = GetConVarInt(cvarEnabled);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != 0)
		{
			if (GetConVarFloat(alert) > 0) {
				//new time;
				//time = GetConVarInt(alert);
				SetHudTextParams(0.04, 0.4, 0.1, 255, 0, 0, 255);
				ShowSyncHudText(i, HudMessage, "ALERT : %s \nVictim : %s\nTimelimit : %d", alertstring, detected, GetConVarInt(roundtime));
				if (IsPlayerAlive(i)) {
					SetEntityRenderMode(i, RENDER_NORMAL);
					SetEntityRenderColor(i, 255, 255, 255, 255);
				}
			}
			else {
				SetHudTextParams(0.04, 0.4, 0.1, 255, 255, 0, 255);
				ShowSyncHudText(i, HudMessage, "CAUTION (STEALTH)\nTimelimit : %d", GetConVarInt(roundtime));
				if ((GetClientTeam(i) == team || team == 1) && IsPlayerAlive(i)) {
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 255, 255, 255, 0);
				}
			}
			if ((GetClientTeam(i) == team || team == 1)) {
				TF2_RemoveWeaponSlot(i,3);
				TF2_RemoveWeaponSlot(i,4);
				TF2_RemoveWeaponSlot(i,5);
			}
			else {
				if (IsPlayerAlive(i)) {
					SetEntityRenderMode(i, RENDER_NORMAL);
					SetEntityRenderColor(i, 255, 255, 255, 255);
				}
				
			}
			/*
			if (GetConVarFloat(roundtime) > 0) {
				SetHudTextParams(-1.0, 0.1, 0.1, 255, 255, 255, 255);
				ShowSyncHudText(i, HudMessage, "Time remaining : %d", GetConVarInt(roundtime));
			}
			else {
				SetHudTextParams(-1.0, 0.4, 0.1, 0, 255, 0, 255);
				ShowSyncHudText(i, HudMessage, "Time Over");
			}
			*/
		}

	}
}

public PerformUnStealth(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0 && GetClientTeam(i) == team)
		{
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			PrintToChat(i, "\x04[MGO] \x01Stealth Camouflage won't work under \x03ALERT \x01status!");
		}
	}
	SetConVarFloat(stealth, 0.0, true, false);
}

public PerformStealth(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0 && (GetClientTeam(i) == team || team == 1))
		{
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 255, 255, 255, 0);
			PrintToChat(i, "\x04[MGO] \x01Your Stealth Camouflage is  back to \x03NORMAL!");
			EmitSoundToClient(i, "tommy/stealth.mp3", _, _, _, _, GetConVarFloat(cvarAlertvolume));
		}
	}
	SetConVarFloat(stealth, 1.0, true, false);
}

public PerformAlert(victim, victeam, attacker)
{
	new String:vicname[64], String:attackname[64];
	GetClientName(victim,vicname,sizeof(vicname));
	GetClientName(attacker,attackname,sizeof(attackname));
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0)
		{
			if (victim != attacker) {
				PrintToChat(i, "\x04[MGO] \x01ALERT! for %d seconds! \x04\%s \x01has been detected by \x04%s", GetConVarInt(cvarAlert), vicname, attackname);
			}
			else {
				PrintToChat(i, "\x04[MGO] \x01ALERT! for %d seconds! \x04\%s \x01has attacked himself", GetConVarInt(cvarAlert), vicname);
			}			
		}
	}
}

public PerformWin(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != 0 && (GetClientTeam(i) == team || team == 1))
		{
			ForcePlayerSuicide(i);
		}
	}
}

public PerformRoundWinSound(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != 0)
		{
			if (GetClientTeam(i) == team || team == 1) {
				EmitSoundToClient(i, "tommy/roundwin.mp3", SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, _, _, GetConVarFloat(cvarAlertvolume));
			}
			else {
				new String:defeatsound[64];
				Format(defeatsound, 64,"tommy/rounddefeat%d.mp3", GetRandomInt(1,2));
				EmitSoundToClient(i, defeatsound, SOUND_FROM_PLAYER, SNDCHAN_USER_BASE, _, _, GetConVarFloat(cvarAlertvolume));
			}
		}
	}
}