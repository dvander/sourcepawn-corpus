//Known bugs:  Knife animation is often sketchy after BOT takeover
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <sdkhooks>
#include <cstrike>
#include <bot2player>
#include <JM>

new const String:PLUGIN_NAME[]= "bot2player"
new const String: PLUGIN_AUTHOR[]= "Bittersweet"
new const String:PLUGIN_DESCRIPTION[]= "Allows players to control bots after they've died (adapted from botcontrol for TF2 by Grognak)"
new const String: PLUGIN_VERSION[]= "2012.11.14.11.41"

new Handle:cvarEnabled
new Handle:BotTakeoverClientsHandle

new bool:b2pEnabled, bool:bHideDeath[MyMaxClients + 1] = {false, ...};

new iTargetActiveWeapon
new g_offObserverTarget
new iTargetWeapon[5]
new iTargetClip[5]
new iTargetAmmo[5]
new ClientSpecClient[MyMaxClients + 1] = {0, ...}
new ClientTookover[MyMaxClients + 1] = {0, ...}
new BetWarning[MyMaxClients + 1] = {0, ...}
new BotTakeverCost[MyMaxClients + 1] = {1000, ...}
new Nades[MyMaxClients + 1][3]
new BotTakeverCostIncrement = 250
new g_iAccount = -1
new gameround = 1

new String:iTargetActiveWeaponName[32]

public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
}
public OnPluginStart()
{
	PrintToServer("[%s %s] - Loaded", PLUGIN_NAME, PLUGIN_VERSION)
	cvarEnabled = CreateConVar("bot2player_enabled", "1", "Enable the plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	CreateConVar("bot2player_version", PLUGIN_VERSION, "Bot Control's Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD)
	HookConVarChange(cvarEnabled, CvarChange)
	b2pEnabled = GetConVarBool(cvarEnabled)
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
	HookEvent("round_start", Event_RoundStart)
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre)
	// round_freeze_end only used for debugging
	//HookEvent("round_freeze_end", Event_RoundFreezeEnd)
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget")
	BotTakeoverClientsHandle = CreateArray(1, MyMaxClients + 1)
	//PrintToServer("[%s] Handle to array=%X", PLUGIN_NAME, BotTakeoverClientsHandle)
	if(g_offObserverTarget == -1)
	{
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.")
	}
	AddCommandListener(NewTarget, "spec_next");
	AddCommandListener(NewTarget, "spec_prev");
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("BotTakeoverClients", Native_BotTakeoverClients);
	RegPluginLibrary("bot2player");
	return APLRes_Success;
}
public Native_BotTakeoverClients(Handle:otherplugin, numParams)
{
	return _:CloneHandle(BotTakeoverClientsHandle, otherplugin)
}
public OnMapStart()
{
	for (new i = 1; i <= MyMaxClients; i++)
	{
		BotTakeverCost[i] = 1000
		SetArrayCell(BotTakeoverClientsHandle, i, 0)
	}
	gameround = 1
}
public Action:Event_RoundStart(Handle:Event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MyMaxClients; i++)
	{
		ClientSpecClient[i] = 0
		//if (IsClientConnected(i) && !IsFakeClient(i) && GetArrayCell(BotTakeoverClientsHandle, i) != 0) PrintToServer("[%s] Round Start - before resetting array value for %N to 0, current value=%i", PLUGIN_NAME, i, GetArrayCell(BotTakeoverClientsHandle, i))
		SetArrayCell(BotTakeoverClientsHandle, i, 0)
		//if (IsClientConnected(i) && !IsFakeClient(i) && GetArrayCell(BotTakeoverClientsHandle, i) != 0) PrintToServer("[%s] Round Start - after resetting array value for %N to 0, current value=%i", PLUGIN_NAME, i, GetArrayCell(BotTakeoverClientsHandle, i))		
		BetWarning[i] = 0
	}
}
public Action:Event_RoundEnd(Handle:Event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MyMaxClients; i++)
	{
		ClientSpecClient[i] = 0
		//if (IsClientConnected(i) && !IsFakeClient(i) && GetArrayCell(BotTakeoverClientsHandle, i) != 0) PrintToServer("[%s] Round End - before resetting array value for %N to 0, current value=%i", PLUGIN_NAME, i, GetArrayCell(BotTakeoverClientsHandle, i))
		SetArrayCell(BotTakeoverClientsHandle, i, 0)
		//if (IsClientConnected(i) && !IsFakeClient(i) && GetArrayCell(BotTakeoverClientsHandle, i) != 0) PrintToServer("[%s] Round End - after resetting array value for %N to 0, current value=%i", PLUGIN_NAME, i, GetArrayCell(BotTakeoverClientsHandle, i))
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientObserver(i) && ClientTookover[i])
		{
			//4.6 just a hair early, 5.0 too late - 4.7 seems good
			CreateTimer(4.7, StripWeapons, i)
		}
		ClientTookover[i] = 0
		BetWarning[i] = 0
	}
	gameround++
}
public Action:Event_RoundFreezeEnd(Handle:Event, const String:name[], bool:dontBroadcast)
{
	//This entire routine is for debugging only
	PrintToServer("Round %i -----------------------------------------------------------------------", gameround)
	for (new i = 1; i <= MyMaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsClientObserver(i)) continue
		new TempWeapon[5]
		for (new ii = 0; ii <= 4; ii++)
		{
			TempWeapon[ii] = Client_GetWeaponBySlot(i, ii)
			if (TempWeapon[ii] > -1) 
			{
				new String:Weapon[32]
				GetEdictClassname(TempWeapon[ii], Weapon, sizeof(Weapon))
				if (ii == 3)
				{
					new tnades = GetAllClientGrenades(i)
					if (tnades)
					{
						PrintToServer("Nade report for %N:", i)
						if (Nades[i][0]) PrintToServer("%i HE Nades", Nades[i][0])
						if (Nades[i][1]) PrintToServer("%i Flash Nades", Nades[i][1])
						if (Nades[i][2]) PrintToServer("%i Smoke Nades", Nades[i][2])
						PrintToServer ("Line 114 - Total = %i", tnades)
					}
				}
			}
		}
	}
}
public GetAllClientGrenades(client)
{
	Nades[client][0] = 0
	Nades[client][1] = 0
	Nades[client][2] = 0
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (11 * 4);
	new granadesnr = GetEntData(client, offsNades)
	new lastgranadesnr = 0
	//PrintToServer("Raw data 0=%i", granadesnr)
	if (granadesnr > lastgranadesnr)
	{
		// HE Nades
		Nades[client][0] = granadesnr
		lastgranadesnr = granadesnr
	}
	offsNades += 4
	granadesnr += GetEntData(client, offsNades)
	//PrintToServer("Raw data 1=%i", granadesnr)
	if (granadesnr > lastgranadesnr)
	{
		// Flashbangs
		Nades[client][1] = granadesnr - lastgranadesnr
		lastgranadesnr = granadesnr
	}
	offsNades += 4
	granadesnr += GetEntData(client, offsNades)
	//PrintToServer("Raw data 2=%i", granadesnr)
	if (granadesnr > lastgranadesnr)
	{
		// Smoke Nades
		Nades[client][2] = granadesnr - lastgranadesnr
		lastgranadesnr = granadesnr
	}
	return granadesnr
}
public OnClientPostAdminCheck(client)
{
	//if (!IsFakeClient(client)) PrintToServer("[%s] - %N connected and initialized", PLUGIN_NAME, client)
	SetArrayCell(BotTakeoverClientsHandle, client, 0)
	BotTakeverCost[client] = 1000
	ClientSpecClient[client] = 0
	ClientTookover[client] = 0
	BetWarning[client] = 0
}
public Action:StripWeapons(Handle:timer, any:client)
{
	Client_RemoveAllWeapons(client)
}
public Action:NewTarget(iClient, const String:cmd[], args)
{
	new iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget")
	if (!b2pEnabled || !IsValidClient(iTarget) || !IsClientObserver(iClient)) return Plugin_Continue;
	CreateTimer(0.1, DisplayTakeOverMessage, iClient)
	return Plugin_Continue;
}
public Action:DisplayTakeOverMessage(Handle:timer, any:iClient)
{
	if (!b2pEnabled || !IsClientConnected(iClient)) return Plugin_Continue
	new ClientTeam = GetClientTeam(iClient)
	if (ClientTeam < 2) return Plugin_Continue
	new iTarget = -1
	iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget")
	if (iTarget == -1) return Plugin_Continue
	decl String:BOTName[64]
	GetClientName(iTarget, BOTName, sizeof(BOTName))
	if (!IsValidClient(iTarget) || !IsClientObserver(iClient)) return Plugin_Continue
	ClientSpecClient[iClient] = iTarget
	new ClientCash = GetMoney(iClient)
	new BotTakeover = GetArrayCell(BotTakeoverClientsHandle, iClient)
	if (BotTakeover > 1)
	{
		if (!BetWarning[iClient] && ClientCash >= BotTakeverCost[iClient])
		{
			PrintHintText(iClient, "You can't take over BOTs in any round after you've placed a bet")
			BetWarning[iClient] = 1
		}
		else
		{
			PrintHintText(iClient, "")
		}
	}
	else
	{
		if (IsFakeClient(iTarget))
		{
			if (ClientCash >= BotTakeverCost[iClient])
			{
				//PrintToServer("[%s] Cash=%i, Cost=%i", PLUGIN_NAME, ClientCash, BotTakeverCost[iClient])
				if (ClientTeam == GetClientTeam(iTarget) && ClientCash >= BotTakeverCost[iClient])
				{
					PrintHintText(iClient, "For $%i - Press the Use key [default E] to take control of %s", BotTakeverCost[iClient], BOTName)
				}
				else
				{
					PrintHintText(iClient, "")
				}
			}
		}
		else
		{
			PrintHintText(iClient, "")
		}
	}
	return Plugin_Continue
}
public Action:Event_PlayerDeath(Handle:Event, const String:name[], bool:dontBroadcast)
{
	if (!b2pEnabled) return Plugin_Continue
	new iClient = GetClientOfUserId(GetEventInt(Event, "userid"))
	if (!IsFakeClient(iClient)) CreateTimer(6.75, DisplayTakeOverMessage, iClient)
	for (new i = 1; i <= MyMaxClients; i++)
	{
		new ClientCash = GetMoney(iClient)
		if (IsClientConnected(iClient) && IsClientConnected(i) && IsClientInGame(i) && IsClientObserver(i) && ClientSpecClient[i] == iClient && (GetArrayCell(BotTakeoverClientsHandle, iClient) < 2) && ClientCash >= BotTakeverCost[iClient])
		{
			PrintHintText(i, "%N died - You can't control dead BOTs", iClient)
			ClientSpecClient[i] = 0
		}
	}
	if (!bHideDeath[iClient]) return Plugin_Continue
	CreateTimer(0.2, tDestroyRagdoll, iClient)
	return Plugin_Handled // Disable the killfeed notification for takeovers
}
public Action:tDestroyRagdoll(Handle:timer, any:iClient)
{
	new iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll")
	bHideDeath[iClient] = false
	if (iRagdoll < 0) return
	AcceptEntityInput(iRagdoll, "kill");
}
public Action:Give_iTargetWeaponsTo_iClient(Handle:timer, any:iClient)
{
	for (new i = 0; i <= 1; i++)
	{
		if (iTargetWeapon[i] != INVALID_ENT_REFERENCE)
		{
			Client_EquipWeapon(iClient, iTargetWeapon[i], false)
			Client_SetActiveWeapon(iClient, iTargetWeapon[i])
			Client_GetActiveWeaponName(iClient, iTargetActiveWeaponName, sizeof(iTargetActiveWeaponName))
			Client_SetWeaponClipAmmo(iClient, iTargetActiveWeaponName, iTargetClip[i])
			Client_SetWeaponPlayerAmmo(iClient, iTargetActiveWeaponName, iTargetAmmo[i])
		}
		Client_SetActiveWeapon(iClient, iTargetActiveWeapon)
	}
	if (Nades[iClient][0] > 0) Client_GiveWeapon(iClient, "weapon_hegrenade", false)
	if (Nades[iClient][1] > 0) Client_GiveWeapon(iClient, "weapon_flashbang", false)
	if (Nades[iClient][1] > 1) Client_GiveWeapon(iClient, "weapon_flashbang", false)
	if (Nades[iClient][2] > 0) Client_GiveWeapon(iClient, "weapon_smokegrenade", false)
}
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{	
	b2pEnabled = GetConVarBool(convar)
}
stock FindRagdollClosestToEntity(iEntity, Float:fLimit)
{
	new iSearch = -1,
	iReturn = -1;
	new Float:fLowest = -1.0,
	Float:fVectorDist,
	Float:fEntityPos[3],
	Float:fRagdollPos[3]
	if (!IsValidEntity(iEntity)) return iReturn;
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
	while ((iSearch = FindEntityByClassname(iSearch, "tf_ragdoll")) != -1)
	{
		GetEntPropVector(iSearch, Prop_Send, "m_vecRagdollOrigin", fRagdollPos);
		fVectorDist = GetVectorDistance(fEntityPos, fRagdollPos);
		if (fVectorDist < fLimit && (fVectorDist < fLowest || fLowest == -1.0))
		{
			fLowest = fVectorDist
			iReturn = iSearch
		}
	}
	return iReturn
}
stock bool:IsValidClient(iClient) 
{
	if (iClient <= 0 ||	iClient > MaxClients ||	!IsClientInGame(iClient)) return false
	return true
}
public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientConnected(iClient) || !(buttons & IN_USE) || IsPlayerAlive(iClient) || !b2pEnabled || !IsClientObserver(iClient)) return Plugin_Continue
	new iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget")
	new ClientCash = GetMoney(iClient)
	if (IsValidClient(iTarget) && IsFakeClient(iTarget) && GetClientTeam(iClient) == GetClientTeam(iTarget) && ClientCash >= BotTakeverCost[iClient])
	{
		if (GetArrayCell(BotTakeoverClientsHandle, iClient) > 1) return Plugin_Continue
		//Get all of BOTs stats
		new Float:iTargetOrigin[3],	Float:iTargetAngles[3]
		GetClientAbsOrigin(iTarget, iTargetOrigin)
		GetClientAbsAngles(iTarget, iTargetAngles)
		new iTargetHealth = GetClientHealth(iTarget)
		new iTargetArmor = GetClientArmor(iTarget)
		iTargetActiveWeapon = Client_GetActiveWeapon(iTarget)
		for (new i = 0; i <= 1; i++)
		{
			iTargetWeapon[i] = Client_GetWeaponBySlot(iTarget, i)
			if (iTargetWeapon[i] > -1) 
			{
				Client_SetActiveWeapon(iTarget, iTargetWeapon[i])
				Client_GetActiveWeaponName(iTarget, iTargetActiveWeaponName, sizeof(iTargetActiveWeaponName))
				iTargetClip[i] = Weapon_GetPrimaryClip(iTargetWeapon[i])
				Client_GetWeaponPlayerAmmo(iTarget, iTargetActiveWeaponName, iTargetAmmo[i])		
			}
			else
			{
				iTargetClip[i] = 0
				iTargetAmmo[i] = 0
			}
		}
		//Set all of humans stats, but not weapons		
		SetEntityHealth(iClient, iTargetHealth)
		Client_SetArmor(iClient, iTargetArmor)
		GetAllClientGrenades(iTarget)
		CreateTimer(0.05, Give_iTargetWeaponsTo_iClient, iClient)
		//Take control
		bHideDeath[iTarget] = true
		ClientTookover[iClient] = 1
		ClientSpecClient[iClient] = 0
		ClientCash = ClientCash - BotTakeverCost[iClient]
		SetMoney(iClient, ClientCash)
		BotTakeverCost[iClient] = BotTakeverCost[iClient] + BotTakeverCostIncrement
		//Show that you've used BOT takeover, so you can't BET this round
		SetArrayCell(BotTakeoverClientsHandle, iClient, 1)
		//check for last player on team alive
		new MyTeam = GetClientTeam(iClient)
		new TeamMatesAlive = 0
		for (new i = 1; i <= MyMaxClients; i++)
		{
			if (!IsClientConnected(i) || i == iClient) continue
			if (MyTeam == GetClientTeam(i) && IsPlayerAlive(i))
			{
				TeamMatesAlive++
			}
		}
		new Handle:NoEndRoundHandle = FindConVar("mp_ignore_round_win_conditions")
		if (TeamMatesAlive == 1)
		{
			SetConVarInt(NoEndRoundHandle, 1)
		}
		ForcePlayerSuicide(iTarget)
		CS_RespawnPlayer(iClient)
		TeleportEntity(iClient, iTargetOrigin, iTargetAngles, NULL_VECTOR)
		SetConVarInt(NoEndRoundHandle, 0)
		PrintToChatAll("%N took control of %N", iClient, iTarget)
		return Plugin_Handled
	}
	return Plugin_Continue
}
public GetMoney(client)
{
	if (g_iAccount != -1)
	{
		return GetEntData(client, g_iAccount)
	}
	else
	{
		return 0
	}
}
public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount)
	}
}

//End of cod