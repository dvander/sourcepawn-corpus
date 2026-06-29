/*  

	Awp Punishment-
	
		*This Plugin Will Punish Players That Shoot Restricted Weapons. With Differnt Levels Of Punishment.
		*Flags For WEapons 
  
  Version 1.3
  
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

#define VERSION "1.3"
#define CS_SLOT_PRIMARY		0	/**< Primary weapon slot. */
#define CS_SLOT_SECONDARY	1	/**< Secondary weapon slot. */

new Handle:Switch;
new Handle:Punishment;
new String:Weapon[20];
new Handle:RestrictedWeapons;
new Handle:MaxShots;
new Handle:AwpMap;
new Shots[MAXPLAYERS + 1];
new info[MAXPLAYERS + 1];
new Max_Shots;
new onoff = 1;

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
	Switch = CreateConVar("awp_punish_on","1","1 Turns The Plugin On 0 Is Off", FCVAR_NOTIFY);
	Punishment = CreateConVar("awp_punish_mode","a","punishment flags: a = start on fire; b = slap player - 1 health; c = strip weapons; d = take armor away - 30; e = force suicide",FCVAR_NOTIFY);
	RestrictedWeapons = CreateConVar("awp_punish_weps","a","Sets The Weapons To Punish For: a = Awp; b = g3sg1; c = sg550; d = scout; e = sg552",FCVAR_NOTIFY);
	MaxShots = CreateConVar("awp_punish_max_shots","0","Amount OF Shots Allowed Before Punishing");
	AwpMap = CreateConVar("awp_punish_awp_map","0","Wether The Plugin Is On For Awp Maps Or Not");
	
	HookEvent("weapon_fire",WeaponEvent);
	HookEvent("player_death",DeathEvent);
	HookEventEx("player_spawn",PlayerSpawn);
	
	HookConVarChange(Switch, CVAR_Changed)
	
	AutoExecConfig(true, "awp_punish")
}
public OnConfigsExecuted()
{
	onoff = GetConVarInt(Switch)
	Max_Shots = GetConVarInt(MaxShots)
}

public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Switch)
	{
		onoff = StringToInt(newValue)
		if(onoff != 1)
		{
			onoff = 0
		}
	}
	if(convar == MaxShots)
	{
		Max_Shots = StringToInt(newValue)
	}
}

public OnClientPutInServer(client)
{
	info[client] = 0
}

public Action:WeaponEvent(Handle:event , String:name[] , bool:dontBroadcast)
{
	new String:Map[32];
	GetCurrentMap(Map,31);
	
	if(onoff == 1 && (GetConVarInt(AwpMap) == 0 || StrContains(Map,"awp_") == -1))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));
		new String:Weps[20];

		GetConVarString(RestrictedWeapons,Weps,20);
		GetClientWeapon(client,Weapon,19)
	 
		if(StrEqual("weapon_awp",Weapon)== true && StrContains(Weps,"a")!= -1) //flag a AWP
		{
			Shots[client]++;
			Shots_Check(client)
			return
		}
		if(StrEqual("weapon_g3sg1",Weapon)== true && StrContains(Weps,"b")!= -1) //flag b g3sg1
		{
			Shots[client]++;
			Shots_Check(client)
			return
		}
		if(StrEqual("weapon_sg550",Weapon)== true && StrContains(Weps,"c")!= -1) //flag c sg550
		{
			Shots[client]++;
			Shots_Check(client)
			return
		}
		if(StrEqual("weapon_scout",Weapon)== true && StrContains(Weps,"d")!= -1) //flag d scout
		{
			Shots[client]++;
			Shots_Check(client)
			return
		}
		
		if(StrEqual("weapon_sg552",Weapon)== true && StrContains(Weps,"e")!= -1) //flag e sg552
		{
			Shots[client]++;
			Shots_Check(client)
			return
		}
	}
	return
}
Shots_Check(client)
{
	if(Shots[client] > Max_Shots)
	{
		PunishPlayer(client);
		return;
	}
	PrintToChat(client, "\x01SNIPER-Punishment ENABLED !!! \x04%d \x01shots left !!", (GetConVarInt(MaxShots) - Shots[client]))
	return
}

public Action:PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(onoff == 1)
	{
		Shots[client] = 0;
		new team = GetClientTeam(client)
		if(team == 2 || team == 3)
		{
			if(info[client] == 0)
			{
				PrintToChat(client, "\x03############################")
				PrintToChat(client, "\x03### SNIPER-Punishment ENABLED !!!")
				PrintToChat(client, "\x03############################")
				info[client] = 1
			}
		}
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
		if(IsPlayerAlive(client))
		{
			SetEntityHealth(client, 1)
		}
	}
	if(StrContains(Mode,"c")!= -1) // flag c
	{
		if(IsPlayerAlive(client))
		{
			StripClientWeapons(client);
		}
	}
	if(StrContains(Mode,"d")!= -1) // flag d
	{
		if(IsPlayerAlive(client))
		{
			SetClientArmor(client,0);
		}
	}
	if(StrContains(Mode,"e")!= -1)  // flag e
	{
		if(IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
	}
}

public DeathEvent(Handle:event , String:name[] , bool:dontBroadcast)
{
	new clientID = GetEventInt(event,"userid");
	new client = GetClientOfUserId(clientID);
		
	if(onoff == 1 && IsClientInGame(client)== true)
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
	new prim_w = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(prim_w != -1)
	{
		RemovePlayerItem(client, prim_w);
	}
}