#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <devzones>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"

Handle CVAR_AdminImmunity;
Handle ARRAY_WeaponsID;

bool IsInsideZone[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Weapon Zone Restrictor",
	author = PLUGIN_AUTHOR,
	description = "Restrict the usage of some weapons in specific zones",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	CVAR_AdminImmunity = CreateConVar("sm_tf2wzr_admin_immunity", "Admin with flag ADMFLAG_SLAY are affected by zones. (1 = yes | 0 = no)", "0", _, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_tf2wzr_rc", CMD_ReloadConfigFile, ADMFLAG_CONFIG, "Reaload the config file.");
	
	int trigger_multiple = -1;
	while ((trigger_multiple = FindEntityByClassname(trigger_multiple, "trigger_multiple")) != INVALID_ENT_REFERENCE)
	{
		HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_multiple, "OnEndTouch", OnEndTouch);
	}
	
	ReadConfigFile();
}

public void OnClientConnected(int client)
{
	IsInsideZone[client] = false;
}

public Action CMD_ReloadConfigFile(int client, int args)
{
	ReadConfigFile();
	ReplyToCommand(client, "Config file reloaded sucessfully !");
}

public Zone_OnClientEntry(client, char[] zone)
{
	if(StrContains(zone, "TF2WZR_", true) != -1)
		CheckWeapon(client, false);
}

public Zone_OnClientLeave(client, char[] zone)
{
	if(StrContains(zone, "TF2WZR_", true) != -1)
		CheckWeapon(client, true);
}

public void OnStartTouch(const char[] output, caller, activator, float delay)
{
	if(IsValidClient(activator))
		CheckWeapon(activator, false);
}

public void OnEndTouch(const char[] output, caller, activator, float delay)
{
	if(IsValidClient(activator))
		CheckWeapon(activator, true);
}

public void CheckWeapon(int client, bool IsLeaving)
{
	if(GetConVarInt(CVAR_AdminImmunity) == 1 && CheckCommandAccess(client, "CHECK_ZONE_RESTRICTION", ADMFLAG_SLAY, false))
		return;
		
	if(IsLeaving)
	{
		TF2_RegeneratePlayer(client)
		return;
	}
	
	int lastUnremovedWeaponSlot = -1;
	
	for (int slot = 0; slot < 8; slot++) 
    { 
        int weapon = GetPlayerWeaponSlot(client, slot); 
        if(weapon != -1)
        {
	        int weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	        if (IsValidEntity(weapon) && FindValueInArray(ARRAY_WeaponsID, weaponIndex) != -1) 
	        {
				AcceptEntityInput(weapon, "Kill");
			}
			else
			{
				if(slot < 2 && lastUnremovedWeaponSlot < slot)
					lastUnremovedWeaponSlot = slot;
			}   
		}
	} 		
						
	int EquipedWeapon = GetPlayerWeaponSlot(client, lastUnremovedWeaponSlot);
	if(EquipedWeapon != -1)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", EquipedWeapon);
}
	
stock bool ReadConfigFile()
{
	if(ARRAY_WeaponsID == INVALID_HANDLE)
		ARRAY_WeaponsID = CreateArray(8);
	else
		ClearArray(ARRAY_WeaponsID);
		
	char line[8], path[100];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/TF2_WeaponZoneRestrictor.ini");
	
	if(!FileExists(path))
	{
		Handle file = OpenFile(path,"w");
		WriteFileLine(file, "// Write your weapons id here. A list of all weapons ID can be found here :");
		WriteFileLine(file, "// https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes");
		CloseHandle(file);
	}
		
	Handle fileHandle = OpenFile(path, "r");
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		if(StrContains(line, "//", true) == -1)
			PushArrayCell(ARRAY_WeaponsID, StringToInt(line));
	}
		
	CloseHandle(fileHandle);
}
	
stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}