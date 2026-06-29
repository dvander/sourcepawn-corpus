#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <morecolors>

public Plugin myinfo = {
    name = "Admin Chat",
    description = "Admin Chat match",
    author = "",
    version = "1.0",
    url = ""
};

public void OnPluginStart() {
    AddCommandListener(SayHook, "say");
}

public Action SayHook(int client, char[] command, int args) {
    AdminId AdminID = GetUserAdmin(client);
    if (AdminID == view_as<AdminId>(-1)) return Plugin_Continue;

    char Msg[384];
    GetCmdArgString(Msg, sizeof(Msg));
    StripQuotes(Msg);

    CPrintToChatAllEx(client, "{default}[{green}ADMIN{default}] {teamcolor}%s: {default}%s", client, Msg);
    return Plugin_Handled;
}

