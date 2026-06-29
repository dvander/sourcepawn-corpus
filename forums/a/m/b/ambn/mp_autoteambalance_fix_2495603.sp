#include <sourcemod>
#define Plugin_Version "1.0"
public Plugin:myinfo = {
	name = "mp_autoteambalance 0",
	author = "noBrain",
	description = "mp_autoteambalance 1 --> 0",
	version = Plugin_Version,
};
ConVar g_convar = null;
public OnPluginStart()
{
	g_convar = FindConVar("mp_autoteambalance");
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}
public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	SetConVarInt(g_convar, 0, true, true);
	return Plugin_Continue;
}