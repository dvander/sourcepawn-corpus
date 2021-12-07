#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Delayed Execute",
	author = "Axel Juan Nieves",
	description = "Delayed sm_execcfg & sm_exec",
	version = PLUGIN_VERSION,
	url = ""
};


public OnPluginStart()
{
	CreateConVar("sm_dexeccfg_version", PLUGIN_VERSION, "Delayed ExecCfg version", FCVAR_NOTIFY);
	RegAdminCmd("sm_dexeccfg", DExecCfg, ADMFLAG_RCON);
}

public Action:DExecCfg(client, args)
{
	char strCommand[256];
	char strTime[8];
	
	GetCmdArg(1, strCommand, sizeof(strCommand));
	GetCmdArg(2, strTime, sizeof(strCommand));
	float fTime = StringToFloat(strTime);
	
	//instant exec...
	if (fTime<=0.0)
	{
		PrintToServer("[SM_DEXECCFG] Time not specified, or <= 0.0. Executing instantly.");
		ServerCommand("sm_execcfg %s", strCommand);
		return Plugin_Continue;
	}
	DataPack pack;
	CreateDataTimer(fTime, DExecCfg_post, pack);
	pack.WriteString(strCommand);
	return Plugin_Continue;
}

public Action:DExecCfg_post(Handle:time, DataPack pack)
{
	char strCommand[256];
	pack.Reset();
	pack.ReadString(strCommand, sizeof(strCommand));
	ServerCommand("sm_execcfg %s", strCommand);
}