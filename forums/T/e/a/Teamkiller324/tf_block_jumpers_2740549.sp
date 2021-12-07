#include	<sdkhooks>
#include	<sdktools>
#include	<multicolors>

#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=	{
	name		=	"[TF2] Block Jumpers",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Prevent the Rocket Jumper & Sticky Jumper from being equipped.",
	version		=	"0.1",
	url			=	"https://steamcommunity.com/id/Teamkiller324"
}

public void OnMapStart()	{
	for(int i = 0; i < MaxClients; i++)	{
		if(!IsValidClient(i))
			continue;
		
		SDKHook(i, SDKHook_WeaponEquipPost, WeaponEquipPost);
	}
}

public void OnClientPutInServer(int client)	{
	SDKHook(client, SDKHook_WeaponEquipPost, WeaponEquipPost);
}

public void OnClientDisconnect(int client)	{
	SDKUnhook(client, SDKHook_WeaponEquipPost, WeaponEquipPost);
}

Action WeaponEquipPost(int client, int weapon)	{
	if(!IsValidClient(client))
		return	Plugin_Handled;
	
	switch(GetWeaponDefinitionIndex(weapon))	{
		case	237:	{
			CPrintToChat(client, "The {orange}Rocket Jumper {default}is not permitted in this server.");
			RemovePlayerItem(client, weapon);
		}
		case	265:	{
			CPrintToChat(client, "The {orange}Sticky Jumper {default}is not permitted in this server");
			RemovePlayerItem(client, weapon);
		}
	}
	
	return	Plugin_Continue;
}

/**
 *	Returns if the client is valid.
 *
 *	@param client		Client index.
 *	@return				Valid if true, else not valid.
 *	@error				Invalid client index.
 */
stock bool IsValidClient(int client)	{
	if(client == 0)
		return	false;
	if(client == -1)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}

//Taken from Tklib

/**
 *	Get the weapon definition index value
 *
 *	@param weapon		Weapon entity.
 */
stock int GetWeaponDefinitionIndex(int weapon)	{
	return	GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}