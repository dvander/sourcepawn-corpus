/*
 *총 특수능력 플러그인
 *
 *특수기능을 쓸 수 있는 총에서는
 *시프트키를 누르면 셀렉터메뉴가 나온다.
 *셀렉터 메뉴에서는 총의 발사 모드를 선택할 수 있다.
 *각각 일반 탄환, 유탄, 유도로켓, 부착형지뢰, 탐지장치를 선택할 수 있다.
 */

public Plugin:myinfo = {
	
	name = "TacticalGunMod",
	author = "javalia",
	description = "powerful gun........",
	version = "1.0.0.14",
	url = "http://www.sourcemod.net/"
	
};

//인클루드문장
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "sdkhooks"
#include "stocklib"
#include "TGMconsts"
#include "TGMsound"

//문법정의
#pragma semicolon 1

new selectortype:selectormode[MAXPLAYERS + 1];
new keybuffer[MAXPLAYERS + 1];
new abilitybuffer[MAXPLAYERS + 1];

new laserdotentity[MAXPLAYERS + 1];//여기에는 엔티티 인덱스가 아니라 엔티티 레퍼런스를 저장한다!

//해당 env_beam엔티티와 연관된 마인엔티티
new mineentity[2048];//여기에는 엔티티 인덱스가 아니라 엔티티 레퍼런스를 저장한다.
new minegroundentity[2048];//여기에는 마인엔티티가 어떤 엔티티에 붙어있는지 저장한다
new bool:mineoutputhooked[2048];//여기에는 마인 엔티티의 아웃펏이 훅되어있는지를 저장한다

//이펙트엔티티
new beamsprite, halosprite;

//센서를 위한 변수
new Float:nextsensoractivetime[MAXPLAYERS + 1];
new bool:ditectedbysensor[MAXPLAYERS + 1][MAXPLAYERS + 1];

public OnPluginStart(){
	
	//이벤트 훅
	HookEvent("player_spawn", EventSpawn);
	
}

public OnMapStart(){
	
	beamsprite = PrecacheModel("materials/sprites/laser.vmt");
	halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheModel("models/Weapons/ar2_grenade.mdl");
	PrecacheModel("models/items/combine_rifle_ammo01.mdl");
	PrecacheModel("models/weapons/w_missile_launch.mdl");
	prepatchsounds();
	
}

public OnClientPutInServer(client){
	
	selectormode[client] = selector_default;
	keybuffer[client] = 0;
	abilitybuffer[client] = 0;
	laserdotentity[client] = -1;
	
}

public OnEntityCreated(entity, const String:classname[]){
	
	if(StrEqual(classname, "player")){
		
		SDKHook(entity, SDKHook_PreThinkPost, PreThinkHook);
		SDKHook(entity, SDKHook_PostThinkPost, PostThinkHook);
		SDKHook(entity, SDKHook_WeaponSwitch, WeaponSwitchHook);
		
	}
	
}

public OnClientDisconnect(client){
	
	//this code has been added to check <is manual unhook can clear crash?>
	SDKUnhook(client, SDKHook_PreThinkPost, PreThinkHook);
	SDKUnhook(client, SDKHook_PostThinkPost, PostThinkHook);
	SDKUnhook(client, SDKHook_WeaponSwitch, WeaponSwitchHook);
	
	removelaserdot(client);
	
}

public PreThinkHook(client){
	
	if(IsClientConnectedIngameAlive(client)){
			
		new buttons = GetClientButtons(client);
		
		//시프트 관련 처리, 현재 시프트를 누르고 있고 키버퍼에서는 시프트를 계속 누르는 중이 아니라고 할때만
		if((buttons & IN_SPEED) && !(keybuffer[client] & IN_SPEED)){
			
			//시프트를 누를 때 키버퍼 체크
			keybuffer[client] = keybuffer[client] | IN_SPEED;
			
			//기능이 있는 무기만 셀렉터메뉴를 보여준다
			if(abilitybuffer[client] > ABILITY_BULLET){
			
				selectormenu(client);
				
			}
			
		}else if(!(buttons & IN_SPEED)){
			
			//시프트를 누르고 있지 않으므로 버퍼를 푼다
			keybuffer[client] = keybuffer[client] & ~IN_SPEED;
			
		}
		
		//E키로 특수 기술을 쓰는 보조 공격모드에서의 처리
		if(buttons & IN_USE){
			
			//만약 모드가 탄환 모드가 아닐 경우에는, 특수기술을 쓴다
			if(selectormode[client] != selector_bullet){
				
				//특수 기술 함수 호출
				specialattack(client);
				
			}
			
		}
		
	}
	
}

public PostThinkHook(client){
	
	//레이저도트에 관한 처리
	if(IsPlayerAlive(client) && abilitybuffer[client] & ABILITY_ROCKET && selectormode[client] == selector_rocket){
		
		//레이저를 켜야하는 상황
		createlaserdot(client);
		
	}else{
		
		//레이저를 꺼야하는 상황
		removelaserdot(client);
		
	}
	
	if(IsPlayerAlive(client) && !IsFakeClient(client)){
		
		new Float:now = GetEngineTime();
		
		if(nextsensoractivetime[client] <= now){
			
			nextsensoractivetime[client] = now + SENSORSHOWDELAY;
			
			decl Float:clientposition[3];
			GetClientEyePosition(client, clientposition);
			clientposition[2] = clientposition[2] - 15.0;//몸통의 가운데 부분을 구한다
			
			for(new target = 1; target <= MaxClients; target++){
					
				//타겟이 클라이언트가 아니고 타겟이 살아있을 경우
				if(ditectedbysensor[client][target] && (target != client) && IsClientConnectedIngameAlive(target)){
					
					decl Float:targetposition[3];
					GetClientEyePosition(target, targetposition);
					targetposition[2] = targetposition[2] - 15.0;//몸통의 가운데 부분을 구한다
					
					new clientteam = GetClientTeam(client);
					new targetteam = GetClientTeam(target);
					
					//타겟이 감지되었다!!!!이펙트를 만들어줘야 한다!!!
					if(targetteam == CS_TEAM_T){
						
						new color[4] = {255, 64, 64, 255};
						//테러 이므로 레이더는 빨간색
						TE_SetupBeamPoints(clientposition, targetposition, beamsprite, halosprite, 0, 1, 0.1, 2.0, 2.0, 0, 1.5, color, 40);
						
					}else if(targetteam == CS_TEAM_CT){
						
						//대테러 이므로 레이더는 파란색
						new color[4] = {0, 0, 255, 255};
						TE_SetupBeamPoints(clientposition, targetposition, beamsprite, halosprite, 0, 1, 0.1, 2.0, 2.0, 0, 1.5, color, 40);
						
					}
					
					new total = 0;
					new clients[MaxClients];
					for (new i=1; i<=MaxClients; i++){
						
						if (IsClientConnectedIngameAlive(i) && GetClientTeam(i) == clientteam){
							
							clients[total++] = i;
							
						}
						
					}
					TE_Send(clients, total, 0.0);
					
					ditectedbysensor[client][target] = false;
					
				}
				
			}
			
		}
		
	}
	
}

stock createlaserdot(client){
	
	//레이저가 없는 경우
	if(!(laserdotentity[client] != -1 && EntRefToEntIndex(laserdotentity[client]) != -1)){
		
		new envsprite = CreateEntityByName("env_sprite");
		//DispatchKeyValueVector(envsprite,"Origin", resultposition);
		DispatchKeyValue(envsprite, "model", "redglow1.vmt");
		DispatchKeyValue(envsprite, "rendermode", "5");
		DispatchKeyValue(envsprite, "renderfx", "15");
		DispatchSpawn(envsprite);
		AcceptEntityInput(envsprite, "ShowSprite");
			
		laserdotentity[client] = EntIndexToEntRef(envsprite);
		
	}
	
	decl Float:cleyepos[3], Float:cleyeangle[3];
	
	GetClientEyePosition(client, cleyepos); 
	GetClientEyeAngles(client, cleyeangle);
	
	new Handle:traceresulthandle = INVALID_HANDLE;
						
	traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterrocket, client);
						
	if(TR_DidHit(traceresulthandle) == true){
		
		decl Float:resultposition[3], Float:normalvector[3];
		
		TR_GetEndPosition(resultposition, traceresulthandle);
		TR_GetPlaneNormal(traceresulthandle, normalvector);
		NormalizeVector(normalvector, normalvector);
		ScaleVector(normalvector, 5.0);
		AddVectors(resultposition, normalvector, resultposition);
		
		
		TeleportEntity(laserdotentity[client], resultposition, NULL_VECTOR, NULL_VECTOR);
		
	}
	
	CloseHandle(traceresulthandle);
	
}

stock removelaserdot(client){
	
	//레이저가 이미 있는 경우
	if(laserdotentity[client] != -1 && EntRefToEntIndex(laserdotentity[client]) != -1){
		
		AcceptEntityInput(laserdotentity[client], "Kill");
		
	}
	
}

public Action:WeaponSwitchHook(client, entity){
	
	//기능 초기화
	abilitybuffer[client] = ABILITY_NONE;
	
	//어느 무기로 바꾸는지 확인해서 해당 무기가 쓸 수 있는 특수기술의 플래그를 저장한다
	if(entity != -1){
	
		decl String:weaponname[64];
		GetEdictClassname(entity, weaponname, sizeof(weaponname));
		
		//엠포, 크릭, 갈릴, 파마스
		if(StrEqual(weaponname, "weapon_m4a1") || StrEqual(weaponname, "weapon_sg552")
			|| StrEqual(weaponname, "weapon_galil") || StrEqual(weaponname, "weapon_famas")){
			
			//이것들은 유탄 기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_GRENADE | ABILITY_BULLET;
			
		}else if(StrEqual(weaponname, "weapon_m249")){
			
			//이것은 유탄과 유도로켓 기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_GRENADE | ABILITY_ROCKET | ABILITY_BULLET;
			
		}else if(StrEqual(weaponname, "weapon_ak47") || StrEqual(weaponname, "weapon_aug")
			|| StrEqual(weaponname, "weapon_sg550") || StrEqual(weaponname, "weapon_g3sg1")){
			
			//이것들은 지뢰 기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_MINE | ABILITY_BULLET;
			
		}else if(StrEqual(weaponname, "weapon_tmp") || StrEqual(weaponname, "weapon_mac10")){
			
			//이것들은 탐지장치 기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_SENSOR | ABILITY_BULLET;
			
		}else if(StrEqual(weaponname, "weapon_m3") || StrEqual(weaponname, "weapon_xm1014")){
			
			//이것들은 탐지장치와 지뢰기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_SENSOR | ABILITY_MINE | ABILITY_BULLET | ABILITY_SHOTGUN;
			
		}else if(StrEqual(weaponname, "weapon_mp5navy") || StrEqual(weaponname, "weapon_ump45") || StrEqual(weaponname, "weapon_p90")){
			
			//이것들은 탐지 기능과 치료 기능이 있다
			abilitybuffer[client] = abilitybuffer[client] | ABILITY_SENSOR | ABILITY_HEAL | ABILITY_BULLET;
			
		}
		
	}
	
	return Plugin_Continue;
	
}

public selectormenu(client){
	
	new Handle:menuhandle = CreateMenu(selectormenuhandler);
	
	SetMenuTitle(menuhandle, "-셀렉터 설정-");
	
	AddMenuItem(menuhandle, "탄환", "탄환");
	
	if(abilitybuffer[client] & ABILITY_GRENADE){
	
		AddMenuItem(menuhandle, "유탄", "유탄");
		
	}else{
		
		AddMenuItem(menuhandle, "유탄", "유탄", ITEMDRAW_DISABLED);
		
	}
	if(abilitybuffer[client] & ABILITY_MINE){
	
		AddMenuItem(menuhandle, "부착형지뢰", "부착형지뢰");
		
	}else{
		
		AddMenuItem(menuhandle, "부착형지뢰", "부착형지뢰", ITEMDRAW_DISABLED);
		
	}
	if(abilitybuffer[client] & ABILITY_SENSOR){
	
		AddMenuItem(menuhandle, "탐지장치", "탐지장치");
		
	}else{
		
		AddMenuItem(menuhandle, "탐지장치", "탐지장치", ITEMDRAW_DISABLED);
		
	}
	if(abilitybuffer[client] & ABILITY_ROCKET){
	
		AddMenuItem(menuhandle, "유도로켓", "유도로켓");
		
	}else{
		
		AddMenuItem(menuhandle, "유도로켓", "유도로켓", ITEMDRAW_DISABLED);
		
	}
	if(abilitybuffer[client] & ABILITY_HEAL){
	
		AddMenuItem(menuhandle, "치료", "치료");
		
	}else{
		
		AddMenuItem(menuhandle, "치료", "치료", ITEMDRAW_DISABLED);
		
	}
	SetMenuExitButton(menuhandle, true);
	
	DisplayMenu(menuhandle, client, MENU_TIME_FOREVER);
	
}

public selectormenuhandler(Handle:menu, MenuAction:action, client, select){
	
	if(action == MenuAction_Select){
		
		if(IsClientConnectedIngameAlive(client)){
		
			if(select == 0){
				
				if(abilitybuffer[client] > ABILITY_BULLET){
				
					PrintToChat(client, "\x04탄환모드");
					selectormode[client] = selector_bullet;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 셀렉터가 없습니다");
					
				}
				
			}else if(select == 1){
				
				if(abilitybuffer[client] & ABILITY_GRENADE){
				
					PrintToChat(client, "\x04유탄모드");
					selectormode[client] = selector_grenade;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 선택한 셀렉터가 없습니다");
					
				}
				
			}else if(select == 2){
				
				if(abilitybuffer[client] & ABILITY_MINE){
				
					PrintToChat(client, "\x04부착형지뢰모드");
					selectormode[client] = selector_mine;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 선택한 셀렉터가 없습니다");
					
				}
				
			}else if(select == 3){
				
				if(abilitybuffer[client] & ABILITY_SENSOR){
				
					PrintToChat(client, "\x04탐지장치모드");
					selectormode[client] = selector_sensor;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 선택한 셀렉터가 없습니다");
					
				}
				
			}else if(select == 4){
				
				if(abilitybuffer[client] & ABILITY_ROCKET){
				
					PrintToChat(client, "\x04유도로켓모드");
					selectormode[client] = selector_rocket;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 선택한 셀렉터가 없습니다");
					
				}
				
			}else if(select == 5){
				
				if(abilitybuffer[client] & ABILITY_HEAL){
				
					PrintToChat(client, "\x04치료모드");
					selectormode[client] = selector_heal;
					
				}else{
					
					PrintToChat(client, "\x04지금 쓰는 무기에는 선택한 셀렉터가 없습니다");
					
				}
				
			}
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		if(select == MenuCancel_Exit){
			
			
			
		}
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

specialattack(client){
	
	if((selectormode[client] == selector_grenade) && (abilitybuffer[client] & ABILITY_GRENADE)){
		
		//유탄발사
		grenadeattack(client);
		
	}else if((selectormode[client] == selector_rocket) && (abilitybuffer[client] & ABILITY_ROCKET)){
		
		rocketattack(client);
		
	}else if((selectormode[client] == selector_mine) && (abilitybuffer[client] & ABILITY_MINE)){
		
		mineattack(client);
		
	}else if((selectormode[client] == selector_sensor) && (abilitybuffer[client] & ABILITY_SENSOR)){
		
		sensorattack(client);
		
	}else if((selectormode[client] == selector_heal) && (abilitybuffer[client] & ABILITY_HEAL)){
		
		healattack(client);
		
	}
	
}

public Action:EventSpawn(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	nextsensoractivetime[client] = GetEngineTime() + 1.0;
	selectormode[client] = selector_default;
	PrintToChat(client, "\x04탄환모드");
	
	for(new i = 0; i <= MAXPLAYERS; i++){
		
		ditectedbysensor[client][i] = false;
		
	}
	
}

stock grenadeattack(client){
	
	//유탄을 발사한다
	
	new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(usingweapon != -1){
			
		//탄환이 충분하고, 재장전이 끝났고, 무기의 다음 공격시간이 유효하고, 플레이어의 다음 공격시간이 유효한가 확인,
		//이것들을 하나라도 빠트리면 버그가 생겼다
		new ammo = GetEntProp(usingweapon, Prop_Data, "m_iClip1");
		
		if(ammo >= selectorammo[selector_grenade]
			&& !GetEntProp(usingweapon, Prop_Data, "m_bInReload")
			&& GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime()
			&& GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime()){
			
			//탄환이 충분하므로 탄환을 줄이고 발사를 시작한다
			SetEntProp(usingweapon, Prop_Data, "m_iClip1", ammo - selectorammo[selector_grenade]);
			//다음 공격 시간을 늧춘다
			SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Float:selectorcooltime[selector_grenade]));
			
			decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
			GetClientEyeAngles(client, clienteyeangle);
			GetClientEyePosition(client, clienteyeposition);
			GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(anglevector, anglevector);
			//ScaleVector(anglevector, 10.0);
			AddVectors(clienteyeposition, anglevector, resultposition);
			NormalizeVector(anglevector, anglevector);
			ScaleVector(anglevector, GRENADE_SPEED);
			
			//이제 중요한 것 하나, 플레이어의 이동속도를 유탄의 속도에 더해야한다.
			//현실성은 중요한것
			decl Float:playerspeed[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
			AddVectors(anglevector, playerspeed, anglevector);
			
			entity = CreateEntityByName("hegrenade_projectile");
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			setm_takedamage(entity, DAMAGE_YES);
			DispatchSpawn(entity);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityModel(entity, "models/Weapons/ar2_grenade.mdl");//유탄
			TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
			//소리
			playsound(SOUNDTYPEGRENADE_LAUNCHER1, clienteyeposition);
			//유탄이 닿는 순간 터지게 하기 위한 훅
			SDKHook(entity, SDKHook_StartTouch, GrenadeTouchHook);
			//유탄이 공격당하는 순간 터지게 하기 위한 훅
			SDKHook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
			
		}
		
	}
	
}

public Action:GrenadeTouchHook(entity, other){
	
	//테스트코드PrintToChatAll("유탄터치훅 %d", GetEntProp(entity, Prop_Data, "m_takedamage"));
	
	if(other != 0){
		
		//발사한 사람의 몸에 닿더라도 터져서는 안된다
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			
			return Plugin_Continue;
			
		}else{
		
			decl String:name[64];
			GetEdictClassname(other, name, sizeof(name));
		
			//닿아서 터져야 하는 것들의 목록 중에 단 한개도 일치하지 않는 경우
			if(!(StrEqual(name, "player") || StrContains(name, "phys", false) != -1 || StrContains(name, "prop", false) != -1 || StrContains(name, "door", false)  != -1
				|| StrContains(name, "weapon", false)  != -1 || StrContains(name, "break", false)  != -1 || StrContains(name, "projectile", false)  != -1 || StrContains(name, "brush", false)  != -1)){
				
				return Plugin_Continue;
				
			}
			
		}
			
	}
	
	GrenadeActive(entity);
	
	return Plugin_Continue;
	
}

public Action:GrenadeDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	//테스트코드PrintToChatAll("유탄데미지훅 %d", GetEntProp(entity, Prop_Data, "m_takedamage"));
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		GrenadeActive(entity);
		
	}
	
	return Plugin_Continue;
	
}

stock GrenadeActive(entity){
	
	//유탄이 닿는 순간 터지게 하기 위한 훅
	SDKUnhook(entity, SDKHook_StartTouch, GrenadeTouchHook);
	//유탄이 공격당하는 순간 터지게 하기 위한 훅
	SDKUnhook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		setm_takedamage(entity, DAMAGE_NO);//더이상 데미지를 안 입게 한다
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		//유탄 엔티티 제거
		AcceptEntityInput(entity, "Kill");
		entityposition[2] = entityposition[2] + 15.0;//폭발을 약간 위쪽으로, 데미지를 제대로 주기 위한 수단
		//폭발을 일으킨다
		makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "grenade launcher", DAMAGE_GRENADE);
		//폭발음을 일으킨다
		playsound(SOUNDTYPEEXPLODE, entityposition);
		
	}
	
}

stock rocketattack(client){
	
	//로켓을 발사한다
	
	new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(usingweapon != -1){
			
		//탄환이 충분하고, 재장전이 끝났고, 무기의 다음 공격시간이 유효하고, 플레이어의 다음 공격시간이 유효한가 확인,
		//이것들을 하나라도 빠트리면 버그가 생겼다
		new ammo = GetEntProp(usingweapon, Prop_Data, "m_iClip1");
		
		if(ammo >= selectorammo[selector_rocket]
			&& !GetEntProp(usingweapon, Prop_Data, "m_bInReload")
			&& GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime()
			&& GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime()){
			
			//탄환이 충분하므로 탄환을 줄이고 발사를 시작한다
			SetEntProp(usingweapon, Prop_Data, "m_iClip1", ammo - selectorammo[selector_rocket]);
			//다음 공격 시간을 늧춘다
			SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Float:selectorcooltime[selector_rocket]));
			
			decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
			GetClientEyeAngles(client, clienteyeangle);
			GetClientEyePosition(client, clienteyeposition);
			GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(anglevector, anglevector);
			//ScaleVector(anglevector, 10.0);
			AddVectors(clienteyeposition, anglevector, resultposition);
			NormalizeVector(anglevector, anglevector);
			ScaleVector(anglevector, ROCKET_SPEED);
			
			entity = CreateEntityByName("hegrenade_projectile");
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			setm_takedamage(entity, DAMAGE_YES);
			//중력을 0 으로
			SetEntityGravity(entity, 0.000001);
			DispatchSpawn(entity);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityModel(entity, "models/weapons/w_missile_launch.mdl");//미사일
			TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
			
			new gascloud = CreateEntityByName("env_smokestack");
			DispatchKeyValueVector(gascloud,"Origin", resultposition);
			DispatchKeyValue(gascloud,"SpreadSpeed", "10");
			DispatchKeyValue(gascloud,"Speed", "100");
			DispatchKeyValue(gascloud,"BaseSpread", "0");
			DispatchKeyValue(gascloud,"StartSize", "4");
			DispatchKeyValue(gascloud,"EndSize", "50");
			DispatchKeyValue(gascloud,"Rate", "80");
			DispatchKeyValue(gascloud,"JetLength", "80");
			DispatchKeyValue(gascloud,"RenderColor", "255 255 255");
			DispatchKeyValue(gascloud,"RenderAmt", "255");
			DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			DispatchSpawn(gascloud);
			AcceptEntityInput(gascloud, "TurnOn");
			decl String:steamid[64];
			GetClientAuthString(client, steamid, 64);
			Format(steamid, 64, "%s%f", steamid, GetGameTime());
			DispatchKeyValue(entity, "targetname", steamid);
			SetVariantString(steamid);
			AcceptEntityInput(gascloud, "SetParent");
			SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", gascloud);
			
			//소리
			playsound(SOUNDTYPEROCKETFIRE1, clienteyeposition);
			playentitysound(entity, SOUNDROCKET1, resultposition);
			//미사일이 닿는 순간 터지게 하기 위한 훅
			SDKHook(entity, SDKHook_StartTouch, RocketTouchHook);
			//미사일이 공격당하는 순간 터지게 하기 위한 훅
			SDKHook(entity, SDKHook_OnTakeDamage, RocketDamageHook);
			
			//미사일의 유도를 위한 함수를 위한 정보
			new Handle:datapack = CreateDataPack();
			//이 미사일의 엔티티 레퍼런스를 담아둔다
			WritePackCell(datapack, EntIndexToEntRef(entity));
			//이것은 소리를 위한 것이다
			WritePackCell(datapack, entity);
			//바로 실행되는 타이머
			CreateTimer(0.1, RocketSeekThink, datapack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
			
		}
		
	}
	
}

public Action:RocketTouchHook(entity, other){
	
	//테스트코드PrintToChatAll("로켓터치훅 %d", GetEntProp(entity, Prop_Data, "m_takedamage"));
	
	if(other != 0){
		
		//발사한 사람의 몸에 닿더라도 터져서는 안된다
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			
			return Plugin_Continue;
			
		}else{
		
			decl String:name[64];
			GetEdictClassname(other, name, sizeof(name));
			
			//닿아서 터져야 하는 것들의 목록 중에 단 한개도 일치하지 않는 경우
			if(!(StrEqual(name, "player") || StrContains(name, "phys", false) != -1 || StrContains(name, "prop", false) != -1 || StrContains(name, "door", false)  != -1
				|| StrContains(name, "weapon", false)  != -1 || StrContains(name, "break", false)  != -1 || StrContains(name, "projectile", false)  != -1 || StrContains(name, "brush", false)  != -1)){
				
				return Plugin_Continue;
				
			}
			
		}
			
	}
	
	RocketActive(entity);
	
	return Plugin_Continue;
	
}

public Action:RocketDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	//테스트코드PrintToChatAll("로켓데미지훅 %d", GetEntProp(entity, Prop_Data, "m_takedamage"));
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		RocketActive(entity);
		
	}
	
	return Plugin_Continue;
	
}

//로켓의 유도코드, 이 코드가 로켓 추진 소리의 중지도 담당한다
public Action:RocketSeekThink(Handle:Timer, Handle:data){
	
	//리셋팩
	decl entity, soundentity, client;
	ResetPack(data);
	entity = ReadPackCell(data);
	entity = EntRefToEntIndex(entity);
	soundentity = ReadPackCell(data);
	
	//미사일엔티티가 존재한다
	if(entity != -1){
	
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
		//클라이언트가 아직 살아있는가? 살아있지 않다면, 유도를 중단하고 곧장 날아간다.
		if(IsClientConnectedIngame(client)){
			
			//접속해 있고 살아있는 경우
			if(IsPlayerAlive(client)){
				
				//현재 꺼내든 무기가 유도로켓 기능이 있는가?
				if(abilitybuffer[client] & ABILITY_ROCKET && selectormode[client] == selector_rocket){
					
					//플레이어가 바라보는 곳의 위치를 구하고, 로켓의 위치로부터 그 위치로까지의 각도를 구해서 그 각도로 향하게 각도 조절
					decl Float:cleyepos[3], Float:cleyeangle[3], Float:resultposition[3], Float:rocketposition[3], Float:vecangle[3], Float:angle[3];
					
					GetClientEyePosition(client, cleyepos); 
					GetClientEyeAngles(client, cleyeangle);
					
					new Handle:traceresulthandle = INVALID_HANDLE;
										
					traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterrocket, client);
										
					if(TR_DidHit(traceresulthandle) == true){
						
						TR_GetEndPosition(resultposition, traceresulthandle);
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", rocketposition);
						//로켓포지션에서 추적 위치로 가는 벡터를 구한다
						MakeVectorFromPoints(rocketposition, resultposition, vecangle);
						NormalizeVector(vecangle, vecangle);
						GetVectorAngles(vecangle, angle);
						ScaleVector(vecangle, ROCKET_SPEED);
						TeleportEntity(entity, NULL_VECTOR, angle, vecangle);
						
					}
					
					CloseHandle(traceresulthandle);
						
				}
				
			}
			
		}
		
		return Plugin_Continue;
		
	}else{
		
		//소리 중지
		stopentitysound(soundentity, SOUNDROCKET1);
		
		return Plugin_Stop;
		
	}
	
}

stock RocketActive(entity){
	
	//미사일이 닿는 순간 터지게 하기 위한 훅
	SDKUnhook(entity, SDKHook_StartTouch, RocketTouchHook);
	//미사일이 공격당하는 순간 터지게 하기 위한 훅
	SDKUnhook(entity, SDKHook_OnTakeDamage, RocketDamageHook);
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == DAMAGE_YES){
	
		setm_takedamage(entity, DAMAGE_NO);//더이상 데미지를 안 입게 한다
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		//로켓과 가스 엔티티 제거
		new gasentity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");//가스엔티티를 구한다
		AcceptEntityInput(gasentity, "ClearParent");//가스엔티티를 떼어둔다
		AcceptEntityInput(gasentity, "TurnOff");//가스엔티티가 꺼지고서 적절히 연막이 사라지도록 하자
		decl String:output[512];
		Format(output, 512, "OnUser1 !self:kill:justkill:8.0:1");
		SetVariantString(output);
		AcceptEntityInput(gasentity, "AddOutput");
		AcceptEntityInput(gasentity, "FireUser1");
		AcceptEntityInput(entity, "Kill");
		entityposition[2] = entityposition[2] + 15.0;
		//폭발을 일으킨다
		makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "rocket", DAMAGE_ROCKET);
		//폭발음을 일으킨다
		playsound(SOUNDTYPEEXPLODE, entityposition);
		
	}
	
}

//힐
stock healattack(client){
	
	new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(usingweapon != -1){
			
		//탄환이 충분하고, 재장전이 끝났고, 무기의 다음 공격시간이 유효하고, 플레이어의 다음 공격시간이 유효한가 확인,
		//이것들을 하나라도 빠트리면 버그가 생겼다
		new ammo = GetEntProp(usingweapon, Prop_Data, "m_iClip1");
		
		if(ammo >= selectorammo[selector_heal]
			&& !GetEntProp(usingweapon, Prop_Data, "m_bInReload")
			&& GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime()
			&& GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime()){
				
			//조준선에 있는 아군 클라이언트를 찾아내서 거리가 100 이하라면 체력을 판단한 뒤 치료와 함께 이펙트
			decl Float:cleyepos[3], Float:cleyeangle[3], Float:resultposition[3];
					
			GetClientEyePosition(client, cleyepos);
			GetClientEyeAngles(client, cleyeangle);
			
			new Handle:traceresulthandle = INVALID_HANDLE;
								
			traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
								
			if(TR_DidHit(traceresulthandle) == true){
				
				TR_GetEndPosition(resultposition, traceresulthandle);
				new target = TR_GetEntityIndex(traceresulthandle);
				
				if(IsClientConnectedIngameAlive(target) && GetClientTeam(target) == GetClientTeam(client)){
					
					//다음 공격 시간을 늧춘다
					SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Float:selectorcooltime[selector_heal]));
					
					if(200 >= GetVectorDistance(cleyepos, resultposition)){
						
						new targethealth = GetEntProp(target, Prop_Data, "m_iHealth");
						
						if(targethealth < 100){
							
							//치료를 해야한다
							//탄환이 충분하므로 탄환을 줄인다
							SetEntProp(usingweapon, Prop_Data, "m_iClip1", ammo - selectorammo[selector_heal]);
							
							new maxhealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");
							
							if(targethealth + HEAL_PER_TIME >= maxhealth){
								
								SetEntProp(target, Prop_Data, "m_iHealth", maxhealth);
								
							}else{
								
								SetEntProp(target, Prop_Data, "m_iHealth", targethealth + HEAL_PER_TIME);
								
							}
							
							//이펙트를 만든다
							playsound(SOUNDTYPEHEAL, cleyepos);
							
						}else{
							
							playsound(SOUNDTYPENOHEAL, cleyepos);
							
						}
						
					}
					
				}
				
			}
			
			CloseHandle(traceresulthandle);
			
		}
		
	}
	
}

//마인어택
stock mineattack(client){
	
	//지뢰를 깐다
	
	new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(usingweapon != -1){
			
		//탄환이 충분하고, 재장전이 끝났고, 무기의 다음 공격시간이 유효하고, 플레이어의 다음 공격시간이 유효한가 확인,
		//이것들을 하나라도 빠트리면 버그가 생겼다
		new ammo = GetEntProp(usingweapon, Prop_Data, "m_iClip1");
		
		if(ammo >= ((abilitybuffer[client] & ABILITY_SHOTGUN) ? SHOTGUNMINEAMMO :  selectorammo[selector_mine])
			&& !GetEntProp(usingweapon, Prop_Data, "m_bInReload")
			&& GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime()
			&& GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime()){
			
			//트레이스레이를 써서 지뢰를 깔 위치를 구한다
			decl Float:cleyepos[3], Float:cleyeangle[3];
					
			GetClientEyePosition(client, cleyepos);
			GetClientEyeAngles(client, cleyeangle);
			
			new Handle:traceresulthandle = INVALID_HANDLE;
			
			decl Float:traceresultposition[3], Float:mineresultposition[3], Float:mineresultnormalvector[3], Float:minevectorangle[3];
			
			traceresulthandle = TR_TraceRayFilterEx(cleyepos, cleyeangle, MASK_SOLID, RayType_Infinite, tracerayfilternoplayer, client);
								
			if(TR_DidHit(traceresulthandle)){
				
				TR_GetEndPosition(traceresultposition, traceresulthandle);
				TR_GetPlaneNormal(traceresulthandle, mineresultnormalvector);
				
				NormalizeVector(mineresultnormalvector, mineresultnormalvector);
				ScaleVector(mineresultnormalvector, 4.0);
				AddVectors(traceresultposition, mineresultnormalvector, mineresultposition);
				GetVectorAngles(mineresultnormalvector, minevectorangle);
				//여기서 얻어낸 것은 마인의 위치와 각도이다
				
				if(80 >= GetVectorDistance(cleyepos, traceresultposition)){
					
					//탄환이 충분하므로 탄환을 줄이고 발사를 시작한다
					SetEntProp(usingweapon, Prop_Data, "m_iClip1", ammo - ((abilitybuffer[client] & ABILITY_SHOTGUN) ? SHOTGUNMINEAMMO : selectorammo[selector_mine]));
					//다음 공격 시간을 늧춘다
					SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Float:selectorcooltime[selector_mine]));
					
					decl String:input[128];
					
					//지뢰엔티티를 만든다
					new physicalmineentity = CreateEntityByName("prop_physics_override");
					DispatchKeyValue(physicalmineentity, "model", "models/items/battery.mdl");
					DispatchKeyValueVector(physicalmineentity, "origin", mineresultposition);
					DispatchKeyValueVector(physicalmineentity, "angles", minevectorangle);
					
					if(TR_GetEntityIndex(traceresulthandle) != 0){
					
						minegroundentity[physicalmineentity] = EntIndexToEntRef(TR_GetEntityIndex(traceresulthandle));
						
					}else{
						
						minegroundentity[physicalmineentity] = 0;
						
					}
					
					decl String:targetname[128];
					
					//빔의 시작 위치를 구하기 위한 계산(시작위치 = 레이저가 닿은 벽면, 끝위치 = 마인이 심어진 위치)
					new Handle:traceresulthandle2 = INVALID_HANDLE;
					decl Float:beamstartpos[3];
					traceresulthandle2 = TR_TraceRayFilterEx(traceresultposition, minevectorangle, MASK_SOLID, RayType_Infinite, tracerayfilternoplayer, client);			
					if(TR_DidHit(traceresulthandle2)){
				
						TR_GetEndPosition(beamstartpos, traceresulthandle2);
						
					}
					CloseHandle(traceresulthandle2);
					
					//엔브빔엔티티 생성
					new envbeamentity = CreateEntityByName("env_beam");
					
					mineentity[envbeamentity] = EntIndexToEntRef(physicalmineentity);
					
					//엔브빔 엔티티 타겟네임 설정
					Format(targetname, 128, "%f%f", GetGameTime(), GetRandomFloat());
					DispatchKeyValue(envbeamentity, "targetname", targetname);
					DispatchKeyValue(envbeamentity, "LightningStart", targetname);
					//시작위치 위치설정
					//NormalizeVector(resultnormal, resultnormal);
					//ScaleVector(resultnormal, 3.0);
					//AddVectors(resultposition, resultnormal, resultposition);
					DispatchKeyValueVector(envbeamentity, "origin", beamstartpos);
					
					//각종 빔엔티티 설정
					//렌더링색설정
					DispatchKeyValue(envbeamentity, "renderamt", "150");
					//렌더링효과설정
					DispatchKeyValue(envbeamentity, "renderfx", "15");
					new team = GetClientTeam(client);
					
					if(team == CS_TEAM_CT){
						
						DispatchKeyValue(envbeamentity, "rendercolor", "0 0 255");
						
					}else if(team == CS_TEAM_T){
						
						DispatchKeyValue(envbeamentity, "rendercolor", "255 64 64");
						
					}
					
					//굵기설정
					DispatchKeyValue(envbeamentity, "BoltWidth", "4.0");
					//모델설정
					DispatchKeyValue(envbeamentity, "texture", "materials/sprites/laser.vmt");
					//지속시간설정
					DispatchKeyValue(envbeamentity, "life", "0.0");
					DispatchKeyValue(envbeamentity, "StrikeTime", "0");
					DispatchKeyValue(envbeamentity, "TextureScroll", "35");
					DispatchKeyValue(envbeamentity, "framerate", "10");
					DispatchKeyValue(envbeamentity, "framestart", "10");
					DispatchKeyValue(envbeamentity, "TouchType", "4");
					
					//엔브빔에 아웃펏을 넣는다
					Format(input, 128, "%s,FireUser2,,0,-1", targetname);
					DispatchKeyValue(envbeamentity, "OnTouchedByEntity", input);
					
					//엔브빔 엔티티의 끝 위치 설정 이전에, 마인을 스폰해야한다
					DispatchSpawn(physicalmineentity);
					setm_takedamage(physicalmineentity, DAMAGE_NO);//마인은 현재 작동하지 않는다
					AcceptEntityInput(physicalmineentity, "DisableMotion");
					SetEntProp(physicalmineentity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE);
					SetEntProp(physicalmineentity, Prop_Data, "m_MoveCollide", MOVECOLLIDE_DEFAULT);
					SetEntProp(physicalmineentity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
					SetEntPropEnt(physicalmineentity, Prop_Send, "m_hOwnerEntity", client);
					SetEntPropEnt(physicalmineentity, Prop_Send, "m_hEffectEntity", envbeamentity);
					
					//이제 또한번의 트레이스를 써서, 엔브빔의 끝위치를 구한다
					new Handle:traceresulthandle3 = INVALID_HANDLE;
					decl Float:beamendpos[3];
					
					decl Float:pointvector[3], Float:pointangle[3];
					MakeVectorFromPoints(beamstartpos, traceresultposition, pointvector);
					GetVectorAngles(pointvector, pointangle);
					
					traceresulthandle3 = TR_TraceRayFilterEx(beamstartpos, pointangle, MASK_SOLID, RayType_Infinite, tracerayfilternoplayer, client);			
					if(TR_DidHit(traceresulthandle3)){
				
						TR_GetEndPosition(beamendpos, traceresulthandle3);
						
					}
					CloseHandle(traceresulthandle3);
					
					SetEntPropVector(envbeamentity, Prop_Data, "m_vecEndPos", beamendpos);
					
					DispatchSpawn(envbeamentity);
					SetEntProp(physicalmineentity, Prop_Data, "m_iHealth", 0);
					setm_takedamage(physicalmineentity, DAMAGE_YES);//이 시점부터 마인이 작동한다
					
					//이 작업은 엔브빔 엔티티의 스폰 이후에 해야한다
					SetEntityModel(envbeamentity, "materials/sprites/laser.vmt");
					
					AcceptEntityInput(envbeamentity, "TurnOff");
					
					CreateTimer(4.0, StartMine, EntIndexToEntRef(envbeamentity), TIMER_FLAG_NO_MAPCHANGE);
					
					SDKHook(physicalmineentity, SDKHook_OnTakeDamage, MineDamageHook);
					SDKHook(physicalmineentity, SDKHook_EndTouch, MineEndTouchHook);
					HookSingleEntityOutput(envbeamentity, "OnUser2", minebeamoutputhook);
					mineoutputhooked[envbeamentity] = true;
					
					//효과음 내기
					playsound(SOUNDTYPEMINEPUT, cleyepos);
					
				}
				
			}
			
			CloseHandle(traceresulthandle);
			
		}
		
	}
	
}

public Action:StartMine(Handle:timer, any:envbeamentity){

	if(EntRefToEntIndex(envbeamentity) != -1){
		
		AcceptEntityInput(envbeamentity, "TurnOn");
		decl Float:entityposition[3];
		GetEntPropVector(EntRefToEntIndex(envbeamentity), Prop_Send, "m_vecOrigin", entityposition);
		playsound(SOUNDTYPEMINEACT, entityposition);
		
	}
	
}

public minebeamoutputhook(const String:output[], envbeamentity, activator, Float:delay){
	
	new physicalmineentity = EntRefToEntIndex(mineentity[envbeamentity]);
	
	new bool:keepsensing = true;
	
	if(physicalmineentity != -1){
		
		new client = GetEntPropEnt(physicalmineentity, Prop_Send, "m_hOwnerEntity");
		
		if(IsClientConnectedIngame(client)){
			
			if(IsClientConnectedIngameAlive(activator)){
				
				if(GetClientTeam(client) != GetClientTeam(activator)){
					
					MineActive(physicalmineentity);
					keepsensing = false;
					
				}
				
			}
			
		}
		
	}else{
		
		keepsensing = false;
		
	}
	
	if(keepsensing){
		
		decl String:input[128];
		AcceptEntityInput(envbeamentity, "TurnOff");
		Format(input, 128, "OnUser1 !self:TurnOn::0.0:1");
		SetVariantString(input);
		AcceptEntityInput(envbeamentity, "AddOutput");
		AcceptEntityInput(envbeamentity, "FireUser1");
		
	}
	
}

public MineEndTouchHook(entity, other){
	
	if(EntRefToEntIndex(minegroundentity[entity]) == other){
		
		MineActive(entity);
		
	}
	
}

public Action:MineDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	//지금까지의 데미지의 총합을 계산한다
	SetEntProp(entity, Prop_Data, "m_iHealth", GetEntProp(entity, Prop_Data, "m_iHealth") + RoundToNearest(damage));
	//데미지를 얼마 이상 먹은 경우!
	if(GetEntProp(entity, Prop_Data, "m_iHealth") >= MINE_DAMAGE_TO_BREAK){
	
		MineActive(entity);
		
	}
	
	return Plugin_Handled;
	
}

stock MineActive(physicalmineentity){
	
	SDKUnhook(physicalmineentity, SDKHook_OnTakeDamage, MineDamageHook);
	SDKUnhook(physicalmineentity, SDKHook_EndTouch, MineEndTouchHook);
	
	if(GetEntProp(physicalmineentity, Prop_Data, "m_takedamage") == DAMAGE_YES){
		
		setm_takedamage(physicalmineentity, DAMAGE_NO);//더이상 데미지를 안 입게 한다
		new client = GetEntPropEnt(physicalmineentity, Prop_Send, "m_hOwnerEntity");
		new beamentity = GetEntPropEnt(physicalmineentity, Prop_Send, "m_hEffectEntity");//빔엔티티를 구한다
		decl Float:entityposition[3], Float:entityangle[3], Float:entityanglevector[3];
		GetEntPropVector(beamentity, Prop_Data, "m_vecEndPos", entityposition);
		GetEntPropVector(physicalmineentity, Prop_Send, "m_angRotation", entityangle);
		GetAngleVectors(entityangle, entityanglevector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(entityanglevector, entityanglevector);
		ScaleVector(entityanglevector, 4.0);
		AddVectors(entityposition, entityanglevector, entityposition);
		AcceptEntityInput(beamentity, "kill");//빔엔티티 삭제
		AcceptEntityInput(physicalmineentity, "Kill");
		//폭발을 일으킨다
		makeexplosion(IsClientConnectedIngame(client) ? client : 0, -1, entityposition, "sensormine", DAMAGE_MINE);
		//폭발음을 일으킨다
		playsound(SOUNDTYPEEXPLODE, entityposition);
		
	}
	
}

//센서어택
stock sensorattack(client){
	
	//센서를 발사한다
	
	new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(usingweapon != -1){
			
		//탄환이 충분하고, 재장전이 끝났고, 무기의 다음 공격시간이 유효하고, 플레이어의 다음 공격시간이 유효한가 확인,
		//이것들을 하나라도 빠트리면 버그가 생겼다
		new ammo = GetEntProp(usingweapon, Prop_Data, "m_iClip1");
		
		if(ammo >= ((abilitybuffer[client] & ABILITY_SHOTGUN) ? SHOTGUNSENSORAMMO : selectorammo[selector_sensor])
			&& !GetEntProp(usingweapon, Prop_Data, "m_bInReload")
			&& GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime()
			&& GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime()){
			
			//탄환이 충분하므로 탄환을 줄이고 발사를 시작한다
			SetEntProp(usingweapon, Prop_Data, "m_iClip1", ammo - ((abilitybuffer[client] & ABILITY_SHOTGUN) ? SHOTGUNSENSORAMMO : selectorammo[selector_sensor]));
			//다음 공격 시간을 늧춘다
			SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Float:selectorcooltime[selector_sensor]));
			
			decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
			GetClientEyeAngles(client, clienteyeangle);
			GetClientEyePosition(client, clienteyeposition);
			GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(anglevector, anglevector);
			//ScaleVector(anglevector, 10.0);
			AddVectors(clienteyeposition, anglevector, resultposition);
			NormalizeVector(anglevector, anglevector);
			ScaleVector(anglevector, SENSOR_SPEED);
			
			//이제 중요한 것 하나, 플레이어의 이동속도를 발사된 센서의 속도에 더해야한다.
			//현실성은 중요한것
			decl Float:playerspeed[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
			AddVectors(anglevector, playerspeed, anglevector);
			
			entity = CreateEntityByName("hegrenade_projectile");
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			setm_takedamage(entity, DAMAGE_YES);
			DispatchSpawn(entity);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityModel(entity, "models/items/combine_rifle_ammo01.mdl");//센서의 모델은 ar2의 코어아이템 모델
			//SetEntityGravity(entity, 1.0);//중력 조절, 센서는 한번 날아가기 시작한 힘으로 아주 멀리까지도 날아가므로
			SetEntityMoveType(entity, MOVETYPE_FLY);//중력에 구애받지 않게 한다! 센서는 특수체
			TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
			//소리
			playsound(SOUNDTYPESENSORFIRE, clienteyeposition);
			//센서가 닿는 순간 센서를 발동시켜야 한다
			SDKHook(entity, SDKHook_StartTouch, SensorTouchHook);
			//센서가 공격당하는 순간 터지게 하기 위한 훅
			SDKHook(entity, SDKHook_OnTakeDamage, SensorDamageHook);
			
		}
		
	}
	
}

public Action:SensorTouchHook(entity, other){
	
	if(other != 0){
		
		//발사한 사람의 몸에 닿더라도 터져서는 안된다
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			
			return Plugin_Continue;
			
		}else{
		
			decl String:name[64];
			GetEdictClassname(other, name, sizeof(name));
		
			//닿아서 작동을 시작해야 하는 것들의 목록 중에 단 한개도 일치하지 않는 경우
			if(!(StrContains(name, "physics", false) != -1 || StrContains(name, "prop", false) != -1 || StrContains(name, "door", false)  != -1
				|| StrContains(name, "weapon", false)  != -1 || StrContains(name, "break", false)  != -1 || StrContains(name, "projectile", false)  != -1 || StrContains(name, "brush", false)  != -1)){
				
				return Plugin_Continue;
				
			}
			
		}
			
	}
	
	SensorActive(entity);
	
	return Plugin_Continue;
	
}

public Action:SensorDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	AcceptEntityInput(entity, "kill");
	
	return Plugin_Continue;
	
}

stock SensorActive(sensorentity){
	
	//센서가 닿는 순간 센서를 발동시켜야 한다
	SDKHook(sensorentity, SDKHook_StartTouch, SensorTouchHook);
	//센서가 공격당하는 순간 터지게 하기 위한 훅
	SDKHook(sensorentity, SDKHook_OnTakeDamage, SensorDamageHook);
	
	if(GetEntProp(sensorentity, Prop_Data, "m_takedamage") == DAMAGE_YES){
		
		setm_takedamage(sensorentity, DAMAGE_NO);//더이상 데미지를 안 입게 한다
		new client = GetEntPropEnt(sensorentity, Prop_Send, "m_hOwnerEntity");
		decl Float:entityposition[3], Float:entityangle[3];
		GetEntPropVector(sensorentity, Prop_Data, "m_vecOrigin", entityposition);
		GetEntPropVector(sensorentity, Prop_Send, "m_angRotation", entityangle);
		AcceptEntityInput(sensorentity, "kill");//센서엔티티 삭제(이것은 hegrenade_projectile이므로, 허공에 제대로 멈출 수가 없다)
		
		entityposition[2] = entityposition[2] + 1.0;//땅에 박힌 센서가 작동하지 않는 것에 대한 보정
		
		//새로운 센서 엔티티를 만든다!
		new physicalsensorentity = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(physicalsensorentity, "model", "models/items/combine_rifle_ammo01.mdl");
		DispatchKeyValueVector(physicalsensorentity, "origin", entityposition);
		DispatchKeyValueVector(physicalsensorentity, "angles", entityangle);
		DispatchSpawn(physicalsensorentity);
		setm_takedamage(physicalsensorentity, DAMAGE_NO);
		AcceptEntityInput(physicalsensorentity, "DisableMotion");
		SetEntProp(physicalsensorentity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE);
		SetEntProp(physicalsensorentity, Prop_Data, "m_MoveCollide", MOVECOLLIDE_DEFAULT);
		SetEntProp(physicalsensorentity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
		SetEntPropEnt(physicalsensorentity, Prop_Send, "m_hOwnerEntity", client);
		
		//센서 탐지를 위한 함수를 위한 정보
		new Handle:datapack = CreateDataPack();
		//이 센서의 엔티티 레퍼런스를 담아둔다
		WritePackCell(datapack, EntIndexToEntRef(physicalsensorentity));
		WritePackCell(datapack, physicalsensorentity);
		WritePackFloat(datapack, GetEngineTime() + SENSORLIFETIME);
		//바로 실행되는 타이머
		CreateTimer(0.1, SensorThink, datapack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		
		setm_takedamage(physicalsensorentity, DAMAGE_YES);//이 시점부터 센서를 파괴하는 것이 가능하다
		
		//센서의 작동 시작음을 일으킨다
		playsound(SOUNDTYPESENSORATTACH, entityposition);
		playentitysound(physicalsensorentity, SOUNDSENSORACTIVE, entityposition);
		
	}
	
}

//센서의 감지코드
public Action:SensorThink(Handle:Timer, Handle:data){
	
	//리셋팩
	decl sensorentity, soundentity, client, Float:lifetime;
	ResetPack(data);
	sensorentity = ReadPackCell(data);
	sensorentity = EntRefToEntIndex(sensorentity);
	soundentity = ReadPackCell(data);
	lifetime = ReadPackFloat(data);
	
	//센서엔티티가 존재한다
	if(sensorentity != -1){
	
		client = GetEntPropEnt(sensorentity, Prop_Send, "m_hOwnerEntity");
		
		//클라이언트가 아직 접속해있고 살아있는가?
		if(IsClientConnectedIngameAlive(client)){
			
			//수명이 다하지 않았는가
			if(lifetime >= GetEngineTime()){
			
				//살아있으므로 감지해서 레이져 이펙트를 만들어보낸다
				
				for(new target = 1; target <= MaxClients; target++){
					
					//타겟이 클라이언트가 아니고 타겟이 살아있을 경우
					if(target != client && IsClientConnectedIngameAlive(target)){
						
						//트레이스를 써서 감지한다
						decl Float:sensorposition[3], Float:targetposition[3], Float:vectordirection[3], Float:angledirection[3];
						GetEntPropVector(sensorentity, Prop_Data, "m_vecOrigin", sensorposition);
						GetClientEyePosition(target, targetposition);
						targetposition[2] = targetposition[2] - 15.0;//몸통의 가운데 부분을 구한다
						
						MakeVectorFromPoints(sensorposition, targetposition, vectordirection);
						GetVectorAngles(vectordirection, angledirection);
								
						new Handle:traceresulthandle = INVALID_HANDLE;
				
						traceresulthandle = TR_TraceRayFilterEx(sensorposition, angledirection, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, sensorentity);
				
						if(TR_DidHit(traceresulthandle)){
					
							if(TR_GetEntityIndex(traceresulthandle) == target){
								
								ditectedbysensor[client][target] = true;
										
							}
									
						}
								
						CloseHandle(traceresulthandle);
					
					}
					
				}
				
				return Plugin_Continue;
				
			}else{
				
				//수명이 다했으므로 장식물 상태가 된다
				stopentitysound(soundentity, SOUNDSENSORACTIVE);
				decl Float:entityposition[3];
				GetEntPropVector(sensorentity, Prop_Data, "m_vecOrigin", entityposition);
				playsound(SOUNDTYPESENSORDEACTIVE, entityposition);
				return Plugin_Stop;
				
			}
				
		}else{
		
			//클라이언트가 살아있지 않으므로 더이상 어떤 감지도 하지 않는, 장식물 상태가 된다
			stopentitysound(soundentity, SOUNDSENSORACTIVE);
			decl Float:entityposition[3];
			GetEntPropVector(sensorentity, Prop_Data, "m_vecOrigin", entityposition);
			playsound(SOUNDTYPESENSORDEACTIVE, entityposition);
			return Plugin_Stop;
			
		}
		
	}else{
		
		//센서 엔티티가 존재하지 않으므로 데이터팩을 닫고 타이머의 반복도 끝낸다
		stopentitysound(soundentity, SOUNDSENSORACTIVE);
		return Plugin_Stop;
		
	}
	
}

//센서의 아웃펏 훅을 없애는 코드
public OnEntityDestroyed(entity){
	
	if(mineoutputhooked[entity]){
		
		UnhookSingleEntityOutput(entity, "OnUser2", minebeamoutputhook);
		mineoutputhooked[entity] = false;
		
	}
	
}