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
	RegConsoleCmd("sm_backflip", Backflip);
	RegConsoleCmd("sm_unbackflip", Normal);
	}
	
	public Action:Backflip(client, args)
	{
	FakeClientCommand(client, "cl_pitchup 900");
	FakeClientCommand(client, "cl_pitchdown 900");
	PrintToChat(client, "Now you can backflip.Jump and use the mouse");
	}
	
		public Action:Normal(client, args)
	{
	FakeClientCommand(client, "cl_pitchup 89");
	FakeClientCommand(client, "cl_pitchdown 89");
	PrintToChat(client, "Back to normal!");
	}
