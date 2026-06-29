#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.8"

#define PREFIX "\x01[\x05Equipment Drop\x01]"

// Values Classified by Counter-Strike Series
#define INVALID_GAME	-1
#define GAME_CSS 		1
#define GAME_CSGO		2

// Ammo Offsets For CS:S
#define CSS_HEGRENADE	11 // HE Grenade
#define CSS_FLASH		12 // Flashbang
#define CSS_SMOKE		13 // Smoke Grenade

// Ammo Offsets For CS:GO
#define CSGO_HEGRENADE	13 // HE Grenade	
#define CSGO_FLASH		14 // Flashbang
#define CSGO_SMOKE		15 // Smoke Grenade
#define CSGO_INCENDIARY	16 // Incendiary Grenade
#define CSGO_MOLOTOV	16 // Molotov Cocktail
#define	CSGO_DECOY		17 // Decoy Grenade

new Handle:ED_Allows_Enable =		INVALID_HANDLE;
new Handle:ED_Allows_Knife = 		INVALID_HANDLE;
new Handle:ED_Allows_Hegrenade = 	INVALID_HANDLE;
new Handle:ED_Allows_Flashbang = 	INVALID_HANDLE;
new Handle:ED_Allows_Smokegrenade = INVALID_HANDLE;
new Handle:ED_Allows_Zeus = 		INVALID_HANDLE;
new Handle:ED_Allows_Incgrenade = 	INVALID_HANDLE;
new Handle:ED_Allows_Molotov = 		INVALID_HANDLE;
new Handle:ED_Allows_Decoy = 		INVALID_HANDLE;
new Handle:ED_Allowed_Team =		INVALID_HANDLE;
new Handle:ED_Allows_Admin_Only =	INVALID_HANDLE;
new Handle:ED_Allow_Drop_Time = 	INVALID_HANDLE;
new Handle:ED_Disallow_Drop_Time = 	INVALID_HANDLE;
new Handle:ED_Notify_Drop_Time = 	INVALID_HANDLE;
new Handle:ED_Notify_To_All =		INVALID_HANDLE;

new iGame = INVALID_GAME;

new bool:AllowDrop;
new bool:AuthorizedClient[MAXPLAYERS+1] = false;

new String:AdminFlags[32];


public Plugin:myinfo = 
{
	name = "Equipment Drop",
	author = "Trostal",
	description = "Allows Clients to Drop Their Knifes and Greandes with 'G' Key (When default setting).",
	version = PLUGIN_VERSION,
	url = "http://cafe.naver.com/sourcemulti"
};

public OnPluginStart()
{
	decl String:sGameName[16];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(StrEqual(sGameName, "cstrike", false))
		iGame = GAME_CSS;
	else if(StrEqual(sGameName, "csgo", false))
		iGame = GAME_CSGO;
	else
	{
		SetFailState("This Plugin only works on Counter-Strike: Source and Counter-Strike: Global Offensive.");
		iGame = INVALID_GAME;
	}
	
	CreateConVar("sm_equipment_drop_version", PLUGIN_VERSION, "Equipment Drop Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	ED_Allows_Enable =			CreateConVar("sm_equipment_drop_allows_enable", 		"1", 	"Enable Equipment Drop.", _, true, 0.0, true, 1.0);
	ED_Allows_Knife =			CreateConVar("sm_equipment_drop_allows_knife", 			"1", 	"Plugin allows players to drop their Knives.", _, true, 0.0, true, 1.0);
	ED_Allows_Hegrenade =		CreateConVar("sm_equipment_drop_allows_hegrenade", 		"1", 	"Plugin allows players to drop their HE Grenades.", _, true, 0.0, true, 1.0);
	ED_Allows_Flashbang =		CreateConVar("sm_equipment_drop_allows_flashbang", 		"1", 	"Plugin allows players to drop their Flashbangs.", _, true, 0.0, true, 1.0);
	ED_Allows_Smokegrenade =	CreateConVar("sm_equipment_drop_allows_smokegrenade", 	"1", 	"Plugin allows players to drop their Smoke Grenades.", _, true, 0.0, true, 1.0);
	ED_Allows_Zeus =			CreateConVar("sm_equipment_drop_allows_zeus", 			"1", 	"Plugin allows players to drop their Zeus x27s (CS:GO Only).", _, true, 0.0, true, 1.0);
	ED_Allows_Incgrenade =		CreateConVar("sm_equipment_drop_allows_incgrenade", 	"1", 	"Plugin allows players to drop their Incendiary Grenades (CS:GO Only).", _, true, 0.0, true, 1.0);
	ED_Allows_Molotov =			CreateConVar("sm_equipment_drop_allows_molotov", 		"1", 	"Plugin allows players to drop their Molotov Cocktails (CS:GO Only).", _, true, 0.0, true, 1.0);
	ED_Allows_Decoy =			CreateConVar("sm_equipment_drop_allows_decoygrenade", 	"1", 	"Plugin allows players to drop their Decoy Grenades (CS:GO Only).", _, true, 0.0, true, 1.0);
	
	ED_Allowed_Team =			CreateConVar("sm_equipment_drop_allowed_team", 			"1", 	"Team index to allow to drop (1 = Both, 2 = Terrorists, 3 = Counter-Terrorists).", _, true, 1.0, true, 3.0);
	ED_Allows_Admin_Only =		CreateConVar("sm_equipment_drop_allows_admin_only", 	"", 	"Administrator flags to allow to drop (if you would like to set).");
	
	ED_Allow_Drop_Time =		CreateConVar("sm_equipment_drop_allow_time", 			"0.0", 	"The time when players can drop their Equipments. (* Second(s) later.)\n0 = Until the time set as sm_equipment_drop_disallow_time (but it is 0, Allows Always).\nsm_equipment_drop_allow_time = sm_equipment_drop_disallow_time => Allow", _, true, 0.0);
	ED_Disallow_Drop_Time =		CreateConVar("sm_equipment_drop_disallow_time", 		"0.0", 	"The time when players can NOT drop their Equipments. (* Second(s) later.)\n0 = Disable This Cvar\nsm_equipment_drop_allow_time = sm_equipment_drop_disallow_time => Allow", _, true, 0.0);
	ED_Notify_Drop_Time =		CreateConVar("sm_equipment_drop_notify_drop_time", 		"1", 	"Notify at the time when players can or can not drop their Equipments. (* Second(s) later.)\n0 = Disable Notifying\n1 = Notify\n2 = Notify + Round start up Notifying", _, true, 0.0, true, 2.0);
	ED_Notify_To_All =			CreateConVar("sm_equipment_drop_notify_to_all", 		"0", 	"0 = Only allowed player can see notifications.\n1 = Every player can see notifications.", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "EquipmentDrop");
	
	HookConVarChange(ED_Allows_Admin_Only, OnConVarChanged);
	
	if(GetConVarInt(ED_Notify_Drop_Time) != 0 || 
	!(GetConVarFloat(ED_Allow_Drop_Time) == 0.0 && GetConVarFloat(ED_Allow_Drop_Time) == 0.0 && GetConVarInt(ED_Notify_Drop_Time) == 1))
		LoadTranslations("equipment_drop.phrases"); //Do not need to load phrases file if you don't notify or set allow (or disallow) time to drop.
	
	HookEvent("round_freeze_end", EventHook_RoundFreezeEnd);
	
	AddCommandListener(Command_Drop, "drop");
}

public Action:EventHook_RoundFreezeEnd(Handle:Event, const String:Name[], bool:Broadcast)
{
	if(GetConVarInt(ED_Allows_Enable) != 1)
		return Plugin_Continue;
	
	new Float:AllowTime = GetConVarFloat(ED_Allow_Drop_Time);
	new Float:DisallowTime = GetConVarFloat(ED_Disallow_Drop_Time);
	
	if(AllowTime <= 0)
	{
		AllowDrop = true;
		if(GetConVarInt(ED_Notify_Drop_Time) == 2)
			PrintNotificationToChat("%t", "You can drop from now on", PREFIX, "\x03");
	}
	else
	{
		AllowDrop = false;
		CreateTimer(AllowTime, DropSettingTimer, 1);
		if(GetConVarInt(ED_Notify_Drop_Time) == 2)
			PrintNotificationToChat("%t", "You can not drop yet", PREFIX, "\x03");
	}
	
	if(AllowTime < DisallowTime || DisallowTime > 0)
	{
		CreateTimer(DisallowTime, DropSettingTimer, 0);
	}
	
	return Plugin_Continue;
}

public Action:DropSettingTimer(Handle:Timer, any:allow)
{
	if(allow == 1)
	{
		AllowDrop = true;
		if(GetConVarInt(ED_Notify_Drop_Time) != 0)
			PrintNotificationToChat("%t", "You can drop from now on", PREFIX, "\x04");
	}
	else if(allow == 0)
	{
		AllowDrop = false;
		if(GetConVarInt(ED_Notify_Drop_Time) != 0)
			PrintNotificationToChat("%t", "You can not drop from now on", PREFIX, "\x04");
	}
}

public Action:Command_Drop(client, const String:command[], argc)
{
	if(GetConVarInt(ED_Allows_Enable) != 1
	|| !AllowDrop
	|| (GetConVarInt(ED_Allowed_Team) != 1 && GetConVarInt(ED_Allowed_Team) != GetClientTeam(client))
	|| !AuthorizedClient[client])
		return Plugin_Continue;
	
	if(IsClientInGame(client))
	{
		new String:sz_Classname[32];
		new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))	return Plugin_Stop;
		
		GetEdictClassname(weapon, sz_Classname, sizeof(sz_Classname));
		
		new nadeSlot = -1;
		if(StrEqual("weapon_knife", sz_Classname) && GetConVarInt(ED_Allows_Knife) == 1)
		{
			CS_DropWeapon(client, weapon, true, true);
			return Plugin_Handled;
		}
		if(StrEqual("weapon_taser", sz_Classname) && GetConVarInt(ED_Allows_Zeus) == 1 && iGame == GAME_CSGO) // CS:GO Only (Zeus x27)
		{
			if(GetEntProp(weapon, Prop_Data, "m_iClip1") > 0) // Block zeus spamming (as a player drop his zeus right after firing, zeus has been dropped, but players can't pick it up).
			{
				CS_DropWeapon(client, weapon, true, true);
				return Plugin_Handled;
			}
		}
		else if(StrEqual("weapon_hegrenade", sz_Classname, false) && GetConVarInt(ED_Allows_Hegrenade) == 1)
			nadeSlot = iGame == GAME_CSS ? CSS_HEGRENADE : iGame == GAME_CSGO ? CSGO_HEGRENADE : -1; // HE Grenade
		else if(StrEqual("weapon_flashbang", sz_Classname, false) && GetConVarInt(ED_Allows_Flashbang) == 1)
			nadeSlot = iGame == GAME_CSS ? CSS_FLASH : iGame == GAME_CSGO ? CSGO_FLASH : -1; // Flashbang
		else if(StrEqual("weapon_smokegrenade", sz_Classname, false) && GetConVarInt(ED_Allows_Smokegrenade) == 1)
			nadeSlot = iGame == GAME_CSS ? CSS_SMOKE : iGame == GAME_CSGO ? CSGO_SMOKE : -1; // Smoke Grenade
		else if(StrEqual("weapon_incgrenade", sz_Classname, false) && GetConVarInt(ED_Allows_Incgrenade) == 1 && iGame == GAME_CSGO) // CS:GO Only
			nadeSlot = CSGO_INCENDIARY; // Incendiary Grenade
		else if(StrEqual("weapon_molotov", sz_Classname, false) && GetConVarInt(ED_Allows_Molotov) == 1 && iGame == GAME_CSGO) // CS:GO Only
			nadeSlot = CSGO_MOLOTOV; // Molotov Cocktail
		else if(StrEqual("weapon_decoy", sz_Classname, false) && GetConVarInt(ED_Allows_Decoy) == 1 && iGame == GAME_CSGO) // CS:GO Only
			nadeSlot = CSGO_DECOY; // Decoy Grenade
			
		
		if(nadeSlot == -1)	return Plugin_Continue;
		
		new nadeCount = GetClientGrenadeCount(client, nadeSlot);
		new nSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
		if(nadeCount > 0)
		{
			if((nSequence != 5 && iGame == GAME_CSS) || (nSequence != 2 && iGame == GAME_CSGO)) // Block nade duplicating by dropping a nade when player is uping his arm (right before throwing).
			{
				CS_DropWeapon(client, weapon, true, true);
				
				if(nadeCount > 1) // Block nades vanishing when client has more than 2 nades (nade is dropped only 1, but the others are vanished).
				{
					AddNormalSoundHook(Hook_PickupSound);
					GivePlayerItem(client, sz_Classname);
					RemoveNormalSoundHook(Hook_PickupSound);
					SetClientGrenadeCount(client, nadeSlot, nadeCount-1);
					FakeClientCommand(client, "use %s", sz_Classname);
				}
					
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

//When client has more than 2 nades and drops that, trigger GivePlayerItem().
//at this moment, unexpected sound(items/itempickup.wav) has been emitted.
//we can remove this sound emitting on server-side, but on client-side.
//so the client who drops the equipment will hear this sound...
public Action:Hook_PickupSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
	return StrEqual(sample, "items/itempickup.wav", false) ? Plugin_Stop : Plugin_Continue;

public OnConfigsExecuted()
	GetConVarString(ED_Allows_Admin_Only, AdminFlags, sizeof(AdminFlags));

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == ED_Allows_Admin_Only)
	{
		GetConVarString(ED_Allows_Admin_Only, AdminFlags, sizeof(AdminFlags));
		
		for(new i=1;i<=MaxClients;i++)
			OnClientPostAdminCheck(i);
	}
}

public OnClientPostAdminCheck(client)
{
	if(StrEqual(AdminFlags, NULL_STRING))
	{
		AuthorizedClient[client] = true;
		return;
	}
	
	new ibFlags = ReadFlagString(AdminFlags);
	
	new AdminId:adminID = GetUserAdmin(client);
	if (adminID == INVALID_ADMIN_ID) return;
	if (GetAdminFlags(adminID, Access_Effective) & (ibFlags|ADMFLAG_ROOT))
		AuthorizedClient[client] = true;
	else
		AuthorizedClient[client] = false;
}

public OnClientPutInServer(client)
	AuthorizedClient[client] = false;

public OnClientDisconnect(client)
	AuthorizedClient[client] = false;

GetClientGrenadeCount(client, slot)
{
	new nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	return GetEntData(client, nadeOffs);
}

SetClientGrenadeCount(client, slot, amount)
{
	new nadeOffs = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	SetEntData(client, nadeOffs, amount);
}

stock PrintNotificationToChat(const String:format[], any:...)
{
	decl String:buffer[192];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetConVarInt(ED_Notify_To_All) == 1
			|| ((GetConVarInt(ED_Allowed_Team) == 1 || GetConVarInt(ED_Allowed_Team) == GetClientTeam(i)) && (AuthorizedClient[i])))
			{
				SetGlobalTransTarget(i);
				VFormat(buffer, sizeof(buffer), format, 2);
				PrintToChat(i, "%s", buffer);
			}
		}
	}
}