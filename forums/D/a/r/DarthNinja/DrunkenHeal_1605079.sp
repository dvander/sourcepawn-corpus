#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.0.1"

new Handle:v_HealAmount = INVALID_HANDLE;
new Handle:v_Cooldown = INVALID_HANDLE;
new Handle:v_BrokenBottle = INVALID_HANDLE;

new bool:IsSuddenDeath;

new bool:IsCoolingDown[MAXPLAYERS+1] = false;

new bool:IsDrinking[MAXPLAYERS+1] = false;
new Float:orig[MAXPLAYERS+1][3];

public Plugin:myinfo =
{
	name = "[TF2] Drunken Heal: Refilled",
	author = "DarthNinja",
	description = "The booze! It heals!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_drunkenhealz_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	v_HealAmount = CreateConVar("sm_drunkenheal_amount", "15", "Amount Healed By Bottle - 0 disables plugin.");
	v_Cooldown = CreateConVar("sm_drunkenheal_cooldown", "0", "Heal Cooldown Time [In Seconds] | 0 = Disabled (Default 10)", 0, true, 0.0, false);
	v_BrokenBottle = CreateConVar("sm_drunkenheal_broken", "3", "Broken Bottle: 0 = Heals nothing, 1 = Heals half value, 2 = Deals double, 3 = no change");

	AutoExecConfig(true, "DrunkenHeal");
	
	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
	HookEvent("post_inventory_application", Event_Regen);
	
	RegConsoleCmd("+taunt", OnPlayerTaunt);
	RegConsoleCmd("taunt", OnPlayerTaunt);
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
	IsSuddenDeath = true;

public Event_Regen(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsCoolingDown[client] = false;
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
	IsSuddenDeath = false;

public OnMapStart()
{
	IsSuddenDeath = false;
	
	for (new i = 1; i < MaxClients; i++)
	{
		IsCoolingDown[i] = false;
		IsDrinking[i] = false;
	}
}

public OnClientDisconnect(client)
{
	IsCoolingDown[client] = false;
	IsDrinking[client] = false;
}

public Action:OnPlayerTaunt(client, args)
{
	if (!IsPlayerAlive(client) || TF2_GetPlayerClass(client) != TFClass_DemoMan || /*!TF2_IsPlayerInCondition(client, TFCond:TF_CONDFLAG_TAUNTING) || */ GetConVarInt(v_HealAmount) == 0)
		return Plugin_Continue;
	
	if (IsSuddenDeath)
	{
		PrintHintText(client, "Drunken Heal is Disabled in Sudden Death!");
		return Plugin_Continue;
	}
	
	new iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iActiveWeapon == -1)
		return Plugin_Continue;
	new iItemID = GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	//---------------------------
	// 1	=	Bottle
	// 191	=	Custom Bottle
	// 609	=	Scottish Handshake
	//---------------------------
	if (iItemID == 1 || iItemID == 191 || iItemID == 609)
	{
		if (IsCoolingDown[client] == false && !IsDrinking[client])
		{
			new iTimer = GetConVarInt(v_Cooldown);
			if(iTimer > 0)
			{
				IsCoolingDown[client] = true;
				CreateTimer(float(iTimer), CooldownTimer, GetClientUserId(client));
			}
			IsDrinking[client] = true;
			GetClientAbsOrigin(client, orig[client]);
			
			CreateTimer(2.2, OnStartDrinking, GetClientUserId(client));
			CreateTimer(4.0, OnFinishDrinking, GetClientUserId(client));
		}
	}
	
	return Plugin_Continue;
}

public Action:CooldownTimer(Handle:timer, any:user)
{
	new client = GetClientOfUserId(user);
	if (client != 0 && TF2_GetPlayerClass(client) == TFClass_DemoMan)
		PrintHintText(client, "Your Bottle Is Full Again");
	IsCoolingDown[client] = false;
	return Plugin_Continue;
}


public Action:OnFinishDrinking(Handle:timer, any:user)
{
	new client = GetClientOfUserId(user);
	if (client != 0)
		IsDrinking[client] = false;
	return Plugin_Continue;
}

public Action:OnStartDrinking(Handle:timer, any:user)
{
	new client = GetClientOfUserId(user);
	if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:fNewOrigin[3];
		GetClientAbsOrigin(client, fNewOrigin);
		if(!ArrayEqual(orig[client], fNewOrigin, 3))
			return Plugin_Continue;	//Player changed location
		
		new iWeapon = GetPlayerWeaponSlot(client, 2);
		if (iWeapon == -1)
			return Plugin_Continue; //No melee weapon
			
		new iHP = GetConVarInt(v_HealAmount);
		if(GetEntProp(iWeapon, Prop_Send, "m_bBroken") == 1)	//Bottle is broken
		{
			new iBroken = GetConVarInt(v_BrokenBottle);
			switch (iBroken)
			{
				case 0: 
					iHP = 0;
				case 1:
					iHP = RoundFloat(iHP * 0.5);
				case 2:
					iHP = iHP * 2;
			}
		}
		
		if (iHP == 0)
			PrintHintText(client, "Sorry, ye cannot be swiggin' from a broken bottle!\n 0 damage healed.");
		else
		{
			//It would be better to get the true value of the client's max health rather then assumming it is 175.
			new iCurrentHealth = GetClientHealth(client);
			if (iCurrentHealth + iHP >= 175)
				SetEntityHealth(client, 175);
			else
				SetEntityHealth(client, iCurrentHealth + iHP);
				
			PrintHintText(client, "Your Bottle Healed %i Health!", iHP);
		}
	}
	return Plugin_Continue;
}

stock ArrayEqual(any:one[], any:two[], length)
{
	for (new i=0; i<length; i++)
	{
		if (one[i] != two[i])
		{
			return false;
		}
		return true;
	}
	return false;
}