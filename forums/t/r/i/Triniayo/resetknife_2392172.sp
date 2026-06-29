#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma newdecls required
#pragma semicolon 1

/***************************************************
 * GLOBALS
 **************************************************/
 int g_iTakeKnifeUserIds[MAXPLAYERS+1] = {-1, ...};

/***************************************************
 * PLUGIN STUFF
 **************************************************/

public Plugin myinfo =
{
	name = "Reset Knife",
	author = "Trinia",
	description = "Allows players to reset their knife with !resetknife",
	version = "1.0.0",
	url = "www.trinia.pro",
	//credits = "Neuro Toxin",
}

public void OnPluginStart()
{
	RegisterCommands();
	Convar_Create();
	Convar_Hook();
}

public void OnConfigsExecuted()
{
	Convar_Load();
}

/***************************************************
 * CONVAR STUFF
 **************************************************/

Handle hcvar_knifeswapper_kniferequired = null;
bool cvar_knifeswapper_kniferequired = false;

Handle hcvar_knifeswapper_disablecmdmessages = null;
bool cvar_knifeswapper_disablecmdmessages = false;

stock void Convar_Create()
{
	hcvar_knifeswapper_kniferequired = CreateConVar("knifeswapper_kniferequired", "0", "Clients who dont have a knife cant receive one via any plugin commands.");
	hcvar_knifeswapper_disablecmdmessages = CreateConVar("knifeswapper_disablecmdmessages", "0", "Hides plugin commands so they dont display in chat.");
}

stock void Convar_Load()
{
	cvar_knifeswapper_kniferequired = GetConVarBool(hcvar_knifeswapper_kniferequired);
	cvar_knifeswapper_disablecmdmessages = GetConVarBool(hcvar_knifeswapper_disablecmdmessages);
}

stock void Convar_Hook()
{
	HookConVarChange(hcvar_knifeswapper_kniferequired, Convar_OnChanged);
	HookConVarChange(hcvar_knifeswapper_disablecmdmessages, Convar_OnChanged);
}

public void Convar_OnChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (cvar == hcvar_knifeswapper_kniferequired)
		cvar_knifeswapper_kniferequired = StringToInt(newVal) == 1 ? true : false;
	else if (cvar == hcvar_knifeswapper_disablecmdmessages)
		cvar_knifeswapper_disablecmdmessages = StringToInt(newVal) == 1 ? true : false;
}

/***************************************************
 * RESET KNIFE COMMAND
 **************************************************/

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if ((StrContains(args, "!resetknife", false) == 0)
			&& cvar_knifeswapper_disablecmdmessages)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

/***************************************************
 * COMMAND STUFF
 **************************************************/

stock void RegisterCommands()
{
	RegConsoleCmd("resetknife", OnCommandResetKnife);
}

public Action OnCommandResetKnife(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;
		
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
		
	g_iTakeKnifeUserIds[client] = -1;
	
	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
		return Plugin_Handled;
	
	int targetactiveweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	bool playerhasknife = false;
	bool equiptargetnewknife = false;
	bool equiptaser = false;
	int targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	
	while (targetknife != -1)
	{
		// check for taser
		if (GetEntProp(targetknife, Prop_Send, "m_iItemDefinitionIndex") == 31)
			equiptaser = true;
		else
		{
			playerhasknife = true;
			if (targetactiveweapon == targetknife)
				equiptargetnewknife = true;
		}
		
		RemovePlayerItem(client, targetknife);
		AcceptEntityInput(targetknife, "Kill");
		targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	}
	
	if (cvar_knifeswapper_kniferequired)
	{
		if (playerhasknife)
			GivePlayerItem(client, "weapon_knife");
	}
	else
		GivePlayerItem(client, "weapon_knife");
	
	if (equiptaser)
		GivePlayerItem(client, "weapon_taser");
		
	if (equiptargetnewknife)
		CreateTimer(0.01, OnEquipPlayerKnifeRequired, GetClientUserId(client));
		
	PrintToChat(client, "[SM] You knife has been reset!");
	return Plugin_Handled;
}

/***************************************************
 * KNIFE STUFF
 **************************************************/

stock Action GivePlayerKnife(int client, int target, int commandclient, bool displaymessage=true)
{
	if (!IsClientInGame(client))
		return Plugin_Stop;

	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife == -1)
	{
		ReplyToCommand(commandclient, "[SM] Knife not found!");
		return Plugin_Stop;
	}
	
	if (cvar_knifeswapper_kniferequired && !PlayerHasKnife(target))
		return Plugin_Continue;
	
	g_bBlockItemEquip[client] = true; // paintkits fix
	int newknife = GivePlayerItem(client, "weapon_knife");
	g_bBlockItemEquip[client] = false; // paintkits fix
	if (newknife == -1)
	{
		ReplyToCommand(commandclient, "[SM] Unable to spawn your knife!");
		return Plugin_Stop;
	}
	
	int weaponindex = GetEntProp(newknife, Prop_Send, "m_iItemDefinitionIndex");
	if (weaponindex == 42 || weaponindex == 59) // standard knife || knife t
	{
		if (commandclient == client)
			ReplyToCommand(commandclient, "[SM] You cant give your default knife to another player!");
		else
			ReplyToCommand(commandclient, "[SM] You cant take a default knife from another player!");
		AcceptEntityInput(newknife, "Kill");
		return Plugin_Stop;
	}
	
	bool equiptargetnewknife = false;
	int targetactiveweapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
	bool equiptaser = false;
	int targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	
	while (targetknife != -1)
	{
		// check for taser
		if (GetEntProp(targetknife, Prop_Send, "m_iItemDefinitionIndex") == 31)
			equiptaser = true;
		else
		{
			if (targetactiveweapon == targetknife)
				equiptargetnewknife = true;
		}
		
		RemovePlayerItem(target, targetknife);
		AcceptEntityInput(targetknife, "Kill");
		targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	}
	
	float targetvec[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetvec);
	TeleportEntity(newknife, targetvec, NULL_VECTOR, NULL_VECTOR);
	
	EquipPlayerWeapon(target, newknife);
	if (equiptargetnewknife)
		CreateTimer(0.01, OnEquipPlayerKnifeRequired, GetClientUserId(target));
		
	if (equiptaser)
		GivePlayerItem(target, "weapon_taser");
	
	PrintToChat(target, "\x01[SM] You received a knife from \x04%N", client);
	
	if (displaymessage)
		PrintToChat(client, "\x01[SM] You gave your knife to \x04%N", target);
	return Plugin_Continue;
}

public Action OnEquipPlayerKnifeRequired(Handle tmr, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Continue;

	int targetknife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (targetknife == -1)
		return Plugin_Continue;
		
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", targetknife);
	return Plugin_Continue;
}

stock void SwapPlayerKnife(int client, int target)
{		
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife == -1)
	{
		ReplyToCommand(client, "[SM] Knife not found!");
		return;
	}
	
	int targetknife = GetPlayerWeaponSlot(target, CS_SLOT_KNIFE);
	if (targetknife == -1)
	{
		ReplyToCommand(client, "[SM] Target does not have a knife!");
		return;
	}
	
	CS_DropWeapon(client, knife, false, true);
	CS_DropWeapon(target, targetknife, false, true);
	
	float clientvec[3]; float targetvec[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientvec);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetvec);
	
	TeleportEntity(knife, targetvec, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(targetknife, clientvec, NULL_VECTOR, NULL_VECTOR);
	
	EquipPlayerWeapon(client, targetknife);
	EquipPlayerWeapon(target, knife);
}

stock void ForceSpawnPlayerKnife(int client)
{
	if (!IsClientInGame(client))
		return;
		
	if (!IsPlayerAlive(client))
		return;
		
	if (GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		return;
		
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (knife > 0)
		return;
		
	knife = GivePlayerItem(client, "weapon_knife");
}

stock bool PlayerHasCorrectFlags(int client)
{
	if (StrEqual(cvar_knifeswapper_flag, ""))
		return true;
	
	AdminId admin = GetUserAdmin(client);
	if (admin == INVALID_ADMIN_ID)
		return false;
	
	AdminFlag flag;
	if (!FindFlagByChar(cvar_knifeswapper_flag[0], flag))
		return true;
	
	if (!GetAdminFlag(admin, flag))
		return false;

	return true;
}

stock bool IsDefIndexMelee(int defindex)
{
	// As this is called with defindicies from weaponslot_melee
	// if the index isnt a taser, we know its a knife
	if (defindex == 31)
		return false;

	return true;
}

stock bool PlayerHasKnife(int client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (weapon == -1 || weapon == 31)
		return false;
	
	return true;
}