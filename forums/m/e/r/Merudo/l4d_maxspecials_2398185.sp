// l4dt forward
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

ConVar MaxSpecials;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name        = "l4d_maxspecials",
	author      = "Merudo",
	version     = PLUGIN_VERSION,
	description = "Turns the director variable MaxSpecials into a ConVar",
};

public OnPluginStart()
{
	MaxSpecials = CreateConVar("MaxSpecials", "-1" , "Change the MaxSpecials director variable. -1: Use default value", FCVAR_DONTRECORD, true, -1.0, false);
	CreateConVar("l4d_maxspecials_version", PLUGIN_VERSION, "Version of l4d_maxspecials", FCVAR_DONTRECORD);
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	if (StrEqual(key, "MaxSpecials"))
	{
		if (MaxSpecials.IntValue == -1) MaxSpecials.IntValue = retVal;  // go back to default
		else
		{
			retVal = MaxSpecials.IntValue;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}