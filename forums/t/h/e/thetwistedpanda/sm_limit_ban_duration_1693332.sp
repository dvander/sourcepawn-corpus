/*
	Revision 1.0.2
	-=-=-=-=-=-=-
	Added an option for -1 index parameter in natives, which will reference the perma ban entry.
	Updated LBD_Basebans & LBD_Sourcebans to have support for perma ban options.

	Notice: 
	-=-=-=-=-=-=-
	Requires sm_limit_ban_duration to recompile.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sm_limit_ban_duration>
#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>

#if !defined _sourcebans_included
	native SBBanPlayer(client, target, time, String:reason[]);
#endif

#define PLUGIN_VERSION "1.0.2"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hReduce = INVALID_HANDLE;
new Handle:g_hMaximum = INVALID_HANDLE;

new bool:g_bDurationRestricted[MAX_BAN_DURATIONS], bool:g_bPermRestricted;
new g_iDurationLength[MAX_BAN_DURATIONS];
new g_iDurationTotalFlags[MAX_BAN_DURATIONS], g_iPermTotalFlags;
new g_iDurationFlags[MAX_BAN_DURATIONS][24], g_iPermFlags[24];
new String:g_sDurationOverride[MAX_BAN_DURATIONS][32], String:g_sPermOverride[32];
new String:g_sDurationDisplay[MAX_BAN_DURATIONS][64], String:g_sPermDisplay[64];

new bool:g_bEnabled, bool:g_bReduce, bool:g_bPermanent, bool:g_bMaximum, bool:g_bSourceBans;
new g_iLastChange, g_iNumTimes;
new String:g_sPrefixPlugin[64];

public Plugin:myinfo = 
{
	name = "Limit Ban Duration",
	author = "Twisted|Panda",
	description = "Provides functionality for creating restrictions on ban lengths.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("sm_limit_ban_duration");

	CreateNative("LimitBan_GetSize", Native_GetSize);
	CreateNative("LimitBan_GetAccess", Native_GetAccess);
	CreateNative("LimitBan_GetDisplay", Native_GetDisplay);
	CreateNative("LimitBan_GetLength", Native_GetLength);
	return APLRes_Success;
}

public Native_GetSize(Handle:hPlugin, iNumParams)
{
	return g_bEnabled ? g_iNumTimes : 0;
}

public Native_GetAccess(Handle:hPlugin, iNumParams)
{
	if(!g_bEnabled)
		return false;

	new index = GetNativeCell(1);
	new client = GetNativeCell(2);

	return (index == -1) ? Bool_CheckFlagsPerm(client) : Bool_CheckFlags(client, index);
}

public Native_GetDisplay(Handle:hPlugin, iNumParams)
{
	if(!g_bEnabled)
		return false;

	new result = -1;
	new index = GetNativeCell(1);
	if(index == -1)
		result = SetNativeString(2, g_sPermDisplay, sizeof(g_sPermDisplay), false);
	else
	{
		decl String:_sTemp[64];
		strcopy(_sTemp, sizeof(_sTemp), g_sDurationDisplay[index]);
		result = SetNativeString(2, _sTemp, sizeof(_sTemp), false);
	}

	return (result == SP_ERROR_NONE) ? true : false;
}

public Native_GetLength(Handle:hPlugin, iNumParams)
{
	if(!g_bEnabled)
		return -1;

	new index = GetNativeCell(1);
	return (index == -1) ? 0 : g_iDurationLength[index];
}

public OnAllPluginsLoaded()
{
	g_bSourceBans = LibraryExists("sourcebans");
}
 
public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "sourcebans"))
		g_bSourceBans = false;
}
 
public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "sourcebans"))
		g_bSourceBans = true;
}

public OnPluginStart()
{	
	LoadTranslations("common.phrases");
	LoadTranslations("sm_limit_ban_duration.phrases");

	CreateConVar("sm_limit_ban_duration_version", PLUGIN_VERSION, "Limit Ban Duration: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("sm_limit_ban_duration_enabled", "1", "Enables/disables all features of this plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hReduce = CreateConVar("sm_limit_ban_duration_reduce", "1", "If enabled, the plugin will lower ban lengths if an admin doesn't have access to their specified length to a length they do possess.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hReduce, OnSettingsChange);
	g_hMaximum = CreateConVar("sm_limit_ban_duration_maximum", "1", "If enabled, the highest entry defined in the plugins configuration file will be the highest amount any admin can ban for.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hMaximum, OnSettingsChange);
	AutoExecConfig(true, "sm_limit_ban_duration");

	AddCommandListener(Command_Ban, "sm_ban");
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bReduce = GetConVarBool(g_hReduce);
	g_bMaximum = GetConVarBool(g_hMaximum);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hReduce)
		g_bReduce = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hMaximum)
		g_bMaximum = StringToInt(newvalue) ? true : false;
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		Void_LoadTimes();
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Format(g_sPrefixPlugin, sizeof(g_sPrefixPlugin), "%T", "Prefix_Plugin", LANG_SERVER);
	}
}

public Action:Command_Ban(client, const String:command[], argc)
{
	if(g_bEnabled && g_iNumTimes && (!client || CheckCommandAccess(client, "sm_ban", ADMFLAG_BAN)))
	{
		if(argc < 2)
			return Plugin_Continue;

		decl String:_sTime[32];
		GetCmdArg(2, _sTime, sizeof(_sTime));
		new _iLength = StrEqual(_sTime, "") ? -1 : StringToInt(_sTime);
		if(_iLength <= -1)
			return Plugin_Continue;

		if(!_iLength)
		{
			if(!g_bPermanent || !g_bPermRestricted || Bool_CheckFlagsPerm(client))
				return Plugin_Continue;

			new _iPosition = -1;
			for(new i = g_iNumTimes; i >= 0; i--)
			{
				if(Bool_CheckFlags(client, i))
				{
					_iPosition = i;
					break;
				}
			}

			if(_iPosition == -1)
				ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_No_Access");
			else	
			{
				if(g_bReduce)
				{
					decl String:_sBuffer[256];
					GetCmdArgString(_sBuffer, sizeof(_sBuffer));
					if(Bool_IssueBan(client, _iPosition, _sBuffer))
						ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Reduced_Perm_Length", g_iDurationLength[_iPosition]);
				}
				else
					ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Illegal_Ban_Perm", g_iDurationLength[_iPosition]);
			}

			return Plugin_Stop;
		}
	
		new _iPosition;
		for(new i = g_iNumTimes; i >= 0; i--)
			if((_iLength >= g_iDurationLength[i] || i == 0) && (i == g_iNumTimes || _iLength <= g_iDurationLength[i + 1]))
				_iPosition = i;

		if(!_iPosition && _iLength < g_iDurationLength[_iPosition])
		{
			if(Bool_CheckFlags(client, _iPosition))
				return Plugin_Continue;
			
			ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_No_Access");
			return Plugin_Stop;
		}
		else if(_iPosition == g_iNumTimes)
		{
			if(Bool_CheckFlags(client, _iPosition))
			{	
				if(g_bMaximum)
				{
					if(g_bReduce)
					{
						decl String:_sBuffer[256];
						GetCmdArgString(_sBuffer, sizeof(_sBuffer));
						if(Bool_IssueBan(client, _iPosition, _sBuffer))
							ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Reduced_Ban_Length", g_iDurationLength[_iPosition]);
					}
					else
						ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Illegal_Ban_Length", g_iDurationLength[_iPosition]);
					
					return Plugin_Stop;
				}

				return Plugin_Continue;
			}
		}

		if(_iLength == g_iDurationLength[_iPosition] && Bool_CheckFlags(client, _iPosition))
			return Plugin_Continue;
		else if(Bool_CheckFlags(client, (_iPosition + 1)))
			return Plugin_Continue;
		else
		{
			for(new i = _iPosition; i >= -1; i--)
			{
				if(i == -1)
					break;

				if(Bool_CheckFlags(client, i))
				{
					_iPosition = i;
					break;
				}
			}
		
			if(_iPosition == -1)
				ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_No_Access");
			else
			{
				if(g_bReduce)
				{
					decl String:_sBuffer[256];
					GetCmdArgString(_sBuffer, sizeof(_sBuffer));
					if(Bool_IssueBan(client, _iPosition, _sBuffer))
						ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Reduced_Ban_Length", _iLength, g_iDurationLength[_iPosition]);
				}
				else
					ReplyToCommand(client, "%s%t", g_sPrefixPlugin, "Phrase_Illegal_Ban_Length", g_iDurationLength[_iPosition]);
			}
		}
		
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

bool:Bool_CheckFlagsPerm(client)
{
	if(!client || !g_bPermRestricted)
		return true;

	new _iTotal;
	for(new i = 0; i < g_iPermTotalFlags; i++)
	{
		if(CheckCommandAccess(client, g_sPermOverride, g_iPermFlags[i]))
			_iTotal++;
		else
			break;
	}

	return (_iTotal == g_iPermTotalFlags) ? true : false;
}

bool:Bool_CheckFlags(client, index)
{
	if(!client || !g_bDurationRestricted[index])
		return true;

	new _iTotal;
	for(new i = 0; i < g_iDurationTotalFlags[index]; i++)
	{
		if(CheckCommandAccess(client, g_sDurationOverride[index], g_iDurationFlags[index][i]))
			_iTotal++;
		else
			break;
	}
			
	return (_iTotal == g_iDurationTotalFlags[index]) ? true : false;
}

Bool_IssueBan(client, index, const String:buffer[])
{
	decl String:_sBuffer[192];
	new _iLength = BreakString(buffer, _sBuffer, sizeof(_sBuffer));
	new _iTarget = FindTarget(client, _sBuffer, true);
	if(_iTarget == -1)
		return false;
	_iLength += BreakString(buffer[_iLength], _sBuffer, sizeof(_sBuffer));
	strcopy(_sBuffer, sizeof(_sBuffer), buffer[_iLength]);
	if(g_bSourceBans)
		SBBanPlayer(client, _iTarget, g_iDurationLength[index], _sBuffer);
	else
		BanClient(_iTarget, g_iDurationLength[index], BANFLAG_AUTO, _sBuffer);
	return true;
}
		
Void_LoadTimes()
{
	decl String:_sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, _sPath, PLATFORM_MAX_PATH, "configs/sm_limit_ban_duration.ini");

	new _iCurrent = GetFileTime(_sPath, FileTime_LastChange);
	if(_iCurrent < g_iLastChange)
		return;
	else
		g_iLastChange = _iCurrent;
	
	g_iNumTimes = 0;
	g_bPermanent = false;
	new Handle:_hKV = CreateKeyValues("Limit_Ban_Durations");
	decl String:_sDisplay[MAX_BAN_DURATIONS][64], String:_sTemp[32], String:_sBuffer[24][3], String:_sOverrides[MAX_BAN_DURATIONS][32];
	new bool:_bDuration[MAX_BAN_DURATIONS], _iLength[MAX_BAN_DURATIONS], _iFlags[MAX_BAN_DURATIONS][24], _iTotalFlags[MAX_BAN_DURATIONS];
	if(FileToKeyValues(_hKV, _sPath))
	{
		KvGotoFirstSubKey(_hKV);
		do
		{
			KvGetSectionName(_hKV, _sTemp, sizeof(_sTemp));
			new _iTemp = StringToInt(_sTemp);

			if(_iTemp == 0)
			{
				g_bPermanent = true;

				KvGetString(_hKV, "flags", _sTemp, sizeof(_sTemp));
				g_iPermTotalFlags = StrEqual(_sTemp, "") ? 0 : ExplodeString(_sTemp, ",", _sBuffer, 24, 3);
				for(new i = 0; i < g_iPermTotalFlags; i++)
					g_iPermFlags[i] = ReadFlagString(_sBuffer[i]);
				KvGetString(_hKV, "override", g_sPermOverride, sizeof(g_sPermOverride));
				g_bPermRestricted = (!g_iPermTotalFlags && StrEqual(g_sPermOverride, "")) ? false : true;
				KvGetString(_hKV, "display", g_sPermDisplay, sizeof(g_sPermDisplay));
			}
			else
			{
				_iLength[g_iNumTimes] = _iTemp;

				KvGetString(_hKV, "flags", _sTemp, sizeof(_sTemp));
				_iTotalFlags[g_iNumTimes] = StrEqual(_sTemp, "") ? 0 : ExplodeString(_sTemp, ",", _sBuffer, 24, 3);
				for(new i = 0; i < _iTotalFlags[g_iNumTimes]; i++)
					_iFlags[g_iNumTimes][i] = ReadFlagString(_sBuffer[i]);
				KvGetString(_hKV, "override", _sOverrides[g_iNumTimes], sizeof(_sOverrides[]));
				_bDuration[g_iNumTimes] = (!_iTotalFlags[g_iNumTimes] && StrEqual(_sOverrides[g_iNumTimes], "")) ? false : true;
				KvGetString(_hKV, "display", _sDisplay[g_iNumTimes], sizeof(_sDisplay[]));
				g_iNumTimes++;
			}
		}
		while (KvGotoNextKey(_hKV));
	}
	else
		SetFailState("Limit Ban Durations: configs/sm_limit_ban_duration.ini is missing or invalid!");

	if(g_iNumTimes)
		g_iNumTimes--;	
	
	new _iCurrentHigh, _iTotalSorted = g_iNumTimes;
	for(new i = 0; i <= g_iNumTimes; i++)
	{
		_iCurrentHigh = -1;
		new _iCurrentIndex;
		for(new j = 0; j <= g_iNumTimes; j++)
		{
			if(_iLength[j] != -1 && _iLength[j] > _iCurrentHigh)
			{
				_iCurrentIndex = j;
				_iCurrentHigh = _iLength[j];
			}
		}

		g_bDurationRestricted[_iTotalSorted] = _bDuration[_iCurrentIndex];
		g_iDurationLength[_iTotalSorted] = _iLength[_iCurrentIndex];
		g_iDurationTotalFlags[_iTotalSorted] = _iTotalFlags[_iCurrentIndex];
		for(new j = 0; j < g_iDurationTotalFlags[_iTotalSorted]; j++)
			g_iDurationFlags[_iTotalSorted][j] = _iFlags[_iCurrentIndex][j];
		strcopy(g_sDurationOverride[_iTotalSorted], sizeof(g_sDurationOverride[]), _sOverrides[_iCurrentIndex]);
		strcopy(g_sDurationDisplay[_iTotalSorted], sizeof(g_sDurationDisplay[]), _sDisplay[_iCurrentIndex]);
		
		_iLength[_iCurrentIndex] = -1;
		_iTotalSorted--;
	}

	CloseHandle(_hKV);
}