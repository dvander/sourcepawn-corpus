#include <sourcemod>
#include <sdktools>


// edit this

#define MUSIC "music_direcotry/yourmusic.mp3"

// end of configurable part




new bool:lastct_enable = false;

public Plugin:myinfo =
{
	name = "SM Last CT for zvp",
	author = "Franc1sco steam: franug",
	description = "Last CT",
	version = "1.1",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_Round_Start);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	lastct_enable = false;
}

public OnMapStart()
{
	PrecacheSound(MUSIC);

	decl String:download1[128];
	Format(download1, sizeof(download1), "sound/%s",MUSIC);
	AddFileToDownloadsTable(download1);

	CreateTimer(1.0, Checker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Checker(Handle:timer)
{
	if(lastct_enable)
		return Plugin_Continue;

	new cts = 0;
	new terros = 0;
	new lastct = 0;
 	for (new i = 1; i < GetMaxClients(); i++)
  	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{

			if(GetClientTeam(i) == 2)
				terros++;
			else if(GetClientTeam(i) == 3)
			{
				cts++;
				lastct = i;
			}
              	}
  	}

    	if(terros < 1 && cts == 1)
	{
		lastct_enable = true;
		PrintToChatAll("Last CT is enabled");
		GivePlayerItem(lastct, "weapon_m249");
		EmitSoundToAll(MUSIC);
	}

	return Plugin_Continue;
}