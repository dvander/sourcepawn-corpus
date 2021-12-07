#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//SourceMod Forum release Link
//https://forums.alliedmods.net/showthread.php?p=2180885

public Plugin:myinfo = {
	name = "NMS Ambient Sound Mute",
	author = "Tast - SDC",
	description = "NMS Ambient Sound Mute",
	version = "1.0",
	url = "http://tast.xclub.tw/viewthread.php?tid=343"
};

new sdn_ambientMute = 1

public OnPluginStart(){
	HookConVarChange(	CreateConVar("sdn_ambientMute", 		"1", 	"Mute Ambient Sound",FCVAR_NOTIFY)		, Cvar_AmbientMute);
	AddAmbientSoundHook(AmbientSHook);
}
public Cvar_AmbientMute(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sdn_ambientMute = StringToInt(newValue); }

public OnMapStart(){
	new String:MapName[32]
	GetCurrentMap(MapName, sizeof(MapName));
	
	if(strncmp(MapName, "nms", strlen("nms"), false) != 0) sdn_ambientMute = 0
}

public Action:AmbientSHook(String:sample[PLATFORM_MAX_PATH], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay){
	//PrintToChatAll(sample)
	if(!sdn_ambientMute || StrContains(sample,"ambient",false) == -1) return Plugin_Continue
	return Plugin_Stop
}