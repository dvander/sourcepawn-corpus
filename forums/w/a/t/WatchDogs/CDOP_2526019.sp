#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.4"

#include <sourcemod>
#include <multicolors>

#pragma newdecls required

int PlayersCount;
Handle h_between;
Handle h_cmdslower;
Handle h_cmdshigher;
Handle h_msglower;
Handle h_msghigher;
bool High_Set = false, First_Set = false;

public Plugin myinfo = 
{
	name = "CMDs Depend On Players",
	author = PLUGIN_AUTHOR,
	description = "Run commands when players's count become lower or higher than a value",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	h_between = CreateConVar("sm_cdop_between", "20", "The number of players that plugin checks lower and higher of it to run commands", _, true, 1.0);
	h_cmdslower = CreateConVar("sm_cdop_cmds_lower", "sm_cvar mapcyclefile mapcycle_lite.txt", "Commands that plugin should run when players become lower that between (Separate with ';') ");
	h_cmdshigher = CreateConVar("sm_cdop_cmds_higher", "sm_cvar mapcyclefile mapcycle_full.txt", "Commands that plugin should run when players become higher that between (Separate with ';') ");
	h_msglower = CreateConVar("sm_cdop_msg_lower", "{green}[SM] {default}Players's count is low!", "Message to print in chat when players are lower than between value (Color supported)");
	h_msghigher = CreateConVar("sm_cdop_msg_higher", "{green}[SM] {default}Players's count is high!", "Message to print in chat when players are higher than between value (Color supported)");
	
	PlayersCount = GetClientCount();
	RunCommands();
	
	AutoExecConfig();
}

public void OnConfigsExecuted()
{
	First_Set = false;
	RunCommands();
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client)) PlayersCount++;
	RunCommands();
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client)) PlayersCount--;
	RunCommands();
}

public void RunCommands()
{
	char sCommandsL[256], sCommandsH[256], sMessageL[256], sMessageH[256];
	GetConVarString(h_cmdslower, sCommandsL, sizeof(sCommandsL));
	GetConVarString(h_cmdshigher, sCommandsH, sizeof(sCommandsH));
	GetConVarString(h_msglower, sMessageL, sizeof(sMessageL));
	GetConVarString(h_msghigher, sMessageH, sizeof(sMessageH));
	
	if(PlayersCount < GetConVarInt(h_between)) 
	{ 
		if(High_Set || !First_Set)
		{
			ServerCommand(sCommandsL);
			CPrintToChatAll(sMessageL);
			High_Set = false;
		}
	} 
	else 
	{ 
		if(!High_Set || !First_Set)
		{
			ServerCommand(sCommandsH);
			CPrintToChatAll(sMessageH);
			High_Set = true;
		}
	}
	First_Set = true;
}
