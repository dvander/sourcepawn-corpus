#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.0"

public Plugin myinfo =  {
	name = "Web Shortcuts",
	author = "James \"sslice\" Gray",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://www.steamfriends.com/"
};

ArrayList g_Shortcuts;
ArrayList g_Titles;
ArrayList g_Links;

char g_ServerIp [32];
char g_ServerPort [16];

public void OnPluginStart() {
	CreateConVar("sm_webshortcuts_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED);

	RegConsoleCmd("say", OnSay);
	RegConsoleCmd("say_team", OnSay);

	g_Shortcuts = new ArrayList(32);
	g_Titles = new ArrayList(64);
	g_Links = new ArrayList(512);

	int hostip = FindConVar("hostip").IntValue;
	FormatEx(
		  g_ServerIp
		, sizeof(g_ServerIp)
		, "%u.%u.%u.%u"
		, (hostip >> 24) & 0x000000FF
		, (hostip >> 16) & 0x000000FF
		, (hostip >> 8) & 0x000000FF
		, hostip & 0x000000FF
	);

	FindConVar("hostport").GetString(g_ServerPort, sizeof(g_ServerPort));

	LoadWebshortcuts();
}

public void OnMapEnd() {
	LoadWebshortcuts();
}

public Action OnSay(int client, int args) {
	char text [512];
	GetCmdArgString(text, sizeof(text));

	int start;
	int len = strlen(text);

	if (len < 1) {
		return Plugin_Handled;
	}

	if (text[len-1] == '"') {
		text[len-1] = '\0';
		start = 1;
	}

	char shortcut [32];
	BreakString(text[start], shortcut, sizeof(shortcut));

	int size = g_Shortcuts.Length;
	for (int i = 0; i != size; ++i) {
		g_Shortcuts.GetString(i, text, sizeof(text));

		if (strcmp(shortcut, text, false) == 0) {
			char title [64];
			char steamId [64];
			char userId [16];
			char name [64];
			char clientIp [32];

			g_Titles.GetString(i, title, sizeof(title));
			g_Links.GetString(i, text, sizeof(text));

			GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
			FormatEx(userId, sizeof(userId), "%u", GetClientUserId(client));
			GetClientName(client, name, sizeof(name));
			GetClientIP(client, clientIp, sizeof(clientIp));

			len = sizeof(title);
			ReplaceString(title, len, "{SERVER_IP}", g_ServerIp);
			ReplaceString(title, len, "{SERVER_PORT}", g_ServerPort);
			ReplaceString(title, len, "{STEAM_ID}", steamId);
			ReplaceString(title, len, "{USER_ID}", userId);
			ReplaceString(title, len, "{NAME}", name);
			ReplaceString(title, len, "{IP}", clientIp);

			len = sizeof(text);
			ReplaceString(text, len, "{SERVER_IP}", g_ServerIp);
			ReplaceString(text, len, "{SERVER_PORT}", g_ServerPort);
			ReplaceString(text, len, "{STEAM_ID}", steamId);
			ReplaceString(text, len, "{USER_ID}", userId);
			ReplaceString(text, len, "{NAME}", name);
			ReplaceString(text, len, "{IP}", clientIp);			

			ShowMOTDPanel(client, title, text, MOTDPANEL_TYPE_URL);
		}
	}

	return Plugin_Continue;
}

void LoadWebshortcuts() {
	char buffer [1024];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt");

	if (!FileExists(buffer)) {
		return;
	}

	File f = OpenFile(buffer, "r");
	if (f == null) {
		LogError("[SM] Could not open file: %s", buffer);
		return;
	}

	g_Shortcuts.Clear();
	g_Titles.Clear();
	g_Links.Clear();

	char shortcut [32];
	char title [64];
	char link [512];
	while (!f.EndOfFile() && f.ReadLine(buffer, sizeof(buffer))) {
		TrimString(buffer);
		if (buffer[0] == '\0' || buffer[0] == ';' || (buffer[0] == '/' && buffer[1] == '/')) {
			continue;
		}

		int pos = BreakString(buffer, shortcut, sizeof(shortcut));
		if (pos == -1) {
			continue;
		}

		int linkPos = BreakString(buffer[pos], title, sizeof(title));
		if (linkPos == -1) {
			continue;
		}

		strcopy(link, sizeof(link), buffer[linkPos+pos]);
		TrimString(link);

		g_Shortcuts.PushString(shortcut);
		g_Titles.PushString(title);
		g_Links.PushString(link);
	}

	delete f;
}