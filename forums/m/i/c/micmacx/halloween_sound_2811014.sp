#include <sourcemod> 
#include <sdktools> 
#define MAX_FILE_LEN 150
#define PLUGIN_VERSION "1.2"
//===== [ PLUGIN INFO ] ==============
public Plugin:myinfo = 
{
	name = "Halloween Random sound", 
	author = "Micmacx", 
	description = "Play random sounds every 40 seconds", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net"
};
new Handle:h_CvarEnable = INVALID_HANDLE;
new Handle:h_CvarDelay = INVALID_HANDLE;
new Handle:h_CvarVolume = INVALID_HANDLE;
new Handle:h_CvarFolder = INVALID_HANDLE;
new Handle:h_PrecacheTrie = INVALID_HANDLE;
new bool:Download_sounds[MAXPLAYERS + 1];
new String:soundFolder[MAX_FILE_LEN];

char g_sSounds[][] = 
{
	"son1.mp3", 
	"son10.mp3", 
	"son11.mp3", 
	"son12.mp3", 
	"son13.mp3", 
	"son14.mp3", 
	"son15.mp3", 
	"son16.mp3", 
	"son17.mp3", 
	"son18.mp3", 
	"son19.mp3", 
	"son2.mp3", 
	"son20.mp3", 
	"son3.mp3", 
	"son4.mp3", 
	"son5.mp3", 
	"son6.mp3", 
	"son7.mp3", 
	"son8.mp3", 
	"son21.mp3", 
	"son22.mp3", 
	"son23.mp3", 
	"son24.mp3", 
	"son25.mp3", 
	"son26.mp3", 
	"son9.mp3"
};

public OnPluginStart()
{
	CreateConVar("halloween_sounds", PLUGIN_VERSION, "halloween sounds Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	h_CvarEnable = CreateConVar("halloween_sounds_enable", "1", "1 : Enable / 0 : Disable Plugin", FCVAR_REPLICATED | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarDelay = CreateConVar("halloween_sounds_delay", "40.0", "Default time in seconds after playing a sound that another one will be played. Default: 40.0", FCVAR_REPLICATED | FCVAR_NOTIFY, true, 11.0, true, 900.0);
	h_CvarVolume = CreateConVar("halloween_sounds_volume", "1.0", "Default volume of played sounds : 0.0 <= x <= 1.0. Default : 1.0.", FCVAR_REPLICATED | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_CvarFolder = CreateConVar("halloween_sounds_folder", "halloween_mx", "Folder Name in folder sound", FCVAR_REPLICATED | FCVAR_NOTIFY);
	AutoExecConfig(true, "halloween_sounds", "halloween_sounds");
}

public OnClientAuthorized(client, const String:auth[])
{
	if(!IsFakeClient(client))
	{
		QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);
	}
}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if (IsClientConnected(client))
	{
		if (strcmp(cvarValue1, "all", true) == 0)
		{
			Download_sounds[client] = true;
		}
		else
		{
			Download_sounds[client] = false;
		}
	}
}

public void OnMapStart()
{
	if(GetConVarBool(h_CvarEnable))
	{
		GetConVarString(h_CvarFolder, soundFolder, MAX_FILE_LEN);
		decl String:buffer[MAX_FILE_LEN];
		for (int i = 0; i < sizeof(g_sSounds); i++)
		{
			Format(buffer, MAX_FILE_LEN, "sound/%s/%s", soundFolder, g_sSounds[i]); 
			AddFileToDownloadsTable(buffer);
		}
		CreateTimer(10.0, tTimerPrecacheSound, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(GetConVarFloat(h_CvarDelay), tTimerRandomSound, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public Action tTimerPrecacheSound(Handle timer)
{
	decl String:buffer[MAX_FILE_LEN];
	for (int i = 0; i < sizeof(g_sSounds); i++)
	{
		Format(buffer, MAX_FILE_LEN, "%s/%s", soundFolder, g_sSounds[i]); 
		PrecacheSound(buffer, true); // Precache sound file... 
	}
	if (h_PrecacheTrie == INVALID_HANDLE)
	{
		h_PrecacheTrie = CreateTrie();
	}
	else
	{
		ClearTrie(h_PrecacheTrie);
	}
}

public Action tTimerRandomSound(Handle timer)
{
	if(GetConVarBool(h_CvarEnable))
	{
		int random = GetRandomInt(0, sizeof(g_sSounds) - 1);
		decl String:buffer[PLATFORM_MAX_PATH+1];
		Format(buffer, PLATFORM_MAX_PATH+1, "%s/%s", soundFolder, g_sSounds[random]);

		if (h_PrecacheTrie == INVALID_HANDLE)
		{
			h_PrecacheTrie = CreateTrie();
		}
		else
		{
			ClearTrie(h_PrecacheTrie);
		}

		new clientlist[MAXPLAYERS + 1];
		new clientcount = 0;
		new Float:h_volume = GetConVarFloat(h_CvarVolume);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				if (Download_sounds[i])
				{
					clientlist[clientcount] = i;
					clientcount++
				}
			}
		}
		if (clientcount > 0)
		{
			if (PrepareSound(buffer))
			{
				EmitSound(clientlist, clientcount, buffer, _, _, .volume=h_volume);
			}
		}
	}
}

stock bool:PrepareSound(const String:sound[], bool:preload=true)
{
	if (PrecacheSound(sound, preload))
	{
		SetTrieValue(h_PrecacheTrie, sound, true);
		return true;
	}
	else
	{
		return false;
	}
}


bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		return true;
	} else {
		return false;
	}
}
