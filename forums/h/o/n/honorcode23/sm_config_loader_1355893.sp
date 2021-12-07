#include <sourcemod>

#define GETVERSION "1.0"

//Plugin Info
public Plugin:myinfo = 
{
	name = "Sourcemod Config Loader",
	author = "honorcode23",
	description = "Will make sure that all config files inside the sourcemod folder are executed",
	version = GETVERSION,
	url = "No URL available"
}

public OnPluginStart()
{
	CreateConVar("sm_config_loader_version", GETVERSION, "Version of Sourcemod Config Loader plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_execute_all_configs", CmdReExecute, ADMFLAG_RCON, "Will execute all sourcemod configs again");
}

public Action:CmdReExecute(client, args)
{
	if(ExecuteAllConfigs())
	{
		PrintToChat(client, "[SM] Succesfully executed all configs");
	}
	else
	{
		PrintToChat(client, "[SM] There was a problem executing the configs");
	}
	return Plugin_Handled;
}

public OnMapStart()
{
	ExecuteAllConfigs();
}

stock bool:ExecuteAllConfigs()
{
	new Handle:file = INVALID_HANDLE;
	decl String:FileName[256], String:ConfigName[256];
	BuildPath(Path_SM, FileName, sizeof(FileName), "data/configlist.txt");
	new Float:time = 0.0;
	new len;
	if(!FileExists(FileName))
	{
		LogError("Cannot load the configlist, aborting");
		return false;
	}
	file = OpenFile(FileName, "r");
	if(file == INVALID_HANDLE)
	{
		LogError("Cannot load the configlist, aborting");
		return false;
	}
	
	while(ReadFileLine(file, ConfigName, sizeof(ConfigName)))
	{
		len = strlen(ConfigName);
		if (ConfigName[len-1] == 'n')
		{
			ConfigName[--len] = '0';
		}
		if(StrEqual(ConfigName, ""))
		{
			continue;
		}
		time+=0.1;
		new Handle:pack = CreateDataPack();
		WritePackString(pack, ConfigName);
		CreateTimer(time, ExecuteConfig, pack, TIMER_FLAG_NO_MAPCHANGE);
		if(IsEndOfFile(file))
		{
			break;
		}
	}
	CloseHandle(file);
	return true;
}

public Action:ExecuteConfig(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	decl String:config[256];
	ReadPackString(pack, config, sizeof(config));
	ServerCommand("exec sourcemod/%s", config);
}