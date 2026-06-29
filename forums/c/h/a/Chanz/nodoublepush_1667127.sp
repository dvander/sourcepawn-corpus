/* 
* No Double Push - Locks buttons.
* 
* 
* Description:
* Locks func_button and func_rot_button entities for a certain amount of time, to prevent double pushing on deathrun or other maps.
* 
* 
* Installation:
* Place the 'nodoublepush.smx' into your "<moddir>/addons/sourcemod/plugins" folder.
* Place the 'plugin.nodoublepush.cfg' into your "<moddir>/cfg/sourcemod/" folder.
* 
* 
* Configuration:
* sm_nodoublepush_enable - Enable or disable No Double Push.
* sm_nodoublepush_time - The time in seconds, when the button should be unlocked again. -1 will never unlock the buttons again.
* sm_nodoublepush_deathrun - How to handle deathrun maps: 0 this plugin is always on, 1 this plugin is only on deathrun maps on, 2 this plugin is only on deathrun maps off.
* sm_nodoublepush_triggertime - Only change the time of buttons if the original time (in seconds) is greater than this value (in seconds).
* 
* 
* Changelog:
* 15.08.2010 - v2.4.5 if you use this in CSS it's recommanded that you update to this version!
* Rewrite of the hole code to prevent double push.
* Changed: Instead of deleting or chaning the buttons return time, this plugin now locks all buttons for a certain time.
* Added: Func_butttons are now red if they are locked.
* Added: On plugin unload all buttons return to their normal behavior.
* 
* 19.07.2010 - v1.2.0
* Fixed in CSS that round_start event is setting back the old values from the map.
* 
* v1.1.0
* Added sm_nodoublepush_triggertime to prevent no trap buttons are only once pushable.
* 
* v1.0.0
* Public release.
* 
* 
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod/AlliedModders-Team
* Thank you thetwistedpanda for letting me know about that the buttons won't keep their assigned time.
*/

/*****************************************************************


I N C L U D E S,   O P T I O N S   A N D   V E R S I O N   N U M B E R 


*****************************************************************/
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "2.5"

/*****************************************************************


 Extracted functions of smlib:


*****************************************************************/
/**
 * Returns true if the entity is locked.
 *
 * @param entity		Entity index.
 * @return				True if locked otherwise false.
 */
stock bool:Entity_IsLocked(entity) {
	
	return bool:GetEntProp(entity, Prop_Data, "m_bLocked", 1);
}

/**
 * Locks an entity.
 *
 * @param entity		Entity index.
 * @noreturn
 */
stock Entity_Lock(entity) {
	SetEntProp(entity, Prop_Data, "m_bLocked", 1, 1);
}
/**
 * Unlocks an entity.
 *
 * @param entity		Entity index.
 * @noreturn
 */
stock Entity_UnLock(entity) {
	SetEntProp(entity, Prop_Data, "m_bLocked", 0, 1);
}

/**
* Checks if the specified index is a player and connected.
*
* @param entity				An entity index.
* @param checkConnected		Set to false to skip the IsClientConnected check
* @return					Returns true if the specified entity index is a player connected, false otherwise.
*/
stock bool:Client_IsValid(client, bool:checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}

/*****************************************************************


 D E F I N E S


*****************************************************************/

/*****************************************************************


 G L O B A L   V A R I A B L E S


*****************************************************************/
new Handle:g_cvar_Version = INVALID_HANDLE;
new Handle:g_cvar_Enable = INVALID_HANDLE;
new Handle:g_cvar_Time = INVALID_HANDLE;
new Handle:g_cvar_TriggerTime = INVALID_HANDLE;

new Handle:g_hLockedButtons = INVALID_HANDLE;


//runtime optimizer
new g_iPlugin_Enabled = 1;
new Float:g_flPlugin_Time = -1.0;
new Float:g_flPlugin_TriggerTime = 5.0;

/*****************************************************************


 P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo = 
{
	name = "No Double Push - Locks buttons.",
	author = "Chanz",
	description = "Locks func_button and func_rot_button entities for a certain amount of time, to prevent double pushing on deathrun or other maps.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1242396 OR http://www.mannisfunhouse.eu/"
}

/*****************************************************************


 F O R W A R D S


*****************************************************************/
public OnPluginStart(){
	
	g_cvar_Version = CreateConVar("sm_nodoublepush_version", PLUGIN_VERSION, "No Double Push Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_cvar_Version,PLUGIN_VERSION);
	g_cvar_Enable = CreateConVar("sm_nodoublepush_enable", "1","Enable or disable No Double Push",FCVAR_PLUGIN);
	g_cvar_Time = CreateConVar("sm_nodoublepush_time", "-1.0","The time in seconds, when the button should be unlocked again.\n-1 will never unlock the buttons again.",FCVAR_PLUGIN);
	g_cvar_TriggerTime = CreateConVar("sm_nodoublepush_triggertime", "5.0","Only lock buttons if the return time (of the button) is greater than this value (in seconds).\nThis prevents locking of buttons that doesn't belong to a trap (on deathrun maps).",FCVAR_PLUGIN);
	
	AutoExecConfig(true,"plugin.nodoublepush");
	
	g_hLockedButtons = CreateArray();
	
	HookEntityOutput("func_button", "OnIn", FuncButtonOutput);
	HookEntityOutput("func_rot_button", "OnIn", FuncButtonOutput);
}

public OnPluginEnd(){
	
	new size = GetArraySize(g_hLockedButtons);
	
	for(new index=0;index<size;index++){
		
		new entityRef = GetArrayCell(g_hLockedButtons,index);
		
		if(entityRef == -1){
			continue;
		}
		
		Timer_UnLockEntity(INVALID_HANDLE,entityRef);
	}
}

public OnConfigsExecuted(){
	
	g_iPlugin_Enabled = GetConVarInt(g_cvar_Enable);
	g_flPlugin_Time = GetConVarFloat(g_cvar_Time);
	g_flPlugin_TriggerTime = GetConVarFloat(g_cvar_TriggerTime);
	
	HookConVarChange(g_cvar_Enable,ConVarChange_Enable);
	HookConVarChange(g_cvar_Time,ConVarChange_Time);
	HookConVarChange(g_cvar_TriggerTime,ConVarChange_TriggerTime);
}

public OnMapStart(){
	
	ClearArray(g_hLockedButtons);
}

//callbacks
public FuncButtonOutput(const String:output[], caller, activator, Float:delay){
	
	if (g_iPlugin_Enabled == 0) {
		return;
	}
	
	if(!Client_IsValid(activator)){
		return;
	}
	
	decl String:classname[MAX_NAME_LENGTH];
	GetEntityClassname(caller,classname,sizeof(classname));
	if(!StrEqual(classname,"func_button",false) || StrEqual(classname,"func_rot_button",false)){
		return;
	}
	
	if(GetEntPropFloat(caller,Prop_Data,"m_flWait") > g_flPlugin_TriggerTime){
		
		new callerRef = EntIndexToEntRef(caller);
		
		PushArrayCell(g_hLockedButtons,callerRef);
		SetEntityRenderColor(caller,255,0,0,255);
		Entity_Lock(caller);
		
		if(g_flPlugin_Time != -1.0){
			
			CreateTimer(g_flPlugin_Time,Timer_UnLockEntity,callerRef);
		}
	}
}

public Action:Timer_UnLockEntity(Handle:timer, any:entityRef) {
	
	new entity = EntRefToEntIndex(entityRef);
	
	if(entity != -1 && IsValidEdict(entity)){
		
		SetEntityRenderColor(entity,255,255,255,255);
		Entity_UnLock(entity);
	}
}

public ConVarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[]){
	g_iPlugin_Enabled = StringToInt(newValue);
}
public ConVarChange_Time(Handle:convar, const String:oldValue[], const String:newValue[]){
	g_flPlugin_Time = StringToFloat(newValue);
}
public ConVarChange_TriggerTime(Handle:convar, const String:oldValue[], const String:newValue[]){
	g_flPlugin_TriggerTime = StringToFloat(newValue);
}


