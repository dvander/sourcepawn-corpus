#include <sourcemod>

public Plugin:myinfo = {
	name = "BackFlip",
	author = "Chokitu",
	description = "Allows you to backflip",
	version = "1.0",
	url =""
};
	
public OnPluginStart()
	{
    new flags = GetCommandFlags("cl_pitchup");
    SetCommandFlags("cl_pitchup", flags & ~FCVAR_CHEAT);
    flags = GetCommandFlags("cl_pitchdown");
    SetCommandFlags("cl_pitchdown", flags & ~FCVAR_CHEAT);
	RegConsoleCmd("sm_backflip", Backflip);
	RegConsoleCmd("sm_unbackflip", Normal);
}
	
public Action:Backflip(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	ClientCommand(client, "cl_pitchup 900");
	ClientCommand(client, "cl_pitchdown 900");
	PrintToChat(client, "Now you can backflip.Jump and use the mouse");
	
	return Plugin_Handled;
}
	
public Action:Normal(client, args)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	FakeClientCommand(client, "cl_pitchup 89");
	FakeClientCommand(client, "cl_pitchdown 89");
	PrintToChat(client, "Back to normal!");
	
	return Plugin_Handled;
}