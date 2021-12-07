#include <sourcemod>
#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = {
	name = "[ANY] Rcon Password Protect",
	author = "DarthNinja",
	description = "Prevents access to the rcon password via sm_rcon and sm_cvar",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_rpp_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddCommandListener(CheckCMDString, "sm_cvar");
	AddCommandListener(CheckCMDString, "sm_rcon");
}

public Action:CheckCMDString(client, const String:command[], argc)
{  
	decl String:sCMD[1024];
	GetCmdArgString(sCMD, sizeof(sCMD));
	
	if (StrContains(sCMD, "rcon_password", false) != -1)
	{
		decl String:file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), "logs/RCON_PASSWORD_EXPLOITS.log");
		
		GetCmdArg(0, sCMD, sizeof(sCMD));
		if (StrEqual(sCMD, "sm_rcon", false))
			LogToFile(file, "%L attempted to access the rcon password using sm_rcon", client);
		else
			LogToFile(file, "%L attempted to access the rcon password using sm_cvar", client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
