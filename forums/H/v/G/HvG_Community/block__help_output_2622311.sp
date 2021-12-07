#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"
public Plugin:myinfo =
{
name = "[CSGO] Block \"!Help\" Text",
author = "Mitch",
description = "one of the recent updates to cs:go added in this feature, with no way of blocking it, until now.",
version = PLUGIN_VERSION,
url = "SnBx.info"
}

public OnPluginStart() {
CreateConVar("sm_savedplayer_version", PLUGIN_VERSION, "[CSGO] Block \"!Help\" Text", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
}

public Action:Event_TextMsg(UserMsg:msg_id, Handle:pb, const players[], playersNum, bool:reliable, bool:init)
{
if(reliable)
{
decl String:text[32];
PbReadString(pb, "params", text, sizeof(text),0);
if (StrContains(text, "console", false) != -1)
return Plugin_Handled;
}
return Plugin_Continue;
}