#include <sourcemod>

new bool:g_bReady = false;
new Address:g_pGameRules;
new Handle:g_hGameconf = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "GameRulesHax",
	author = "Dr!fter",
	description = "Adds native to get GameRules ptr address",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_hGameconf = LoadGameConfigFile("gameruleshax.games");
	if(!g_hGameconf)
	{
		strcopy(error, err_max, "Failed to load gameruleshax.games.txt gamedata");
		return APLRes_Failure;
	}
	RegPluginLibrary("gameruleshax");
	CreateNative("GetGameRulesPtr", Native_GetGameRulesPtr);
	return APLRes_Success;
}
public OnMapStart()
{
	g_pGameRules = GameConfGetAddress(g_hGameconf, "g_pGameRules");
	if(g_pGameRules != Address_Null)
	{
		g_bReady = true;
	}
	else
	{
		g_bReady = false;
	}
}
public OnMapEnd()
{
	g_bReady = false;
	g_pGameRules = Address_Null;
}
public OnPluginEnd()
{
	if(g_hGameconf)
	{
		CloseHandle(g_hGameconf);
	}
}
public Native_GetGameRulesPtr(Handle:hPlugin, iNumParams)
{
	if(!g_bReady)
	{
		OnMapStart();//Try to get ready
	}
	if(g_bReady)
	{
		return _:g_pGameRules;
	}
	return ThrowNativeError(SP_ERROR_NATIVE, "Plugin not ready! Call this only IN OR AFTER OnMapStart");
}