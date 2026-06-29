#include <sourcemod> 


new Handle:left_message = INVALID_HANDLE;
new Handle:welcome_message = INVALID_HANDLE;

new String:left[300];
new String:welcome[300];
new String:playermame[100];

new bool:visible[MAXPLAYERS+1] = true;

public Plugin:myinfo =  
{  
	name = "Admin Stealth - Arkarr edition",  
	author = "Arkarr",  
	description = "Allow to make player invisible wit a fake disconnected message",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{
	RegAdminCmd("sm_stealth", Cmd_Stealth, ADMFLAG_CHEATS);   
	
	welcome_message = CreateConVar("sm_stealth_welcomemsg", "The player [PLAYERNAME] as join the game", "Print to chat when player become visible");
	left_message = CreateConVar("sm_stealth_leftmsg", "The player [PLAYERNAME] as left the game", "Print to chat when player become invisible");
	
	GetConVarString(left_message, left, sizeof(left));
	GetConVarString(welcome_message, welcome, sizeof(welcome));
}


public Action:Cmd_Stealth(client, args)  
{
	if(IsValidClient(client))
	{
		GetClientName(client, playermame, sizeof(playermame));
		
		ReplaceString(left, sizeof(left), "[PLAYERNAME]", playermame, true);
		ReplaceString(welcome, sizeof(welcome), "[PLAYERNAME]", playermame, true);
		
		if(visible[client] == true)
		{
			PrintToChatAll(left);
			//Set client invisibility
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 0);
			//Set ACTIVE weapon invisibility
			new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SetEntityRenderMode(hClientWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(hClientWeapon, 255, 255, 255, 0);
			visible[client] = false;
		}
		else
		{
			PrintToChatAll(welcome);
			//Set client invisibility
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			//Set ACTIVE weapon visibile
			new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SetEntityRenderMode(hClientWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(hClientWeapon, 255, 255, 255, 255);
			visible[client] = true;
		}
	}
	
	return Plugin_Handled;
}

//Stocks here <------------------------------------------------------------------------------

//Stock one, thank to Chaosxk https://forums.alliedmods.net/showpost.php?p=1975847&postcount=25
stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

