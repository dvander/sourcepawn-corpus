#include <sdktools>
#include <cstrike>

bool g_bCanWhistle[MAXPLAYERS+1];

char g_szPrefix[] 						= " \x04\x01\x04[WHISTLE]\x01";
char WHISTLE_FULL_SOUND_PATH[] 			= "sound/zwolof/s_whistle.mp3";
char WHISTLE_RELATIVE_SOUND_PATH[] 		= "*zwolof/s_whistle.mp3";

float fTime = 10.0;

public Plugin myinfo = 
{
	name = "Simple Whistle", 
	author = "zwolof",
	description = "Simple Whistle Plugin",
	version = "1.0",
	url = "https://steamcommunity.com/id/zwolof"
};

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			g_bCanWhistle[i] = true;
}

public OnMapStart()
{
	AddFileToDownloadsTable(WHISTLE_FULL_SOUND_PATH);
	FakePrecacheSound(WHISTLE_RELATIVE_SOUND_PATH);
}

public Action OnPlayerRunCmd(client, &buttons)
{
	if(!IsPlayerAlive(client)) 
		return Plugin_Continue;
		
	if(!IsValidClient(client))
		return Plugin_Continue;
		
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		if(buttons & IN_USE && g_bCanWhistle[client])
		{
			char szName[256];
			GetClientName(client, szName, sizeof(szName));
			
			PrintToChatAll("%s %s has \x04whistled\x01!", g_szPrefix, szName);
			float fVec[3];
			GetClientAbsOrigin(client, fVec);
			fVec[2] += 10;	
		
			EmitAmbientSound(WHISTLE_RELATIVE_SOUND_PATH, fVec, client, SNDLEVEL_RAIDSIREN, _, 0.3);
			g_bCanWhistle[client] = false;
			
			CreateTimer(fTime, RemoveCooldown, client);
		}
	}
	return Plugin_Continue;
}

public Action RemoveCooldown(Handle tmr, int client)
{
	g_bCanWhistle[client] = true;
	PrintToChat(client, "%s You can now \x04whistle\x01 again!", g_szPrefix);
}

stock FakePrecacheSound(const char[] szPath) 
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

stock bool IsValidClient(int client)
{
	if (0 < client && client <= MaxClients && IsClientInGame(client))
		return true;

	return false;
}