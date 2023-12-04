#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= "[Any] ConVar Bounds",
	author		= "Yaser2007",
	description	= "Sets a cvar bounds.",
	version		= "1.3.0 (rewritten by Grey83)",
	url			= "https://forums.alliedmods.net/showthread.php?t=343628"
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/cvar_bounds.cfg");
	if(!FileExists(buffer))
	{
		LogError("Config %s is not found", buffer);
		return;
	}

	KeyValues kv = CreateKeyValues("CvarBounds");
	if(!FileToKeyValues(kv, buffer))
	{
		LogError("Failed to import from config %s", buffer);
		return;
	}

	KvRewind(kv);

	if(!KvGotoFirstSubKey(kv))
	{
		LogError("Config %s is empty!", buffer);
		delete kv;
		return;
	}

	ConVar cvar;
	bool set;
	int i;
	float bound;
	char val[12];
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		if((cvar = FindConVar(buffer)))
		{
			KvGetString(kv, "min", val, sizeof(val));
			if(val[0] && StringToFloatEx(val, bound))
			{
				SetConVarBounds(cvar, ConVarBound_Lower, true, StringToFloat(val));
				set = true;
			}

			KvGetString(kv, "max", val, sizeof(val));
			if(val[0] && StringToFloatEx(val, bound))
			{
				SetConVarBounds(cvar, ConVarBound_Upper, true, StringToFloat(val));
				set = true;
			}

			if(set) i++;
			else LogError("The config has no bounds for the variable '%s'.", buffer);
			
		}
		else LogError("ConVar \"%s\" was not found in this game/mod. Please change or delete this section", buffer);

		set = false;
	} while(KvGotoNextKey(kv));

	delete kv;

	if(i) PrintToServer("Value is limited for %i console variables.", i);
	else LogError("The config does not contain existing variables.");
}