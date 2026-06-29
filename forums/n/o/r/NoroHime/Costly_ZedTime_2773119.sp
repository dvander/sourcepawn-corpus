#define PLUGIN_NAME "Costly_ZedTime"

#pragma newdecls required

#include <sourcemod>

#define MAX_MESSAGE_LENGTH 250

native bool BuyItem(int client, int points, const char item[32]);
native int ZedTime(float duration, float timescale);

public Plugin myinfo = {
	name = "Costly ZedTime",
	author = "NoroHime",
	description = "Ctrl+E to buy ZedTime",
	version = "1.0",
};

bool hasTranslations = false;
int AlivedHumanSurvivor = 0;

enum {
	CENTER = 	(1 << 0),
	CHAT =		(1 << 1),
	HINT= 		(1 << 3)
}

public void OnPluginStart() {

	HookEvent("player_team", OnHumanChanged, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", OnHumanChanged, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", OnHumanChanged, EventHookMode_PostNoCopy);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_NAME ... ".phrases");
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	static int buttons_last[MAXPLAYERS + 1];

	bool pressed_use = buttons & IN_USE && !(buttons_last[client] & IN_USE);

	if (pressed_use && (buttons & IN_DUCK) && isAliveHumanSurvivor(client))

		if (BuyItem(client, AlivedHumanSurvivor, "ZedTime")) {
			ZedTime(1.0, 0.0);
			AnnounceAll(CHAT, client, "%t", "Active ZedTime", client);
		}

	buttons_last[client] = buttons;
}

void Announce(int client, int announce_type, const char[] format, any ...) {
	if (!hasTranslations) return;

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 4);
	ReplaceColor(buffer, sizeof(buffer));

	if (announce_type & CHAT)
		PrintToChat(client, "%s", buffer);

	if (announce_type & HINT)
		PrintHintText(client, "%s", buffer);

	if (announce_type & CENTER)
		PrintCenterText(client, "%s", buffer);
}

void AnnounceAll(int announce_type, int excludedClient, const char[] format, any ...) {
	if (!hasTranslations) return;

	char message[MAX_MESSAGE_LENGTH];
	for (int client = 1; client <= MaxClients; client++) {
		if (isHumanClient(client) && excludedClient != client) {
			SetGlobalTransTarget(client);
			VFormat(message, sizeof(message), format, 4);
			Announce(client, announce_type, message);
		}
	}
}

public void OnHumanChanged(Event event, const char[] name, bool dontBroadcast) {

	int alives = 0;
	for (int client = 1; client <= MaxClients; client++)
		if (isAliveHumanSurvivor(client))
			alives++;

	AlivedHumanSurvivor = alives;
}

stock void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock bool isAliveHumanSurvivor(int client){
	return isHumanClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2;
}

stock bool isHumanClient(int client) {
	return isClient(client) && !IsFakeClient(client);
}

stock bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

stock bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}
