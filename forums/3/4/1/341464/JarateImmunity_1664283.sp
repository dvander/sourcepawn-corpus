
#include <sourcemod>
#include <tf2>
#include <tf2_stocks> 

new Immunity[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Anti Jarate",
	author = "341464",
	description = "Jarate Immunity",
	version = "1.1",
	url = "341464.webs.com"
}

public OnPluginStart()
{
	TF2only();
	RegConsoleCmd("sm_ji",Command_JarateImmune,"Makes client player immune to jarate");
}
public Action:Command_JarateImmune(client, args)
{
	if(CheckCommandAccess(client, "sm_ji_access", 0))
	{
		switch(Immunity[client])
		{
			case 0:
			{
				Immunity[client]=1;
				PrintToChat(client, "[SM] Jarate Immunity Enabled.");
			}
			case 1:
			{
				Immunity[client]=0;
				PrintToChat(client, "[SM] Jarate Immunity Disabled.");
			}
		}
	}
	return Plugin_Handled;
}
public TF2_OnConditionAdded(client, TFCond:cond) 
{ 
    if (cond != TFCond_Jarated) return; 
    if (Immunity[client])
    {
    	TF2_RemoveCondition(client, TFCond_Jarated);
    }
} 
public OnClientDisconnect_Post(client)
{
	Immunity[client] = 0;
}

public OnClientPutInServer(client)
{
	Immunity[client] = 0;
}
TF2only()
{
	decl String:Game[10];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		SetFailState("[SM] Please remove this plugin, it only works for Team Fortress 2.");
	}
}
