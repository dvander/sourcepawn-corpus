#include <sourcemod>

ConVar gcv_bPluginEnabled;

public Plugin:myinfo =
{
	name = "Round Message",
	description = "Displays a informational message at every round!",
	author = "LenHard",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public OnPluginStart()
{
	gcv_bPluginEnabled = CreateConVar("lh_round_message", "1", "Enable round message? (1 = YES, 0 = NO)", 0, true, 0.0, false, 0.0);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public Action:Event_RoundStart(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	if (gcv_bPluginEnabled.BoolValue)
	{
		CreateTimer(1.5, Timer_Display);
	}
}

public Action:Timer_Display(Handle:hTimer)
{
	new String:Date[64];
	FormatTime(Date, 64, "%m/%d/%Y", -1);
	new String:Map[64];
	GetCurrentMap(Map, 64);
	new Players = GetClientCount(true);
	new MaxPlayers = GetMaxHumanPlayers();
	PrintToChatAll(" %s%s %sTarih: %s%s %s| %sMap: %s%s %s| %sOyuncular: %s%i%s/%s%i", "\x02", "[Server Bilgi]", "	", "\x04", Date, "\x01", "	", "\x04", Map, "\x01", "	", "\x04", Players, "\x01", "\x04", MaxPlayers);
}