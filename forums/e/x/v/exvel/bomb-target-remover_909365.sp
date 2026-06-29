#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Bomb Target Remover",
	author = "exvel",
	description = "Removes bomb targets from the map",
	version = "1.0.0",
	url = "www.sourcemod.com"
}

public OnMapStart() 
{
	new iMaxEnt = GetMaxEntities();
	decl String:szClassName[64];
	
	for (new i = MaxClients; i <= iMaxEnt; i++) 
    {
		if (IsValidEdict(i) && IsValidEntity(i)) 
        {
			GetEdictClassname(i, szClassName, sizeof(szClassName)); 
            
			if (StrEqual("func_bomb_target", szClassName)) 
			{
				AcceptEntityInput(i, "Kill"); 
			}
		}
	}
}