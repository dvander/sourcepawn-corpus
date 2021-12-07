#include <sourcemod>
#include <sdktools>
new Handle:hCvarEnabled;
new MaxEntities;
public Plugin:myinfo = 
{
	name = "Disable the Intelligence",
	author = "Afronanny",
	description = "Disable the Intelligence on the fly",
	version = "1.0",
	url = "http://letmegooglethatforyou.com"
}

public OnPluginStart()
{
	MaxEntities = GetMaxEntities();
	hCvarEnabled = CreateConVar("sm_intel_disable", "0", "Disable the intel", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(hCvarEnabled, ConVarChanged_Enabled);
}

public ConVarChanged_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new String:classname[128];
	new enabled;
	enabled = StringToInt(newValue);
	for (new i = 1; i < MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			if (strcmp(classname, "item_teamflag") == 0)
			{
				if (enabled == 1)
				{
					AcceptEntityInput(i, "Disable");
				} else {
					AcceptEntityInput(i, "Enable");
				}
			}
		}
	}
}