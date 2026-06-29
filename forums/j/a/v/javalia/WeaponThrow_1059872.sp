/**********************************카솟용 무기 던지게 하는 플러그인************************************/
public Plugin:myinfo = {
	
	name = "Weapon Throw",
	author = "javalia",
	description = "advanced weapon throw for css",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
	
};

//인클루드문장
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "sdkhooks"

//문법정의
#pragma semicolon 1

new Handle:hSDKWeaponDrop;

//플러그인이 시작할 때
public OnPluginStart(){

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(219);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, VDECODE_FLAG_ALLOWNULL);
	hSDKWeaponDrop = EndPrepSDKCall();
	
	RegConsoleCmd("drop", command_drop);
	
}

SDKWeaponDrop(client, weaponEnt, const Float:vecTarget[3], const Float:velocity[3]) {
	
	SDKCall(hSDKWeaponDrop, client, weaponEnt, vecTarget, velocity);
	
}

public Action:command_drop(client, Args){
	
	if(isplayerconnectedingamealive(client)){
		
		decl String:weapon[64];
		
		GetClientWeapon(client, weapon, 64);
		
		if(StrEqual(weapon, "weapon_knife")){
			
			//모든 칼을 버려야한다
			new Weapon_Offset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
			new String:tempweaponname[60];
			new Max_Guns = 48;

			for(new n = 0; n < Max_Guns; n = (n + 1)){
		
				new Weapon_ID = GetEntDataEnt2(client, Weapon_Offset + n);
			
				if(Weapon_ID > 0){
		
					GetEdictClassname(Weapon_ID, tempweaponname, 60);
				
					if(StrEqual("weapon_knife", tempweaponname, false)){
						
						decl Float:pos[3], Float:ang[3], Float:vecangle[3], Float:resultpos[3];
						GetClientEyePosition(client, pos);
						GetClientEyeAngles(client, ang);
						
						GetAngleVectors(ang, vecangle, NULL_VECTOR, NULL_VECTOR);
						
						NormalizeVector(vecangle, vecangle);
						ScaleVector(vecangle, 85.0);
						AddVectors(pos, vecangle, resultpos);
						
						SDKWeaponDrop(client, Weapon_ID, resultpos, vecangle);
						
					}
		
				}
		
			}
			
			return Plugin_Handled;
			
		}else if(StrEqual(weapon, "weapon_hegrenade")){
			
			//모든 칼을 버려야한다
			new Weapon_Offset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
			new String:tempweaponname[60];
			new Max_Guns = 48;

			for(new n = 0; n < Max_Guns; n = (n + 1)){
		
				new Weapon_ID = GetEntDataEnt2(client, Weapon_Offset + n);
			
				if(Weapon_ID > 0){
		
					GetEdictClassname(Weapon_ID, tempweaponname, 60);
				
					if(StrEqual("weapon_hegrenade", tempweaponname, false)){
						
						decl Float:pos[3], Float:ang[3], Float:vecangle[3], Float:resultpos[3];
						GetClientEyePosition(client, pos);
						GetClientEyeAngles(client, ang);
						
						GetAngleVectors(ang, vecangle, NULL_VECTOR, NULL_VECTOR);
						
						NormalizeVector(vecangle, vecangle);
						ScaleVector(vecangle, 85.0);
						AddVectors(pos, vecangle, resultpos);
						
						SDKWeaponDrop(client, Weapon_ID, resultpos, vecangle);
						
					}
		
				}
		
			}
			
			return Plugin_Handled;
			
		}else if(StrEqual(weapon, "weapon_smokegrenade")){
			
			//모든 칼을 버려야한다
			new Weapon_Offset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
			new String:tempweaponname[60];
			new Max_Guns = 48;

			for(new n = 0; n < Max_Guns; n = (n + 1)){
		
				new Weapon_ID = GetEntDataEnt2(client, Weapon_Offset + n);
			
				if(Weapon_ID > 0){
		
					GetEdictClassname(Weapon_ID, tempweaponname, 60);
				
					if(StrEqual("weapon_smokegrenade", tempweaponname, false)){
						
						decl Float:pos[3], Float:ang[3], Float:vecangle[3], Float:resultpos[3];
						GetClientEyePosition(client, pos);
						GetClientEyeAngles(client, ang);
						
						GetAngleVectors(ang, vecangle, NULL_VECTOR, NULL_VECTOR);
						
						NormalizeVector(vecangle, vecangle);
						ScaleVector(vecangle, 85.0);
						AddVectors(pos, vecangle, resultpos);
						
						SDKWeaponDrop(client, Weapon_ID, resultpos, vecangle);
						
					}
		
				}
		
			}
			
			return Plugin_Handled;
			
		}else if(StrEqual(weapon, "weapon_flashbang")){
			
			//모든 칼을 버려야한다
			new Weapon_Offset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
			new String:tempweaponname[60];
			new Max_Guns = 48;

			for(new n = 0; n < Max_Guns; n = (n + 1)){
		
				new Weapon_ID = GetEntDataEnt2(client, Weapon_Offset + n);
			
				if(Weapon_ID > 0){
		
					GetEdictClassname(Weapon_ID, tempweaponname, 60);
				
					if(StrEqual("weapon_flashbang", tempweaponname, false)){
						
						decl Float:pos[3], Float:ang[3], Float:vecangle[3], Float:resultpos[3];
						GetClientEyePosition(client, pos);
						GetClientEyeAngles(client, ang);
						
						GetAngleVectors(ang, vecangle, NULL_VECTOR, NULL_VECTOR);
						
						NormalizeVector(vecangle, vecangle);
						ScaleVector(vecangle, 85.0);
						AddVectors(pos, vecangle, resultpos);
						
						SDKWeaponDrop(client, Weapon_ID, resultpos, vecangle);
						
					}
		
				}
		
			}
			
			return Plugin_Handled;
			
		}
		
		return Plugin_Continue;
		
	}
	
	return Plugin_Continue;
	
}

//클라이언트 상태 체크 3개를 한꺼번에 해주는 함수
public bool:isplayerconnectedingamealive(client){
	
	if(client > 0 && client <= MaxClients){
	
		if(IsClientConnected(client) == true){
				
			if(IsClientInGame(client) == true){
					
				if(IsPlayerAlive(client) == true){
					
					return true;
					
				}else{
					
					return false;
					
				}
				
			}else{
				
				return false;
				
			}
			
		}else{
					
			return false;
					
		}
		
	}else{
		
		return false;
	
	}
	
}