/*
end_sound.sp

Description:
	Plays Music/sound at the end of the map.
        Has a cvar for the filename to play

Versions:
	1.2
		* Initial Release
	
*/


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#pragma semicolon 1
#define MAX_FILE_LEN 255

public Plugin:myinfo = 
{
	name = "Map End Music/Sound",
	author = "TechKnow",
	description = "Plays Music/sound at the end of the map.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:cvarSoundName;
new String:soundFileName[MAX_FILE_LEN];


public OnPluginStart()
{
	CreateConVar("sm_MapEnd_Sound_version", PLUGIN_VERSION, "MapEnd_Sound_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarSoundName = CreateConVar("sm_end_sound", "mapend/end.mp3", "The sound to play at the end of map");
	HookEvent("round_end", EndEvent);

	AutoExecConfig(true, "end_sound");
	OnMapStart();
}


public OnMapStart()
{
	GetConVarString(cvarSoundName, soundFileName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(soundFileName, true);
	Format(buffer, MAX_FILE_LEN, "sound/%s", soundFileName);
	AddFileToDownloadsTable(buffer);
}

public EndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new timeleft;
	GetMapTimeLeft(timeleft);
	if (timeleft <= 0)
        {
               for(new i = 1; i <= GetMaxClients(); i++)
               if(IsClientConnected(i) && !IsFakeClient(i))
	       {
                    decl String:buffer[255];
		    Format(buffer, sizeof(buffer), "play %s", (soundFileName), SNDLEVEL_RAIDSIREN);
	            ClientCommand((i), buffer);
               }
         }
}

public OnEventShutdown()
{
	UnhookEvent("round_end", EndEvent);
}