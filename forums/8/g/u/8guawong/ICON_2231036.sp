#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new _fun [MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	PrecacheModel("models/stamm/stammview.mdl");
	
	AddFileToDownloadsTable("materials/models/stamm/stammview.vtf");
	AddFileToDownloadsTable("models/stamm/stammview.mdl");
	AddFileToDownloadsTable("materials/models/stamm/stammview.vmt");
	AddFileToDownloadsTable("models/stamm/stammview.vvd");
	AddFileToDownloadsTable("models/stamm/stammview.sw.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.phy");
	AddFileToDownloadsTable("models/stamm/stammview.dx80.vtx");
	AddFileToDownloadsTable("models/stamm/stammview.dx90.vtx");
}

public Action:Event_PlayerDeath(Handle:Event, const String:Name[], bool:DontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if (_fun[client] != 0)
	{
		if (IsValidEntity(_fun[client]))
		{
			decl String:class[128];
			GetEdictClassname(_fun[client], class, sizeof(class));

			if (StrEqual(class, "prop_dynamic")) 
			{
				RemoveEdict(_fun[client]);
			}
		}	
		
		_fun[client] = 0;
	}
}

public Action:Event_PlayerSpawn(Handle:Event, const String:Name[], bool:DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	if (GetUserFlagBits(Client) & ADMFLAG_ROOT)
	{
		if ((GetClientTeam(Client) == 2 || GetClientTeam(Client) == 3) && IsPlayerAlive(Client)) 
			{
				// Create timer
				CreateTimer(2.5, Create__fun, GetClientUserId(Client));
			}
	}
}

public Action:Create__fun(Handle:iTimer, any:userid)
{
	new Client = GetClientOfUserId(userid);

	if ((GetClientTeam(Client) == 2 || GetClientTeam(Client) == 3) && IsPlayerAlive(Client))
	{
		// First delete old one
		if (_fun[Client] != 0) 
		{
			if (IsValidEntity(_fun[Client]))
			{
				decl String:class[128];
				GetEdictClassname(_fun[Client], class, sizeof(class));
					
				if (StrEqual(class, "prop_dynamic")) 
				{
					RemoveEdict(_fun[Client]);
				}
			}
		}
			
		new view = CreateEntityByName("prop_dynamic");
			
		if (view != -1)
		{
		// Set up the entity
			DispatchKeyValue(view, "DefaultAnim", "rotate");
			DispatchKeyValue(view, "spawnflags", "256");
			DispatchKeyValue(view, "model", "models/stamm/stammview.mdl");
			DispatchKeyValue(view, "solid", "6");
				
			// Spawn it
			if (DispatchSpawn(view))
			{
				decl Float:origin[3];
				decl String:steamid[20];
					
				// Valid?
				if (IsValidEntity(view))
				{
					// Mark players entity and spawn it to him
					_fun[Client] = view;
						
					GetClientAbsOrigin(Client, origin);
						
					origin[2] = origin[2] + 90.0;
						
					TeleportEntity(view, origin, NULL_VECTOR, NULL_VECTOR);
						
					GetClientAuthString(Client, steamid, sizeof(steamid));
					DispatchKeyValue(Client, "targetname", steamid);
						
					SetVariantString(steamid);
					AcceptEntityInput(view, "SetParent", -1, -1, 0);
				}
			}
		}
	}
}