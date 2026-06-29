#include <sourcemod>
#include <sdktools>
#include <colors>
#include <attributes>

#pragma semicolon 1

#define PLUGIN_VERSION 		"0.1.1"

new Handle:g_hForwardAttributeChange;

new g_iAttributeId = 0;
new g_iAttributeIdxMax = -1;
new Handle:g_hAttributes = INVALID_HANDLE;

new g_iPlayerAvailablePoints[MAXPLAYERS+1];

new Handle:g_hCvarEnable;
new bool:g_bEnabled;

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo =
{
	name = "tAttributes Core",
	author = "Thrawn",
	description = "A RPG-like attribute core to be used by other plugins",
	version = PLUGIN_VERSION,
	url = "http://thrawn.de"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart() {
	// V E R S I O N    C V A R //
	CreateConVar("sm_att_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// C O N V A R S //
	g_hCvarEnable = CreateConVar("sm_att_enabled", "1", "Enables the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvarEnable, Cvar_Changed);

	g_hForwardAttributeChange = CreateGlobalForward("att_OnClientAttributeChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_hAttributes = CreateArray(ATTRIBUTESIZE);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnable);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


//////////////////////////////////
//C L I E N T  C O N N E C T E D//
//////////////////////////////////
public OnClientConnected(iClient) {
	if(g_bEnabled)
	{
		g_iPlayerAvailablePoints[iClient] = 0;

		if (g_iAttributeIdxMax > -1)
		{
			for (new i = 0; i < g_iAttributeIdxMax+1; i++)
			{
				new Handle:attribute = GetArrayCell(g_hAttributes, i);

				new playerLevels[MAXPLAYERS+1];
				GetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				playerLevels[iClient] = 0;
				SetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);
			}
		}
	}
}

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
	}
}


//////////
//Stocks//
//////////
stock setPlayerAvailablePoints(iClient, iPoints) {
	if(iPoints > MAXSKILLLEVEL*3)
		iPoints = MAXSKILLLEVEL*3;

	g_iPlayerAvailablePoints[iClient] = iPoints;
}

stock attChooseResult:ChooseAttribute(iClient, iAttributeId, iAmount) {
	if(g_iPlayerAvailablePoints[iClient] <= 0)
		return att_NoAvailablePoints;

	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				new playerLevels[MAXPLAYERS+1];
				GetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				if(playerLevels[iClient] >= MAXSKILLLEVEL)
					return att_MaxSkillLevelReached;

				g_iPlayerAvailablePoints[iClient]--;
				playerLevels[iClient] = playerLevels[iClient] + iAmount;
				SetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				Call_StartForward(GetArrayCell(attribute, 4));
				Call_PushCell(iClient);
				Call_PushCell(playerLevels[iClient]);
				Call_PushCell(iAmount);
				Call_Finish();

				Forward_AttributeChange(iClient, iAttributeId, playerLevels[iClient], iAmount);
				return att_OK;
			}
		}
	}

	return att_AttributeNotRegistered;
}

stock SetClientAttributeValue(iClient, iAttributeId, iValue) {
	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				new playerLevels[MAXPLAYERS+1];
				GetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				playerLevels[iClient] = iValue;
				SetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				Call_StartForward(GetArrayCell(attribute, 4));
				Call_PushCell(iClient);
				Call_PushCell(playerLevels[iClient]);
				Call_PushCell(-1);
				Call_Finish();

				Forward_AttributeChange(iClient, iAttributeId, playerLevels[iClient], -1);
			}
		}
	}
}

/////////////////
//N A T I V E S//
/////////////////
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("attributes");

	CreateNative("att_IsEnabled", Native_GetEnabled);
	CreateNative("att_SetClientAvailablePoints", Native_SetClientAvailablePoints);
	CreateNative("att_AddClientAvailablePoints", Native_AddClientAvailablePoints);
	CreateNative("att_GetClientAvailablePoints", Native_GetClientAvailablePoints);

	CreateNative("att_RegisterAttribute", Native_RegisterAttribute);
	CreateNative("att_UnregisterAttribute", Native_UnregisterAttribute);
	CreateNative("att_GetAttributeName", Native_GetAttributeName);
	CreateNative("att_GetAttributeDescription", Native_GetAttributeDescription);
	CreateNative("att_GetAttributeCount", Native_GetAttributeCount);
	CreateNative("att_GetAttributeID", Native_GetAttributeID);

	CreateNative("att_SetClientAttributeValue", Native_SetClientAttributeValue);
	CreateNative("att_GetClientAttributeValue", Native_GetClientAttributeValue);
	CreateNative("att_AddClientAttributeValue", Native_AddClientAttributeValue);


	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

public Native_RegisterAttribute(Handle:hPlugin, iNumParams)
{
	// att_RegisterAttribute(type, const String:name[], const String:desc[], att_AttributeCallback:callback);
	new Handle:attribute = CreateArray(15);

	//PushArrayCell(attribute, GetNativeCell(1));			// 0
	PushArrayCell(attribute, true);			// 0
	new eId = g_iAttributeId;
	g_iAttributeId++;
	PushArrayCell(attribute, eId);				// 1

	new String:tmpName[128];
	GetNativeString(1, tmpName, sizeof(tmpName)+1);
	PushArrayString(attribute, tmpName);					// 2

	LogMessage("Registered Attribute: %s (%i)", tmpName, eId);
	new String:tmpDesc[128];
	GetNativeString(2, tmpDesc, sizeof(tmpDesc)+1);
	PushArrayString(attribute, tmpDesc);					// 3

	new Handle:fwd = CreateForward(ET_Single, Param_Cell, Param_Cell, Param_Cell);

	if (!AddToForward(fwd, hPlugin, GetNativeCell(3)))
	{
		decl String:szCallerName[PLATFORM_MAX_PATH];
		GetPluginFilename(hPlugin, szCallerName, sizeof(szCallerName));
		ThrowError("Failed to add forward from %s", szCallerName);
	}

	PushArrayCell(attribute, fwd);							// 4

	new iClientPoints[MAXPLAYERS+1] = {0,...};
	PushArrayArray(attribute, iClientPoints);				// 5

	PushArrayCell(g_hAttributes, attribute);
	g_iAttributeIdxMax++;

	return eId;
}

public Native_UnregisterAttribute(Handle:hPlugin, iNumParams)
{
	// *FIXME* Seems to be broken
	new iAttributeId = GetNativeCell(1);

	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				CloseHandle(GetArrayCell(attribute,4));
				RemoveFromArray(g_hAttributes, i);
				g_iAttributeIdxMax--;
				g_iAttributeId--;
				i--;
			}
		}
	}
}


public Native_GetAttributeCount(Handle:hPlugin, iNumParams)
{
	return GetArraySize(g_hAttributes);
}

public Native_GetAttributeID(Handle:hPlugin, iNumParams)
{
	new arrayID = GetNativeCell(1);

	// *FIXME* Add some checks here
	new Handle:attribute;

	attribute = GetArrayCell(g_hAttributes, arrayID);
	new eid = GetArrayCell(attribute, 1);

	return eid;
}

//native psy_GetAttributeName(iAttributeId, attributeType);
public Native_GetAttributeName(Handle:hPlugin, iNumParams)
{
	new iAttributeId = GetNativeCell(1);

	//LogMessage("looking for attribute: %i", iAttributeId);

	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				new String:attributeTitle[128];
				GetArrayString(attribute, 2, attributeTitle, 128);
				//LogMessage("trying to pass %s", attributeTitle);
				SetNativeString(2, attributeTitle, 64, false);
				return true;
			}
		}
	}

	return false;
}

//native psy_GetAttributeDescription(iAttributeId, attributeType);
public Native_GetAttributeDescription(Handle:hPlugin, iNumParams)
{
	new iAttributeId = GetNativeCell(1);

	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				new String:attributeDesc[64];
				GetArrayString(attribute, 3, attributeDesc, 64);

				SetNativeString(2, attributeDesc, 64, false);
			}
		}
	}
}


//att_IsEnabled();
public Native_GetEnabled(Handle:hPlugin, iNumParams)
{
	return g_bEnabled;
}

//att_AddClientAttributeValue(iClient);
public Native_AddClientAttributeValue(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iAttributeId = GetNativeCell(2);
	new iAmount = GetNativeCell(3);

	return ChooseAttribute(iClient, iAttributeId, iAmount);
}

//att_SetClientAttributeValue(iClient, iAttributeId, iLevel);
public Native_SetClientAttributeValue(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iAttributeId = GetNativeCell(2);
	new iValue = GetNativeCell(3);

	SetClientAttributeValue(iClient, iAttributeId, iValue);
}

//att_GetClientAttributeValue(iClient, iAttributeId);
public Native_GetClientAttributeValue(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iAttributeId = GetNativeCell(2);

	if (g_iAttributeIdxMax > -1)
	{
		for (new i = 0; i < g_iAttributeIdxMax+1; i++)
		{
			new Handle:attribute = GetArrayCell(g_hAttributes, i);

			if (GetArrayCell(attribute,1) == iAttributeId)
			{
				new playerLevels[MAXPLAYERS+1];
				GetArrayArray(attribute,5,playerLevels,MAXPLAYERS+1);

				return playerLevels[iClient];
			}
		}
	}

	return 0;
}

//lm_setPlayerAvailablePoints(iClient, iPoints);
public Native_SetClientAvailablePoints(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iPoints = GetNativeCell(2);

	setPlayerAvailablePoints(iClient, iPoints);
}

//lm_addPlayerAvailablePoints(iClient, iPoints);
public Native_AddClientAvailablePoints(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);
	new iPoints = GetNativeCell(2);

	setPlayerAvailablePoints(iClient, g_iPlayerAvailablePoints[iClient] + iPoints);
}

//lm_getClientDexterity(iClient);
public Native_GetClientAvailablePoints(Handle:hPlugin, iNumParams)
{
	new iClient = GetNativeCell(1);

	return g_iPlayerAvailablePoints[iClient];
}

//public att_OnClientAttributeChange(iClient, iAttributeId, iValue, iAmount); {};
public Forward_AttributeChange(iClient, iAttributeId, iValue, iAmount)
{
	Call_StartForward(g_hForwardAttributeChange);
	Call_PushCell(iClient);
	Call_PushCell(iAttributeId);
	Call_PushCell(iValue);
	Call_PushCell(iAmount);
	Call_Finish();
}