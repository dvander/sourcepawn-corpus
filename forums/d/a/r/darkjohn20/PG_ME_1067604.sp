#include <sourcemod>

new cvar_add_tag;

public Plugin:myinfo =
{
	name = "PG ME",
	author = "John Fedorchak",
	description = "Add a clan tag",
	version = "1.0.0.0",
	url = ""
};
 
public OnPluginStart()
{
	RegConsoleCmd("PGME", Command_Name);
	cvar_add_tag = CreateConVar("pgme_add_tag", " #PG ", "Tag to prefix name with.");
}

public Action:Command_Name(client, args)
{
	decl String:Name[64];
	
	decl String:Tag[64];
	GetConVarString(cvar_add_tag, Tag, sizeof(Tag));
	
	GetClientName(client, Name, sizeof(Name));
	ClientCommand(client, "name \"%s%d\"", Tag, Name);
	return Plugin_Handled
}