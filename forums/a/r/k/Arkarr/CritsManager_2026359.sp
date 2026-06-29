#include <sourcemod>  
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

new String:plugintag[40] = "{strange}[CritsManager]{default} ";

new Handle:g_BanOrAddCrits;
new Handle:g_DisplayMessage;
new Handle:WeaponIndexArray;


public Plugin:myinfo =  
{  
	name = "Crits Manager",  
	author = "Arkarr",  
	description = "Active/remove crits for some weapons",  
	version = "3.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre)
	
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitch);
	}
	
	g_BanOrAddCrits = CreateConVar("sm_ban_or_add_crits", "0", "Should weapon get banned from crits or added ?");
	g_DisplayMessage = CreateConVar("sm_display_crits_messge", "1", "Should the plugin warn players when they lost/get crits ?");
	
	WeaponIndexArray = CreateArray(5);
	
	GetWeaponsIndex();
}

public OnClientPutInServer(client)
{    
	SDKHook(client, SDKHook_WeaponCanSwitchToPost, OnWeaponSwitch);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsPlayerAlive(client) && IsClientConnected(client))
	{
		if(GetConVarInt(g_BanOrAddCrits) == 1)
			TF2_AddCondition(client, TFCond_CritOnWin, 9999999.0);
			
		new hClientWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
		new weaponindex = -1
		
		if(hClientWeapon != -1)
			weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
		if(weaponindex != -1)
			CheckWeapon(client, weaponindex);
	}
}

public Action:OnWeaponSwitch(client, weapon)
{
	if(client > 0 && IsPlayerAlive(client) && IsClientConnected(client))
	{
		new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		CheckWeapon(client, weaponindex);
	}
}

stock CheckWeapon(client, weaponindex)  
{
	if(FindValueInArray(WeaponIndexArray, weaponindex))
	{
		if(GetConVarInt(g_BanOrAddCrits) == 0)
		{
			if(GetConVarInt(g_DisplayMessage) == 1)
				CPrintToChat(client, "%sCrits are {green}actived {default}for this weapon !", plugintag);
				
			TF2_AddCondition(client, TFCond_CritOnWin, 9999999.0);
		}
		else if(GetConVarInt(g_BanOrAddCrits) == 1)
		{
			if(GetConVarInt(g_DisplayMessage) == 1)
				CPrintToChat(client, "%sCrits are {red}removed {default}for this weapon !", plugintag);
				
			TF2_RemoveCondition(client, TFCond_CritOnWin);
		}
		else
		{
			PrintToServer("Inavlid value for sm_ban_or_add_crits ! Accepted values : '0' and '1'");
		}
	}
	else
	{
		if(GetConVarInt(g_BanOrAddCrits) == 0)
			TF2_RemoveCondition(client, TFCond_CritOnWin);
		else
			TF2_AddCondition(client, TFCond_CritOnWin, 9999999.0);
	}
}

stock GetWeaponsIndex()
{
	decl String:path[PLATFORM_MAX_PATH], String:line[128];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/CritsWeapon.cfg");
	new Handle:fileHandle=OpenFile(path, "r");
	while(!IsEndOfFile(fileHandle)&& ReadFileLine(fileHandle, line, sizeof(line)))
		PushArrayCell(WeaponIndexArray, StringToInt(line));
	CloseHandle(fileHandle);
}
