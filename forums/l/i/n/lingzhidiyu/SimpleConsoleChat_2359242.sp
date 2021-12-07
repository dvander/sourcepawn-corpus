#include <sourcemod>

public Plugin myinfo = {
	name = "simple console chat",
	author = "lingzhidiyu",
	description = "1111",
	version = "1111",
	url = "1111"
};

public Action OnClientSayCommand(client, const String:command[], const String:sArgs[]) {
	if (client == 0) {
		char szBuffer[256];
		strcopy(szBuffer, 256, sArgs);
		if (StrContains(szBuffer, "(ALL) Console:", true) == 0) {
			ReplaceString(szBuffer, sizeof(szBuffer), "(ALL) Console:", "", true);
		}
		PrintToChatAll(" \x0CMAP INFO:\x04%s", szBuffer);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
