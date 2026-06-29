#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6.2"
	
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle hClientTimer[MAXPLAYERS+1];

ConVar hBlockSecondaryDrop;
ConVar hBlockM60Drop;
ConVar hBlockDropMidAction;

bool g_bBlockSecondaryDrop;
bool g_bBlockM60Drop;
bool g_bBlockDropMidAction;

bool g_bCanPlayerDrop[MAXPLAYERS+1];
const int ACTIVE_SLOT = -1;
public Plugin myinfo =
{
	name = "[L4D2] Weapon Drop",
	author = "Machine, dcx2, Electr0 /z, Senip, Shao, Zheldorg",
	description = "Allows players to drop the Weapon they are holding.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");	
	
	hBlockSecondaryDrop =	CreateConVar ("l4d2_block_secondary_drop",	"1" , "Prevent players from dropping their secondaries? (Fixes bugs that can come with incapped weapons or A-Posing.)",	FCVAR_NONE, true, 0.0, true, 1.0);
	hBlockM60Drop =			CreateConVar ("l4d2_block_m60_drop",		"1" , "Prevent players from dropping the M60? (Allows for better compatibility with certain plugins.)",					FCVAR_NONE, true, 0.0, true, 1.0);
	hBlockDropMidAction =	CreateConVar ("l4d2_block_drop_mid_action",	"1" , "Prevent players from dropping objects in between actions? (Fixes throwable cloning.)",							FCVAR_NONE, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_drop",	Command_Drop);
	RegConsoleCmd("sm_d",		Command_Drop);

	hBlockSecondaryDrop.	AddChangeHook(ConVarChanged_Cvars);
	hBlockM60Drop.			AddChangeHook(ConVarChanged_Cvars);
	hBlockDropMidAction.	AddChangeHook(ConVarChanged_Cvars);
	
	AutoExecConfig(true, "l4d2_drop");
	GetCvars(); // Read plugin ConVar
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

stock void GetCvars()
{
	g_bBlockSecondaryDrop =		hBlockSecondaryDrop.	BoolValue;
	g_bBlockM60Drop =			hBlockM60Drop.			BoolValue;
	g_bBlockDropMidAction =		hBlockDropMidAction.	BoolValue;
}

public void OnMapStart()
{
	for (int i = 1; i <= MAXPLAYERS; i++)	g_bCanPlayerDrop[i] = true; // To make sure that if the "USE" button is locked, there is an event that reliably resets the lock
}

public void OnClientPutInServer(int client)
{
	g_bCanPlayerDrop[client] = true;
}

public void OnClientDisconnect(int client)
{
	if(hClientTimer[client] != null)
	{
		KillTimer(hClientTimer[client]);
		hClientTimer[client] = null;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& entWeapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(g_bCanPlayerDrop[client] == false && (buttons & IN_USE)) // (buttons & IN_SPEED) deliberately ignored, to avoid accidental uses, when the walk button is released first
	{
		buttons &= ~IN_USE;
		return Plugin_Continue;
	}

	if(GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client) && (buttons & IN_SPEED) && (buttons & IN_USE) && hClientTimer[client] == null)
	{
		buttons &= ~IN_USE;
		g_bCanPlayerDrop[client] = false;
		hClientTimer[client] = CreateTimer(0.1, Timer_CanPlayerDrop_Reset, client);	 
	}
	return Plugin_Continue;
}

public Action Timer_CanPlayerDrop_Reset(Handle timer, any client)
{
	hClientTimer[client] = null;
	g_bCanPlayerDrop[client] = false;
	CreateTimer(0.3, ResetDelay, client); // as a result of tests, I think a delay of 0.3 seconds is optimal, with the hClientTimer timer with a delay of 0.1 seconds
	DropWeapon(client, ACTIVE_SLOT);
}

public Action ResetDelay(Handle timer, any client)
{
	g_bCanPlayerDrop[client] = true;
}

public Action Command_Drop(int client, int args)
{
	if (args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
			ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
	}
	else if (args == 0)
	{
		DropWeapon(client, ACTIVE_SLOT);
	}
	else if (args > 0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			char target[MAX_TARGET_LENGTH], arg[8];
			GetCmdArg(1, target, sizeof(target));
			GetCmdArg(2, arg, sizeof(arg));
			int slot = StringToInt(arg);

			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count; 
			bool bStub; // NOT FOR REAL USE ( stub var for ProcessTargetString() )
			
			if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), bStub)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			if(slot > 0)
			{
				slot--;
				for (int i = 0; i < target_count; i++)	DropWeapon(target_list[i], slot);
			}
			else
				for (int i = 0; i < target_count; i++)	DropWeapon(target_list[i], ACTIVE_SLOT);
		}
	}
	return Plugin_Handled;
}

void DropWeapon(int client, int slot)
{
	if (!(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 4) && IsPlayerAlive(client))) return;
	
	int entWeapon;
	
	if (slot >= 0) 
		entWeapon = GetPlayerWeaponSlot(client, slot);
	else
		entWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if (!(entWeapon > MaxClients  && IsValidEntity(entWeapon) && entWeapon != INVALID_ENT_REFERENCE)) return; //Bad entity
	if ((g_bBlockDropMidAction || GetPlayerWeaponSlot(client, 2) == entWeapon) && GetEntPropFloat(entWeapon,Prop_Data,"m_flNextPrimaryAttack") >= GetGameTime()) return;
	if (g_bBlockSecondaryDrop && (GetPlayerWeaponSlot(client, 1) == entWeapon)) return;
	
	char classname[32];
	GetEntityClassname(entWeapon, classname, sizeof(classname));
	
	if (g_bBlockM60Drop && (strcmp(classname, "weapon_rifle_m60") == 0)) return;
	
	int ammotype = GetEntProp(entWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if(ammotype >= 0)
	{
		int ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
		SDKHooks_DropWeapon(client, entWeapon);
		SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
		SetEntProp(entWeapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		
		if(strcmp(classname, "weapon_rifle_m60") == 0)
		{
			if (GetEntProp(entWeapon, Prop_Data, "m_iClip1") == 0)
				SetEntProp(entWeapon, Prop_Send, "m_iClip1", 1);
		}
		else if(strcmp(classname, "weapon_defibrillator") == 0)
		{
			int modelindex = GetEntProp(entWeapon, Prop_Data, "m_nModelIndex");
			SetEntProp(entWeapon, Prop_Send, "m_iWorldModelIndex", modelindex);
		}		
	}
	else SDKHooks_DropWeapon(client, entWeapon);
}