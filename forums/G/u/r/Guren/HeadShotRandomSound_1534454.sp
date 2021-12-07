#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#define PLUGIN_VERSION	"1.1"
#define PLUGIN_AUTHOR	"[KR] Chamamyungsu"

new Handle:g_HeadshotAlertToAll = INVALID_HANDLE;
new Handle:HeadshotHUD;

new String:Headshotsound[][PLATFORM_MAX_PATH]=
{
	"headshotrandomsoud/boomhs/headshot.mp3",
	"headshotrandomsoud/etc/headshot1.wav",
	"headshotrandomsoud/etc/headshot2.wav",
	"headshotrandomsond/etc/sniper_shoot_crit.wav",
	"headshotrandomsond/female/headshot.mp3",
	"headshotrandomsond/monkey/headshot.wav",
	"headshotrandomsond/robot/headshot.mp3",
	"headshotrandomsond/sudden/headshot.wav",
	"headshotrandomsond/sudden/headshot_0.wav",
	"headshotrandomsond/sudden/headshot_1.wav",
	"headshotrandomsond/sudden/headshot_2.wav",
	"headshotrandomsond/sudden/headshot_3.wav",
	"headshotrandomsond/sudden/headshot_4.wav",
	"headshotrandomsond/sudden/headshot_kor.wav",
	"headshotrandomsond/headshot.mp3"
};

public Plugin:myinfo = 
{
	name = "HeadShot Random Sound",
	author = PLUGIN_AUTHOR,
	description = "BOOM! HEADSHOT!",
	version = PLUGIN_VERSION,
	url = "http://cafe.naver.com/sourcemulti"
}

public OnPluginStart()
{
	HookEvent( "player_death", Event_PlayerDeath);
	CreateConVar("sm_headshot_random_sound", PLUGIN_VERSION, "Made By Chamamyungsu(Guren)", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );

	g_HeadshotAlertToAll = CreateConVar("sm_HeadshotRandomSoundToAll", "1", " 0 = play headshot random sound to attacker and victim. 1 = to all");
	AutoExecConfig();
	
	HeadshotHUD = CreateHudSynchronizer();
}

public OnMapStart() 
{
	decl String:downloadpath[PLATFORM_MAX_PATH];
	for(new i=0; i<sizeof(Headshotsound); i++)
	{
		PrecacheSound(Headshotsound[i],true);
		Format(downloadpath,PLATFORM_MAX_PATH,"sound/%s",Headshotsound[i]);
		AddFileToDownloadsTable(downloadpath);
	}
}

public Action:Event_PlayerDeath( Handle:event, const String:name[], bool:Broadcast )
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid" ));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new customkill = GetEventInt(event, "customkill");

	if( Victim == Attacker )
		return Plugin_Handled;
	if(customkill == TF_CUSTOM_HEADSHOT)
	{
		new quake;
		quake = GetRandomInt(0, sizeof(Headshotsound)-1);
		if(GetConVarInt(g_HeadshotAlertToAll) == 0)
		{
			EmitSoundToClient(Attacker, Headshotsound[quake], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
			EmitSoundToClient(Victim, Headshotsound[quake], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);
		}
		else
			EmitSoundToAll(Headshotsound[quake], SOUND_FROM_PLAYER, SNDCHAN_AUTO);
		new String:Name[32], String:Name2[32];
		GetClientName(Attacker, Name, 32);
		GetClientName(Victim, Name2, 32);
		SetHudTextParams(-1.0, 0.38, 2.0, 255, 90, 90, 255, 0, 1.0, 0.0, 0.1);
		for(new i=1; i<=MaxClients; i++)
		{
			if(isClientConnectedIngame(i))
				ShowSyncHudText(i, HeadshotHUD, "%s -> %s HEADSHOT!", Name, Name2);
		}
	}
	return Plugin_Continue;
}

//Javalia's Stocklib.
stock bool:isClientConnectedIngame(client){
	
	if(client > 0 && client <= MaxClients){
	
		if(IsClientInGame(client) == true){
			
			return true;
				
		}else{
				
			return false;
				
		}
		
	}else{
		
		return false;
		
	}
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg949\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
