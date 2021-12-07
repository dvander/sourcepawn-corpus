#include <sourcemod>

public Plugin myinfo =
{
	name = "dump_client_cvars",
	author = "Arthurdead",
	description = "Plugin to dump all client convars",
	version = "0.4",
	url = ""
};

ArrayList g_Files = null;
ArrayList g_ClientsBeingDumped = null;
int g_iWaitingForQuery = -1;
Handle g_CommandIter = null;

ConVar sm_dumpcvars_delay = null;

ArrayList invalid_cvars = null;

public void OnPluginStart()
{
	RegAdminCmd("sm_dumpcvars", sm_dumpcvars, ADMFLAG_GENERIC, "dumps client cvars");
	RegAdminCmd("sm_dumpcvars_cancel", sm_dumpcvars_cancel, ADMFLAG_GENERIC, "cancels the current dump");

	sm_dumpcvars_delay = CreateConVar("sm_dumpcvars_delay", "0.0", "delay between each cvar query, 0.0 == disable");

	char folderpath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, folderpath, sizeof(folderpath), "data/client_cvars_dumps");

	if(!DirExists(folderpath, true)) {
		CreateDirectory(folderpath, FPERM_U_READ|FPERM_U_WRITE|FPERM_G_READ|FPERM_G_WRITE, true);
	}

	invalid_cvars = new ArrayList(64);
}

bool IsServerCvar(const char[] cvarname)
{
	return (
	invalid_cvars.FindString(cvarname) != -1 ||
	StrContains(cvarname, "sm_") != -1 ||
	StrContains(cvarname, "sourcemod_") != -1 ||
	StrContains(cvarname, "mm_") != -1 ||
	StrContains(cvarname, "meta_") != -1 ||
	StrContains(cvarname, "metamod_") != -1 ||
	StrContains(cvarname, "tf2items_") != -1 ||
	StrContains(cvarname, "tfecondata_") != -1 ||
	StrContains(cvarname, "tf2attributes_") != -1 ||
	StrContains(cvarname, "sv_") != -1 ||
	StrContains(cvarname, "mp_") != -1 ||
	StrContains(cvarname, "bot_") != -1 ||
	StrContains(cvarname, "tv_") != -1 ||
	StrContains(cvarname, "item_") != -1 ||
	StrContains(cvarname, "log_") != -1 ||
	StrContains(cvarname, "sk_") != -1 ||
	StrContains(cvarname, "ai_") != -1
	);
}

public void OnClientDisconnect(int client)
{
	if(g_ClientsBeingDumped != null) {
		int index = g_ClientsBeingDumped.FindValue(client);
		if(index != -1) {
			PrintToServer("[CVARDUMPS] %N disconnected before cvar dump could finish", client);

			--g_iWaitingForQuery;

			File file = g_Files.Get(index);
			delete file;

			g_Files.Erase(index);
			g_ClientsBeingDumped.Erase(index);

			if(g_ClientsBeingDumped.Length == 0) {
				delete g_ClientsBeingDumped;

				for(int i = 0; i < g_Files.Length; ++i) {
					File hndl = g_Files.Get(i);
					delete hndl;
				}

				delete g_Files;
			}
		}
	}
}

Action Timer_Query(Handle timer, DataPack data)
{
	if(g_ClientsBeingDumped == null) {
		return Plugin_Continue;
	}

	data.Reset();

	int target = data.ReadCell();
	char cvarname[64];
	data.ReadString(cvarname, sizeof(cvarname));

	int index = g_ClientsBeingDumped.FindValue(target);

	++g_iWaitingForQuery;

	QueryClientConVar(target, cvarname, OnConVarQueried, g_Files.Get(index));

	return Plugin_Continue;
}

void OnConVarQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, File file)
{
	if(result == ConVarQuery_Okay) {
		file.WriteLine("%s = %s", cvarName, cvarValue);
		file.Flush();
	} else if(result == ConVarQuery_Protected) {
		file.WriteLine("%s = %s (protected)", cvarName, cvarValue);
		file.Flush();
	} else {
		invalid_cvars.PushString(cvarName);
	}

	--g_iWaitingForQuery;

	if(g_iWaitingForQuery == 0) {
		bool isCommand = false;
		char cvarname[64];

		do {
			if(!FindNextConCommand(g_CommandIter, cvarname, sizeof(cvarname), isCommand)) {
				delete g_ClientsBeingDumped;

				for(int i = 0; i < g_Files.Length; ++i) {
					File hndl = g_Files.Get(i);
					delete hndl;
				}

				delete g_CommandIter;

				delete g_Files;
				return;
			}
		} while(isCommand || IsServerCvar(cvarname));

		float delay = sm_dumpcvars_delay.FloatValue;

		if(delay <= 0.0) {
			++g_iWaitingForQuery;
			QueryClientConVar(client, cvarname, OnConVarQueried, file);
		} else {
			DataPack data = null;
			CreateDataTimer(delay, Timer_Query, data);
			data.WriteCell(client);
			data.WriteString(cvarname);
		}
	}
}

Action sm_dumpcvars_cancel(int client, int args)
{
	if(g_ClientsBeingDumped == null) {
		ReplyToCommand(client, "[SM] theres no cvar dump in-progress");
		return Plugin_Handled;
	}

	g_iWaitingForQuery = 0;

	for(int i = 0; i < g_Files.Length; ++i) {
		File hndl = g_Files.Get(i);
		delete hndl;
	}

	delete g_Files;
	delete g_ClientsBeingDumped;

	ReplyToCommand(client, "[SM] the current cvar dump was canceled");
	return Plugin_Handled;
}

Action sm_dumpcvars(int client, int args)
{
	if(args == 0) {
		ReplyToCommand(client, "[SM] Usage: sm_dumpcvars <filter>....")
		return Plugin_Handled;
	}

	if(g_ClientsBeingDumped != null) {
		ReplyToCommand(client, "[SM] cvars are being dumped right now please wait until it finishes");
		return Plugin_Handled;
	}

	ArrayList players = new ArrayList();

	for(int i = 1; i <= args; ++i) {
		char filter[64];
		GetCmdArg(i, filter, sizeof(filter));

		char name[MAX_TARGET_LENGTH];
		bool isml = false;
		int targets[MAXPLAYERS];
		int count = ProcessTargetString(filter, client, targets, MAXPLAYERS, COMMAND_FILTER_ALIVE, name, sizeof(name), isml);
		if(count == 0) {
			ReplyToTargetError(client, count);
			continue;
		}

		for(int j = 0; j < count; ++j) {
			int target = targets[j];
			players.Push(target);
		}
	}

	bool isCommand = false;
	char cvarname[64];
	g_CommandIter = FindFirstConCommand(cvarname, sizeof(cvarname), isCommand);
	while(isCommand || IsServerCvar(cvarname)) {
		if(!FindNextConCommand(g_CommandIter, cvarname, sizeof(cvarname), isCommand)) {
			delete g_CommandIter;
			delete players;
			return Plugin_Handled;
		}
	}

	g_ClientsBeingDumped = new ArrayList();
	g_Files = new ArrayList();

	g_iWaitingForQuery = players.Length;

	for(int i = 0; i < players.Length; ++i) {
		int target = players.Get(i);

		g_ClientsBeingDumped.Push(target);

		char auth[64];
		GetClientAuthId(target, AuthId_SteamID64, auth, sizeof(auth));

		char filepath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, filepath, sizeof(filepath), "data/client_cvars_dumps/%s.txt", auth);

		File file = OpenFile(filepath, "r+", true);
		if(file == null) {
			file = OpenFile(filepath, "w+", true);
		}

		g_Files.Push(file);

		QueryClientConVar(target, cvarname, OnConVarQueried, file);
	}

	delete players;

	return Plugin_Handled;
}