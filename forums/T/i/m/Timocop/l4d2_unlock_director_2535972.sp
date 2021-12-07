#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

//#define DIRECTORSCRIPT_TYPE		"g_MapScript.LocalScript.DirectorOptions"
#define DIRECTORSCRIPT_TYPE			"DirectorScript.MapScript.LocalScript.DirectorOptions"
//#define DIRECTORSCRIPT_TYPE		"DirectorScript.DirectorOptions"

enum KeyValueIndex {
	KeyValueIndex_Key,
	KeyValueIndex_Value
}

static Handle:g_hMapDirectorOptions;
static Handle:g_hCheckDelay;
static String:g_sKeyValues[512][2][64];
static g_iKeyValuesSize;
static bool:g_bUseTimer;

static const DEBUG = 0;

public Plugin:myinfo =
{
	name = "Left 4 Dead 2 VScript Director Options Unlocker",
	author = "Timocop",
	description = "Sets VScript Director options KeyValues",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	g_hMapDirectorOptions = CreateConVar("l4d2_directoroptions_overwrite", "", "Overwrites DirectorOptions key values. Seperate with ';' and assign with '=' (Assign to nothing will remove the key value). (e.g WitchLimit=;TankLimit=5)", FCVAR_SPONLY);
	g_hCheckDelay = CreateConVar("l4d2_directoroptions_use_check_delay", "1", "Use delays to set or remove director option keyvalues, may not precise.", FCVAR_SPONLY, true, 0.0, true, 1.0);
	HookConVarChange(g_hMapDirectorOptions, ConVarChanged);
	HookConVarChange(g_hCheckDelay, ConVarChanged);
	
	CvarChanged();
	
	CreateTimer(0.5, UpdateDirectorTimer, INVALID_HANDLE, TIMER_REPEAT);
	
	AutoExecConfig(true, "VScriptDirectorUnlocker");
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CvarChanged();
	UpdateDirector();
}

public OnEntityCreated(iEntity, const String:sClassname[])
{
	if(!g_bUseTimer)
		SDKHook(iEntity, SDKHook_ThinkPost, OnThink);
}

public OnThink(iEntity)
{
	if(g_bUseTimer) {
		SDKUnhook(iEntity, SDKHook_ThinkPost, OnThink);
		return;
	}
	
	UpdateDirector();
}

public Action:UpdateDirectorTimer(Handle:timer)
{
	if(g_bUseTimer)
		UpdateDirector();
}

static CvarChanged()
{
	{
		g_bUseTimer = GetConVarInt(g_hCheckDelay) > 0;
		
		static i;
		for(i = 0; i < 2048+1; i++) {
			if(!IsValidEntity(i))
				continue;
			
			if(g_bUseTimer) {
				SDKUnhook(i, SDKHook_ThinkPost, OnThink);
			}
			else {
				SDKHook(i, SDKHook_ThinkPost, OnThink);
			}
		}
	}
	{
		LogMessage("DirectorOptions Unlocker Start");
		g_iKeyValuesSize = 0;
		
		decl String:sDirectorOptionsFull[2048];
		GetConVarString(g_hMapDirectorOptions, sDirectorOptionsFull, sizeof(sDirectorOptionsFull));
		
		new iKeyNum = ReplaceString(sDirectorOptionsFull, sizeof(sDirectorOptionsFull), ";", ";") + 1;
		
		decl String:sKeyValuesFull[iKeyNum][64];
		ExplodeString(sDirectorOptionsFull, ";", sKeyValuesFull, iKeyNum, 64);
		
		for(new i = 0; i < iKeyNum; i++) {
			decl String:sKeyValue[2][64];
			sKeyValue[KeyValueIndex_Key][0] = 0;
			sKeyValue[KeyValueIndex_Value][0] = 0;
			ExplodeString(sKeyValuesFull[i], "=", sKeyValue, sizeof(sKeyValue), sizeof(sKeyValue[]));
			
			if(sKeyValue[KeyValueIndex_Key][0] == 0)
				continue;
			
			if(DEBUG) PrintToChatAll("CvarChanged: Add %s=%s", sKeyValue[KeyValueIndex_Key], sKeyValue[KeyValueIndex_Value]);
			
			LogMessage("DirectorOptions Unlocker: %s=%s", sKeyValue[KeyValueIndex_Key], sKeyValue[KeyValueIndex_Value]);
			
			g_sKeyValues[g_iKeyValuesSize][KeyValueIndex_Key] = sKeyValue[KeyValueIndex_Key];
			g_sKeyValues[g_iKeyValuesSize][KeyValueIndex_Value] = sKeyValue[KeyValueIndex_Value];
			g_iKeyValuesSize++;
		}
		
		LogMessage("DirectorOptions Unlocker End");
	}
}

static UpdateDirector()
{
	static String:sBuffer[256];
	
	static i;
	for(i = 0; i < g_iKeyValuesSize; i++) {
		if(g_sKeyValues[i][KeyValueIndex_Value][0] == 0) {
			if(DEBUG) PrintToChatAll("DirectorMap: Del %s", g_sKeyValues[i][KeyValueIndex_Key]);
			//Avoid VScript runtime errors when removing nonexistent keyvalues
			FormatEx(sBuffer, sizeof(sBuffer), "%s.%s <- 0;delete %s.%s", DIRECTORSCRIPT_TYPE, g_sKeyValues[i][KeyValueIndex_Key], DIRECTORSCRIPT_TYPE, g_sKeyValues[i][KeyValueIndex_Key]);
		}
		else {
			if(DEBUG) PrintToChatAll("DirectorMap: Edit %s=%s", g_sKeyValues[i][KeyValueIndex_Key], g_sKeyValues[i][KeyValueIndex_Value]);
			FormatEx(sBuffer, sizeof(sBuffer), "%s.%s <- %s", DIRECTORSCRIPT_TYPE, g_sKeyValues[i][KeyValueIndex_Key], g_sKeyValues[i][KeyValueIndex_Value]);
		}
		
		L4D2_RunScript(sBuffer);
	}
}

/**
* Runs a single line of vscript code.
* NOTE: Dont use the "script" console command, it startes a new instance and leaks memory. Use this instead!
*
* @param sCode		The code to run.
* @noreturn
*/
stock L4D2_RunScript(const String:sCode[], any:...)
{
	static iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static String:sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}
