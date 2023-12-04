 /* 
* 
*  Extra Nades 
*   By 
*    Peoples Army 
* 
* Version 1.0 - Origonal Release
* 
*    Flags For Nades :
* 
*     a == HE Nades
*     b == Flash Nades
*     c == Smoke Nades
*/

#include <sourcemod>
#include <sdktools>

new Handle: Switch;
new Handle: Amount;
new Handle: NadeType;
new he_nades_num[MAXPLAYERS + 1] = 0
new fb_nades_num[MAXPLAYERS + 1] = 0
new sg_nades_num[MAXPLAYERS + 1] = 0 

public Plugin:myinfo = 
{
	 name = "Extra Nads",
	 author = "Peoples Army",
	 description = "Gives Extra Nades To Players",
	 version = "1.0",
	 url = ""
}

public OnPluginStart()
{
	 Switch = CreateConVar("extra_nades_on","1","Turns The Plugin On Or Off",FCVAR_NOTIFY);
	 Amount = CreateConVar("extra_nades_amount","3","The Amount Of Extra Nades Given To Players",FCVAR_NOTIFY);
	 NadeType = CreateConVar("extra_nades_type","abc","The Flags For Which Type Of Nades To Give",FCVAR_NOTIFY);
	 
	 HookEvent("hegrenade_detonate",HeGrenade);
	 HookEvent("flashbang_detonate",FbGrenade);
	 HookEvent("smokegrenade_detonate",SgGrenade);
	 HookEvent("player_death",DeathEvent);
}

public Action:HeGrenade(Handle:event,String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);  
	new String:Mode[20];
	 
	if(GetConVarInt(Switch) && he_nades_num[client] < GetConVarInt(Amount))
	{
		GetConVarString(NadeType,Mode,20);
		PrintToChat(client,"You Have Been Given Extra Nades");
	  
		if(StrContains(Mode,"a")!= -1) // flag a He Nades
		{
			GivePlayerItem(client,"weapon_hegrenade");
			++he_nades_num[client];
		}
	}
}

public Action:FbGrenade(Handle:event,String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);  
	new String:Mode[20];
 
	if(GetConVarInt(Switch) && fb_nades_num[client] < GetConVarInt(Amount))
	{
		GetConVarString(NadeType,Mode,20);
		PrintToChat(client,"You Have Been Given Extra Nades");
  
		if(StrContains(Mode,"b")!= -1) // flag b Flash Nades
		{
			GivePlayerItem(client,"weapon_flashbang");
			++fb_nades_num[client];
		}
	}
}

public Action:SgGrenade(Handle:event,String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);  
	new String:Mode[20];
 
	if(GetConVarInt(Switch) && sg_nades_num[client] < GetConVarInt(Amount))
	{
		GetConVarString(NadeType,Mode,20);
		PrintToChat(client,"You Have Been Given Extra Nades");
  
		if(StrContains(Mode,"c")!= -1) // flag c Smoke Nades
		{
			GivePlayerItem(client,"weapon_smokegrenade");
			++sg_nades_num[client];
		}
	}
}

public Action:DeathEvent(Handle:event , String:name[] , bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);
 
	if(GetConVarInt(Switch) && IsClientInGame(client))
	{
		he_nades_num[client] = 0
		fb_nades_num[client] = 0
		sg_nades_num[client] = 0
	}
}

public OnClientDisconnect(client)
{
	he_nades_num[client] = 0;
	fb_nades_num[client] = 0;
	sg_nades_num[client] = 0;
 
}
public bool:OnClientConnect(client)
{

	he_nades_num[client] = 0;
	fb_nades_num[client] = 0;
	sg_nades_num[client] = 0;
}