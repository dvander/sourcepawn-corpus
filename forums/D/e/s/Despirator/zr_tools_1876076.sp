#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>

#define PLUGIN_VERSION	"1.6.1"

new Handle:kv;
new Handle:hPlayerClasses, String:sClassPath[PLATFORM_MAX_PATH] = "configs/zr/playerclasses.txt";
new bool:g_RoundEnd = false;

public Plugin:myinfo = 
{
	name = "[ZR] Tools",
	author = "FrozDark",
	description = "Useful tools for Zombie:Reloaded",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ZRT_GetClientClassSectionName", Native_GetClientClassSectionName);
	CreateNative("ZRT_GetClientAttributeString", Native_GetClientAttributeString);
	CreateNative("ZRT_GetClientAttributeValue", Native_GetClientAttributeValue);
	CreateNative("ZRT_GetClientAttributeValueFloat", Native_GetClientAttributeValueFloat);
	CreateNative("ZRT_PlayerHasAttribute", Native_PlayerHasAttribute);
	CreateNative("ZRT_IsRoundActive", Native_IsRoundActive);
	
	RegPluginLibrary("zr_tools");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("zr_tools_version", PLUGIN_VERSION, "Zombie:Reloaded tools plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	RegAdminCmd("zr_tools_reload", Command_Reload, ADMFLAG_ROOT);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public OnAllPluginsLoaded()
{
	if (hPlayerClasses != INVALID_HANDLE)
	{
		UnhookConVarChange(hPlayerClasses, OnClassPathChange);
		CloseHandle(hPlayerClasses);
	}
	if ((hPlayerClasses = FindConVar("zr_config_path_playerclasses")) == INVALID_HANDLE)
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
	HookConVarChange(hPlayerClasses, OnClassPathChange);
}

public OnClassPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(sClassPath, sizeof(sClassPath), newValue);
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	if (kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
	}
	kv = CreateKeyValues("classes");
	
	decl String:buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "%s", sClassPath);
	
	if (!FileToKeyValues(kv, buffer))
	{
		SetFailState("Class data file \"%s\" not found", buffer);
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = false;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundEnd = true;
}

public Action:Command_Reload(client, args)
{
	OnConfigsExecuted();
	return Plugin_Handled;
}

public Native_IsRoundActive(Handle:plugin, numParams)
{
	return !g_RoundEnd;
}

public Native_PlayerHasAttribute(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	ValidateClient(client);
	
	decl String:attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	decl String:className[64], String:buffer[64];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	new bool:result = false;
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				KvGetString(kv, attrib, buffer, sizeof(buffer), "0");
				
				result = bool:(StrContains("yes|1|true", buffer, false) != -1);
				break;
			}
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	return result;
}

public Native_GetClientAttributeString(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	ValidateClient(client);
	
	decl String:attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	decl String:className[64], String:buffer[PLATFORM_MAX_PATH];
	buffer[0] = '\0';
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	new bytes;
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				KvGetString(kv, attrib, buffer, sizeof(buffer), "");
				
				SetNativeString(3, buffer, GetNativeCell(4), true, bytes);
				break;
			}
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	if (!buffer[0])
	{
		GetNativeString(5, buffer, sizeof(buffer));
		SetNativeString(3, buffer, GetNativeCell(4), true, bytes);
	}
	return bytes;
}

public Native_GetClientAttributeValue(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	ValidateClient(client);
	
	decl String:attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	decl String:className[64], String:buffer[PLATFORM_MAX_PATH];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	new result = -1;
	
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				result = KvGetNum(kv, attrib, GetNativeCell(3));
				break;
			}
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	return result;
}

public Native_GetClientAttributeValueFloat(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	ValidateClient(client);
	
	decl String:attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	decl String:className[64], String:buffer[PLATFORM_MAX_PATH];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	new Float:result = -1.0;
	
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				result = KvGetFloat(kv, attrib, Float:GetNativeCell(3));
				break;
			}
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	return _:result;
}

public Native_GetClientClassSectionName(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	ValidateClient(client);
	
	decl String:className[64], String:buffer[64];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	new bytes;
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			KvGetString(kv, "name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				KvGetSectionName(kv, buffer, sizeof(buffer));
				
				SetNativeString(2, buffer, GetNativeCell(3), true, bytes);
				break;
			}
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	return bytes;
}

ValidateClient(client)
{
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return;
	}
}