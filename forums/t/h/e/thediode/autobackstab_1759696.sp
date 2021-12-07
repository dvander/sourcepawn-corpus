#pragma semicolon 1

#include <sourcemod>
#include <admin>
#include <tf2_stocks>

public Plugin:myinfo = {
	name = "Auto Backstab",
	author = "thediode",
	description = "Admins who are spies will automatically backstab targets",
	version = "1.1",
	url = "http://forums.alliedmods.net/showthread.php?t=191250"
}

new bool:EnabledPlayers[MAXPLAYERS];

new Handle:Enabled = INVALID_HANDLE;
new Handle:AllowWhileStunnedOrTaunting = INVALID_HANDLE;

public OnPluginStart(){
	Enabled = CreateConVar("autobackstab_enabled", "1", "Enable/disable autobackstab for admins.", FCVAR_PLUGIN|FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	AllowWhileStunnedOrTaunting = CreateConVar("autobackstab_allowwhiletaunting", "0", "Enable/disable getting autobackstabs while taunting or stunned", FCVAR_PLUGIN|FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	RegAdminCmd("autobackstab_set", SetPlayerAccess, ADMFLAG_KICK, "autobackstab_set <#userid|name> [on|off]", "", 0);
}

public Action:SetPlayerAccess(Client, Arguments){
	if (Arguments < 2)
	{
		ReplyToCommand(Client, "[SM] Usage: autobackstab_set <#userid|name> [on|off]");
		return Plugin_Handled;
	}
	
	new String:Argument1[64];
	new String:Argument2[4];
	new bool:Setting;
	GetCmdArg(1, Argument1, sizeof(Argument1));
	GetCmdArg(2, Argument2, sizeof(Argument2));
	
	if (StrEqual(Argument2, "on", false) || StrEqual(Argument2, "1", false)){
		Setting = true;
	}else{
		Setting = false;
	}
	
	new String:TargetName[MAX_TARGET_LENGTH];
	new TargetList[MAXPLAYERS];
	new TargetCount;
	new bool:tn_is_ml;
	
	if ((TargetCount = ProcessTargetString(Argument1, Client, TargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, TargetName, sizeof(TargetName), tn_is_ml)) <= 0){
		ReplyToTargetError(Client, TargetCount);
		return Plugin_Handled;
	}

	for (new Index = 0; Index < TargetCount; Index++){
		EnabledPlayers[TargetList[Index]] = Setting;
	}
	
	return Plugin_Handled;
}

// OnPlayerRunCmd is essentially CreateMove with a few less things (like random_seed)
public Action:OnPlayerRunCmd(Client, &Buttons, &Impulse, Float:Velocity[3], Float:Angles[3], &Weapons){
	new String:Weapon[16];
	GetClientWeapon(Client, Weapon, sizeof(Weapon));
	
	if (GetConVarBool(Enabled) && StrEqual(Weapon, "tf_weapon_knife", false) && EnabledPlayers[Client]){
		if (GetConVarBool(AllowWhileStunnedOrTaunting) && (TF2_IsPlayerInCondition(Client, TFCond_Taunting) || TF2_IsPlayerInCondition(Client, TFCond_Dazed)))
			return Plugin_Continue;
		
		new ReadyOffset = FindSendPropOffs("CTFKnife", "m_bReadyToBackstab");
		new Knife = GetPlayerWeaponSlot(Client, 2);
		new IsReady = GetEntData(Knife, ReadyOffset, 1);
		
		if (IsReady == 1)
			Buttons |= IN_ATTACK;
	}

	return Plugin_Continue;
}
