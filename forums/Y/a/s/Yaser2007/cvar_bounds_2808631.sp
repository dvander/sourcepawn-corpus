#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[Any] ConVar Bounds",
	author = "Yaser2007",
	description = "Sets a cvar bounds.",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=2808631#post2808631"
};

public void OnPluginStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/cvar_bounds.cfg");

	if(!FileExists(path))
	{
		SetFailState("KeyValues file %s is not found", path);
		return;
	}

	KeyValues kv = CreateKeyValues("CvarBounds");
	if(!FileToKeyValues(kv, path))
	{
		SetFailState("Failed to parse keyvalues file %s", path);
		return;
	}

	if(!KvGotoFirstSubKey(kv))
	{
		SetFailState("Failed to parse sub key %s", path);
		return;
	}

	do
	{
		char cvarName[128];
		char min[64];
		char max[64];

		KvGetSectionName(kv, cvarName, sizeof(cvarName));
		KvGetString(kv, "min", min, sizeof(min));
		KvGetString(kv, "max", max, sizeof(max));

		if(FindConVar(cvarName))
		{
			SetConVarBounds(FindConVar(cvarName), ConVarBound_Lower, true, StringToFloat(min));
			SetConVarBounds(FindConVar(cvarName), ConVarBound_Upper, true, StringToFloat(max));
		}
		else
		{
			PrintToServer("[CvarBounds] ConVar \"%s\" was not found in this game/mod. please change or delete this section", cvarName);
		}
	}
	while(KvGotoNextKey(kv));

	delete kv;
}