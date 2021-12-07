#include <sourcemod>

new g_iMvpOffset = -1;
public Plugin:myinfo = 
{
	name = "MVP Hax",
	author = "Dr!fter",
	description = "Adds native to get/set MVP count",
	version = "1.0.0",
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new Handle:hGameConf = LoadGameConfigFile("mvphax.games");
	if(!hGameConf)
	{
		strcopy(error, err_max, "Failed to load mvphax.games.txt gamedata");
		return APLRes_Failure;
	}
	g_iMvpOffset = GameConfGetOffset(hGameConf, "MVPOffset");
	if(g_iMvpOffset == -1)
	{
		strcopy(error, err_max, "Failed to get MVPOffset");
		return APLRes_Failure;
	}
	RegPluginLibrary("mvphax");
	CreateConVar("mvphax_version", "1.0.0", "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateNative("SetMVPCount", Native_SetMVPCount);
	CreateNative("GetMVPCount", Native_GetMVPCount);
	return APLRes_Success;
}
public Native_SetMVPCount(Handle:hPlugin, iNumParams)
{
	new client = GetNativeCell(1);
	new value = GetNativeCell(2);
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
	}
	SetEntData(client, g_iMvpOffset, value, _, true);
	return 1;
}
public Native_GetMVPCount(Handle:hPlugin, iNumParams)
{
	new client = GetNativeCell(1);
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %i", client);
	}
	return GetEntData(client, g_iMvpOffset);
}