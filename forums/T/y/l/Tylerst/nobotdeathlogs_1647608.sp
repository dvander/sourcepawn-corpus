#pragma semicolon 1

#include <sourcemod>

public Action:OnLogAction(Handle:source, Identity:ident, client, target, const String:message[])
{
	if(target > 0 && IsClientInGame(target))
	{
		if(IsFakeClient(target))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}