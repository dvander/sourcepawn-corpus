#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.3"

#define cCastInteger 0
#define cCastFloat 1
#define cCastString 2

new Handle:g_hTrie_MapCvars = INVALID_HANDLE;
new Handle:g_hArray_MapCvars = INVALID_HANDLE;
new Handle:g_hArray_CvarProtected = INVALID_HANDLE;
new Handle:g_hArray_CvarOriginal = INVALID_HANDLE;
new Handle:g_hArray_CvarValues = INVALID_HANDLE;
new Handle:g_hArray_CvarHandles = INVALID_HANDLE;

new bool:g_bFirstLoad = true;
new g_bMapConfigs;
new g_bCvarConfigs;
new String:g_sCurrentMap[256];

public Plugin:myinfo =
{
	name = "KvConfigs",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "A map configuration plugin and convar enforcement system.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("kvconfigs_version", PLUGIN_VERSION, "KvConfigs: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hTrie_MapCvars = CreateTrie();
	g_hArray_MapCvars = CreateArray(2);
	g_hArray_CvarHandles = CreateArray(2);
	g_hArray_CvarProtected = CreateArray(13);
	g_hArray_CvarOriginal = CreateArray(12);
	g_hArray_CvarValues = CreateArray(12);
	
	RegAdminCmd("kv_reloadmaps", Command_ReloadMaps, ADMFLAG_ROOT);
	RegAdminCmd("kv_reloadcvars", Command_ReloadCvars, ADMFLAG_ROOT);
	RegAdminCmd("kv_setprotected", Command_SetProtected, ADMFLAG_RCON, "[KvConfigs] Sets a protected cvar to the provided value. Protected CVARs cannot be changed outside of this command. Reset on kv_reloadcvars.");
	RegAdminCmd("kv_remprotected", Command_RemProtected, ADMFLAG_RCON, "[KvConfigs] Removes a protected cvar from protection array.");
}

public OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

public OnConfigsExecuted()
{
	if(g_bFirstLoad)
	{
		ReadMapConfigs();
		ReadCvarConfigs();

		g_bFirstLoad = false;
	}

	new iIndex;
	if(!GetTrieValue(g_hTrie_MapCvars, g_sCurrentMap, iIndex))
		return;

	decl String:sBuffer[256];
	decl String:sTemp[256];
	if(GetArraySize(g_hArray_MapCvars) > 0)
	{
		new Handle:hCvar = Handle:GetArrayCell(g_hArray_MapCvars, iIndex, 0);
		new Handle:hAction = Handle:GetArrayCell(g_hArray_MapCvars, iIndex, 1);

		new iSize = GetArraySize(hCvar);
		for(new i = 0; i < iSize; i++)
		{
			GetArrayString(hCvar, i, sBuffer, sizeof(sBuffer));
			GetArrayString(hAction, i, sTemp, sizeof(sTemp));

			ServerCommand("%s %s", sBuffer, sTemp);
		}
	}
}

ReadMapConfigs()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/kvconfigs.maps.ini");

	g_bMapConfigs = false;
	new iSize, Handle:hKeyValues = CreateKeyValues("KvConfigs.Maps");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
	{
		g_bMapConfigs = true;

		do
		{
			iSize = GetArraySize(g_hArray_MapCvars);
			KvGetSectionName(hKeyValues, sPath, sizeof(sPath));
				
			SetTrieValue(g_hTrie_MapCvars, sPath, iSize);
			ResizeArray(g_hArray_MapCvars, iSize + 1);

			new Handle:hCvar = CreateArray(64);
			new Handle:hAction = CreateArray(64);

			if(KvGotoFirstSubKey(hKeyValues, false))
			{
				do
				{
					KvGetSectionName(hKeyValues, sPath, sizeof(sPath));
					PushArrayString(hCvar, sPath);

					KvGetString(hKeyValues, NULL_STRING, sPath, sizeof(sPath));
					PushArrayString(hAction, sPath);
				}
				while (KvGotoNextKey(hKeyValues, false));
				KvGoBack(hKeyValues);
			}

			SetArrayCell(g_hArray_MapCvars, iSize, hCvar, 0);
			SetArrayCell(g_hArray_MapCvars, iSize, hAction, 1);
		}
		while (KvGotoNextKey(hKeyValues));

		CloseHandle(hKeyValues);
	}
	
	return iSize;
}

ReadCvarConfigs()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/kvconfigs.cvars.ini");

	g_bCvarConfigs = false;
	new iSize, Handle:hKeyValues = CreateKeyValues("KvConfigs.Cvars");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues, false))
	{
		g_bCvarConfigs = true;

		new String:sValue[48];
		new String:sBuffer[48];
		do
		{
			do
			{
				KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));

				new Handle:hTemp = FindConVar(sBuffer);
				if(hTemp != INVALID_HANDLE)
				{
					HookConVarChange(hTemp, OnRestrictChange);

					iSize = GetArraySize(g_hArray_CvarProtected);
					ResizeArray(g_hArray_CvarProtected, iSize + 1);
					ResizeArray(g_hArray_CvarHandles, iSize + 1);
					ResizeArray(g_hArray_CvarOriginal, iSize + 1);
					ResizeArray(g_hArray_CvarValues, iSize + 1);

					SetArrayString(g_hArray_CvarProtected, iSize, sBuffer);

					KvGetString(hKeyValues, NULL_STRING, sValue, sizeof(sValue));
					if(StrContains(sBuffer, ".") != -1)
					{
						SetArrayCell(g_hArray_CvarHandles, iSize, hTemp, 0);
						SetArrayCell(g_hArray_CvarHandles, iSize, cCastFloat, 1);

						new Float:fBuffer = StringToFloat(sValue);
						SetArrayCell(g_hArray_CvarValues, iSize, fBuffer);


						SetArrayCell(g_hArray_CvarProtected, iSize, cCastFloat, 12);
						SetArrayCell(g_hArray_CvarOriginal, iSize, GetConVarFloat(hTemp));
						SetConVarFloat(hTemp, fBuffer);
					}
					else if(IsCharNumeric(sValue[0]))
					{
						SetArrayCell(g_hArray_CvarHandles, iSize, hTemp, 0);
						SetArrayCell(g_hArray_CvarHandles, iSize, cCastInteger, 1);

						KvGetString(hKeyValues, NULL_STRING, sValue, sizeof(sValue));
						new iBuffer = StringToInt(sValue);
						SetArrayCell(g_hArray_CvarValues, iSize, iBuffer);

						SetArrayCell(g_hArray_CvarProtected, iSize, cCastInteger, 12);
						SetArrayCell(g_hArray_CvarOriginal, iSize, GetConVarInt(hTemp));
						SetConVarInt(hTemp, iBuffer);
					}
					else
					{
						SetArrayCell(g_hArray_CvarHandles, iSize, hTemp, 0);
						SetArrayCell(g_hArray_CvarHandles, iSize, cCastString, 1);

						KvGetString(hKeyValues, NULL_STRING, sValue, sizeof(sValue));
						SetArrayString(g_hArray_CvarValues, iSize, sValue);

						SetArrayCell(g_hArray_CvarProtected, iSize, cCastString, 12);
						SetArrayString(g_hArray_CvarOriginal, iSize, sValue);
						SetConVarString(hTemp, sValue);
					}
				}
			}
			while(KvGotoNextKey(hKeyValues, false));

			KvGoBack(hKeyValues);
		}
		while (KvGotoNextKey(hKeyValues));
	}
	
	return iSize;
}

public OnRestrictChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	decl String:sBuffer[64];
	new Float:fBuffer, iBuffer;
	new iSize = GetArraySize(g_hArray_CvarHandles);
	for(new i = 0; i < iSize; i++)
	{
		new Handle:hTemp = GetArrayCell(g_hArray_CvarHandles, i, 0);
		if(hTemp == cvar)
		{
			GetArrayString(g_hArray_CvarProtected, i, sBuffer, sizeof(sBuffer));

			switch(GetArrayCell(g_hArray_CvarHandles, i, 1))
			{
				case cCastFloat:
				{
					fBuffer = Float:GetArrayCell(g_hArray_CvarValues, i);
					if(fBuffer != StringToFloat(newvalue))
						SetConVarFloat(hTemp, fBuffer);
				}
				case cCastInteger:
				{
					iBuffer = GetArrayCell(g_hArray_CvarValues, i);
					if(iBuffer != StringToInt(newvalue))
						SetConVarInt(hTemp, iBuffer);
				}
				case cCastString:
				{
					decl String:sValue[64];
					GetArrayString(g_hArray_CvarValues, i, sValue, sizeof(sValue));
					if(!StrEqual(sValue, sBuffer))
						SetConVarString(hTemp, sValue);
				}
			}

			break;
		}
	}
}

public Action:Command_ReloadMaps(client, args)
{
	new iSize = GetArraySize(g_hArray_MapCvars);
	for(new i = 0; i < iSize; i++)
	{
		CloseHandle(Handle:GetArrayCell(g_hArray_MapCvars, i, 0));
		CloseHandle(Handle:GetArrayCell(g_hArray_MapCvars, i, 1));
	}

	ClearTrie(g_hTrie_MapCvars);
	ClearArray(g_hArray_MapCvars);

	new iTemp = ReadMapConfigs();
	if(!g_bMapConfigs)
		ReplyToCommand(client, "[SM] Configuration \"kvconfigs.maps.ini\" not found!");
	else
		ReplyToCommand(client, "[SM] Map Configuration Reloaded - %d Maps Found!", iTemp);

	return Plugin_Handled;
}

public Action:Command_ReloadCvars(client, args)
{
	new iMax = GetArraySize(g_hArray_CvarHandles);
	for(new i = 0; i < iMax; i++)
	{
		new Handle:hTemp = Handle:GetArrayCell(g_hArray_CvarHandles, i, 0);
		CloseHandle(hTemp);
	}

	ClearArray(g_hArray_CvarHandles);
	ClearArray(g_hArray_CvarProtected);
	ClearArray(g_hArray_CvarOriginal);
	ClearArray(g_hArray_CvarValues);

	new iTemp = ReadCvarConfigs();
	if(!g_bCvarConfigs)
		ReplyToCommand(client, "[SM] Configuration \"kvconfigs.cvars.ini\" not found!");
	else
		ReplyToCommand(client, "[SM] Cvar Configuration Reloaded - %d Maps Found!", iTemp);

	return Plugin_Handled;
}

public Action:Command_SetProtected(client, args)
{
	if(!g_bCvarConfigs)
	{
		ReplyToCommand(client, "[SM] Configuration \"kvconfigs.cvars.ini\" not found!");
		return Plugin_Handled;
	}

	if(args < 2)
	{
		ReplyToCommand(client, "Usage: kv_setprotected <cvar> <value>");
		return Plugin_Handled;
	}

	new iBreak;
	decl String:sText[192], String:sBuffer[48], String:sValue[16], String:sCvar[48];
	GetCmdArgString(sText, sizeof(sText));
	if((iBreak = BreakString(sText, sCvar, sizeof(sCvar))) == -1)
	{
		ReplyToCommand(client, "Usage: kv_setprotected <cvar> <value>");
		return Plugin_Handled;
	}
	BreakString(sText[iBreak], sValue, sizeof(sValue));

	new iBuffer, Float:fBuffer;
	new bool:bFound, iSize = GetArraySize(g_hArray_CvarProtected);
	for(new i = 0; i < iSize; i++)
	{
		GetArrayString(g_hArray_CvarProtected, i, sBuffer, sizeof(sBuffer));
		if(!StrEqual(sCvar, sBuffer, false))
			continue;

		switch(GetArrayCell(g_hArray_CvarProtected, i, 12))
		{
			case cCastFloat:
			{
				fBuffer = StringToFloat(sValue);
				SetArrayCell(g_hArray_CvarValues, i, fBuffer);
				SetConVarFloat(GetArrayCell(g_hArray_CvarHandles, i, 0), fBuffer);

				ReplyToCommand(client, "[KvConfigs] Protected ConVar %s has had its default value changed to %f.", sBuffer, fBuffer);
			}
			case cCastInteger:
			{
				iBuffer = StringToInt(sValue);
				SetArrayCell(g_hArray_CvarValues, i, iBuffer);
				SetConVarInt(GetArrayCell(g_hArray_CvarHandles, i, 0), iBuffer);

				ReplyToCommand(client, "[KvConfigs] Protected ConVar %s has had its default value changed to %d.", sBuffer, iBuffer);
			}
			case cCastString:
			{
				iBuffer = StringToInt(sValue);
				SetArrayString(g_hArray_CvarValues, i, sValue);
				SetConVarInt(GetArrayCell(g_hArray_CvarHandles, i, 0), iBuffer);

				ReplyToCommand(client, "[KvConfigs] Protected ConVar %s has had its default value changed to %s.", sBuffer, sValue);
			}
		}

		break;
	}

	if(!bFound)
	{
		new Handle:hTemp = FindConVar(sCvar);
		if(hTemp != INVALID_HANDLE)
		{
			ResizeArray(g_hArray_CvarProtected, iSize + 1);
			ResizeArray(g_hArray_CvarHandles, iSize + 1);
			ResizeArray(g_hArray_CvarValues, iSize + 1);
			ResizeArray(g_hArray_CvarOriginal, iSize + 1);

			SetArrayString(g_hArray_CvarProtected, iSize, sCvar);
			SetArrayCell(g_hArray_CvarHandles, iSize, hTemp, 0);
			if(StrContains(sValue, ".") != -1)
			{
				SetArrayCell(g_hArray_CvarHandles, iSize, cCastFloat, 1);

				fBuffer = StringToFloat(sValue);
				SetArrayCell(g_hArray_CvarValues, iSize, fBuffer);
				SetArrayCell(g_hArray_CvarProtected, iSize, cCastFloat, 12);

				SetArrayCell(g_hArray_CvarOriginal, iSize, GetConVarFloat(hTemp));
				SetConVarFloat(hTemp, fBuffer);

				ReplyToCommand(client, "[KvConfigs] Added ConVar %s to the Protected array with a value of %f.", sCvar, fBuffer);
			}
			else if(IsCharNumeric(sValue[0]))
			{
				SetArrayCell(g_hArray_CvarHandles, iSize, cCastInteger, 1);

				iBuffer = StringToInt(sValue);
				SetArrayCell(g_hArray_CvarValues, iSize, iBuffer);
				SetArrayCell(g_hArray_CvarProtected, iSize, cCastInteger, 12);

				SetArrayCell(g_hArray_CvarOriginal, iSize, GetConVarInt(hTemp));
				SetConVarInt(hTemp, iBuffer);

				ReplyToCommand(client, "[KvConfigs] Added ConVar %s to the Protected array with a value of %d.", sCvar, iBuffer);
			}
			else
			{
				SetArrayCell(g_hArray_CvarHandles, iSize, cCastString, 1);

				SetArrayString(g_hArray_CvarValues, iSize, sValue);
				SetArrayCell(g_hArray_CvarProtected, iSize, cCastString, 12);

				SetArrayString(g_hArray_CvarOriginal, iSize, sValue);
				SetConVarString(hTemp, sValue);

				ReplyToCommand(client, "[KvConfigs] Added ConVar %s to the Protected array with a value of %s.", sCvar, sValue);
			}


			HookConVarChange(hTemp, OnRestrictChange);
		}
		else
			ReplyToCommand(client, "[KvConfigs] Could not add ConVar %s to the Protected array as it doesn't exist in the engine!", sCvar);
	}

	return Plugin_Handled;
}

public Action:Command_RemProtected(client, args)
{
	if(!g_bCvarConfigs)
	{
		ReplyToCommand(client, "[SM] Configuration \"kvconfigs.cvars.ini\" not found!");
		return Plugin_Handled;
	}

	if(args < 1)
	{
		ReplyToCommand(client, "Usage: kv_remprotected <cvar>");
		return Plugin_Handled;
	}

	decl String:sText[192], String:sBuffer[48], String:sCvar[48];
	GetCmdArgString(sText, sizeof(sText));
	BreakString(sText, sCvar, sizeof(sCvar));

	new bool:bFound, iSize = GetArraySize(g_hArray_CvarProtected);
	for(new i = 0; i < iSize; i++)
	{
		GetArrayString(g_hArray_CvarProtected, i, sBuffer, sizeof(sBuffer));
		if(!StrEqual(sCvar, sBuffer, false))
			continue;

		bFound = true;
		new Handle:hTemp = Handle:GetArrayCell(g_hArray_CvarHandles, i, 0);
		UnhookConVarChange(hTemp, OnRestrictChange);

		switch(GetArrayCell(g_hArray_CvarProtected, i, 12))
		{
			case cCastFloat:
				SetConVarFloat(hTemp, Float:GetArrayCell(g_hArray_CvarOriginal, i));
			case cCastInteger:
				SetConVarInt(hTemp, GetArrayCell(g_hArray_CvarOriginal, i));
			case cCastString:
			{
				decl String:sValue[64];
				GetArrayString(g_hArray_CvarOriginal, i, sValue, sizeof(sValue));
				SetConVarString(hTemp, sValue);
			}
		}

		RemoveFromArray(g_hArray_CvarProtected, i);
		RemoveFromArray(g_hArray_CvarHandles, i);
		RemoveFromArray(g_hArray_CvarOriginal, i);
		RemoveFromArray(g_hArray_CvarValues, i);

		ReplyToCommand(client, "[KvConfigs] Removed ConVar %s from the Protected array; it will no longer have its value reset!", sCvar);
		CloseHandle(hTemp);
		break;
	}

	if(!bFound)
		ReplyToCommand(client, "[KvConfigs] Could not remove ConVar %s from the Protected array as it doesn't exist in the engine!", sCvar);

	return Plugin_Handled;
}