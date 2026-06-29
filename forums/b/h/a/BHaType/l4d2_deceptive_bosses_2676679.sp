#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[L4D2] Deceptive bosses",
	author = "BHaType",
	description = "Hunter doesn't mean hunter",
	version = "0.0",
	url = "SDKCall"
};

enum struct IInfo
{
	int g_iClass;
	int g_iHealth;
}

IInfo g_iStructInfo[MAXPLAYERS + 1];
Handle g_hSetClass;
bool g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hData = new GameData("l4d2_deceptive_bosses");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSetClass = EndPrepSDKCall();
	
	delete hData;
	
	if (g_bLate)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
			
	HookEvent("ability_use", eSystem);
}

public void eSystem (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (0 < client <= MaxClients && IsClientInGame(client) && g_iStructInfo[client].g_iClass)
	{
		g_iStructInfo[client].g_iHealth = GetClientHealth(client);
		SDKCall(g_hSetClass, client, g_iStructInfo[client].g_iClass);
		SetEntityHealth(client, g_iStructInfo[client].g_iHealth);
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(0.1, tTimer, GetClientUserId(client));
}

public Action tTimer (Handle timer, int client)
{
	client = GetClientOfUserId(client);
	
	if (0 < client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		int iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (iClass == 8)
			return;
		
		int ix16 = GetRandomInt(0, 8);
		
		if (ix16 == 7)
			ix16++;
		
		g_iStructInfo[client].g_iClass = iClass;
		g_iStructInfo[client].g_iHealth = GetClientHealth(client);
		
		SDKCall(g_hSetClass, client, ix16);
		SetEntityHealth(client, g_iStructInfo[client].g_iHealth);
	}
}