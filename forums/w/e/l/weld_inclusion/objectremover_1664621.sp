#include <sourcemod>
#include <sdktools>
#define VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Object Remover",
	author = "Weld Inclusion",
	description = "Removes an object where aimed.",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=179911"
}
public OnPluginStart()
{
	//Rewrite with CheckCommandAccess and CheckAccess to remove flag necessity
	//Register the command for use
	RegAdminCmd("sm_removeobject", Command_RemoveObject, ADMFLAG_ROOT, "Remove Object.");
}

public Action:Command_RemoveObject(client, args)
{
	if(!client)
	{
	PrintToServer("Client is invalid");
	return Plugin_Handled;
	}

	RemoveObject(client);
	return Plugin_Handled;
}

public RemoveObject(client)
{
	
	decl String:Target[128];
	//Get the object where the client is looking
	new object = GetClientAimTarget(client, false);
		
	if ((object == -1) || (!IsValidEntity(object)))
	{
	ShowActivity2(client, "[SM] ", "%N tried to remove an invalid object.", client);
	LogAction(client, -1, "%N tried to remove an invalid object.", client);
	return;
	}
	//Check if the object is a client and show activity if so.
	else if (object > 0 && object <= GetMaxClients())
	{
	ShowActivity2(client, "[SM] ", "%N tried to remove %N", client, object);
	LogAction(client, object, "%N tried to remove %N", client, object);
	return;
	}
	GetEdictClassname(object, Target, sizeof(Target));
	ShowActivity2(client, "[SM] ", "%N removed %s", client, Target);
	LogAction(client, object, "%N removed %s", client, Target);
	AcceptEntityInput(object, "kill", -1, -1, -1);
}