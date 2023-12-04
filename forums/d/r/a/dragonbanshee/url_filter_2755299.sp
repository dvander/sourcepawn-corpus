#include <sourcemod>
#include <regex>

#pragma newdecls required
#pragma semicolon 1

#define VERSION "1.0.0"
#define PATTERN "(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})"

public Plugin myinfo = {
    name = "[ANY] URL Chat Filter",
    description = "Prevents users from sending urls in chat",
    version = VERSION,
    author = "Banshee",
    url = "https://firepowered.org"
};

Regex regex;

public void OnPluginStart() {
    char error[128];
    regex = CompileRegex(PATTERN, 0, error, sizeof(error));
    if (strlen(error) != 0) {
        LogError(error);
    }

    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
}

public Action Command_Say(int client, const char[] command, int argc) {
    char message[256];
    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    TrimString(message);
    
    if (regex == INVALID_HANDLE) {
        if (StrContains(message, "https://", false) != -1 || StrContains(message, "http://", false) != -1) {
            ReplyToCommand(client, "\x04[SM] \x01You are not allowed to send links in chat.");
            return Plugin_Stop;
        }
    } else {
        int captures = regex.Match(message);
        if (captures > 0) {
            ReplyToCommand(client, "\x04[SM] \x01You are not allowed to send links in chat.");
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}
