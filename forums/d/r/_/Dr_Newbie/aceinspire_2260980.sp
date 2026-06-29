#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new Handle:g_isEnabled = INVALID_HANDLE;
new Handle:WaitForACE[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

public Plugin:myinfo = 
{
	name = "Inspire",
	author = "Dr_Newbie",
	description = "Throw the adrenaline and help your team get up.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_isEnabled = CreateConVar("sm_aceinspire_enable", "1", "(1 = ON ; 0 = OFF)", FCVAR_PLUGIN);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart, EventHookMode_Post);
	HookEvent("revive_success", Event_PlayerRemoveFromACEList1, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerRemoveFromACEList2, EventHookMode_Post);
	if(GetConVarBool(g_isEnabled))
		CreateTimer(0.3, ScanACEList);
	HookConVarChange(g_isEnabled, OnThisConVarChange);
}

public OnThisConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if (GetConVarBool(g_isEnabled))
		CreateTimer(0.3, ScanACEList);
}

public Action:ScanACEList(Handle:timer, any:client)
{
	new Float:inListerpOs[3];
	new Float:ACErpOs[3];
	new Float:result;
	new amountt = GetClientCount(true);
	new String:weapon[32];
	new buttons;
	for (new ACEr = 1; ACEr < amountt; ACEr++)
	{
		if (!IsClientInGame(ACEr) || !IsPlayerAlive(ACEr) || GetClientTeam(ACEr) != 2 || IsFakeClient(ACEr))
			continue;
		new inListID = GetClientAimTarget(ACEr, true);
		if( inListID <= 0 )
			continue;
		if( WaitForACE[inListID] == INVALID_HANDLE )
			continue;
		GetClientAbsOrigin(inListID, inListerpOs);
		GetClientAbsOrigin(ACEr, ACErpOs);
		result = GetVectorDistance(ACErpOs, inListerpOs);
		if( result > 800.0 )
			continue;
		buttons = GetClientButtons(ACEr);
		if(buttons & IN_USE)
		{
			GetClientWeapon(ACEr, weapon, 32);
			if (StrEqual(weapon, "weapon_adrenaline"))
			{
				RemovePlayerItem(ACEr, GetPlayerWeaponSlot(ACEr, 4));
				
				new userflags = GetUserFlagBits( inListID );
				new cmdflags = GetCommandFlags( "give" );
				SetUserFlagBits( inListID, ADMFLAG_ROOT );
				SetCommandFlags( "give", cmdflags & ~FCVAR_CHEAT );
				FakeClientCommand( inListID,"give health" );
				SetCommandFlags( "give", cmdflags );
				SetUserFlagBits( inListID, userflags );
				
				SetEntProp(inListID, Prop_Data, "m_iHealth", 1 );
				SetEntPropFloat(inListID, Prop_Send, "m_healthBuffer", 10.0 );
				WaitForACE[inListID] = INVALID_HANDLE;
				EmitSoundToClient(inListID, "ui/bigreward.wav" );
				EmitSoundToClient(ACEr, "ui/bigreward.wav" );
			}
		}
	}
	if (GetConVarBool(g_isEnabled))
		CreateTimer(0.3, ScanACEList);
	return Plugin_Handled;
}

public Action:Event_PlayerIncapacitatedStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	WaitForACE[userid] = 1;
}

public Action:Event_PlayerRemoveFromACEList1(Handle:event, const String:name[], bool:dontBroadcast)
{
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	WaitForACE[subject] = INVALID_HANDLE;
}

public Action:Event_PlayerRemoveFromACEList2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	WaitForACE[userid] = INVALID_HANDLE;
}