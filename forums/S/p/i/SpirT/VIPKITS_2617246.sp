                                               /* THIS IS A NEW VERSION OF VIPKIT! */
								/* TRANSLATIONS WILL BE ADDED ON THE NEXT VERSION IF IT COMES OUT */
							/* THIS IS A PUBLIC PLUGIN YOU CAN'T SELL IT WITH MY PERMISSION OR POST IT */
						  /* THIS PLUGIN IS MY AUTHORY SO IF YOU POST A PLUGIN LIKE MINE I WILL REPORT IT */
						  
#pragma semicolon 1

#define DEBUG

#define PLUGIN_NAME "VIP Weapon & Client Name on Joining server"
#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_DESCRIPTION "VIP Weapons on Spawn if VIP do command"

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <colors>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	description = PLUGIN_DESCRIPTION,
	url = "https://steamcommunity.com/id/spirtbtx"	
};

public void OnPluginStart()
{
	RegAdminCmd("sm_vipak47", Cmd_ak47, ADMFLAG_CUSTOM1, "AK47 if client has certain flag"); /* FOR THIS THE CLIENT NEEDS THE FLAG "o" */
	RegAdminCmd("sm_vipm4a4", Cmd_m4a4, ADMFLAG_CUSTOM1, "M4A4 is client has certain flag"); /* FOR THIS THE CLIENT NEEDS THE FLAG "o" */
	RegAdminCmd("sm_vipawp", Cmd_awp, ADMFLAG_CUSTOM1, "AWP if client has certain flag");    /* FOR THIS THE CLIENT NEEDS THE FLAG "o" */
}

public void OnClientConnected(int client)
{
	decl String:name[128];
	
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("{blue}[VIP KIT] {purple}%s {red} is joining the server!", name);
}

public void OnClientPutInServer(int client)
{
	decl String:name[128];
	
	GetClientName(client, name, sizeof(name));
	CPrintToChat(client, "{blue}[VIP KIT] {red}Hello {purple}%s {red} and {green}welcome to our server!", name);
	CPrintToChat(client, "{blue} [VIP KIT] {red}Don't forgot to buy {blue}VIP {red} to get acess to the {purple}KITS");
}

public Action Cmd_ak47(int client, int args)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_ak47");
		CPrintToChat(client, "{blue}[VIP KIT] {red}You choosed AK47! {purple}GOOD LUCK!"); /* IF PLAYER IS ALIVE HE CAN USE VIP KIT */
	}
	else
	{
		CPrintToChat(client, "{blue}[VIP KIT] {red}You need to be {purple}alive {red}to use this {blue}command"); /* IF PLAYER IS DEAD HE CAN'T USE VIP KIT */
	}
	
	return Plugin_Handled;
}

public Action Cmd_m4a4(int client, int args)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_m4a1");
		CPrintToChat(client, "{blue}[VIP KIT] {red}You choosed M4A4! {purple}GOOD LUCK!"); /* IF PLAYER IS ALIVE HE CAN USE VIP KIT */
	}
	else
	{
		CPrintToChat(client, "{blue}[VIP KIT] {red}You need to be {purple}alive {red}to use this {blue}command"); /* IF PLAYER IS DEAD HE CAN'T USE VIP KIT */
	}
	
	return Plugin_Handled;
}

public Action Cmd_awp(int client, int args)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_awp");
		CPrintToChat(client, "{blue}[VIP KIT] {red}You choosed AWP! {purple}GOOD LUCK!"); /* IF PLAYER IS ALIVE HE CAN USE VIP KIT */
	}
	else
	{
		CPrintToChat(client, "{blue}[VIP KIT] {red}You need to be {purple}alive {red}to use this {blue}command"); /* IF PLAYER IS DEAD HE CAN'T USE VIP KIT */
	}
	
	return Plugin_Handled;
}

/* YOU CAN COMPILE THIS BUT YOU CAN'T POST THIS ON YOUR ACCOUNT OR SELL IT! */
/* IF SOMEONE SAYS THAT PLUGIN IS PRIVATE, IT ISN'T YOU HAVE HERE MY PROFF THAT IS IT FREE :D */
/* IF YOU WANT MY GITHUB WILL BE AVAIABLE LATER :D */