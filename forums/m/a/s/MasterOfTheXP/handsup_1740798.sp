#include <sourcemod>
public OnPluginStart()
{
	RegAdminCmd("sm_loser", Command_handsup, ADMFLAG_ROOT);
	RegAdminCmd("sm_humiliate", Command_handsup, ADMFLAG_ROOT);
	RegAdminCmd("sm_handsup", Command_handsup, ADMFLAG_ROOT);
}

public Action:Command_handsup(client, args)
{
	new String:arg1[3];
	GetCmdArgString(arg1, sizeof(arg1));
	new newState;
	if (args > 0)
	{
		if (StrEqual(arg1,"1") || StrContains(arg1,"on", false) == 0) newState = 1;
		else if (StrEqual(arg1,"0") || StrContains(arg1,"of", false) == 0) newState = 0;
	}
	else
	{
		if (GetConVarInt(FindConVar("tf_always_loser")) == 0) newState = 1;
		else newState = 0;
	}
	SetConVarInt(FindConVar("tf_always_loser"), newState);
	return Plugin_Handled;
}