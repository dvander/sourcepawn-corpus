#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "3.4.2"
#define IMMUNITY 9001

new Handle:v_Enabled = INVALID_HANDLE;
new Handle:v_NameReplay = INVALID_HANDLE;
new Handle:v_NameSTV = INVALID_HANDLE;

new g_ReplayClientID = -1;
new g_SourceTVClientID = -1;

public Plugin:myinfo =
{
	name = "[Any] Immunity4Replay + SourceTV",
	author = "DarthNinja",
	description = "Give your Replay and SourceTV bots some immunity!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("I4R_GetReplayClientID", ReplayClientID);
	CreateNative("I4R_GetSourceTVClientID", SourceTVClientID);

	RegPluginLibrary("Immunity4Replay");
	return APLRes_Success;
}

public ReplayClientID(Handle:plugin, numParams)
{
	return g_ReplayClientID;
}

public SourceTVClientID(Handle:plugin, numParams)
{
	return g_SourceTVClientID;
}

public OnPluginStart()
{
	CreateConVar("sm_i4r_version", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	v_Enabled = CreateConVar("sm_i4r_enable", "1", "Enable/Disable the plugin.", 0, true, 0.0, true, 1.0);

	v_NameReplay = CreateConVar("sm_i4r_replay_name", "replay", "If set to something other then \"replay\", the bot will be renamed to the new value.");
	v_NameSTV = CreateConVar("sm_i4r_sourcetv_name", "sourcetv", "If set to something other then \"sourcetv\", the bot will be renamed to the new value.");

	AutoExecConfig(true, "ReplayImmunity");

	HookConVarChange(v_NameReplay, OnCvarChanged);
	HookConVarChange(v_NameSTV, OnCvarChanged);

	/*
	#####################################
	#	Try to detect bots on late-load	#
	#####################################
	*/
	decl String:SourceTV[MAX_NAME_LENGTH];
	decl String:Replay[MAX_NAME_LENGTH];
	GetConVarString(v_NameReplay, Replay, MAX_NAME_LENGTH);
	GetConVarString(v_NameSTV, SourceTV, MAX_NAME_LENGTH);
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsFakeClient(i))
		{
			continue;
		}

		decl String:name[MAX_NAME_LENGTH];
		GetClientName(i, name, sizeof(name));

		if (g_SourceTVClientID == -1 && (StrEqual(name, SourceTV, false) || StrEqual(name, "sourcetv", false)))
		{
			g_SourceTVClientID = i;
			SetBotImmunity(i);
			SetBotName(i);
		}
		else if (g_ReplayClientID == -1 && (StrEqual(name, Replay, false) || StrEqual(name, "replay", false)))
		{
			g_ReplayClientID = i;
			SetBotImmunity(i);
			SetBotName(i);
		}
	}
}


/*
#################################################
#	Detects and saves bot client IDs on connect	#
#################################################
*/
public OnClientConnected(client)
{
	decl String:SourceTV[MAX_NAME_LENGTH];
	decl String:Replay[MAX_NAME_LENGTH];
	GetConVarString(v_NameReplay, Replay, MAX_NAME_LENGTH);
	GetConVarString(v_NameSTV, SourceTV, MAX_NAME_LENGTH);
	if (!IsFakeClient(client))
	{
		return;
	}
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	// this will always be name at the time of initial connect.
	// if using tv_name or later var for replay name, it renames later in frame
	if (g_SourceTVClientID == -1 && (StrEqual(name, SourceTV, false) || StrEqual(name, "sourcetv", false)))
	{
		g_SourceTVClientID = client;
		return;
	}
	else if (g_ReplayClientID == -1 && (StrEqual(name, Replay, false) || StrEqual(name, "replay", false)))
	{
		g_ReplayClientID = client;
		return;
	}
}


/*
#########################
#	Set bots as admins	#
#########################
*/
public Action:OnClientPreAdminCheck(client)
{
	if (client == g_SourceTVClientID || client == g_ReplayClientID) //This is an extra check since its checked later as well, but screw it
		SetBotImmunity(client);
		//SetBotName(client); This needs to be done later after configs are loaded

	return Plugin_Continue;
}

/*
#############################################
#	Set bots names after configs are loaded	#
#############################################
*/
public OnConfigsExecuted()
{
	if (g_SourceTVClientID != -1)
	{
		SetBotName(g_SourceTVClientID);
	}
	if (g_ReplayClientID != -1)
	{
		SetBotName(g_ReplayClientID);
	}
}
//Also change them if the config cvars are changed later
public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_SourceTVClientID != -1)
	{
		SetBotName(g_SourceTVClientID);
	}
	if (g_ReplayClientID != -1)
	{
		SetBotName(g_ReplayClientID);
	}
}



/*
#############################################
#	Set bot immunity and names respectively	#
#############################################
*/
SetBotImmunity(client)
{
	if (GetConVarBool(v_Enabled))
	{
		new AdminId:admin;

		if (client == g_ReplayClientID) // Replay Bot
		{
			admin = CreateAdmin("Replay");
			SetAdminImmunityLevel(admin, IMMUNITY);
		}
		else // SourceTV Bot
		{
			admin = CreateAdmin("SourceTV");
			SetAdminImmunityLevel(admin, IMMUNITY);
		}
		//SetAdminFlag(admin, Admin_Custom1, true);
		SetUserAdmin(client, admin);
	}
}

SetBotName(client)
{
	if (GetConVarBool(v_Enabled))
	{
		new String:sName[64];
		new String:sNewName[64];
		GetClientName(client, sName, sizeof(sName));

		if (client == g_ReplayClientID)	//Replay
		{
			GetConVarString(v_NameReplay, sNewName, sizeof(sNewName));
		}
		else	//SourceTV
		{
			GetConVarString(v_NameSTV, sNewName, sizeof(sNewName));
		}

		if (!StrEqual(sNewName, sName, true))
		{
			//Names do not match -> rename the bot:
			if (GuessSDKVersion() > SOURCE_SDK_EPISODE1)
				SetClientInfo(client, "name", sNewName);
			else
				ClientCommand(client, "name %s", sNewName);
		}
	}
}

//Clean up ids in case a bot disconnects somehow
public OnClientDisconnect(client)
{
	if (client == g_SourceTVClientID)
	{
		g_SourceTVClientID = -1;
	}
	else if (client == g_ReplayClientID)
	{
		g_ReplayClientID = -1;
	}
}