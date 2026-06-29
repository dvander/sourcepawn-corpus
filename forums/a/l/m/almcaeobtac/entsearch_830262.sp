#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "Entity Search",
	author = "Alm",
	description = "Search the map for certain entities",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_searchmap", SearchForEnt, ADMFLAG_CHANGEMAP, "<part of ent type> Search for an entity type.");
}

stock PrintMessage(Client, String:Message[255])
{
	if(Client == 0)
	{
		PrintToConsole(Client, "%s", Message);
	}
	else
	{
		PrintToChat(Client, "%s", Message);
	}
	
	return true;
}

public Action:SearchForEnt(Client, Args)
{
	if(Args == 0)
	{
		PrintMessage(Client, "--Please type an entity name.");
		return Plugin_Handled;
	}

	decl MaxEnts;
	decl String:EntType[32];
	decl String:EntName[32];
	decl Float:Origin[3];
	decl bool:Found;
	Found = false;
	
	GetCmdArg(1, EntType, 32);

	MaxEnts = GetMaxEntities();
	for(new A = 1; A <= MaxEnts; A++)
    	{
		if(IsValidEdict(A) && IsValidEntity(A))
		{
			GetEdictClassname(A, EntName, 32);

			if(StrContains(EntName, EntType, false) != -1)
			{
				GetEntPropVector(A, Prop_Data, "m_vecOrigin", Origin);
				PrintToConsole(Client, "Found: (Ent #%d) {Type: %s} [Origin: %f %f %f]", A, EntName, Origin[0], Origin[1], Origin[2]);
			
				if(!Found)
				{
					Found = true;
				}
			}
		}
	}

	if(!Found)
	{
		PrintMessage(Client, "--No matching entities were found.");
	}

	return Plugin_Handled;
}