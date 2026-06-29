#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_freezetime", FreezeTime, ADMFLAG_GENERIC)
	RegAdminCmd("sm_resumetime", ResumeTime, ADMFLAG_GENERIC)
}

public Action:FreezeTime(client, args)
{
	new timer = -1;
	while ((timer = FindEntityByClassname2(timer, "team_round_timer")) != -1)
		AcceptEntityInput(timer, "Pause");
}

public Action:ResumeTime(client, args)
{
	new timer = -1;
	while ((timer = FindEntityByClassname2(timer, "team_round_timer")) != -1)
		AcceptEntityInput(timer, "Resume");
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
