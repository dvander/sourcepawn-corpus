#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 	"1.0.0"
new Handle:v_Time = INVALID_HANDLE;
new Handle:g_hWeaponSwitch;

public Plugin:myinfo =
{
	name 	= "[TF2] Super Steak",
	author = "DarthNinja",
	description = "Players picking up dropped Steaks get crits, not heals.",
	version = VERSION,
};

public OnPluginStart() 
{
	CreateConVar("sm_supersteak_version", VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	v_Time = CreateConVar("sm_supersteak_time", "10", "Length of time to give crits for. A zero value disables the plugin.", 0, true, 0.0);
	PrepMeleeSDKCall()
}

public OnEntityCreated(entity, const String:classname[]) 
{
	if(GetConVarInt(v_Time) > 0 && StrEqual(classname, "item_healthkit_medium"))
		SDKHook(entity, SDKHook_StartTouch, TouchinSandvich);
}

public TouchinSandvich(iHookedEnt, iTouchingEnt) 
{ 
	new iOwner = GetEntPropEnt(iHookedEnt, Prop_Data, "m_hOwnerEntity");
	if(iOwner > 0 && iOwner <= MaxClients && IsClientInGame(iOwner) && TF2_GetPlayerClass(iOwner) == TFClass_Heavy && iTouchingEnt > 0 && iTouchingEnt <= MaxClients && IsClientInGame(iTouchingEnt))
	{
		new String:model[256];
		GetEntPropString(iHookedEnt, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrEqual("models/items/plate_steak.mdl", model, false))	// It's a steak!
		{
			SetEntProp(iHookedEnt, Prop_Data, "m_bDisabled", 1);	// disable it so it cant get picked up before we kill it
			AcceptEntityInput(iHookedEnt, "Kill");	// Kill it	
			new Float:f = GetConVarFloat(v_Time);
			TF2_AddCondition(iTouchingEnt, TFCond_RestrictToMelee, f);
			TF2_AddCondition(iTouchingEnt, TFCond_CritCola, f);
			EmitSoundToAll("items/gunpickup2.wav", iTouchingEnt);	//medkit sound: items/smallmedkit1.wav
			
			SDKCall(g_hWeaponSwitch, iTouchingEnt, GetPlayerWeaponSlot(iTouchingEnt, 2), 0);
		}
	}
}


// Code blatently stolen from pheadxdll's melee only plugin
// http://forums.alliedmods.net/showthread.php?p=1241921
PrepMeleeSDKCall()
{
	new Handle:hConf = LoadGameConfigFile("melee");
	if(hConf == INVALID_HANDLE)
	{
		SetFailState("Could not locate melee.txt in sourcemod/gamedata");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hWeaponSwitch = EndPrepSDKCall();
	if(g_hWeaponSwitch == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call for CTFPlayer::Weapon_Switch");
		CloseHandle(hConf);
		return;
	}
}