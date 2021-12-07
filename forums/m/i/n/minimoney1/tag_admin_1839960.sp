#include <sourcemod>
#include <regex>

enum DetectionMethod
{
	DetectionMethod_None,
	DetectionMethod_Regex,
	DetectionMethod_StringCheck,
};

new Handle:g_hRegex = INVALID_HANDLE,
	bool:g_bEnabled,
	DetectionMethod:g_dMethod = DetectionMethod_None,
	String:g_strFlags[33],
	String:g_strTag[256];

public OnPluginStart()
{
	new Handle:conVar;
	conVar = CreateConVar("sm_tagadm_enabled", "1");
	g_bEnabled = GetConVarBool(conVar);
	HookConVarChange(conVar, OnEnableChanged);

	conVar = CreateConVar("sm_tagadm_method", "1", "0 - Disabled\n1 - Regex\n2 - Checking String for First Word");
	g_dMethod = DetectionMethod:GetConVarInt(conVar);
	HookConVarChange(conVar, OnMehtodChanged);

	conVar = CreateConVar("sm_tagadm_flags", "a");
	GetConVarString(conVar, g_strFlags, sizeof(g_strFlags));
	HookConVarChange(conVar, OnFlagsChanged);

	decl String:regex[512];
	conVar = CreateConVar("sm_tagadm_regex", "#MY_REGEX");
	GetConVarString(conVar, regex, sizeof(regex));
	HookConVarChange(conVar, OnRegexChanged);
	g_hRegex = CompileRegex(regex);

	conVar = CreateConVar("sm_tagadm_tag", "[MYTAG]");
	GetConVarString(conVar, g_strTag, sizeof(g_strTag));
	HookConVarChange(conVar, OnTagChanged);

	AutoExecConfig();

	CloseHandle(conVar);
}

public OnEnableChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = StringToInt(newVal) ? true : false;
}
public OnMehtodChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_dMethod = DetectionMethod:StringToInt(newVal);
}
public OnFlagsChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_strFlags, sizeof(g_strFlags), newVal);
}
public OnRegexChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	if (g_hRegex != INVALID_HANDLE)
		CloseHandle(g_hRegex);
	g_hRegex = CompileRegex(newVal);
}
public OnTagChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_strTag, sizeof(g_strTag), newVal);
}

public OnClientPostAdminCheck(client)
{
	if (g_bEnabled)
	{
		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		if (CheckTag(name))
		{
			new AdminId:admin = GetUserAdmin(client);
			if (admin == INVALID_ADMIN_ID)
			{
				admin = CreateAdmin(name);
				decl String:steamId[32];
				GetClientAuthString(client, steamId, sizeof(steamId));
				BindAdminIdentity(admin, "steam", steamId);
				for (new i = 0; i < strlen(g_strFlags); i++)
				{
					new AdminFlag:flag;
					if (FindFlagChar(flag, _:g_strFlags[i]))
					{
						SetAdminFlag(admin, flag, true);
					}
				}
			}
		}
	}
}

stock bool:CheckTag(String:name[])
{
	switch (g_dMethod)
	{
		case DetectionMethod_Regex:
		{
			new RegexError:err = REGEX_ERROR_NONE;
			return ((MatchRegex(g_hRegex, name, err) > 0) && (err == REGEX_ERROR_NONE) ? true : false);
		}
		case DetectionMethod_StringCheck:
		{
			return ((StrContains(name, g_strTag) == 0) ? true : false);
		}
		case DetectionMethod_None:
		{
			return false;
		}
	}
	return false;
}