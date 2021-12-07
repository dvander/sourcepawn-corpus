#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new Handle:g_cLogFlags = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Admin loggin",
	author = "vIr-Dan",
	description = "Logs to admin_name_STEAMID",
	version = PLUGIN_VERSION,
	url = "http://dansbasement.us"
};

public OnPluginStart(){
	CreateConVar("sm_al_version",PLUGIN_VERSION,"The version of 'admin logging' running.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cLogFlags = CreateConVar("sm_al_logflags", "bz", "Set the admin flags you want to log.",FCVAR_PLUGIN);
	AutoExecConfig(true, "sm_admin_logging");
}	

public Action:OnLogAction(Handle:source, 
						   Identity:ident,
						   client,
						   target,
						   const String:message[])
						   
{
	// Get the flags we're allowed to log
	decl String:logFlags[26];
	GetConVarString(g_cLogFlags, logFlags, sizeof(logFlags));
	
	// Get the admin ID
	decl AdminId:adminID;
	if (client > 0)
		adminID = GetUserAdmin(client);
	
	/* If there is no client or they're not an admin, we don't care. */
	if (client < 1 ||  adminID == INVALID_ADMIN_ID || !HasClientFlags(logFlags, client))
	{
		return Plugin_Continue;
	}
	
	// Holds the log tag
	decl String:logtag[64];
	
	/* At the moment extensions can't be passed through here yet, 
	 * so we only bother with plugins, and use "SM" for anything else.
	 */
	if (ident == Identity_Plugin)
	{
		GetPluginFilename(source, logtag, sizeof(logtag));
	} else {
		strcopy(logtag, sizeof(logtag), "SM");
	}
	
	/* ':' is not a valid filesystem token on Windows so we replace 
	 * it with '-' to keep the file names readable.
	 */
	decl String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));
	ReplaceString(steamid, sizeof(steamid), ":", "-");
	
	// Get the admin name and store it in the adminName string
	decl String:adminName[64];
	GetAdminUsername(adminID, adminName, sizeof(adminName));
	
	/* Prefix our file with the word 'admin_' */
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "logs/admin_%s_%s.log", adminName, steamid);
	
	/* Finally, write to the log file with the log tag we deduced. */
	LogToFileEx(file, "[%s] %s", logtag, message);
	
	/* Block Core from re-logging this. */
	return Plugin_Handled;
}

bool:HasClientFlags (const String:flags[], client)
{
	new len = strlen(flags);
	
	if (len == 0)
		return false;
	
	new AdminFlag:flag;
	
	for (new i = 0; i < len; i++)
	{
		if (!FindFlagByChar(flags[i], flag))
			LogError("Ivalid flag detected: %c", flags[i]);
		
		else if ((GetUserFlagBits(client) & FlagToBit(flag)))
			return true;
	}
	return false;
}