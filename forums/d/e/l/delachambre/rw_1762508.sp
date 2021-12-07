#include <sdktools>

new PlayerRw[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "Remove Weapon",
    author = "Delachambre",
    description = "Remove weapon aim",
    version = "1.0.0",
    url = "http://clan-magnetik.fr"
}

public OnPluginStart()
{   
	RegConsoleCmd("sm_rw", Command_Rw);
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 3)
	{
		PlayerRw[client] = 3;
	}
	else
	{
		PlayerRw[client] = 0;
	}
}

public Action:Command_Rw(client, args)
{
	if (IsClientConnected(client))
	{
		if (GetClientTeam(client) == 3)
		{	
			new Ent;
			Ent = GetClientAimTarget(client, false);
			
			if (Ent != -1)
			{
				new String:Classname[32];
				GetEdictClassname(Ent, Classname, sizeof(Classname));
				
				if (StrContains(Classname, "weapon_", false) != -1)
				{
					if (PlayerRw[client] > 0)
					{
						RemoveEdict(Ent);
						PrintToChat(client, "\x[RW] : you have remove the aim weapon.");
						PlayerRw[client]--;
					}
					else
					{
						PrintToChat(client, "[RW] : You don't have !rw.");
					}
				}
			}
		}
		else
		{
			PrintToChat(client, "[RW] you don't have to this command.");
		}
	}
}