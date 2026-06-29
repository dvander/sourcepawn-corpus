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
* sm_nodoublepush_enablecolor - If this is set to 1 every button turns red when locked. By setting this to 0 the buttrons never change color.
*
* 
* Changelog:
* 05.12.2015 - v2.4.6 - Added cvar to disable colors
*
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
* Thank you Berni and SourceMod/AlliedModders-Team
* Thank you thetwistedpanda for letting me know about that the buttons won't keep their assigned time.
*/

/*****************************************************************


I N C L U D E S,   O P T I O N S   A N D   V E R S I O N   N U M B E R 


*****************************************************************/
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "2.4.6"

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

/*****************************************************************


 D E F I N E S


*****************************************************************/

/*****************************************************************


 G L O B A L   V A R I A B L E S


*****************************************************************/
new Handle:g_cvar_Version = INVALID_HANDLE;
new Handle:g_cvar_Enable = INVALID_HANDLE;
new Handle:g_cvar_Time = INVALID_HANDLE;
new Handle:g_cvar_Deathrun = INVALID_HANDLE;
new Handle:g_cvar_TriggerTime = INVALID_HANDLE;
new Handle:g_cvar_EnableColors = INVALID_HANDLE;

new Handle:g_hLockedButtons = INVALID_HANDLE;

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
	g_cvar_Time = CreateConVar("sm_nodoublepush_time", "-1","The time in seconds, when the button should be unlocked again. -1 will never unlock the buttons again.",FCVAR_PLUGIN);
	g_cvar_Deathrun = CreateConVar("sm_nodoublepush_deathrun", "1","How to handle deathrun maps: 0 this plugin is always on, 1 this plugin is only on deathrun maps on, 2 this plugin is only on deathrun maps off",FCVAR_PLUGIN);
	g_cvar_TriggerTime = CreateConVar("sm_nodoublepush_triggertime", "5.0","Only change the time of buttons if the original time (in seconds) is greater than this value (in seconds).",FCVAR_PLUGIN);
	g_cvar_EnableColors = CreateConVar("sm_nodoublepush_enablecolor", "1", "If this is set to 1 every button turns red when locked. By setting this to 0 the buttrons never change color.", FCVAR_PLUGIN);

	AutoExecConfig(true,"plugin.nodoublepush");
	
	g_hLockedButtons = CreateArray();
	
	HookEntityOutput("func_button", "OnIn", EntityOutput:FuncButtonOutput);
	HookEntityOutput("func_rot_button", "OnIn", EntityOutput:FuncButtonOutput);
}

public OnPluginEnd(){
	
	new size = GetArraySize(g_hLockedButtons);
	
	for(new index=0;index<size;index++){
		
		Timer_UnLockEntity(INVALID_HANDLE,index);
	}
}

public OnMapStart(){
	
	ClearArray(g_hLockedButtons);
	
	if(GetConVarBool(g_cvar_Enable)){
		
		decl String:mapname[128];
		GetCurrentMap(mapname, sizeof(mapname));
		
		switch(GetConVarInt(g_cvar_Deathrun)){
			
			case 1:{
				
				if (strncmp(mapname, "dr_", 3, false) != 0 && (strncmp(mapname, "deathrun_", 9, false) != 0) && (strncmp(mapname, "dtka_", 5, false) != 0)){
					//LogMessage("sm_nodoublepush_deathrun is 1 and this is the map: %s, so this plugin is disabled.",mapname);
					SetConVarBool(g_cvar_Enable,false);
					return;
				}
			}
			case 2:{
				
				if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0)){
					//LogMessage("sm_nodoublepush_deathrun is 2 and this is the map: %s, so this plugin is disabled.",mapname);
					SetConVarBool(g_cvar_Enable,false);
					return;
				}
			}
		}
	}
}

public EntityOutput:FuncButtonOutput(const String:output[], entity, client, Float:delay){
	
	if(!GetConVarBool(g_cvar_Enable)){
		return;
	}
	
	if(GetEntPropFloat(entity,Prop_Data,"m_flWait") > GetConVarFloat(g_cvar_TriggerTime)){
		
		new Float:time = GetConVarFloat(g_cvar_Time);
		
		PushArrayCell(g_hLockedButtons,entity);
		SetButtonColor(entity, true);
		Entity_Lock(entity);
		
		if(time != -1.0){
			
			CreateTimer(time,Timer_UnLockEntity,entity);
		}
	}
}

public Action:Timer_UnLockEntity(Handle:timer, any:entity) {
	
	if(IsValidEdict(entity)){
		SetButtonColor(entity, false);
		Entity_UnLock(entity);
	}
}

SetButtonColor(entity, bool:bLocked) {

	if (GetConVarInt(g_cvar_EnableColors) == 1) {

		if (bLocked) {

			// This will set the color to red
			SetEntityRenderColor(entity,255,0,0,255);
		}
		else {

			// This will set the color back to normal
			SetEntityRenderColor(entity,255,255,255,255);
		}
	}
}



