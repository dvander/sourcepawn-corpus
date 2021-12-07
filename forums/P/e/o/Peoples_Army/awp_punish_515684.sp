/*  

	Awp Punishment-
	
		*This Plugin Will Punish Players That Shoot Restricted Weapons. With Differnt Levels Of Punishment.
		*Flags For WEapons 
  
  Version 0.4
  
  Punishment Flags
  
  a  == start on fire
  b  == slap player - 1 health 
  c  == strip weapons 
  d  == take armor away - 30
  e  == force suicide
  
  Weapons Restricted Flags 
  
  a  == Awp 
  b  == g3sg1
  c  == sg550
  d  == scout
  e  == sg552
  
  
*/
  
#include <sourcemod>
#include <sdktools>

#define VERSION "1.5"

new Handle:Switch;
new Handle:Punishment;
new Handle:RemoveItems;
new Handle:Config;
new String:Weapon[20];
new Handle:RestrictedWeapons;
new Handle:MaxShots;
new Handle:AwpMap;
new Shots;

public Plugin:myinfo = 
{
	name = "Awp Punishment",
	author = "Peoples Army",
	description = "Punishes For Using An Awp",
	version = VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	Switch = CreateConVar("awp_punish_on","1","1 Tunrs The Plugin On 0 Is Off", FCVAR_NOTIFY);
	Punishment = CreateConVar("awp_punish_mode","a","punishment flags",FCVAR_NOTIFY);
	RestrictedWeapons = CreateConVar("awp_punish_weps","a","Sets The Weapons To Punish For",FCVAR_NOTIFY);
	MaxShots = CreateConVar("awp_punish_max_shots","0","Amount OF Shots Allowed Before Punishing");
	AwpMap = CreateConVar("awp_punish_awp_map","0","Wether The Plugin Is On For Awp Maps Or Not");
	
	HookEvent("weapon_fire",WeaponEvent);
	HookEvent("player_death",DeathEvent);
	HookEvent("round_start",RoundStart);
	
	Config = LoadGameConfigFile("plugin.awp_punish");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(Config, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	RemoveItems = EndPrepSDKCall();
}

// catch weapon fire and see if its an awp
public Action:WeaponEvent(Handle:event , String:name[] , bool:dontBroadcast)
{
	new String:Map[32];
	GetCurrentMap(Map,31);
	
	if(GetConVarInt(Switch) && (GetConVarInt(AwpMap) == 0 || StrContains(Map,"awp_") == -1))
	{
		new clientID = GetEventInt(event,"userid");
		new client = GetClientOfUserId(clientID);
		new String:Weps[20];
		
		Shots++;
		
		GetConVarString(RestrictedWeapons,Weps,20);
		GetClientWeapon(client,Weapon,19)
	 
		if(StrEqual("weapon_awp",Weapon)== true && StrContains(Weps,"a")!= -1 && Shots > GetConVarInt(MaxShots))   //flag a AWP
		{
			PunishPlayer(client);
		}
		if(StrEqual("weapon_g3sg1",Weapon)== true && StrContains(Weps,"b")!= -1 && Shots > GetConVarInt(MaxShots)) //flag b g3sg1
		{
			PunishPlayer(client);
		}
		if(StrEqual("weapon_sg550",Weapon)== true && StrContains(Weps,"c")!= -1 && Shots > GetConVarInt(MaxShots))  //flag c sg550
		{
			PunishPlayer(client);
		}
		if(StrEqual("weapon_scout",Weapon)== true && StrContains(Weps,"d")!= -1 && Shots > GetConVarInt(MaxShots))  //flag d scout
		{
			PunishPlayer(client);
		}
		if(StrEqual("weapon_sg552",Weapon)== true && StrContains(Weps,"c")!= -1 && Shots > GetConVarInt(MaxShots)) //flag e sg552
		{
			PunishPlayer(client);
		}
	}
}

public Action:RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(GetConVarInt(Switch))
	{
		Shots = 0;
	}
}

// punish player based on flags
public PunishPlayer(client)
{
	new String:Mode[20];
	GetConVarString(Punishment,Mode,20);
	PrintToChat(client,"You Have Been Punished For Using A Restricted Weapon");
	
	if(StrContains(Mode,"a")!= -1) // flag a
	{
		IgniteEntity(client,15.0);
	}
	if(StrContains(Mode,"b")!= -1)  // flag b
	{
		SlapPlayer(client,45);
	}
	if(StrContains(Mode,"c")!= -1) // flag c
	{
		StripClientWeapons(client);
	}
	if(StrContains(Mode,"d")!= -1) // flag d
	{
		SetClientArmor(client,0);
	}
	if(StrContains(Mode,"e")!= -1)  // flag e
	{
		ForcePlayerSuicide(client);
	}
}

public DeathEvent(Handle:event , String:name[] , bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);
		
	if(GetConVarInt(Switch) && IsClientInGame(client)== true)
	{	 
		ExtinguishEntity(client);
	}
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client)== true)
	{
		ExtinguishEntity(client);
	}
}

public bool:OnClientConnect(client)
{
	if(IsClientInGame(client)== true)
	{
		ExtinguishEntity(client);
	}
	return true;
}

stock SetClientArmor(client,armour)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", armour, 1);
	return 0;
}

stock StripClientWeapons(client)
{
	SDKCall(RemoveItems, client,false);
	return 0;
}