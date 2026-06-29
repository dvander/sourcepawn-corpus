#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	
	name = "Gravity",
	
	author = "Tylerst",

	description = "Adds commands sm_lowgrav and sm_normalgrav",

	version = "1.0",
	
	url = "None"

};



public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_lowgrav", Command_Lowgrav, "Set gravity to 150");
	RegConsoleCmd("sm_normalgrav", Command_Normalgrav, "Set gravity to 800");
}

public Action:Command_Lowgrav(client, args)
{
	SetEntityGravity(client, 0.1875);
	PrintToChat(client,"You now have low gravity")
	return Plugin_Handled;
}
public Action:Command_Normalgrav(client, args)
{
	SetEntityGravity(client, 1.0);
	PrintToChat(client,"You now have normal gravity")
	return Plugin_Handled;
}