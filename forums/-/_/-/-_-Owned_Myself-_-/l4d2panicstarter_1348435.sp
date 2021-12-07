/* Left 4 Dead 2 Panic Events */

#include <sourcemod>

public OnPluginStart()
{
	/* Hook Panic Create event after it has happened */
	HookEvent("create_panic_event", OnPanicCreate);
}

public Action:OnPanicCreate(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Copy the UserID from the event over */
	new uId = GetEventInt(event, "userid");
	/* Now get the person's name */
	new client = GetClientOfUserId(uId);
	new cName[MAX_NAME_LENGTH];
	GetClientName(client, cName, sizeof(cName));
	/* Now tell everyone who created the event */
	PrintToChatAll("\x03[Panic Event]\x01 %s created a panic event!", cName);
}