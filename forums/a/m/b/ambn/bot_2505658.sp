#include <sourcemod>
ConVar g_mBot = null;
public void OnPluginStart()
{
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	g_mBot = CreateConVar("sm_max_bot", "0")
}
public Action RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	int BotNum = GetConVarInt(g_mBot);
	ServerCommand("bot_quota %d", BotNum);
}