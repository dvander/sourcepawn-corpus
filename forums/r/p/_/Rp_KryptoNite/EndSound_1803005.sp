#include <sdktools>
#include <sdktools_sound>
#include <sourcemod>
#pragma semicolon 1
#define VERSION "1.1"


new Handle:CvarJoinSoundName;
new Handle:CvarJoinSoundCheck;
new Handle:CvarEndMapSoundName;
new Handle:CvarEndMapSoundCheck;
new Handle:CvarStartRoundSoundName;
new Handle:CvarStartRoundSoundCheck;
new Handle:CvarEndRoundSoundName;
new Handle:CvarEndRoundSoundCheck;

new String:g_JoinSoundName[128];
new String:g_EndMapSoundName[128];
new String:g_StartRoundSoundName[128];
new String:g_EndRoundSoundName[128];
new bool:g_LastRound = false;


public Plugin:myinfo = 
{
	name = "RoundEnd Sound",
	author = "KryptoNite[IL]",
	version = "1.0",
	url = "http://css.vgames.co.il/"
}

public OnPluginStart()
{
	AutoExecConfig(true, "serversounds");
	HookEvent("round_end", RoundEnd);
	CreateConVar("sm_serversounds_version", VERSION, "ServerSounds", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CvarEndMapSoundCheck = CreateConVar("sm_ssendmapsound", "1", "Play sound on map end. 0 -No | 1 -Yes", _, true, 0.0, true, 1.0);
	CvarEndMapSoundName = CreateConVar("sm_ssendmapsoundpath", "mapend/sound.mp3", "Sound played on map end");
}

public OnConfigsExecuted()
{
	GetConVarString(CvarEndMapSoundName, g_EndMapSoundName, sizeof(g_EndMapSoundName));
	decl String:EndMapPath[128];
	PrecacheSound(g_EndMapSoundName, true);
	Format(EndMapPath, sizeof(EndMapPath), "sound/%s", g_EndMapSoundName);
	AddFileToDownloadsTable(EndMapPath);
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(CvarEndMapSoundCheck))
	{
		new timeleft;
		GetMapTimeLeft(timeleft);
		if (timeleft <= 0)
		{
			EmitSoundToAll(g_EndMapSoundName);
			g_LastRound = true;
		}
	}
	if (GetConVarBool(CvarEndRoundSoundCheck))
	{
		if (!g_LastRound)
		{
			EmitSoundToAll(g_EndRoundSoundName);
		}	
	}
}



