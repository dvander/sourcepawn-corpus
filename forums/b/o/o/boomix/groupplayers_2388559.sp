#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <SteamWorks>
#include <smlib>
#include <autoexecconfig>

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1) && !IsFakeClient(%1))

bool b_InGroup[MAXPLAYERS + 1];

Handle GroupID;
Handle MoneyPerKill;

int iGroupID;
int iMoneyPerKill;

public Plugin myinfo = 
{
	name = "Group players",
	author = PLUGIN_AUTHOR,
	description = "Gives more money for players that are in steam group",
	version = PLUGIN_VERSION,
	url = "http://google.lv"
};

public void OnPluginStart()
{
	AutoExecConfig_SetFile("groupplayers");
	
	HookConVarChange(GroupID 		=	AutoExecConfig_CreateConVar("sm_groupid", "xxxxxxxxxxxxxxxxxx", "Group ID 64"), 								OnCvarChanged);
	HookConVarChange(MoneyPerKill 	=	AutoExecConfig_CreateConVar("sm_moneyperkill", "50", "How much more money per kill, if player is in group"), 	OnCvarChanged);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_death", Event_PlayerDeath);
	
	UpdateConvars();
	
}

public void OnCvarChanged(Handle hConvar, const char[] chOldValue, const char[] chNewValue)
{
	UpdateConvars();
}

public void UpdateConvars()
{
	iGroupID 		= GetConVarInt(GroupID);
	iMoneyPerKill	= GetConVarInt(MoneyPerKill);	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(IsClientInGame(client) && b_InGroup[client])
	{
		int money = Client_GetMoney(client);
		Client_SetMoney(client, money + iMoneyPerKill);
	}
		
}

public void OnClientPutInServer(int client)
{
	b_InGroup[client] = false;
	SteamWorks_GetUserGroupStatus(client, iGroupID);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
	
	int client = GetUserFromAuthID(authid);
	
	if(isMember)
	{
		b_InGroup[client] = true;
	}
	
}

int GetUserFromAuthID(int authid)
{
	
	LoopAllPlayers(i)
	{
		char authstring[50];
		GetClientAuthId(i, AuthId_Steam3, authstring, sizeof(authstring));	
		
		char authstring2[50];
		IntToString(authid, authstring2, sizeof(authstring2));
		
		if(StrContains(authstring, authstring2) != -1)
		{
			return i;
		}
	}
	
	return -1;

}