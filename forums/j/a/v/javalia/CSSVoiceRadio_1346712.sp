/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.4.29";

public Plugin:myinfo = {
	
	name = "CSSVoiceRadio",
	author = "javalia",
	description = "Voice Radio for CSS",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include "sdkhooks"
//#include "vphysics"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

new g_iVoicePitch[MAXPLAYERS + 1];
new Float:g_fNextRadioTime[MAXPLAYERS + 1];//when they able to use Radio cmd again?
new Float:g_fNextVoiceTime[MAXPLAYERS + 1];//when they able to make voice(include pain and death, blind scream sound)

new Handle:g_cvarRadioText = INVALID_HANDLE;

new Handle:g_cvarFFPainSound = INVALID_HANDLE;
new Handle:g_cvarDeathSound = INVALID_HANDLE;
new Handle:g_cvarBlindSound = INVALID_HANDLE;
new Handle:g_cvarRadioIcon = INVALID_HANDLE;
new Handle:g_cvarBotRadioOverride = INVALID_HANDLE;

new Handle:g_cvarSVGrenadeSound = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	return APLRes_Success;
	
}

public OnPluginStart(){

	CreateConVar("CSSVoiceRadio_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_cvarRadioText = CreateConVar("CSSVoiceRadio_RadioText", "1", "1/0 to enable/disable");
	g_cvarFFPainSound = CreateConVar("CSSVoiceRadio_FFPainSound", "1", "1/0 to enable/disable, pain sound when damaged by teammates");
	g_cvarDeathSound = CreateConVar("CSSVoiceRadio_DeathSound", "1", "1/0 to enable/disable");
	g_cvarBlindSound = CreateConVar("CSSVoiceRadio_BlindSound", "1", "1/0 to enable/disable blind scream");
	g_cvarRadioIcon = CreateConVar("CSSVoiceRadio_RadioIcon", "1", "1/0 to enable/disable radio icon");
	g_cvarBotRadioOverride = CreateConVar("CSSVoiceRadio_BotRadioOverride", "1", "1/0 to enable/disable override of bot`s death, blind scream");
	g_cvarSVGrenadeSound = FindConVar("sv_ignoregrenaderadio");
	AutoExecConfig();
	
	//hook every cmd of css radio
	AddCommandListener(cmdRadio, "coverme");
	AddCommandListener(cmdRadio, "takepoint");
	AddCommandListener(cmdRadio, "holdpos");
	AddCommandListener(cmdRadio, "regroup");
	AddCommandListener(cmdRadio, "followme");
	AddCommandListener(cmdRadio, "takingfire");
	AddCommandListener(cmdRadio, "go");
	AddCommandListener(cmdRadio, "fallback");
	AddCommandListener(cmdRadio, "sticktog");
	AddCommandListener(cmdRadio, "getinpos");
	AddCommandListener(cmdRadio, "stormfront");
	AddCommandListener(cmdRadio, "report");
	AddCommandListener(cmdRadio, "roger");
	AddCommandListener(cmdRadio, "enemyspot");
	AddCommandListener(cmdRadio, "needbackup");
	AddCommandListener(cmdRadio, "sectorclear");
	AddCommandListener(cmdRadio, "inposition");
	AddCommandListener(cmdRadio, "reportingin");
	AddCommandListener(cmdRadio, "getout");
	AddCommandListener(cmdRadio, "negative");
	AddCommandListener(cmdRadio, "enemydown");
	
	HookEvent("player_spawn", EventSpawn);
	HookEvent("player_hurt", EventHurt);
	HookEvent("player_blind", EventBlind);
	HookEvent("player_death", EventDeath);
	HookEvent("weapon_fire", EventWeaponFire);
	
	HookUserMessage(GetUserMessageId("SendAudio"), hookSendAudio, true);
	HookUserMessage(GetUserMessageId("RadioText"), hookRadioText, true);
	HookUserMessage(GetUserMessageId("RawAudio"), hookRawAudio, true);
	AddTempEntHook("RadioIcon", hookRadioIcon);
	
	//this is for rate load of plugin
	for(new i = 1; i <= MaxClients; i++){
	
		g_iVoicePitch[i] = GetRandomInt(85, 115);
	
	}
	
}

public OnMapStart(){

	AutoExecConfig();

}

public OnClientPutInServer(client){
	
	//let every player has different voice
	g_iVoicePitch[client] = GetRandomInt(85, 120);
	g_fNextRadioTime[client] = GetGameTime();
	g_fNextVoiceTime[client] = GetGameTime();
	
}

public Action:hookSendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){

	decl String:msg_str[255];
	BfReadString(bf, msg_str, sizeof(msg_str));
	
	if(StrContains(msg_str, "Radio.") != -1){
	
		return Plugin_Handled;

	}	
	
        return Plugin_Continue;

}

public Action:hookRadioText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){

	if(!GetConVarBool(g_cvarRadioText)){
	
		return Plugin_Handled;

	}	
	
	return Plugin_Continue;

}

public Action:hookRawAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){

	new pitch = BfReadByte(bf);
	new client = BfReadByte(bf);
	
	//match bot`s pitch to plugin`s voice pitch
	if(pitch != g_iVoicePitch[client]){
	
		g_iVoicePitch[client] = pitch;
	
	}
	
	return Plugin_Continue;

}

public Action:cmdRadio(client, String:cmdname[], args){
	
	//클라가 살아있고 라디오 사용 쿨타임이 지났는가
	new Float:nowtime = GetGameTime();
	
	if(isClientConnectedIngameAlive(client) && g_fNextRadioTime[client] <= nowtime){
	
		if(StrEqual(cmdname, "coverme", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_coverme.wav", g_iVoicePitch[client], 0.91);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 0.91;
		
		}else if(StrEqual(cmdname, "takepoint", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/takepoint.wav", g_iVoicePitch[client], 1.24);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.24;
		
		}else if(StrEqual(cmdname, "holdpos", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/position.wav", g_iVoicePitch[client], 1.39);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.39;
		
		}else if(StrEqual(cmdname, "regroup", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/regroup.wav", g_iVoicePitch[client], 1.54);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.54;
		
		}else if(StrEqual(cmdname, "followme", false)){
			
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/followme.wav", g_iVoicePitch[client], 1.11);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.11;
		
		}else if(StrEqual(cmdname, "takingfire", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/fireassis.wav", g_iVoicePitch[client], 2.54);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 2.54;
		
		}else if(StrEqual(cmdname, "go", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/com_go.wav", g_iVoicePitch[client], 1.32);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.32;
		
		}else if(StrEqual(cmdname, "fallback", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/fallback.wav", g_iVoicePitch[client], 1.44);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.44;
		
		}else if(StrEqual(cmdname, "sticktog", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/sticktog.wav", g_iVoicePitch[client], 1.57);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.57;
		
		}else if(StrEqual(cmdname, "getinpos", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/com_getinpos.wav", g_iVoicePitch[client], 2.22);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 2.22;
		
		}else if(StrEqual(cmdname, "stormfront", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/stormfront.wav", g_iVoicePitch[client], 1.13);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.13;
		
		}else if(StrEqual(cmdname, "report", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/com_reportin.wav", g_iVoicePitch[client], 1.52);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.52;
		
		}else if(StrEqual(cmdname, "roger", false)){
			
			if(GetRandomInt(0, 1) == 0){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_affirm.wav", g_iVoicePitch[client], 0.93);
				g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 0.93;
				
			}else{
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/roger.wav", g_iVoicePitch[client], 0.88);
				g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 0.88;
			
			}
		
		}else if(StrEqual(cmdname, "enemyspot", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_enemys.wav", g_iVoicePitch[client], 1.24);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.24;
		
		}else if(StrEqual(cmdname, "needbackup", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_backup.wav", g_iVoicePitch[client], 1.32);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.32;
		
		}else if(StrEqual(cmdname, "sectorclear", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/clear.wav", g_iVoicePitch[client], 1.08);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.08;
		
		}else if(StrEqual(cmdname, "inposition", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_inpos.wav", g_iVoicePitch[client], 1.04);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.04;
		
		}else if(StrEqual(cmdname, "reportingin", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_reportingin.wav", g_iVoicePitch[client], 1.1);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.10;
		
		}else if(StrEqual(cmdname, "getout", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/blow.wav", g_iVoicePitch[client], 1.9);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.9;
		
		}else if(StrEqual(cmdname, "negative", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/negative.wav", g_iVoicePitch[client], 0.96);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 0.96;
		
		}else if(StrEqual(cmdname, "enemydown", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/enemydown.wav", g_iVoicePitch[client], 1.22);
			g_fNextRadioTime[client] = g_fNextVoiceTime[client] = nowtime + 1.22;
		
		}
	
	}
	
	return Plugin_Continue;
	
}

public Action:hookRadioIcon(const String:te_name[], const Players[], numClients, Float:delay){
	
	if(GetConVarBool(g_cvarRadioIcon)){
	
		return Plugin_Continue;
	
	}else{
	
		return Plugin_Handled;
	
	}

}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	g_fNextRadioTime[client] = GetGameTime();
	
}

public Action:EventHurt(Handle:Event, const String:Name[], bool:Broadcast){

	decl client, attacker, health;

	/*
	short 	 userid 	 player index who was hurt
	short 	attacker 	player index who attacked
	byte 	health 	remaining health points
	byte 	armor 	remaining armor points
	string 	weapon 	weapon name attacker used, if not the world
	byte 	dmg_health 	damage done to health
	byte 	dmg_armor 	damage done to armor
	byte 	hitgroup 	hitgroup that was damaged 
	*/
	
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	health = GetEventInt(Event, "health");
	
	new Float:nowtime = GetGameTime();
	
	
	
	//still alive, pain sound
	if(health > 0){
		
		if(!IsFakeClient(client) && client != attacker && isClientConnectedIngame(attacker) && (GetClientTeam(attacker) == GetClientTeam(client)) && GetConVarBool(g_cvarFFPainSound) && g_fNextVoiceTime[client] < GetGameTime()){
		
			new iSound = GetRandomInt(0, 7);
			
			if(iSound == 0){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/hey.wav", g_iVoicePitch[client], 0.7);
				g_fNextVoiceTime[client] = nowtime + 0.7;
			
			}else if(iSound == 1){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/hey2.wav", g_iVoicePitch[client], 0.71);
				g_fNextVoiceTime[client] = nowtime + 0.71;
			
			}else if(iSound == 2){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/hold_your_fire.wav", g_iVoicePitch[client], 1.15);
				g_fNextVoiceTime[client] = nowtime + 1.15;
			
			}else if(iSound == 3){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/im_on_your_side.wav", g_iVoicePitch[client], 1.79);
				g_fNextVoiceTime[client] = nowtime + 1.79;
			
			}else if(iSound == 4){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/ouch.wav", g_iVoicePitch[client], 0.49);
				g_fNextVoiceTime[client] = nowtime + 0.49;
			
			}else if(iSound == 5){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/ow.wav", g_iVoicePitch[client], 0.68);
				g_fNextVoiceTime[client] = nowtime + 0.68;
			
			}else if(iSound == 6){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/ow_its_me.wav", g_iVoicePitch[client], 0.98);
				g_fNextVoiceTime[client] = nowtime + 0.98;
				
			}else if(iSound == 7){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/what_are_you_doing.wav", g_iVoicePitch[client], 1.0);
				g_fNextVoiceTime[client] = nowtime + 1.63;
			
			}
		
		}
	
	}
	
}

public Action:EventBlind(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if(isClientConnectedIngameAlive(client) && GetConVarBool(g_cvarBlindSound) && g_fNextVoiceTime[client] < GetGameTime() && (!IsFakeClient(client) || GetConVarBool(g_cvarBotRadioOverride))){
	
		new Float:nowtime = GetGameTime();
	
		new iSound = GetRandomInt(0, 3);
			
		if(iSound == 0){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/i_cant_see.wav", g_iVoicePitch[client], 0.85);
			g_fNextVoiceTime[client] = nowtime + 0.85;
		
		}else if(iSound == 1){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/im_blind.wav", g_iVoicePitch[client], 0.79);
			g_fNextVoiceTime[client] = nowtime + 0.79;
		
		}else if(iSound == 2){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/ive_been_blinded.wav", g_iVoicePitch[client], 0.93);
			g_fNextVoiceTime[client] = nowtime + 0.93;
		
		}else if(iSound == 3){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/my_eyes.wav", g_iVoicePitch[client], 0.84);
			g_fNextVoiceTime[client] = nowtime + 0.84;
		
		}
	
	}
	
}

public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast){
	
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if(client != 0){
		
		if(GetConVarBool(g_cvarDeathSound) && (!IsFakeClient(client) || GetConVarBool(g_cvarBotRadioOverride))){
			
			new Float:nowtime = GetGameTime();
			
			//has dead, play death sound
			new iSound = GetRandomInt(0, 5);
				
			if(iSound == 0){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain2.wav", g_iVoicePitch[client], 0.8);
				g_fNextVoiceTime[client] = nowtime + 0.8;
			
			}else if(iSound == 1){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain4.wav", g_iVoicePitch[client], 0.58);
				g_fNextVoiceTime[client] = nowtime + 0.58;
			
			}else if(iSound == 2){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain5.wav", g_iVoicePitch[client], 1.11);
				g_fNextVoiceTime[client] = nowtime + 1.11;
				
			}else if(iSound == 3){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain8.wav", g_iVoicePitch[client], 1.39);
				g_fNextVoiceTime[client] = nowtime + 1.39;
				
			}else if(iSound == 4){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain9.wav", g_iVoicePitch[client], 2.02);
				g_fNextVoiceTime[client] = nowtime + 2.02;
				
			}else if(iSound == 5){
			
				sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "bot/pain10.wav", g_iVoicePitch[client], 1.07);
				g_fNextVoiceTime[client] = nowtime + 1.07;
				
			}
		
		}
		
	}
	
}

public Action:EventWeaponFire(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client, String:sWeapon[64];
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	GetEventString(Event, "weapon", sWeapon, 64);
	
	if(!GetConVarBool(g_cvarSVGrenadeSound) && g_fNextVoiceTime[client] < GetGameTime()){
		
		new Float:nowtime = GetGameTime();
		
		if(StrEqual(sWeapon, "hegrenade", false) || StrEqual(sWeapon, "flashbang", false) || StrEqual(sWeapon, "smokegrenade", false)){
		
			sendRawAudioToTeamAndSpectator(client, GetClientTeam(client), "radio/ct_fireinhole.wav", g_iVoicePitch[client], 1.43);
			g_fNextVoiceTime[client] = nowtime + 1.43;
		
		}
		
	}
	
}