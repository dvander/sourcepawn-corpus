#include <sourcemod>
#include <sdktools>



#define PL_VERSION "1.0"

new Float:g_Location[33][3];



public Plugin:myinfo = 
{
	name = "Teleport Mod",
	author = "Dean Poot",
	description = "Teleport Mod - This mod is ment to be used on jump servers so players can save there location using !saveloc and teleport to there location using !teleport",
	version = PL_VERSION,
	url = "http://veedev.com.au"
}

public OnPluginStart()
{
	
	
	CreateConVar("teleport_mod_version", PL_VERSION, "Teleport Mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	
	new maxClients = GetMaxClients();
		
	for (new i=1; i<=maxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		g_Location[i][0] = 0;
		g_Location[i][1] = 0;
		g_Location[i][2] = 0;
	}
}

public OnClientPutInServer(client)
{
		g_Location[client][0] = 0;
		g_Location[client][1] = 0;
		g_Location[client][2] = 0;
}


public Action:Save_Loc(client)
{
	GetClientAbsOrigin(client, g_Location[client]);
	PrintToChat (client, "Your location has been saved");
}



public Action:Command_Say(client,args){
	
	if(client != 0){
		decl String:szText[192];
		GetCmdArgString(szText, sizeof(szText));
		szText[strlen(szText)-1] = '\0';
	
		new String:szParts[3][16];
		ExplodeString(szText[1], " ", szParts, 3, 16);
		
		if((strcmp(szParts[0],"!saveloc",false) == 0)) {
			Save_Loc(client);
		}
		
		if((strcmp(szParts[0],"!teleport",false) == 0)) {
			Teleport_User(client);
		}
			
		
	}
	
	
}
	

public Action:Teleport_User(client)
{
	
	if (g_Location[client][1] != 0) {
	
		PrintToChat (client, "You have been teleported");

		TeleportEntity(client, g_Location[client], NULL_VECTOR, NULL_VECTOR);
	} else {
		PrintToChat (client, "You have not saved a location");
	}
	
}
