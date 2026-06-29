#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <smlib>
#include <emitsoundany>
#include <cstrike>

#define Prefix "CARNAGE"
#pragma newdecls required

int g_Carnage;
int g_Round;

bool g_NoScope = false;

public Plugin myinfo = 
{
	name = "[CSGO] Carnage Round", 
	author = "Elitcky", 
	description = "Normal carnage rounds", 
	version = "1.00", 
	url = "http://steamcommunity.com/id/stormsmurf2"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("weapon_zoom", Fun_EventWeaponZoom, EventHookMode_Post);
	
	RegConsoleCmd("sm_carnage", CMD_MENSAJECARNAGE);
	RegConsoleCmd("sm_awp", CMD_AWP);
	RegConsoleCmd("sm_forcecarnage", CMD_TEST);
	
	CreateConVar("carnage_round", "5");
	
}

public void OnMapStart()
{
	AddFilesFromFolder("sound/misc/carnageround/");
	
	// COUNT SOUND 1
	PrecacheSoundAny("*misc/carnageround/ronda_carnageR.mp3");
	PrecacheSoundAny("*misc/carnageround/ronda_carnage2R.mp3");
	
	g_Round = 0;
}

public void OnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_NoScope = false;
	g_Carnage = 0;
	g_Round++;
	
	if (g_Round == 5)
	{
		g_Carnage = 1;
		g_Round = 0;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	if (g_Carnage)
	{
		CPrintToChat(client, "{green}[%s] {default}CARNAGE ROUND!!!", Prefix);
	}
	else
	{ 
		int g_RestaRound = 5 - g_Round;
		CPrintToChat(client, "{green}[%s] {default}%d Rounds left for carnage.", Prefix, g_RestaRound);
	}
}

public void OnRoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	/*
	if (g_Round + 1 == 5)
	{
		//something
	}
	*/
	
	if (g_Carnage)
	{
		//NO SCOPE
		g_NoScope = false;
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	if (IsPlayerAlive(client))
	{
		CreateTimer(2.0, chequear_carnage, client + 100);
	}
}

public Action Fun_EventWeaponZoom(Handle hEvent, const char[] name, bool bDontBroadcast) {
	
	if (g_NoScope) {
		
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			int ent = GetPlayerWeaponSlot(client, 0);
			CS_DropWeapon(client, ent, true, true);
			PrintToChat(client, "Is NO-SCOPE MODE! Don't try to zoom in.)");
		}
	}
	
}

public Action CMD_TEST(int client, int args)
{
	if (CheckCommandAccess(client, "", ADMFLAG_ROOT))  
	{
		g_Carnage = 1;
		g_Round = 0;
		
		if (IsPlayerAlive(client))
		{
			CreateTimer(2.0, chequear_carnage, client + 100);
		}
	}
	else
	{
		CPrintToChat(client, "{green}[%s] {default} You are not admin for use this command.", Prefix);
	}
}

public Action CMD_AWP(int client, int args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if (g_Carnage) //Si es carnage le informamos q carnage es y si es only headshoot
		{
			g_NoScope = true;
			
			CPrintToChat(client, "{green}[%s] {default} YOU RECEIVED AN {green}AWP", Prefix);
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
		}
		else
		{
			CPrintToChat(client, "{green}[%s] {default} Not carnage round yet.", Prefix);
		}
	}
}

public Action CMD_MENSAJECARNAGE(int client, int args)
{
	if (g_Carnage) //Si es carnage le informamos q carnage es y si es only headshoot
	{
		CPrintToChat(client, "{green}[%s] {default}CARNAGE ROUND!!!", Prefix);
	}
	else
	{ 
		int g_RestaRound = 5 - g_Round;
		CPrintToChat(client, "{green}[%s] {default}%d Rounds left for carnage.", Prefix, g_RestaRound);
	}
}

public Action chequear_carnage(Handle timer, int client)
{
	if (!g_Carnage)
		return 
	
	client -= 100;
	
	int weapon = -1;
	for (int i = 0; i <= 5; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	}
	
	CreateTimer(1.0, AVISO_1);
	CreateTimer(2.0, AVISO_2);
	CreateTimer(3.0, AVISO_3);
	CreateTimer(3.5, DAR_ARMAS);
}

public Action AVISO_1(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}CARNAGE ROUND IN {green}3", Prefix);
}

public Action AVISO_2(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}CARNAGE ROUND IN {green}2", Prefix);
}

public Action AVISO_3(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}CARNAGE ROUND IN {green}1", Prefix);
}

public Action DAR_ARMAS(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			g_NoScope = true;
			
			CPrintToChat(client, "{green}[%s] {default} YOU RECEIVED AN {green}AWP", Prefix);
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
			
			//Mostramos un hud para informar que es carnage
			CPrintToChatAll("{green}[%s] {default}IS CARNAGE ROUND", Prefix);
			CPrintToChatAll("{green}[%s] {default}IS CARNAGE ROUND", Prefix);
			CPrintToChatAll("{green}[%s] {default}IS CARNAGE ROUND", Prefix);
			
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					ClientCommand(client, "play *misc/carnageround/ronda_carnageR.mp3");
				}
				case 2:
				{
					ClientCommand(client, "play *misc/carnageround/ronda_carnage2R.mp3");
				}
			}
		}
	}
}

void AddFilesFromFolder(char path[PLATFORM_MAX_PATH])
{
	DirectoryListing dir = OpenDirectory(path, true);
	if (dir != INVALID_HANDLE)
	{
		PrintToServer("Success directory!!!");
		char buffer[PLATFORM_MAX_PATH];
		FileType type;
		
		while (dir.GetNext(buffer, PLATFORM_MAX_PATH, type))
		{
			if (type == FileType_File && (StrContains(buffer, ".mp3", false) != -1 || (StrContains(buffer, ".wav", false) != -1)) && !(StrContains(buffer, ".ztmp", false) != -1))
			{
				//Here you can precache sounds for everyfile checked, buffer is the full name of the file checked, (example: music.mp3)
				AddFileToDownloadsTable("sound/misc/carnageround/ronda_carnageR.mp3");
				AddFileToDownloadsTable("sound/misc/carnageround/ronda_carnage2R.mp3");
			}
		}
	}
} 