#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.3"

public Plugin:myinfo = {
	name		= "[TF2] Kart Horn",
	author		= "Tony Baretta",
	description	= "kart horn calling medic",
	version		= PLUGIN_VERSION,
	url			= "http://www.wantedgov.it"
};
new bool:g_iMedic[MAXPLAYERS+1];
new LastUsed[MAXPLAYERS+1];


public OnPluginStart()
{
	CreateConVar("karthorn_version", PLUGIN_VERSION, "Current karthorn version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddCommandListener(Listener_Voice, "voicemenu");
}
public OnMapStart() {
	AddFileToDownloadsTable("sound/kartsounds/horn1.mp3");
	AddFileToDownloadsTable("sound/kartsounds/horn2.mp3");
	AddFileToDownloadsTable("sound/kartsounds/horn3.mp3");
	AddFileToDownloadsTable("sound/kartsounds/horn4.mp3");
	AddFileToDownloadsTable("sound/kartsounds/horn5.mp3");
	AddFileToDownloadsTable("sound/kartsounds/hazzard.mp3");
	AddFileToDownloadsTable("sound/kartsounds/beepbeep.mp3");
	PrecacheSound("kartsounds/horn1.mp3", true);
	PrecacheSound("kartsounds/horn2.mp3", true);
	PrecacheSound("kartsounds/horn3.mp3", true);
	PrecacheSound("kartsounds/horn4.mp3", true);
	PrecacheSound("kartsounds/horn5.mp3", true);
	PrecacheSound("kartsounds/hazzard.mp3", true);
	PrecacheSound("kartsounds/beepbeep.mp3", true);
	
}

public Action:Listener_Voice(client, const String:command[], argc) {
	g_iMedic[client] = false;
	
	decl String:arguments[4];
    GetCmdArgString(arguments, sizeof(arguments));
    
	if (StrEqual(arguments, "0 0") && IsPlayerAlive(client))
	{
		if(TF2_IsPlayerInCondition(client, TFCond:82))
		{
			g_iMedic[client] = true;
			//LastUsed[client] = 0;
			new currentTime = GetTime();
			if (currentTime - LastUsed[client] < 5)
				return Plugin_Handled; // 5 seconds hasn't passed yet, don't allow
				LastUsed[client] = GetTime();
			switch (GetRandomInt(0, 6))
			{
				case 0:
				{
					EmitSoundToAll("kartsounds/horn5.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
				case 1:
				{
					EmitSoundToAll("kartsounds/horn1.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
				case 2:
				{
					EmitSoundToAll("kartsounds/horn2.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
				case 3:
				{
					EmitSoundToAll("kartsounds/beepbeep.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
				case 4:
				{
					EmitSoundToAll("kartsounds/horn3.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
					case 5:
				{
					EmitSoundToAll("kartsounds/horn4.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
				case 6:
				{
					EmitSoundToAll("kartsounds/hazzard.mp3", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,_);
				}
			}				
			if (!TF2_IsPlayerInCondition(client, TFCond:82) && (!g_iMedic[client])) 
				return Plugin_Continue;
			else				
				return Plugin_Handled;
			}
		}
	return Plugin_Continue;
	}