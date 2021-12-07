/*
* Infinite-Jumping aka Bunny Hop
* 
* Description:
* Lets user auto jump when holding down space.
* 
* Installation:
* Place infinite-jumping.smx into your <moddir>/addons/sourcemod/plugins/
* 
* Console Variables:
* sm_infinite-jumping_enabled - Lets you turn on and off this plugin
* sm_infinite-jumping_flags - Needed admin level to be able to jump. Leave this empty to allow it for all players or use the SourceMod admin flags a,b,c etc.
* 
* Changelog:
* v1.2.3
* Added sm_infinite-jumping_flags.
* 
* v1.1.3
* Fixed in water and ladder bugs.
* 
* v1.0.0
* Public release
* 
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod/AlliedModders-Team
* Thank you Fredd for the original plugin idea.
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2.3-ex-dj"

new Handle:g_cvar_Version = INVALID_HANDLE;
new Handle:g_cvar_Enabled = INVALID_HANDLE;
new Handle:g_cvar_Flag = INVALID_HANDLE;

new bool:g_bAllowJumping[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Infinite-Jumping aka Bunny Hop",
	author = "Chanz",
	description = "Lets user auto jump when holding down space.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1239361 OR http://www.mannisfunhouse.eu/"
}
public OnPluginStart(){
	
	g_cvar_Version = CreateConVar("sm_infinite-jumping_version", PLUGIN_VERSION, "Infinite-Jumping aka Bunny Hop Version", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	g_cvar_Enabled	= CreateConVar("sm_infinite-jumping_enabled", "1", "Enables or disables Infinite-Jumping",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_cvar_Flag	= CreateConVar("sm_infinite-jumping_flags", "", "Needed admin level to be able to jump. Leave this empty to allow it for all players or use the SourceMod admin flags a,b,c etc.",FCVAR_PLUGIN);
	
	HookConVarChange(g_cvar_Flag,ConVarChange_Flag);
	
	AutoExecConfig(true,"plugin.infinite-jumping");
}

public OnConfigsExecuted(){
	
	new String:szflag[1];
	GetConVarString(g_cvar_Flag,szflag,sizeof(szflag));
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		CheckJumpFlags(client,szflag);
	}
}

public OnClientConnected(client){
	
	g_bAllowJumping[client] = false;
}

public OnClientPostAdminCheck(client){
	
	new String:szflag[1];
	GetConVarString(g_cvar_Flag,szflag,sizeof(szflag));
	
	CheckJumpFlags(client,szflag);
}

stock CheckJumpFlags(client,const String:szflag[]){
	
	new AdminFlag:flag;
	
	if(FindFlagByChar(szflag[0],flag)){
		
		new AdminId:adminid = GetUserAdmin(client);
		
		if(adminid == INVALID_ADMIN_ID){
			
			//PrintToServer("client %d isn't allowed jumping since he is no admin",client);
			g_bAllowJumping[client] = false;
			return;
		}
		
		if(GetAdminFlag(adminid,flag)){
			
			//PrintToServer("client %d is allowed since he has the right admin flag",client);
			g_bAllowJumping[client] = true;
		}
	}
	else {
		
		//PrintToServer("client %d is allowed since no flag is set",client);
		g_bAllowJumping[client] = true;
	}
}

public ConVarChange_Flag(Handle:cvar, const String:oldVal[], const String:newVal[]){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		CheckJumpFlags(client,newVal);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	
	if(!GetConVarBool(g_cvar_Enabled)){
		
		return Plugin_Continue;
	}
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client)){
		
		return Plugin_Continue;
	}
	
	if(!g_bAllowJumping[client]){
		return Plugin_Continue;
	}
	
	if(buttons & IN_JUMP){
		
		new flags = GetEntityFlags(client);
		
		if(flags & FL_INWATER){
			
			return Plugin_Continue;
		}
		
		if(InLadder(client)){
			
			return Plugin_Continue;
		}
		
		if(!(flags & FL_ONGROUND)){
			
			if(vel[2] <= 0.0){
				
				buttons &= ~IN_JUMP;
			}
		}
	}
	
	return Plugin_Continue;
}

/*
* Extracted functions of smlib:
*/

/*
* This function returns true if the client is at a ladder..
*
* @param client			Client index.
* @return				Returns true if the client is on a ladder other wise false.
*/
stock bool:InLadder(client){
	
	new MoveType:movetype = GetEntityMoveType(client);
	
	if (movetype == MOVETYPE_LADDER){
		
		return true;
	}
	else{
		
		return false;
	}
}
