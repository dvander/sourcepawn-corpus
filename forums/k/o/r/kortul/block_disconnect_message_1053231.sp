//block disconnect message in chat
//by Kortul 2010

public Plugin:myinfo =
{
	name = "[SM] Block Disconnect Message",
	author = "Kortul",
	description = "blocks disconnect message in chat when players leave the server",
	version = "1.0",
	url = "http://www.a3gaming.com"
}

public OnPluginStart()
{
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre)
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{	
	//copy event into a new event, then refire the event with dontBroadcast set as true (and block this event)
	new String:buffer[MAX_NAME_LENGTH]
	new Handle:new_event = CreateEvent("player_disconnect", true)
	SetEventInt(new_event, "userid", GetEventInt(event, "userid"))
	GetEventString(event, "reason", buffer, sizeof(buffer))
	SetEventString(new_event, "reason", buffer)	
	GetEventString(event, "name", buffer, sizeof(buffer))
	SetEventString(new_event, "name", buffer)	
	GetEventString(event, "networkid", buffer, sizeof(buffer))
	SetEventString(new_event, "networkid", buffer)
	
	FireEvent(new_event, true)
/*	event variables

	"player_disconnect"			// a client was disconnected
	{
		"userid"	"short"		// user ID on server
		"reason"	"string"	// "self", "kick", "ban", "cheat", "error"
		"name"		"string"	// player name
		"networkid"	"string"	// player network (i.e steam) id
	}
*/	
	return Plugin_Handled
}