/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.0.8";

public Plugin:myinfo = {
	
	name = "Generic Melee Knock Back",
	author = "javalia",
	description = "Description",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
//#include <cstrike>
#include "sdkhooks"
//#include "vphysics"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

#define TEAM_UNASSIGNED 0
#define TEAM_RED 2
#define TEAM_BLUE 3

new Handle:g_cvarUnassignedKnockBack = INVALID_HANDLE;
new Handle:g_cvarBlueKnockBack = INVALID_HANDLE;
new Handle:g_cvarRedKnockBack = INVALID_HANDLE;

new Handle:g_cvarUnassignedDmgIncrement = INVALID_HANDLE;
new Handle:g_cvarBlueDmgIncrement = INVALID_HANDLE;
new Handle:g_cvarRedDmgIncrement = INVALID_HANDLE;

new Handle:g_cvarAllowKnockBackByTeam = INVALID_HANDLE;
new Handle:g_cvarAllowDmgIncByTeam = INVALID_HANDLE;

new Handle:g_cvarKnockBackSound = INVALID_HANDLE;
new Handle:g_cvarKnockBackSoundAutoDownload = INVALID_HANDLE;

new Handle:g_cvarMeleeWeaponList = INVALID_HANDLE;

new Handle:g_cvarKnockBackMsg = INVALID_HANDLE;


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	//네티브 함수등록
	RegPluginLibrary("GenericMeleeKnockBack");
	
	return APLRes_Success;
	
}

public OnPluginStart(){
	
	CreateConVar("GenericMeleeKnockBackMod_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_cvarUnassignedKnockBack = CreateConVar("GenericMeleeKnockBackMod_UnassignedKnockBack", "1000.0", "knockback of melee attack by Unassigned team, set 0 to disable");
	g_cvarBlueKnockBack = CreateConVar("GenericMeleeKnockBackMod_BlueKnockBack", "1000.0", "knockback of melee attack by Blue team, set 0 to disable");
	g_cvarRedKnockBack = CreateConVar("GenericMeleeKnockBackMod_RedKnockBack", "1000.0", "knockback of melee attack by Red team, set 0 to disable");
	
	g_cvarUnassignedDmgIncrement = CreateConVar("GenericMeleeKnockBackMod_UnassignedDmgIncrement", "0", "damage increment of melee attack by Unassigned team");
	g_cvarBlueDmgIncrement = CreateConVar("GenericMeleeKnockBackMod_BlueDmgIncrement", "0", "damage increment of melee attack by Blue team");
	g_cvarRedDmgIncrement = CreateConVar("GenericMeleeKnockBackMod_RedDmgIncrement", "0", "damage increment of melee attack by Red team");
	
	g_cvarAllowKnockBackByTeam = CreateConVar("GenericKnifeKnockBackMod_AllowKnockBackByTeam", "0", "1 to enable 0 to disable");
	g_cvarAllowDmgIncByTeam = CreateConVar("GenericKnifeKnockBackMod_AllowDmgIncByTeam", "0", "1 to enable 0 to disable");
	
	g_cvarKnockBackSound = CreateConVar("GenericMeleeKnockBackMod_KnockBackSound", "weapons/irifle/irifle_fire2.wav", "sound of KnockBack, set to \"\" string to disable");
	g_cvarKnockBackSoundAutoDownload = CreateConVar("GenericMeleeKnockBackMod_SoundAutoDownload", "1", "this should be 0 if knockback sound is one of default game sound");
	
	g_cvarMeleeWeaponList = CreateConVar("GenericMeleeKnockBackMod_MeleeWeaponList",
						"weapon_knife;weapon_crowbar;weapon_stunstick;weapon_amerknife;weapon_spade",
						"list of melee weapon that will occur knockback and damage increment, separate weapon` name with ;");
	
	g_cvarKnockBackMsg = CreateConVar("GenericMeleeKnockBackMod_KnockBackMsg", "{attacker} knocked {victim} back", "set this msg to empty if u dont want knockback msg, {attacker} and {victim} will be replaced to name of them");
	
	AutoExecConfig();
	
}

public OnMapStart(){
	
	decl String:soundpath[256];
	GetConVarString(g_cvarKnockBackSound, soundpath, 256);
	PrecacheSound(soundpath, true);
	
	if(GetConVarBool(g_cvarKnockBackSoundAutoDownload)){
	
		Format(soundpath, 256, "sound/%s", soundpath);
		AddFileToDownloadsTable(soundpath);
		
	}
	
	AutoExecConfig();
	
}

public OnClientPutInServer(client){

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
	
}

public Action:OnTakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype){

	if(isClientConnectedIngame(client) && isClientConnectedIngame(attacker)){
	
		decl String:s_Weapon[32];
		GetEdictClassname(inflictor, s_Weapon, 32);
		
		if(!StrEqual(s_Weapon, "player")){
				
			return Plugin_Continue;
				
		}else{
			
			GetClientWeapon(attacker, s_Weapon, 32);	
			
			if(IsKnockBackWeapon(s_Weapon)){
				
				decl Float:clientposition[3], Float:targetposition[3], Float:vector[3];
				
				GetClientEyePosition(attacker, clientposition);
				GetClientEyePosition(client, targetposition);
				
				MakeVectorFromPoints(clientposition, targetposition, vector);
				NormalizeVector(vector, vector);
				
				new Float:fKnockBackToMake = GetKnockBackToClient(client, attacker);
				
				if(fKnockBackToMake != 0.0){
				
					ScaleVector(vector, fKnockBackToMake);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
					
					decl String:buffer[256], String:clientname[64], String:attackername[64];		
					
					GetConVarString(g_cvarKnockBackMsg, buffer, 256);
					
					if(!StrEqual(buffer, "")){
							
						GetClientName(client, clientname, 64);
						GetClientName(attacker, attackername, 64);	
						
						ReplaceString(buffer, 256, "{attacker}", attackername, false);
						ReplaceString(buffer, 256, "{victim}", clientname, false);
						PrintCenterTextAll(buffer);
					
					}
					
					EmitKnockBackSound(clientposition);
					
				
				}
				
				damage += GetDmgIncrementToClient(client, attacker);
				
				return Plugin_Changed;
				
			}
			
		}
		
	}
	
	return Plugin_Continue;
	
}

Float:GetKnockBackToClient(client, attacker){

	new clientteam = GetClientTeam(client);
	new attackerteam = GetClientTeam(attacker);
	
	if((attackerteam == TEAM_UNASSIGNED && (GetConVarFloat(g_cvarUnassignedKnockBack) != 0.0))
		|| (attackerteam == TEAM_RED && (GetConVarFloat(g_cvarRedKnockBack) != 0.0))
		|| (attackerteam == TEAM_BLUE && (GetConVarFloat(g_cvarBlueKnockBack) != 0.0))){
		
		if((clientteam != attackerteam) || GetConVarBool(g_cvarAllowKnockBackByTeam)){
		
			if(attackerteam == TEAM_UNASSIGNED){
			
				return GetConVarFloat(g_cvarUnassignedKnockBack);
			
			}else if(attackerteam == TEAM_RED){
			
				return GetConVarFloat(g_cvarRedKnockBack);
			
			}else if(attackerteam == TEAM_BLUE){
			
				return GetConVarFloat(g_cvarBlueKnockBack);
			
			}
		
		}
		
	}
	
	return 0.0;

}

GetDmgIncrementToClient(client, attacker){

	new clientteam = GetClientTeam(client);
	new attackerteam = GetClientTeam(attacker);
	
	if((attackerteam == TEAM_UNASSIGNED && (GetConVarInt(g_cvarUnassignedDmgIncrement) != 0))
		|| (attackerteam == TEAM_RED && (GetConVarInt(g_cvarRedDmgIncrement) != 0))
		|| (attackerteam == TEAM_BLUE && (GetConVarInt(g_cvarBlueDmgIncrement) != 0))){
		
		if((clientteam != attackerteam) || GetConVarBool(g_cvarAllowDmgIncByTeam)){
		
			if(attackerteam == TEAM_UNASSIGNED){
			
				return GetConVarInt(g_cvarUnassignedDmgIncrement);
			
			}else if(attackerteam == TEAM_RED){
			
				return GetConVarInt(g_cvarRedDmgIncrement);
			
			}else if(attackerteam == TEAM_BLUE){
			
				return GetConVarInt(g_cvarBlueDmgIncrement);
			
			}
		
		}
		
	}
	
	return 0;

}

bool:IsKnockBackWeapon(const String:weaponname[]){

	decl String:convarstring[256];
	GetConVarString(g_cvarMeleeWeaponList, convarstring, 256);
	
	if(StrContains(convarstring, weaponname, false) != -1){
		
		return true;
		
	}

	return false;

}

EmitKnockBackSound(const Float:vecPos[3]){

	decl String:convarstring[256];
	GetConVarString(g_cvarKnockBackSound, convarstring, 256);

	EmitSoundToAll(convarstring ,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,vecPos,NULL_VECTOR,true,0.0);
	
}