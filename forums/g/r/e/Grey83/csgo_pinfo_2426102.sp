#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.0"
#define PLUGIN_NAME		"[CS:GO] Player info"

ConVar hAuthType = null;
int iAuthType;
AuthIdType AuthType[3] ={
AuthId_Steam2,
AuthId_Steam3,
AuthId_SteamID64
};

public Plugin myinfo =
{
	name				= PLUGIN_NAME,
	author				= "Grey83",
	description			= "Shows player info in the hint & console",
	version				= PLUGIN_VERSION,
	url					= "https://forums.alliedmods.net/showthread.php?t=283701"
};

public void OnPluginStart()
{
	char game[8];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "csgo", false) != 0) SetFailState("Unsupported game!");

	hAuthType = CreateConVar("sm_pinfo_type", "0", "Type of Steam auth string", FCVAR_NONE, true, 0.0, true, 2.0);
	iAuthType = GetConVarInt(hAuthType);
	HookConVarChange(hAuthType, OnConVarChanged);
}

public void OnConVarChanged(Handle hCVar, const char[] oldValue, const char[] newValue)
{
	iAuthType = StringToInt(newValue);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static int iPrevButtons[MAXPLAYERS+1];

	if (IsFakeClient(client)) return Plugin_Continue;

	if ((buttons & IN_USE) && !(iPrevButtons[client] & IN_USE)) OnButtonPressed(client);

	iPrevButtons[client] = buttons;

	return Plugin_Continue;
}

void OnButtonPressed(int client)
{
	int target = GetClientAimTarget(client);
	if (target > 0)
	{
		char SID[18];
		if (!IsFakeClient(target) && GetClientAuthId(target, AuthType[iAuthType], SID, sizeof(SID)))
		{
			PrintHintText(client, "<u>%N</u>\n%s", target, SID);
			PrintToConsole(client, "Player \"%N\"\nSteamID: %s", target, SID);
		}
	}
}