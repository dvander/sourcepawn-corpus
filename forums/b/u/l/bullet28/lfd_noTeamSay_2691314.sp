#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

ConVar cvarIgnoreList;
char ignoreList[16][16];

public Plugin myinfo =
{
	name = "No Team Chat",
	author = "bullet28",
	description = "Redirecting all 'say_team' messages to 'say' in order to remove (Survivor) prefix when it's useless",
	version = "2",
	url = ""
}

public void OnPluginStart() {
	cvarIgnoreList = CreateConVar("noteamsay_ignorelist", "/|@", "Messages starting with this will be ignored, separate by | symbol", FCVAR_NONE);
	cvarIgnoreList.AddChangeHook(OnConVarChange);
	OnConVarChange(null, "", "");
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	char buffer[256];
	cvarIgnoreList.GetString(buffer, sizeof buffer);
	for (int i = 0; i < sizeof ignoreList; i++) ignoreList[i] = "";
	ExplodeString(buffer, "|", ignoreList, sizeof ignoreList, sizeof ignoreList[]);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!StrEqual(command, "say_team", false))
		return Plugin_Continue;

	if (client <= 0)
		return Plugin_Continue;

	char msg[192];
	GetCmdArg(1, msg, sizeof(msg));

	for (int i = 0; i < sizeof ignoreList; i++) {
		if (ignoreList[i][0] != EOS && StrContains(msg, ignoreList[i]) == 0) {
			return Plugin_Continue;
		}
	}
	
	TrimString(msg);

	char buffer[256];
	Format(buffer, sizeof(buffer), "\x03%N\x01 :  %s", client, msg);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			SayText2(i, client, buffer);
		}
	}

	return Plugin_Stop;
}

void SayText2(int client, int sender, const char[] msg) {
	Handle hMessage = StartMessageOne("SayText2", client);
	if (hMessage != null) {
		BfWriteByte(hMessage, sender);
		BfWriteByte(hMessage, true);
		BfWriteString(hMessage, msg);
		EndMessage();
	}
}
