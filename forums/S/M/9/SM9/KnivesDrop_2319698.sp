/****************************************************************************************************
[CSGO] Knives Drop
*****************************************************************************************************/

/****************************************************************************************************
CHANGELOG
*****************************************************************************************************/
/*	
		0.1 - First Public Release.
		0.2 - Fixed errors & Improved efficiency.
		0.3 - Prevent Vanilla Knives dropping on death & Allow knives to be equipped by pressing E (+Use).
		0.4 - Added ConVars, Fixed a little mistake inside OnPlayerRunCmd.
		0.4.1 - Fixed another small Logic error.
		0.5 - 
				- Fixed crashing on MapEnd.
				- Fixed error spam when entity not owned by player.
				- Optimized / cleaned some functions.
		0.6 - Fixed Knives not dropping on death.
*/

/****************************************************************************************************
INCLUDES
*****************************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <dhooks>
#include <sdkhooks>
#include <autoexecconfig>

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
#define PLUGIN_VERSION "0.6"
#define PLUGIN_AUTHOR "SM9 (xCoderx)"

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required // To be moved before includes one day.
#pragma semicolon 1

/****************************************************************************************************
INTS.
*****************************************************************************************************/
int iOffSets[2];
int iKnifeRef[MAXPLAYERS + 1];
int iSpecialKnives[] =  { 500, 505, 506, 507, 508, 509, 512, 515 };

/****************************************************************************************************
FLOATS.
*****************************************************************************************************/
float fPickUpRange;

/****************************************************************************************************
BOOLS.
*****************************************************************************************************/
bool bPluginEnabled;
bool bTouchPickup;
bool bUsePickup;
bool bAllowDrop;
bool bAllowDropOnDeath;
bool bIsClientHooked[MAXPLAYERS + 1];

/****************************************************************************************************
HANDLES.
*****************************************************************************************************/
Handle hHooks[2] = INVALID_HANDLE;
Handle hGameConfig = INVALID_HANDLE;
Handle hCvarPluginEnabled = INVALID_HANDLE;
Handle hCvarTouchPickup = INVALID_HANDLE;
Handle hCvarUsePickup = INVALID_HANDLE;
Handle hCvarPickupRange = INVALID_HANDLE;
Handle hCvarAllowDrop = INVALID_HANDLE;
Handle hCvarAllowDropOnDeath = INVALID_HANDLE;

/****************************************************************************************************
PLUGIN INFO.
*****************************************************************************************************/
public Plugin myinfo = 
{
	name = "Knife Drop / Pickup", 
	author = PLUGIN_AUTHOR, 
	description = "Allows knives to be dropped and picked up.", 
	version = PLUGIN_VERSION, 
	url = "www.fragdeluxe.com"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) {
		SetFailState("This plugin is for CSGO only.");
	}
	
	AddCommandListener(CommandDrop, "drop");
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	
	AutoExecConfig_SetFile("knivesdrop");
	HookConVarChange(hCvarPluginEnabled = AutoExecConfig_CreateConVar("kd_enabled", "1", "Plugin enabled"), OnCvarChanged);
	HookConVarChange(hCvarTouchPickup = AutoExecConfig_CreateConVar("kd_touch_pickup", "1", "Allow players to pickup knives by touching them"), OnCvarChanged);
	HookConVarChange(hCvarUsePickup = AutoExecConfig_CreateConVar("kd_use_pickup", "1", "Allow players to pickup knives by pressing the use button"), OnCvarChanged);
	HookConVarChange(hCvarAllowDrop = AutoExecConfig_CreateConVar("kd_allow_drop", "1", "Allow players to drop the knife by pressing the drop button"), OnCvarChanged);
	HookConVarChange(hCvarAllowDropOnDeath = AutoExecConfig_CreateConVar("kd_allow_drop_on_death", "1", "Allow players to drop the knife when they die"), OnCvarChanged);
	HookConVarChange(hCvarPickupRange = AutoExecConfig_CreateConVar("kd_pickup_range", "125.000000", "The distance a player can be to allow pickup with the use key"), OnCvarChanged);
	CreateConVar("knifesdrop_version", PLUGIN_VERSION, "Version of Knives Drop", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	UpdateVariables();
	CreateHooks();
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsValidClient(iClient)) {
			OnClientPutInServer(iClient);
		}
	}
}

public void OnCvarChanged(Handle hConvar, const char[] chOldValue, const char[] chNewValue)
{
	UpdateVariables();
}

public void UpdateVariables()
{
	bPluginEnabled = GetConVarBool(hCvarPluginEnabled);
	bTouchPickup = GetConVarBool(hCvarTouchPickup);
	bUsePickup = GetConVarBool(hCvarUsePickup);
	bAllowDrop = GetConVarBool(hCvarAllowDrop);
	bAllowDropOnDeath = GetConVarBool(hCvarAllowDropOnDeath);
	fPickUpRange = GetConVarFloat(hCvarPickupRange);
}

public void CreateHooks()
{
	hGameConfig = LoadGameConfigFile("sdkhooks.games");
	
	if (hGameConfig == INVALID_HANDLE) {
		SetFailState("There was a problem reading your gamedata, please reinstall sourcemod.");
	}
	
	iOffSets[0] = GameConfGetOffset(hGameConfig, "Weapon_CanUse");
	
	CloseHandle(hGameConfig);
	
	if (iOffSets[0] == -1) {
		SetFailState("There was an error while trying to find the offsets, please reinstall sourcemod.");
	}
	
	hHooks[0] = DHookCreate(iOffSets[0], HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, OnWeaponCanUsePre);
	
	DHookAddParam(hHooks[0], HookParamType_CBaseEntity);
}

public void OnClientPutInServer(int iClient)
{
	HookClient(iClient);
}

public void HookClient(int iClient)
{
	if (!bIsClientHooked[iClient]) {
		DHookEntity(hHooks[0], false, iClient);
		SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquip_Post);
		bIsClientHooked[iClient] = true;
	}
}

public void OnClientDisconnect(int iClient)
{
	bIsClientHooked[iClient] = false;
}

public Action OnPlayerDeath(Handle hEvent, const char[] chName, bool bDontBroadcast)
{
	if (!bAllowDropOnDeath || !bPluginEnabled) {
		return;
	}
	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsClientConnected(iClient) && IsClientInGame(iClient)) {
		int iKnife = EntRefToEntIndex(iKnifeRef[iClient]);
		
		if (IsValidWeapon(iKnife)) {
			CS_DropWeaponCustom(iClient, iKnife, false, true);
		}
	}
}

public Action CommandDrop(int iClient, const char[] chCommand, int iArgs)
{
	if (!IsValidClient(iClient) || !bPluginEnabled || !bAllowDrop) {
		return Plugin_Continue;
	}
	
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidWeapon(iWeapon)) {
		return Plugin_Continue;
	}
	
	if (!IsSpecialKnife(iWeapon) && !IsDefaultKnife(iWeapon)) {
		return Plugin_Continue;
	}
	
	CS_DropWeaponCustom(iClient, iWeapon, true, true);
	
	return Plugin_Handled;
}

public MRESReturn OnWeaponCanUsePre(int iClient, Handle hReturn, Handle hParams)
{
	if (!IsValidClient(iClient) || !bPluginEnabled || !bTouchPickup) {
		return MRES_Ignored;
	}
	
	int iWeapon = DHookGetParam(hParams, 1);
	
	if (!IsValidWeapon(iWeapon)) {
		return MRES_Ignored;
	}
	
	if (!IsSpecialKnife(iWeapon) && !IsDefaultKnife(iWeapon)) {
		return MRES_Ignored;
	}
	
	DHookSetReturn(hReturn, true);
	return MRES_Override;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons)
{
	if (!IsPlayerAlive(iClient) || IsFakeClient(iClient) || !bPluginEnabled || !bUsePickup) {
		return;
	}
	
	if (iButtons & IN_USE) {
		
		int iEntity = GetClientAimTarget(iClient, false);
		
		if (!IsValidWeapon(iEntity)) {
			return;
		}
		
		if (!IsSpecialKnife(iEntity) && !IsDefaultKnife(iEntity)) {
			return;
		}
		
		if (GetDistance(iClient, iEntity) > fPickUpRange) {
			return;
		}
		
		ReplaceClientKnife(iClient, GetPlayerWeaponSlot(iClient, CS_SLOT_KNIFE), iEntity);
	}
}

public Action OnWeaponEquip_Post(int iClient, int iWeapon)
{
	if (!bPluginEnabled || !bAllowDropOnDeath) {
		return Plugin_Continue;
	}
	
	if (!IsSpecialKnife(iWeapon) && !IsDefaultKnife(iWeapon)) {
		return Plugin_Continue;
	}
	
	iKnifeRef[iClient] = EntIndexToEntRef(iWeapon);
	
	return Plugin_Continue;
}

stock bool IsValidClient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients) {
		return false;
	}
	
	if (!IsClientConnected(iClient) || IsFakeClient(iClient)) {
		return false;
	}
	
	if (!IsClientInGame(iClient)) {
		return false;
	}
	
	return true;
}

stock bool IsValidWeapon(int iWeapon)
{
	if (iWeapon > 4096 && iWeapon != INVALID_ENT_REFERENCE) {
		iWeapon = EntRefToEntIndex(iWeapon);
	}
	
	if (!IsValidEdict(iWeapon) || !IsValidEntity(iWeapon) || iWeapon == -1) {
		return false;
	}
	
	char chWeapon[64];
	GetEdictClassname(iWeapon, chWeapon, sizeof(chWeapon));
	
	return StrContains(chWeapon, "weapon_") == 0;
}

stock bool IsDefaultKnife(int iWeapon)
{
	int iDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if (iDefIndex == 42 || iDefIndex == 59) {
		return true;
	}
	
	return false;
}

stock bool IsSpecialKnife(int iWeapon)
{
	int iDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if (iDefIndex == 42 || iDefIndex == 59) {
		return false;
	}
	
	else {
		for (int i; i < sizeof(iSpecialKnives); i++) {
			if (iDefIndex == iSpecialKnives[i]) {
				return true;
			}
		}
	}
	
	return false;
}

stock void ReplaceClientKnife(int iClient, int iOriginalKnife, int iNewKnife)
{
	if (IsValidWeapon(iOriginalKnife) && iOriginalKnife != iNewKnife) {
		CS_DropWeaponCustom(iClient, iOriginalKnife, true, true);
	}
	
	EquipPlayerWeapon(iClient, iNewKnife);
}

stock void CS_DropWeaponCustom(int iClient, int iWeapon, bool bToss, bool bBlockHook)
{
	int iOwnerEntity = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	
	if (iOwnerEntity != iClient) {
		SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iClient);
	}
	
	CS_DropWeapon(iClient, iWeapon, bToss, bBlockHook);
	
	if (iOwnerEntity != -1) {
		SetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity", iOwnerEntity);
	}
	
	if (!IsPlayerAlive(iClient)) {
		return;
	}
	
	RemovePlayerItem(iClient, iWeapon);
	
	int iPrimary = GetPlayerWeaponSlot(iClient, CS_SLOT_PRIMARY);
	int iSecondary = GetPlayerWeaponSlot(iClient, CS_SLOT_SECONDARY);
	int iSwitchTo = iPrimary != -1 ? iPrimary : iSecondary;
	
	if (!IsValidWeapon(iSwitchTo)) {
		return;
	}
	
	static char chWeapon[64]; GetEdictClassname(iSwitchTo, chWeapon, sizeof(chWeapon));
	FakeClientCommandEx(iClient, "use %s", chWeapon);
	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iSwitchTo);
}

stock float GetDistance(int iClient, int iEntity)
{
	float fClientPos[3]; float fEntityPos[3]; float fClientMins[3]; float fClientMaxs[3];
	
	GetClientMins(iClient, fClientMins); GetClientMaxs(iClient, fClientMins);
	
	float fHalfHeight = fClientMins[2] - fClientMaxs[2] + 10;
	
	GetClientAbsOrigin(iClient, fClientPos); GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
	
	float fPosHeightDiff = fClientPos[2] - fEntityPos[2];
	
	if (fPosHeightDiff > fHalfHeight) {
		fClientPos[2] -= fHalfHeight;
	}
	
	else if (fPosHeightDiff < (-1.0 * fHalfHeight)) {
		fClientPos[2] -= fHalfHeight;
	}
	
	else {
		fClientPos[2] = fEntityPos[2];
	}
	
	return GetVectorDistance(fClientPos, fEntityPos, false);
} 