#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <smlib>
#include <cstrike>
#include <waky>

//------------Defines------------
#define PLUGIN_VERSION "1.0"
#define URL "www.area-community.net"
#define AUTOR "Waky"
#define NAME "Player respawn"
#define DESCRIPTION "Players can respawn with !respawn"
#define MAX_FILE_LEN 256

new Handle:hTag = INVALID_HANDLE;
new Handle:hColor = INVALID_HANDLE;
new Handle:hEnable = INVALID_HANDLE;
new Handle:hEnableSP = INVALID_HANDLE;
new Handle:hSPTime = INVALID_HANDLE;
new String:sTag[MAX_FILE_LEN];
new String:sColor[MAX_FILE_LEN];
new iEnable;
new iEnableSP;
new Float:fSPTime;

public Plugin:myinfo = 
{
	name = NAME,
	author = AUTOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}
public OnPluginStart()
{
	hTag = CreateConVar("respawn_tag","Waky-Respawn","Chattag");
	hColor = CreateConVar("respawn_color","green","Farbe des Tags");
	hEnable = CreateConVar("respawn_enable","1","Enable the plugin? 1= ON, 0 = Off");
	hEnableSP = CreateConVar("respawn_sp_enable","1","Enable the spawnprotection? 1= ON, 0 = Off");
	hSPTime = CreateConVar("respawn_sp_time","3.0","How long a player should be protected?");
	HookEvent("player_spawn",OnSpawn);
	LoadTranslations("respawn.phrases");
	AutoExecConfig(true,"player-respawn");
	RegConsoleCmd("sm_respawn",Respawn);
}
public OnConfigsExecuted()
{
	GetConVarString(hTag,sTag,MAX_FILE_LEN);
	GetConVarString(hColor,sColor, MAX_FILE_LEN);
	iEnable = GetConVarInt(hEnable);
	iEnableSP = GetConVarInt(hEnableSP);
	fSPTime = GetConVarFloat(hSPTime);
}
public OnClientPutInServer(client)
{
	if(iEnable)
	{
		if(IsClientValid(client))
		{
			CPrintToChat(client,"%T","RESPAWN",LANG_SERVER,sColor,sTag);
		}
	}
}
public Action:Respawn(client,args)
{
	if(iEnable)
	{
		if(IsClientValid(client))
		{
			CS_RespawnPlayer(client);
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
// #################### Spawnprot - Start ##########################
public Action:OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(iEnableSP)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsClientValid(client))
		{
			SpawnProtection(client);
		}
	}
}
//################### Spawnprotection ########################
SpawnProtection(client)
{
	if(iEnableSP)
	{
		if(IsClientValid(client))
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			SetEntityRenderColor(client, 0, 255, 0, 255);
			CPrintToChat(client,"%T","SPENABLE",LANG_SERVER,sColor,sTag,fSPTime);
			CreateTimer(fSPTime, SpawnProtOff, client);
		}
	}
}
//########################### S-P aus #######################
public Action:SpawnProtOff(Handle:timer, any:client)
{
	if(IsClientValid(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderColor(client, 255, 255, 255,255);
		CPrintToChat(client,"%T","SPDISABLE",LANG_SERVER,sColor,sTag);
	}
}