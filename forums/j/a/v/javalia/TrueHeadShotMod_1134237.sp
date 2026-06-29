/**********************************헤드샷만 데미지 먹히는 플러그인*********************************/
public Plugin:myinfo = {
	
	name = "TrueHeadShotMod",
	author = "javalia",
	description = "the true head shot for css",
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

new String:hitboxname[8][64] = {
	
	"몸통", //body
	"머리", //head
	"가슴", //chest
	"배", //stomach
	"왼팔", //left arm
	"오른팔", //right arm
	"왼다리", //left leg
	"오른다리" //right leg
	
};

new Handle:mp_friendlyfire;

new lasthittedgroup[MAXPLAYERS + 1];

public OnPluginStart(){
	
	//이벤트 훅
	HookEvent("player_hurt", EventHurt);
	HookEvent("player_spawn", EventSpawn);
	
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	SetConVarInt(mp_friendlyfire, 0, true, true);
	HookConVarChange(mp_friendlyfire, mp_friendlyfirehook);
	
}

public OnClientPutInServer(client){
	
	SDKHook(client, SDKHook_TraceAttack, TraceAttackHook);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
	
	showwelcomemsg(client, true);
	
}

public Action:TraceAttackHook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup){
	
	if(isplayerconnectedingame(victim) && isplayerconnectedingame(attacker)){
	
		//무기에 맞은 부위만 기록한다
		lasthittedgroup[victim] = hitgroup;
		
		return Plugin_Continue;
		
	}else{
			
		return Plugin_Continue;
			
	}
	
}

public Action:OnTakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype){
	
	if(isplayerconnectedingame(client) && isplayerconnectedingame(attacker)){
		
		if(GetClientTeam(client) == GetClientTeam(attacker) && client != attacker){
			
			return Plugin_Handled;
			
		}
		
		//총이나 칼 종류의 무기
		if(attacker == inflictor){
			
			decl String:weaponname[32];
			GetClientWeapon(attacker, weaponname, 32);
			
			//총인 경우
			if(!StrEqual(weaponname, "weapon_knife")){
				
				//머리에 맞은 것이 아닐 경우
				new hitgroup = lasthittedgroup[client];
				
				if(hitgroup != 1 && (client != attacker) && (GetClientTeam(client) != GetClientTeam(attacker))){
					
					decl String:clientname[64], String:attackername[64];
					
					GetClientName(client, clientname, 64);
					GetClientName(attacker, attackername, 64);
					
					decl String:msg[256];
					
					ReplaceString(weaponname, 32, "weapon_", "", false);
					
					Format(msg, 256, "\x03%s \x01님의 \x04%s\x01(을)를 \x04%s\x01(으)로 맟춰서 \x04%d\x01의 데미지는 \x04무효\x01입니다", clientname, hitboxname[lasthittedgroup[client]], weaponname, RoundToNearest(damage));
					SayText2To(client, attacker, msg);
					
					Format(msg, 256, "\x03%s \x01님이 당신의 \x04%s\x01(을)를 \x04%s\x01(으)로 맟춰서 \x04%d\x01의 데미지는 \x04무효\x01입니다", attackername, hitboxname[lasthittedgroup[client]], weaponname, RoundToNearest(damage));
					SayText2To(attacker, client, msg);
					
					return Plugin_Handled;
					
				}else{
				
					//머리에 맞은 경우
					return Plugin_Continue;
					
				}
				
			}else{
				
				//칼인경우
				return Plugin_Continue;
				
			}
			
		}else{
			
			//수류탄 종류의 무기
			return Plugin_Continue;
			
		}
		
	}else{
		
		return Plugin_Continue;
		
	}
	
}

public Action:EventHurt(Handle:Event, const String:Name[], bool:Broadcast){

	decl client, attacker,  health, armor, String:weaponname[64], dmg_health, dmg_armor, hitgroup;
	
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	health = GetEventInt(Event, "health");
	armor = GetEventInt(Event, "armor");
	GetEventString(Event, "weapon", weaponname, 64);
	dmg_health = GetEventInt(Event, "dmg_health");
	dmg_armor = GetEventInt(Event, "dmg_armor");
	hitgroup = GetEventInt(Event, "hitgroup");
	
	if(isplayerconnectedingame(client) && isplayerconnectedingame(attacker) && client != attacker){
	
		decl String:clientname[64], String:attackername[64];
		
		GetClientName(client, clientname, 64);
		GetClientName(attacker, attackername, 64);
		
		decl String:msg[256];
		
		Format(msg, 256, "\x03%s \x01님의 \x04%s\x01(을)를 \x04%s\x01(으)로 맟춰서 \x04%d\x01의 데미지를 입혔습니다", clientname, hitboxname[hitgroup], weaponname, dmg_health);
		SayText2To(client, attacker, msg);
		
		Format(msg, 256, "\x03%s \x01님이 당신의 \x04%s\x01(을)를 \x04%s\x01(으)로 맟춰서 \x04%d\x01의 데미지를 입었습니다", attackername, hitboxname[hitgroup], weaponname, dmg_health);
		SayText2To(attacker, client, msg);
		
	}
	
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	showwelcomemsg(client);
	
}

public mp_friendlyfirehook(Handle:convar, const String:oldvalue[], const String:newvalue[]){
	
	new value = StringToInt(newvalue);
	
	if (value != 0){
		
		PrintToChatAll("\x04TrueHeadShotMod를 쓸 때는 mp_friendlyfire 를 1 로 설정할 수 없습니다");
		PrintToServer("TrueHeadShotMod를 쓸 때는 mp_friendlyfire 를 1 로 설정할 수 없습니다");
		
		SetConVarInt(mp_friendlyfire, 0, true, true);
			
	}
	
}

/********************************************************부가함수들*******************************************/
//클라이언트 상태 체크 3개를 한꺼번에 해주는 함수
stock bool:isplayerconnectedingamealive(client){
	
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

//클라이언트 상태 체크 2개를 한꺼번에 해주는 함수
//클라이언트가 게임 안에 있는지까지 검사한다.
stock bool:isplayerconnectedingame(client){
	
	if(client > 0 && client <= MaxClients){
	
		if(IsClientConnected(client) == true){
			
			if(IsClientInGame(client) == true){
			
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
	
}

//세이텍스트올
stock SayText2ToAll(client, const String:message[]){ 
	
	new Handle:buffer = StartMessageAll("SayText2");
			
	if (buffer != INVALID_HANDLE) { 
		
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage(); 
		
	}
   
}

//세이텍스트투
stock SayText2To(client, target, const String:message[]){ 
	
	new Handle:buffer = StartMessageOne("SayText2", target);
			
	if (buffer != INVALID_HANDLE) { 
		
		BfWriteByte(buffer, client);
		BfWriteByte(buffer, true);
		BfWriteString(buffer, message);
		EndMessage(); 
		
	}
   
}

stock showwelcomemsg(client, const bool:firstjoin = false){
	
	decl String:clientname[64];
	GetClientName(client, clientname, 64);
	
	if(firstjoin){
	
		PrintToChat(client, "\x04안녕하세요, %s님. TrueHeadShotMod 서버에 오신것을 환영합니다.", clientname);
		PrintToChat(client, "\x04이 모드에서는 총기류의 데미지는 머리를 맟출 때만 유효합니다.");
		PrintToChat(client, "\x04즐거운 시간 보내시길 바랍니다.");
		
	}else{
		
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT){
		
			PrintToChat(client, "\x04스폰되셨군요, %s님.", clientname);
			PrintToChat(client, "\x04다시 말씀드리지만 이 모드에서는 총기류의 데미지는 머리를 맟출 때만 유효합니다.");
			PrintToChat(client, "\x04즐거운 시간 보내시길 바랍니다.");
			
		}
		
	}
	
}