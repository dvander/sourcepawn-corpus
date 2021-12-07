//트레뮬로우스 모드
public Plugin:myinfo = {
	
	name = "tremelous",
	author = "javalia",
	description = "tremelous mod",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
	
};

//인클루드문장
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "sdkhooks"
#include "tremulous"

//문법정의
#pragma semicolon 1

//서버의 맥스플레이어 설정을 이 플러그인에 적용하려면 다음 상수를 수정하면 된다.
#define MAX_PLAYERS_SETTING 64

//키보드 입력을 위한 변수
new bool:prethinkbuffer[MAX_PLAYERS_SETTING + 1];

//이벤트로 처리할 데스이벤트
new bool:haskilledbysystemevent[MAX_PLAYERS_SETTING + 1];

//트레뮬로우스의 상태 저장에 필요한 변수 및 상수 선언

//서버의 게임 종류를 정하기 위한 값
new gametype:servergametype;

//팀 설정 : 1은 관전자, 2은 에일리언, 3는 인간
//hl2mp에서는 언사이네이드팀은 0, 1은 관전자, 2는 콤바인, 3은 시민군이다.
//cs:source에서는 0 은 사용되지 않는다. 팀플레이만 하므로. 관전자는 1, 테러리스트는 2, 대테러리스트는 3이다.
//전에 이 자리에 팀 설정을 저장하는 변수가 있었지만 지웠다
//또한 소스코드에서 그 변수와 관련된 모든 구문을 삭제했다

//테크 레벨 설정 저장
new techlevel;
new stagekills;

//플레이어 크레디트 저장
//인간은 적에게 데미지를 주는 것 만으로도 조금씩 크레디트가 찬다.
//그러나 에일리언은 실제로는 조금씩 데미지를 줘도 크레디트가 차지만,
//그것을 쓰려면 일정 이상 단위씩 모여야만 그 단위씩 진화에 쓰인다.
//기본적으로 1킬에 100 크레디트
new playercredit[MAX_PLAYERS_SETTING + 1];

//인간에게만 유효한 설정
new bool:playerhasmedkit[MAX_PLAYERS_SETTING + 1];//메드킷 소유여부
new bool:playerusedmedkit[MAX_PLAYERS_SETTING + 1];//메드킷 사용중
new playergetpoisonattack[MAX_PLAYERS_SETTING + 1];//독공격, 메드킷 먹으면 효과 상실, 인덱스는 당하는 사람, 값은 공격하는 사람
new playergetgasattack[MAX_PLAYERS_SETTING + 1];//가스 공격에 당한 상태, 인덱스는 당하는 사람, 값은 공격하는 사람
new bool:playergetadhesiveattack[MAX_PLAYERS_SETTING + 1];//트래퍼의 잡기 공격, 시간제한
new playergetgrabattack[MAX_PLAYERS_SETTING + 1];//바실리스크의 잡기 공격, 인덱스는 당하는 사람, 값은 공격하는 사람

//에일리언에게만 유효한 설정
new ownerofprojectile[2048];//가시공던지기 공격에서, 가시공이 누가 던진 것인가를 나타내는 변수
new bool:playerhaspoisonability[MAX_PLAYERS_SETTING + 1];//독공격 상태 저장
new playerisgrabing[MAX_PLAYERS_SETTING + 1];//바실리스크의 잡기 공격을 쓰는 사람용
new bool:playerpounceskillcooltime[MAX_PLAYERS_SETTING + 1];//드라군의 파운스공격의 쿨타임
new bool:playertrampleskillcooltime[MAX_PLAYERS_SETTING + 1];//돌진공격의 쿨타임
new bool:playerprojectileabilitycooltime[MAX_PLAYERS_SETTING + 1];//어드벤스드 그렌져의 포물체 던지기 공격의 쿨타임
new bool:playergasabilitycooltime[MAX_PLAYERS_SETTING + 1];//어드벤스드 바실리스크의 가스공격의 쿨타임
new bool:playerjumpskillcooltime[MAX_PLAYERS_SETTING + 1];//마라우더의 점프 쿨타임, 처음엔 이것이 필요하다고 여기지 않았다.
//그러나 이 기술을 땅에 있는 상태로 연속으로 써서 빠른 이동을 하는 사람들을 보고 이것이 필요함을 느꼇다.
new bool:playerelectricabilitycooltime[MAX_PLAYERS_SETTING + 1];//어드벤스드 마라우더의 방전공격의 쿨타임
new bool:playerbarbabilitycooltime[MAX_PLAYERS_SETTING + 1];//어드벤스드 드라군의 가시 발사 공격

//체력 회복 관련 설정
new Float:playerlasthealtime[MAX_PLAYERS_SETTING + 1];//에일리언의 체력 자동 회복을 위한 시간저장
new Float:playerlasthurttime[MAX_PLAYERS_SETTING + 1];//에일리언이 마지막으로 공격당한 시간을 저장한다
new bool:playergetdoubleheal[MAX_PLAYERS_SETTING + 1];//플레이어가 부스터 등의 건물에 의해 더블 힐 효과를 받고 있는지 점검한다
//플레이어클래스저장
new playerclasstype:playerclass[MAX_PLAYERS_SETTING + 1];

//타이머를 관리하기 위한 변수들. 이것은 킬타이머에 쓰인다.
new Handle:playerusedmedkithandle[MAX_PLAYERS_SETTING + 1];//메드킷 사용상태의 해제 타이머 핸들
new Handle:playerhaspoisonhandle[MAX_PLAYERS_SETTING + 1];//독공격 능력 시간제한 핸들
new Handle:playergetadhesivehandle[MAX_PLAYERS_SETTING + 1];//트래퍼의 잡기 공격의 쿨타임 해제 타이머 핸들
new Handle:playergetgashandle[MAX_PLAYERS_SETTING + 1];//어드벤스드 바실리스크의 가스공격에 당한 상태의 해제 타이머 핸들
new Handle:playerjumpcooltimehandle[MAX_PLAYERS_SETTING + 1];//마라우더의 점프의 쿨타임 해제 핸들
new Handle:playerpouncecooltimehandle[MAX_PLAYERS_SETTING + 1];//드라군의 파운스공격의 쿨타임 해제 핸들
new Handle:playerprojectilecooltimehandle[MAX_PLAYERS_SETTING + 1];//어드벤스드 그렌져의 포물체 던지기 공격의 쿨타임 해제 타이머 핸들
new Handle:playergascooltimehandle[MAX_PLAYERS_SETTING + 1];//어드벤스드바실리스크의 가스공격의 쿨타임 해제 타이머 핸들
new Handle:playerelectriccooltimehandle[MAX_PLAYERS_SETTING + 1];//어드벤스드마라우더의 전기 공격의 쿨타임 해제 타이머 핸들
new Handle:playerbarbcooltimehandle[MAX_PLAYERS_SETTING + 1];//어드벤스드드라군의 가시발사 공격의 쿨타임
new Handle:playertramplecooltimehandle[MAX_PLAYERS_SETTING + 1];//타이란트의 돌진 공격의 쿨타임 해제 타이머 핸들

//건설 관련 변수
new playerisconstructing[MAX_PLAYERS_SETTING + 1];//플레이어가 건설중임을 나타낸다.
new bool:constructconfirm[MAX_PLAYERS_SETTING + 1];//플레이어가 마지막으로 건설을 확정한 시간을 나타낸다.
new bool:constructcancel[MAX_PLAYERS_SETTING + 1];//플레이어가 마지막으로 건설을 취소한 시간을 나타낸다.

new Float:structurelastworktime[2048];//건물이 마지막으로 작동된 때를 나타내는 시간, 간헐적으로 쓰이므로 구지 완벽할 필요가 없다
new Float:structurelasthealtime[2048];//건물이 마지막으로 수리된 때를 나타낸다. 인간의 건물에만 쓰인다

//인덱스캐시데이터, 배열에 건물정보를 저장해 둔다. 단 건설 확정 이후의 건물만
new structurecacheinfo[2][INDEXCACHESIZE];

//건물 데이터파일 로드 상태를 나타내는 변수
new structureloadstatus:loadstatus;

new bool:thereisbot;

//이펙트프리캐시변수
new beamsprite;
new halosprite;
new reactorbeamsprite;
new crystalbeamsprite;

//오프셋 관련 변수
new weaponoffset;


//플러그인 시작시에 플러그인 초기화
public OnPluginStart(){

	HookEvent("player_death", eventdeath, EventHookMode_Pre);
	HookEvent("player_hurt", eventhurt, EventHookMode_Pre);
	HookEvent("player_shoot", eventshoot);
	HookEvent("player_spawn", eventspawn);
	HookEvent("break_prop", eventbreak);
	
	//세이훅
	RegConsoleCmd("say", sayhook);
	
	//명령어 등록
	RegConsoleCmd("sm_건설", command_construction, "건설을 시작하기 위한 명령어");
	RegConsoleCmd("sm_건설취소", command_calcelconstruction, "건설을 취소하기 위한 명령어");
	RegConsoleCmd("sm_건설확정", command_confirmconstruction, "건설을 확정하기 위한 명령어");
	RegConsoleCmd("sm_메드킷", command_usemedkit, "메드킷을 사용하기 위한 명령어");
	RegConsoleCmd("sm_진화", command_useevolution , "진화하기 위해 쓰는 명령어");
	
	RegAdminCmd("sm_초기건물저장", command_savestructure, ADMFLAG_GENERIC, "트레뮬로우스의 맵 초기 건물 설정을 저장한다");
	RegAdminCmd("sm_크레디트설정", command_setcredit, ADMFLAG_GENERIC, "특정 사용자의 크레디트를 원하는 값으로 설정한다");
	RegAdminCmd("sm_테크레벨설정", command_settechlevel, ADMFLAG_GENERIC, "[디버그용]테크레벨을 원하는 값으로 설정한다");
	
	
	//게임의 종류를 지정해주는 것
	decl String:gamefolder[64];
	GetGameFolderName(gamefolder, sizeof(gamefolder));
	
	if(StrEqual(gamefolder, "hl2mp", false)){
		
		servergametype = GAMETYPE_HL2MP;
		
		//오프셋 처리
		weaponoffset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 게임의 종류는 [HL2MP] 로 인식되었습니다");
		
	}else if(StrEqual(gamefolder, "cstrike", false)){
		
		servergametype = GAMETYPE_CSS;
		
		//오프셋 처리
		weaponoffset = FindSendPropOffs("CCSPlayer", "m_hMyWeapons");
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 게임의 종류는 [CSS] 로 인식되었습니다");
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : [CSS] 를 위한 추가적인 이벤트 훅을 시도합니다");
		
		if(HookEvent("round_start", eventroundstart)){
			
			PrintToServer("[SM] 트레뮬로우스 플러그인 : [CSS] 를 위한 <round_start> 이벤트 훅 성공");
			
		}else{
			
			SetFailState("[SM] 트레뮬로우스 플러그인 : 오류 정보, [CSS] 를 위한 <round_start> 이벤트 훅 실패");
			
		}
		
		if(HookEvent("round_freeze_end", eventroundfreezeend)){
			
			PrintToServer("[SM] 트레뮬로우스 플러그인 : [CSS] 를 위한 <round_freeze_end> 이벤트 훅 성공");
			
		}else{
			
			SetFailState("[SM] 트레뮬로우스 플러그인 : 오류 정보, [CSS] 를 위한 <round_freeze_end> 이벤트 훅 실패");
			
		}
		
	}else{
		
		servergametype = GAMETYPE_UNSUPPORT;
		
		SetFailState("[SM] 트레뮬로우스 플러그인 : 오류 정보, 게임의 종류는 [%s] 지원하지 않는 종류 입니다", gamefolder);
		
	}
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : 로딩 완료");
	
	CreateConVar("tremulous_version", "1.0.0.1", "tremulous_version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}

//맵 시작때마다 실행되는 값
public OnMapStart(){
	
	for(new client = 1; client <= MaxClients; client++){
		
		playervariablesetter(client, true);
		playertimerhandlesetter(client);
		haskilledbysystemevent[client] = false;
		
	}
	
	for(new i = 0; i < 2048; i++){
		
		ownerofprojectile[i] = 0;	
		
	}
	
	beamsprite = PrecacheModel("materials/sprites/laser.vmt");
	halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	reactorbeamsprite = PrecacheModel("materials/sprites/bluelight1.vmt");
	crystalbeamsprite = PrecacheModel("sprites/crystal_beam1.vmt");
	
	//건물 모델 프리캐싱
	for(new i = 0; i <= 18; i++){
		
		PrecacheModel(entitymodel[i], true);
		
	}
	
	new Float:time = GetGameTime();
		
	//시간을 나타내는 변수 몇개를 초기화시켜주어야 한다
	for(new i = 0; i < MaxClients; i++){
		
		playerlasthealtime[i] = time;
		playerlasthurttime[i] = time;
		
	}
	
	for(new i = 0; i < 2048; i++){
		
		structurelastworktime[i] = time;
		structurelasthealtime[i] = time;
		
	}
	
	techlevel = 1;
	stagekills = 0;
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 로딩 이후 초기화 완료");
	
	resetcache();
	
	//아직 로딩되지 않은 것으로 간주한다
	loadstatus = NOTLOADED;
	
	//건물 로딩 시작
	if(servergametype == GAMETYPE_HL2MP){
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물을 로드합니다");
		PrintToChatAll("\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물을 로드합니다");
		CreateTimer(0.1, loadstructure, TIMER_FLAG_NO_MAPCHANGE);
		
	}else if(servergametype == GAMETYPE_CSS){
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 게임의 종류가 [CSS]이므로 맵 초기 구조물의 로딩은 <round_freeze_end>이벤트가 발생할 때까지 지연됩니다");
		
	}
	
	thereisbot = false;
	
}

public OnMapEnd(){
	
	resetcache();
	
}

//이벤트처리함수들

//데스이벤트 처리, 플레이어가 죽을 때 모든 상태저장 변수와 타이머가 초기화된다.
public Action:eventdeath(Handle:Event, const String:Name[], bool:Broadcast){
	
	decl client, attacker;

	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	
	if(haskilledbysystemevent[client] == true){
		
		haskilledbysystemevent[client] = false;
		return Plugin_Handled;
		
	}
	
	if(client != 0){
		
		if(GetClientTeam(client) == 2){
			
			//플레이어가 죽을 때 그것이 게임이 진행중일 때의 일인 경우 패배조건에 부합되는지 확인한다
			if(loadstatus == LOADED){
				
				playerlasthurttime[client] = GetGameTime();
				
				//팀이 살아있는가
				new bool:teamisalive = false;
				
				for(new i = 1; i <= MaxClients; i++){
			
					if(isplayerconnectedingamealive(i)){
			
						if(!IsFakeClient(i)){
							
							if(GetClientTeam(i) == 2){
								
								teamisalive = true;
								
							}
							
						}
						
					}
					
				}
			
				//다른 팀원이 살아있지 않을 경우 에그가 남아있는지 확인한다
				if(!teamisalive){
					
					//작동 가능한 에그가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
					if(!getworkablestructure(EGG)){
						
						for(new i = 1; i <= MaxClients; i++){
					
							if(isplayerconnectedingamealive(i)){
					
								if(GetClientTeam(i) == 2){
									
									ForcePlayerSuicide(i);
									
								}
								
							}
							
						}
						
						loadstatus = NOTLOADED;
						
					}
					
				}
				
			}
			
			if(attacker != 0){
			
				if(GetClientTeam(attacker) == 3){
					
					playercredit[attacker] = playercredit[attacker] + 100;
					stagekills++;
					
				}
				
			}
			
		}else if(GetClientTeam(client) == 3){
			
			//플레이어가 죽을 때 그것이 게임이 진행중일 때의 일인 경우 패배조건에 부합되는지 확인한다
			if(loadstatus == LOADED){
				
				playerlasthurttime[client] = GetGameTime();
				
				//팀이 살아있는가
				new bool:teamisalive = false;
				
				for(new i = 1; i <= MaxClients; i++){
			
					if(isplayerconnectedingamealive(i)){
			
						if(!IsFakeClient(i)){
							
							if(GetClientTeam(i) == 3){
								
								teamisalive = true;
								
							}
							
						}
						
					}
					
				}
			
				//다른 팀원이 살아있지 않을 경우 에그가 남아있는지 확인한다
				if(!teamisalive){
					
					//작동 가능한 텔레노드가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
					if(!getworkablestructure(TELENODE)){
						
						for(new i = 1; i <= MaxClients; i++){
					
							if(isplayerconnectedingamealive(i)){
					
								if(GetClientTeam(i) == 3){
									
									ForcePlayerSuicide(i);
									
								}
								
							}
							
						}
						
						loadstatus = NOTLOADED;
						
					}
					
				}
				
			}
			
			if(attacker != 0){
			
				if(GetClientTeam(attacker) == 2){
					
					playercredit[attacker] = playercredit[attacker] + 100;
					stagekills++;
					
				}
				
			}
			
		}
		
	}
	
	if(stagekills >= 20 && techlevel == 1){
			
		techlevel = 2;
		PrintToChatAll("\x042단계가 시작되었습니다");
		
	}
	if(stagekills >= 60 && techlevel == 2){
		
		techlevel = 3;
		PrintToChatAll("\x043단계가 시작되었습니다");
		
	}
	
	playervariablesetter(client, false);
	
	playertimerhandlesetter(client);

	return Plugin_Continue;

}

public Action:eventhurt(Handle:Event, const String:Name[], bool:Broadcast){

	decl client, attacker;

	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if(haskilledbysystemevent[client] == true){
		
		return Plugin_Handled;
		
	}
	
	playerlasthurttime[client] = GetGameTime();
	
	if(GetEventInt(Event, "attacker") != 0){
		
		attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
		
	}else{
		
		return Plugin_Handled;
		
	}
		
	//에일리언이 공격당했을 때
	if(GetClientTeam(client) == 2){
			
		if(GetClientTeam(attacker) == 3){
				
			playercredit[attacker] = playercredit[attacker] + 5;
				
		}
			
	}else if(GetClientTeam(client) == 3){
		
		if(GetClientTeam(attacker) == 2){
			
			playercredit[attacker] = playercredit[attacker] + 15;
			
			if(playerhaspoisonability[attacker] == true){
				
				playergetpoisonattack[client] = attacker;
					
			}
				
		}
			
	}
	
	return Plugin_Continue;

}

public Action:eventspawn(Handle:Event, const String:Name[], bool:Broadcast){

	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));
	
	if(servergametype == GAMETYPE_HL2MP && loadstatus == NOTLOADED){
		
		if(GetClientTeam(client) == 3 || GetClientTeam(client) == 2){
			
			//SetEntPropFloat(client, Prop_Data, "m_fNextSuicideTime", GetGameTime() - 10.0);
			
			haskilledbysystemevent[client] = true;
			
			ForcePlayerSuicide(client);
			
			PrintToChat(client, "\x04맵 초기 구조물이 로드되지 않았으므로 스폰할 수 없습니다");
			PrintToChat(client, "\x04맵 초기 구조물이 로드된 후 E키를 눌러주세요");
			
		}
		
	}
	
	if(GetClientTeam(client) == 2){
		
		CreateTimer(0.1, csshuddisplay, client);
		CreateTimer(0.1, removeweapon, client);
		
	}
	if(GetClientTeam(client) == 3){
		
		CreateTimer(0.1, csshuddisplay, client);
		CreateTimer(0.1, removeweapon, client);
		CreateTimer(0.1, playerstatuscheck, client);
				
	}
	
	prethinkbuffer[client] = false;
	
	return Plugin_Handled;

}

public Action:eventshoot(Handle:Event, const String:Name[], bool:Broadcast){

	return Plugin_Handled;

}

public Action:eventbreak(Handle:Event, const String:Name[], bool:Broadcast){

	return Plugin_Handled;

}

public Action:eventroundstart(Handle:Event, const String:Name[], bool:Broadcast){
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : <round_start> 이벤트 이후 초기화를 시작합니다");
	
	techlevel = 1;
	stagekills = 0;
	
	for(new client = 1; client <= MaxClients; client++){
		
		playervariablesetter(client, true);
		playertimerhandlesetter(client);
		haskilledbysystemevent[client] = false;
		
	}
	
	resetcache();
	
	//아직 로딩되지 않은 것으로 간주한다
	loadstatus = NOTLOADED;
	
	for(new client = 1; client <= MaxClients; client++){
			
		if(isplayerconnectedingamealive(client)){
			
			if(!IsFakeClient(client)){
				
				//무기 떨구지 말란 말이다
				for(new i = 0; i < 48; i++){
		
					new weapon = GetEntDataEnt2(client, weaponoffset + i);
				
					if(weapon > 0){
						
						RemovePlayerItem(client, weapon);
						RemoveEdict(weapon);
										
					}
									
				}
				
				ForcePlayerSuicide(client);
			
				PrintToChat(client, "\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물이 로드되지 않았으므로 스폰할 수 없습니다");
				PrintToChat(client, "\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물이 로드된 후 E키를 눌러주세요");
					
			}
				
		}
			
	}
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : <round_start> 이벤트 이후 초기화를 완료했습니다");
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : 잠시 뒤 게임이 시작됩니다");
	PrintToChatAll("\x04[SM] 트레뮬로우스 플러그인 : 잠시 뒤 게임이 시작됩니다");
	
	if(thereisbot == false){
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 게임의 종류가 [CSS]이므로 라운드 종료 방지용 봇을 생성합니다");
		
		new ctbot = CreateFakeClient("인간팀 ㅇㅅㅇ");
		
		if(ctbot != 0){
				
			PrintToServer("[SM] 트레뮬로우스 플러그인 : [CSS] 를 위한 라운드 종료 방지용 CT팀 봇 생성 성공");
			ChangeClientTeam(ctbot, 3);
			CS_RespawnPlayer(ctbot);
			SetEntProp(ctbot, Prop_Data, "m_takedamage", 0);
				
		}else{
				
			SetFailState("[SM] 트레뮬로우스 플러그인 : 오류 정보, [CSS] 를 위한 라운드 종료 방지용 CT팀 봇 생성 실패");
				
		}
			
		new tbot = CreateFakeClient("에일리언팀 ㅇㅅㅇ");
			
		if(tbot != 0){
				
			PrintToServer("[SM] 트레뮬로우스 플러그인 : [CSS] 를 위한 라운드 종료 방지용 T팀 봇 생성 성공");
			ChangeClientTeam(tbot, 2);
			CS_RespawnPlayer(tbot);
			SetEntProp(tbot, Prop_Data, "m_takedamage", 0);
			
		}else{
			
			SetFailState("[SM] 트레뮬로우스 플러그인 : 오류 정보, [CSS] 를 위한 라운드 종료 방지용 T팀 봇 생성 실패");
				
		}
		
		if(ctbot != 0 && tbot != 0){
		
			thereisbot = true;
		
		}
	
	}else{
		
		//봇이 있을 경우엔 데미지를 입지 않도록 설정한다
		for(new client = 1; client <= MaxClients; client++){
			
			if(isplayerconnectedingamealive(client)){
			
				if(IsFakeClient(client)){
					
					SetEntProp(client, Prop_Data, "m_takedamage", 0);
					
				}
				
			}
			
		}
		
	}
	
	return Plugin_Handled;

}

public Action:eventroundfreezeend(Handle:Event, const String:Name[], bool:Broadcast){
	
	PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물을 로드합니다");
	PrintToChatAll("\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물을 로드합니다");
	CreateTimer(0.1, loadstructure, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;

}

//클라이언트가 접속할 때
public OnClientConnected(client){
	
	playervariablesetter(client, true);
	
	playertimerhandlesetter(client);
	
	haskilledbysystemevent[client] = false;

}

//완전히 접속했을때
public OnClientPutInServer(client){
	
	if(!IsFakeClient(client)){
	
		//무기 바꿔지는것 방지
		SDKHook(client, SDKHook_WeaponSwitch, onweaponswitch);
		
		//몇몇 에일리언의 특수기술과 땅에 짓는 건물을 구현하기 위한 것
		//아직 함수를 시험했을 뿐이다
		//SDKHook(client, SDKHook_StartTouch, onstarttouch);
		
		//SDKHook(client, SDKHook_EndTouch, onendtouch);
		
	}
	
}

//클라이언트가 연결을 끊을 때
public OnClientDisconnect(client){

	playervariablesetter(client, true);
	
	playertimerhandlesetter(client);
	
	haskilledbysystemevent[client] = false;

}

//온게임프레임
public OnGameFrame(){
	
	for(new client = 1; client <= MaxClients; client++){
		
		//플레이어가 접속해 있을 경우
		if(isplayerconnectedingame(client)){
			
			if(!IsFakeClient(client)){
				
				//클래스를 고르지 않은 사람은 절대로 무기도 허용 할수 없고 살아있는것도 용납 못한다
				if(playerclass[client] == NONECLASS){
					
					for(new i = 0; i < 48; i++){
		
						new weapon = GetEntDataEnt2(client, weaponoffset + i);
				
						if(weapon > 0){
						
							RemovePlayerItem(client, weapon);
							RemoveEdict(weapon);
										
						}
									
					}
					
					if(loadstatus != NODATA){
					
						ForcePlayerSuicide(client);
						
					}
					
				}
				
				//팀 관련 정보
				new playerteam = GetClientTeam(client);
				
				if(GetClientButtons(client) & IN_ATTACK == IN_ATTACK){//1차공격(기본적으로 마우스 왼쪽)
					
					if(servergametype == GAMETYPE_CSS){
				
						if(!prethinkbuffer[client]){
									
							prethinkbuffer[client] = true;
									
						}
					
					}
						
				}else if(GetClientButtons(client) & IN_USE == IN_USE){//사용(기본적으로 E키)
					
					if(!prethinkbuffer[client]){
						
						constructcancel[client] = true;
						
						if(playerteam == 2 && IsPlayerAlive(client)){
							
							alienskill(client);
							
						}
						
						//플레이어가 인간팀이고, 살아있으며, e키를 누를 때 시선에 아머리가 있을 경우
						if(playerteam == 3 && IsPlayerAlive(client)){
							
							//함수 호출로 해야지. 온게임프레임이 길어지는건 못본다
							usearmoury(client);
							
						}
						
						
						if((playerteam == 2 || playerteam == 3) && !IsPlayerAlive(client)){
							
							if(loadstatus == LOADED){
								
								spawnmenu(client);
								
							}else if(loadstatus == NODATA){
								
								CS_RespawnPlayer(client);
								
							}
								
						}
						
						prethinkbuffer[client] = true;
						
					}
						
				}else if(GetClientButtons(client) & IN_RELOAD == IN_RELOAD){//재장전(기본적으로 R키)
					
					if(!prethinkbuffer[client]){
						
						if(playerteam == 2 && IsPlayerAlive(client)){
							
							alienability(client);
							
						}
						
						prethinkbuffer[client] = true;
						
					}
					
				}else if(GetClientButtons(client) & IN_SPEED == IN_SPEED){//스피드 버튼, 데메에선 스플린트, 카솟에선 천천히 걷기(기본적으로 시프트키)
					
					if(!prethinkbuffer[client]){
						
						constructconfirm[client] = true;
						
						prethinkbuffer[client] = true;
						
					}
					
				}else{
					
					prethinkbuffer[client] = false;
					
				}
				
				if(playerteam == 2){
				
					new Float:gametime = GetGameTime();
					
					//체력 자동 회복을 위한 처리
					if(gametime >= playerlasthurttime[client] + TIMETOSTARTHEAL && gametime >= playerlasthealtime[client] + HEALDELAY){
						
						alienautoheal(client);
						playerlasthealtime[client] = gametime;
						
					}
				
				}
				
			}
				
		}
		
	}
	
}

public Action:onweaponswitch(client, weapon){
	
	if(isplayerconnectedingame(client)){
			
		if(!IsFakeClient(client)){
			
			//논클래스는 어떤 무기도 들수없다
			if(playerclass[client] == NONECLASS){
					
				return Plugin_Handled;
					
			}else{
			
				new playerteam = GetClientTeam(client);
				
				//에일리언은 칼 이외엔 어떤 무기도 들 수 없다
				if(playerteam == 2){
					
					decl String:weaponname[64];
				
					GetEdictClassname(weapon, weaponname, 64);
					
					if(!(StrEqual("weapon_knife", weaponname, false) || StrEqual("weapon_stunstick", weaponname, false) ||
						StrEqual("weapon_crowbar", weaponname, false))){
							
						return Plugin_Handled;
										
					}
					
				}else if(playerteam == 3){
					
					if(playerclass[client] == HUMANBUILDER){
						
						decl String:weaponname[64];
				
						GetEdictClassname(weapon, weaponname, 64);
						
						if(!(StrEqual("weapon_knife", weaponname, false) || StrEqual("weapon_stunstick", weaponname, false) ||
							StrEqual("weapon_crowbar", weaponname, false) || StrEqual("weapon_pistol", weaponname, false) ||
							StrEqual("weapon_usp", weaponname, false) || StrEqual("weapon_glock", weaponname, false) ||
							StrEqual("weapon_deagle", weaponname, false) || StrEqual("weapon_p228", weaponname, false) ||
							StrEqual("weapon_elite", weaponname, false) || StrEqual("weapon_fiveseven", weaponname, false) ||
							StrEqual("weapon_smokegrenade", weaponname, false) || StrEqual("weapon_hegrenade", weaponname, false) ||
							StrEqual("weapon_flashbang", weaponname, false) || StrEqual("weapon_frag", weaponname, false) ||
							StrEqual("weapon_slam", weaponname, false))){
							
							return Plugin_Handled;
							
						}
						
					}
					
				}
			
			}
			
		}
		
	}
	
	return Plugin_Continue;
	
}

public Action:onstarttouch(entity, target){
	
	PrintToChatAll("%d 닿고있는 엔티티 : %d", entity, target);
	
	return Plugin_Handled;
	
}

public Action:onendtouch(entity, target){
	
	PrintToChatAll("%d 떨어지고있는 엔티티 : %d", entity, target);
	
	return Plugin_Handled;
	
}

public Action:sayhook(client, Args){
	
	new String:msg[255], String:cmdbuffer[255];
	GetCmdArgString(msg, sizeof(msg));
	
	strcopy(cmdbuffer, 255, msg);
	
	msg[strlen(msg)-1] = '\0';
	
	StripQuotes(cmdbuffer);
	TrimString(cmdbuffer);
	
	/*
	if(StrContains(cmdbuffer, "!건설확정", false) == 0){
		
		constructconfirm[client] = true;
		
	}else if(StrContains(cmdbuffer, "!건설취소", false) == 0){
		
		constructcancel[client] = true;
		
	}
	*/
	
	return Plugin_Continue;
			
}

//인간에게만 쓰이는 플레이어 상태 확인 및 조절 타이머
public Action:playerstatuscheck(Handle:Timer, any:client){
	
	if(isplayerconnectedingamealive(client) && GetClientTeam(client) == 3){
		
		decl Float:clientposition[3];
		
		GetClientAbsOrigin(client, clientposition);
		
		if(playergetadhesiveattack[client] == true){
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			
		}
		//클라이언트에게 그랩공격을 한 사람이 더이상 클라이언트를 그랩의 목표로 하지 않는 경우
		if(playergetgrabattack[client] != 0 && playerisgrabing[playergetgrabattack[client]] != client){
			
			playergetgrabattack[client] = 0;
			
		}
		//클라이언트가 이동 불가 상태에서 풀려날 수 있는 경우
		if(playergetadhesiveattack[client] == false && playergetgrabattack[client] == 0 && GetEntityMoveType(client) != MOVETYPE_NOCLIP){
			
			SetEntityMoveType(client, MOVETYPE_WALK);
			
		}
		if(playerusedmedkit[client] == true){
			
			humanautoheal(client, 4);
			
		}
		if(playergetgasattack[client] != 0){
			
			makedamage(playergetgasattack[client], client, 4, "gas", clientposition);
		
		}
		
		if(playergetpoisonattack[client] != 0){
		
			makedamage(playergetpoisonattack[client], client, 4, "poison", clientposition);
			
		}
		
		//크레이트 타이머의 절묘한 위치
		CreateTimer(1.0, playerstatuscheck, client);
			
	}
	
	return Plugin_Handled;
			
}

//에일리언특수기술의 사용, E 키로으로 발동시키는 것들은 alienskill 함수로, e버튼으로 발동시키는 것들은 alienbility 함수로 처리한다.
/*플레이어클래스 :
1은 그렌져(건설벌레), 2는 드레치(기본공격유닛), 3은 어드벤스드그렌져(건설벌레, 공던지기), 4는 바실리스크(잡기)
5는 어드벤스드바실리스크(잡기,가스공격), 6은 마라우더(점프), 7은 어드벤스드 마라우더(점프, 전기공격)
8은 드라군(파운스), 9는 어드벤스드 드라군(파운스, 공던지기), 10은 타이란트(돌진, 주위에 있는 아군 체력 회복속도 2배)*/
//마우스 오른쪽 단추로 발동시키는 기술들, 일반 유닛과 어드벤스드 유닛의 공통기술이 여기에 포함된다.
public alienskill(client){
	
	//바실리스크와 어드벤스드 바실리스크의 잡기 공격
	if(playerclass[client] == BASILISK || playerclass[client] == ADVANCEDBASILISK){
	
		activegrabskill(client);
		
	}
	
	//마라우더와 어드벤스드 마라우더의 점프
	if(playerclass[client] == MARAUDER || playerclass[client] == ADVANCEDMARAUDER){
	
		activejumpskill(client);
		
	}
	
	//드라군과 어드벤스드 드라군의 파운스
	if(playerclass[client] == DRAGOON || playerclass[client] == ADVANCEDDRAGOON){
	
		activepounceskill(client);
		
	}
	
	//타이란트의 돌진
	if(playerclass[client] == TYRANT){
	
		activetrampleskill(client);
		
	}
	
}


//키보드의 R키로 발동시키는 기술들, 어드벤스드 라는 이름으로 시작하는 유닛들만의 특수기술
public alienability(client){
	
	//어드벤스드그렌져의 공던지기 기술
	if(playerclass[client] == ADVANCEDGRANGER){
	
		activeprojectileability(client);
		
	}
	
	//어드벤스드바실리스크의 가스 공격
	if(playerclass[client] == ADVANCEDBASILISK){
	
		activegasability(client);
		
	}
	
	//어드벤스드마라우더의 전기공격
	if(playerclass[client] == ADVANCEDMARAUDER){
	
		activeelectricability(client);
		
	}
	
	//어드벤스드드라군의 공던지기 공격
	if(playerclass[client] == ADVANCEDDRAGOON){
	
		activebarbability(client);
		
	}
	
}

//초기화 관련 함수들

//핸들 초기화 함수, 핸들만 처리한다.
public playertimerhandlesetter(client){
	
	//핸들 초기화
	if(playerusedmedkithandle[client] != INVALID_HANDLE){
		
		KillTimer(playerusedmedkithandle[client]);
		playerusedmedkithandle[client] = INVALID_HANDLE;
		
	}
	if(playergetadhesivehandle[client] != INVALID_HANDLE){
		
		KillTimer(playergetadhesivehandle[client]);
		playergetadhesivehandle[client] = INVALID_HANDLE;
		
	}
	if(playergetgashandle[client] != INVALID_HANDLE){
		
		KillTimer(playergetgashandle[client]);
		playergetgashandle[client] = INVALID_HANDLE;
		
	}
	if(playerhaspoisonhandle[client] != INVALID_HANDLE){
		
		KillTimer(playerhaspoisonhandle[client]);
		playerhaspoisonhandle[client] = INVALID_HANDLE;
		
	}
	if(playerprojectilecooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playerprojectilecooltimehandle[client]);
		playerprojectilecooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playergascooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playergascooltimehandle[client]);
		playergascooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playerjumpcooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playerjumpcooltimehandle[client]);
		playerjumpcooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playerelectriccooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playerelectriccooltimehandle[client]);
		playerelectriccooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playerbarbcooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playerbarbcooltimehandle[client]);
		playerbarbcooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playerpouncecooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playertramplecooltimehandle[client]);
		playerpouncecooltimehandle[client] = INVALID_HANDLE;
		
	}
	if(playertramplecooltimehandle[client] != INVALID_HANDLE){
		
		KillTimer(playertramplecooltimehandle[client]);
		playertramplecooltimehandle[client] = INVALID_HANDLE;
		
	}
		
}

//플레이어상태변수 초기화 함수
public playervariablesetter(client, bool:resetall){
	
	if(resetall == true){
		
		playercredit[client] = 0;
		
	}
	
	playerclass[client] = NONECLASS;
	playergetadhesiveattack[client] = false;
	playergetgasattack[client] = 0;
	playergetgrabattack[client] = 0;
	playerisgrabing[client] = 0;
	playergetpoisonattack[client] = 0;
	playerhasmedkit[client] = true;
	playerusedmedkit[client] = false;
	playertrampleskillcooltime[client] = false;
	playerhaspoisonability[client] = false;
	playerprojectileabilitycooltime[client] = false;
	playergasabilitycooltime[client] = false;
	playerelectricabilitycooltime[client] = false;
	playerjumpskillcooltime[client] = false;
	playerbarbabilitycooltime[client] = false;
	
	playergetdoubleheal[client] = false;
	
	
}

//플레이어상태해제 관련 타이머
//메드킷 효과 제한시간 타이머
public Action:playerusedmedkitdisable(Handle:Timer, any:client){
	
	playerusedmedkit[client] = false;
	playerusedmedkithandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//트래퍼의 공격에서 자동으로 풀려나는 타이머
public Action:playergetadhesiveattackdisable(Handle:Timer, any:client){
	
	playergetadhesiveattack[client] = false;
	playergetadhesivehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//가스공격에서 풀려나는 타이머
public Action:playergetgasattackdisable(Handle:Timer, any:client){
	
	playergetgasattack[client] = 0;
	playergetgashandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//플레이어의 독공격 능력의 시간제한 타이머
public Action:playerhaspoisondisable(Handle:Timer, any:client){
	
	playerhaspoisonability[client] = false;
	playerhaspoisonhandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}

//플레이어 쿨타임 관련 타이머

//드라군의 파운스 공격의 쿨타임 해제 타이머
public Action:playerpouncecooltimer(Handle:Timer, any:client){
	
	playerpounceskillcooltime[client] = false;
	playerpouncecooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}

//타이란트의 트램플공격의 쿨타임 해제 타이머
public Action:playertramplecooltimer(Handle:Timer, any:client){
	
	playertrampleskillcooltime[client] = false;
	playertramplecooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//어드벤스드그렌저의 포물체 공격 쿨타임 해제 타이머
public Action:playerprojectilecooltimer(Handle:Timer, any:client){
	
	playerprojectileabilitycooltime[client] = false;
	playerprojectilecooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//어드벤스드바실리스트크의 가스공격의 쿨타임 해제 타이머
public Action:playergascooltimer(Handle:Timer, any:client){
	
	playergasabilitycooltime[client] = false;
	playergascooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//어드벤스드마라우더의 방전공격의 쿨타임 해제 타이머
public Action:playerelectriccooltimer(Handle:Timer, any:client){
	
	playerelectricabilitycooltime[client] = false;
	playerelectriccooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//어드벤스드마라우더의 점프의 쿨타임 해제 타이머
public Action:playerjumpcooltimer(Handle:Timer, any:client){
	
	playerjumpskillcooltime[client] = false;
	playerjumpcooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}
//어드벤스드드라군의 가시공 던지기 공격의 쿨타임 해제 타이머
public Action:playerbarbattackcooltimer(Handle:Timer, any:client){
	
	playerbarbabilitycooltime[client] = false;
	playerbarbcooltimehandle[client] = INVALID_HANDLE;
	
	return Plugin_Handled;
	
}


//에일리언 특수 기술 사용


//마우스 오른쪽 버튼으로 발동하는 기술들

//바실리스크의 잡기 공격
public activegrabskill(client){
		
	decl Float:clienteyeposition[3], Float:targeteyeposition[3], Float:clienteyeangle[3], target;
	GetClientEyePosition(client, clienteyeposition);
	GetClientEyeAngles(client, clienteyeangle);
		
	//몸의 중간부분을 구한다
	clienteyeposition[2] = clienteyeposition[2] - 20.0;
		
	decl Handle:traceresulthandle;
		
	traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienteyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
		
	if(TR_DidHit(traceresulthandle) == true){
			
		target = TR_GetEntityIndex(traceresulthandle);
			
		if(target >= 1 && target <= MaxClients){
				
			if(isplayerconnectedingamealive(target)){
				
				if(GetClientTeam(target) == 3){
				
					GetClientEyePosition(target, targeteyeposition);
					targeteyeposition[2] = targeteyeposition[2] - 20.0;
						
					if(100 >= GetVectorDistance(clienteyeposition, targeteyeposition)){
					
						playerisgrabing[client] = target;
						playergetgrabattack[target] = client;
						SetEntityMoveType(playerisgrabing[client], MOVETYPE_NONE);
						CreateTimer(0.1, playergrabcheck, client);
							
					}
					
				}
					
			}
					
		}
			
	}
	
	if(traceresulthandle != INVALID_HANDLE){
									
		CloseHandle(traceresulthandle);
									
	}
		
}


//마라우더의 점프 능력
public activejumpskill(client){
	
	if(playerjumpskillcooltime[client] == false){
		
		playerjumpskillcooltime[client] = true;
	
		if(GetEntityFlags(client) & FL_ONGROUND){
		
			decl Float:clienteyeangle[3], Float:speedvector[3];
			GetClientEyeAngles(client, clienteyeangle);
			GetAngleVectors(clienteyeangle, speedvector, NULL_VECTOR, NULL_VECTOR); 
			NormalizeVector(speedvector, speedvector);
			ScaleVector(speedvector, 800.0);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speedvector);
	
		}
		
		playerjumpcooltimehandle[client] = CreateTimer(JUMPCOOLTIME, playerjumpcooltimer, client);
		
	}
	
}
//드라군과 어드벤스드 드라군의 파운스능력
public activepounceskill(client){
	
	if(playerpounceskillcooltime[client] == false){
		
		if(GetEntityFlags(client) & FL_ONGROUND){
		
			playerpounceskillcooltime[client] = true;
			decl Float:clienteyeangle[3], Float:speedvector[3];
			GetClientEyeAngles(client, clienteyeangle);
			GetAngleVectors(clienteyeangle, speedvector, NULL_VECTOR, NULL_VECTOR); 
			NormalizeVector(speedvector, speedvector);
			ScaleVector(speedvector, 1000.0);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speedvector);
			CreateTimer(0.1, playerpouncecheck, client);
			playerpouncecooltimehandle[client] = CreateTimer(POUNCECOOLTIME, playerpouncecooltimer, client);
		
		}
		
	}
	
}

//타이란트의 돌진 공격
public activetrampleskill(client){
	
	if(playertrampleskillcooltime[client] == false){
		
		playertrampleskillcooltime[client] = true;
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, client);
		WritePackCell(datapack, 60);
		CreateTimer(0.1, playertramplecheck, datapack);
		playertramplecooltimehandle[client] = CreateTimer(TRAMPLECOOLTIME, playertramplecooltimer, client);
		
	}
	
}

//키보드의 E키로 발동하는 기술들
//어드벤스드 그렌져의 공던지기 기술
public activeprojectileability(client){
	
	if(playerprojectileabilitycooltime[client] == false){
		
		playerprojectileabilitycooltime[client] = true;
		
		//클라이언트의 각도를 구해서 물체를 소환할 곳을 구한다.
		//물체는 클라이언트의 전방 약 30떨어진 곳에 소환되야한다.
		//물체가 소환될 위치는 클라이언트의 눈 위치에서 클라이언트의 시야각 방향으로 50 만큼떨어진다. resultposition 에 저장한다.
		//물체가 던져질 각도또한 클라이언트의 시야각을 쓴다
		decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
		GetClientEyeAngles(client, clienteyeangle);
		GetClientEyePosition(client, clienteyeposition);
		GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(anglevector, anglevector);
		ScaleVector(anglevector, 30.0);
		AddVectors(clienteyeposition, anglevector, resultposition);
		//anglevector변수를 속도벡터로 재활용하자. 다시 노말라이즈해서 크기를 도로 1로 만들어야한다.
		//스케일벡터 함수는 벡터를 지정한 크기로 만들어주는게 아니라 그저 크기를 키워줄 뿐이라는 걸 테스트로 알아냈다.
		NormalizeVector(anglevector, anglevector);
		//그냥 적당하게 포물선을 그리는 수준으로 한다.
		ScaleVector(anglevector, 800.0);
		
		clienteyeangle[1] = 0.0;
		
		//만든다
		entity = CreateEntityByName("prop_physics");
		//수박은 정말로 싫었다
		//SetEntityModel(entity, "models/props_junk/watermelon01.mdl");이 방식을 쓰면 맵에 안쓰인 모델은 프리캐싱을 해줘도 문제가 생긴다
		DispatchKeyValue(entity, "model", "models/props_junk/watermelon01.mdl");//이 방식을 써야 문제가 생기지 않는다
		//새카맣게 칠하면 그래도 아무도 모를꺼야.....
		SetEntityRenderMode(entity, RENDER_GLOW);
		SetEntityRenderColor(entity, 0, 0, 0, 255);
		//엔티티의 식별을 위한 고유번호를 만드는 과정
		decl String:id[128];
		createentityidentification(client, PROJECTILE, STATUS_NOTSTRUCTURE, id, 128);
		DispatchKeyValue(entity, "targetname", id);
		DispatchKeyValueFloat(entity, "physdamagescale", 0.1);
		//자 가라 우주로!!!
		DispatchSpawn(entity);
		
		TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
		
		ownerofprojectile[entity] = client;
		
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, entity);
		WritePackCell(datapack, PROJECTILELIFE);
		WritePackString(datapack, id);
		
		CreateTimer(0.1, projectilebarbdamegecheck, datapack);
		
		playerprojectilecooltimehandle[client] = CreateTimer(PROJECTILECOOLTIME, playerprojectilecooltimer, client);
		
	}
	
}

//어드벤스드 바실리스크의 가스 공격
public activegasability(client){
	
	if(playergasabilitycooltime[client] == false){
		
		playergasabilitycooltime[client] = true;
		
		decl Float:clienteyeposition[3], Float:clienteyeangle[3], Float:clientanglevector[3], Float:targeteyeposition[3], Float:clienttotargetvector[3], Float:clienttotargetangle[3];
		new Handle:traceresulthandle = INVALID_HANDLE;
		
		GetClientEyePosition(client, clienteyeposition);
		GetClientEyeAngles(client, clienteyeangle);
		
		createbasiliskgas(clienteyeposition, clienteyeangle);
		
		for(new target = 1; target <= MaxClients; target++){
		
			if(isplayerconnectedingamealive(target) == true){

				GetClientEyePosition(target, targeteyeposition);
				targeteyeposition[2] = targeteyeposition[2] - 20.0;
			
				if(client == target){
							
					continue;
							
				}

				if(400 <= GetVectorDistance(clienteyeposition, targeteyeposition)){

					continue;

				}

				if(GetClientTeam(target) == 3){

					GetAngleVectors(clienteyeangle, clientanglevector, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(clientanglevector, clientanglevector);
					MakeVectorFromPoints(clienteyeposition, targeteyeposition, clienttotargetvector);
					NormalizeVector(clienttotargetvector, clienttotargetvector);
					GetVectorAngles(clienttotargetvector, clienttotargetangle);
					
					if(30 >= RadToDeg(ArcCosine(GetVectorDotProduct(clientanglevector, clienttotargetvector)))){
							
						traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienttotargetangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					
						if(TR_DidHit(traceresulthandle) == true){
						
							if(TR_GetEntityIndex(traceresulthandle) == target){
								
								playercredit[client] = playercredit[client] + 10;
								playergetgasattack[target] = client;
								
								if(playergetgashandle[target] != INVALID_HANDLE){
									
									KillTimer(playergetgashandle[target]);
									
								}
								playergetgashandle[target] = CreateTimer(GASEFFECTTIME, playergetgasattackdisable, target);
								
							}
						
						}
						
						if(traceresulthandle != INVALID_HANDLE){
		
							CloseHandle(traceresulthandle);
		
						}
					
					}
				
				}
			
			}
				
		}
	
		playergascooltimehandle[client] = CreateTimer(GASCOOLTIME, playergascooltimer, client);
		
	}
	
}

//어드벤스드마라우더의 전기 공격
public activeelectricability(client){
	
	if(playerelectricabilitycooltime[client] == false){
		
		//이 값을 일단 참으로 해 줌으로 해서, 이 함수를 연달아 호출하더라도 다른 함수가 작업을 끝낼 때까지 중복 작동을 하지 않는다
		playerelectricabilitycooltime[client] = true;
		
		//전기 공격의 첫번째 목표로 삼을 클라이언트를 구한다.
		//이 클라이언트와의 거리, 트레이스의 결과를 기준으로 전기공격이 지속될 것인가 지속되지 않을 것인가를 결정한다
		decl Float:clienteyeposition[3], Float:clienteyeangle[3], Float:targeteyeposition[3], target;
		new Handle:traceresulthandle = INVALID_HANDLE;
		
		GetClientEyePosition(client, clienteyeposition);
		GetClientEyeAngles(client, clienteyeangle);
		
		clienteyeposition[2] = clienteyeposition[2] - 20.0;
		
		traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienteyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					
		if(TR_DidHit(traceresulthandle) == true){
			
			target = TR_GetEntityIndex(traceresulthandle);
			
			if(target >= 1 && target <= MaxClients){
				
				if(isplayerconnectedingamealive(target)){
				
					if(GetClientTeam(target) == 3){
						
						GetClientEyePosition(target, targeteyeposition);
						
						targeteyeposition[2] = targeteyeposition[2] - 20.0;
						
						if(400 >= GetVectorDistance(clienteyeposition, targeteyeposition)){
						
							//핸들의 첫번째 값은 기술을 사용하는 클라이언트, 두번째 값은 당하는 사람, 마지막 값은 전기공격의 남은 지속시간
							new Handle:datapack = CreateDataPack();
							WritePackCell(datapack, client);
							WritePackCell(datapack, target);
							WritePackCell(datapack, ELECTRICCHARGEMAXTIME);
					
							CreateTimer(0.1, electricchargedamagecheck, datapack);
					
							playerelectriccooltimehandle[client] = CreateTimer(ELECTRICCHARGECOOLTIME, playerelectriccooltimer, client);
						
						}else{
						
							//목표로 잡아낸 사람이 너무 멀 경우
							playerelectricabilitycooltime[client] = false;
						
						}
						
					}else{
						
						//목표로 잡아낸 사람의 팀이 인간이 아닐 경우
						playerelectricabilitycooltime[client] = false;
						
					}
				
				}else{
					
					//목표로 잡아낸 사람이 살아있지 않을 경우
					playerelectricabilitycooltime[client] = false;
						
				}
								
			}else{
				
				//클라이언트를 목표로 잡지 않은 경우	
				playerelectricabilitycooltime[client] = false;
						
			}
						
		}else{
			
			//트레이스의 결과가 올바르지 않을 경우
			playerelectricabilitycooltime[client] = false;
						
		}
						
		if(traceresulthandle != INVALID_HANDLE){
		
			CloseHandle(traceresulthandle);
		
		}
					
	}
	
}

//어드벤스드드라군의 공던지기 공격
public activebarbability(client){
	
	if(playerbarbabilitycooltime[client] == false){
		
		playerbarbabilitycooltime[client] = true;
		
		//클라이언트의 각도를 구해서 물체를 소환할 곳을 구한다.
		//물체는 클라이언트의 전방 약 30떨어진 곳에 소환되야한다.
		//물체가 소환될 위치는 클라이언트의 눈 위치에서 클라이언트의 시야각 방향으로 50 만큼떨어진다. resultposition 에 저장한다.
		//물체가 던져질 각도또한 클라이언트의 시야각을 쓴다
		decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
		GetClientEyeAngles(client, clienteyeangle);
		GetClientEyePosition(client, clienteyeposition);
		GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(anglevector, anglevector);
		ScaleVector(anglevector, 30.0);
		AddVectors(clienteyeposition, anglevector, resultposition);
		//anglevector변수를 속도벡터로 재활용하자. 다시 노말라이즈해서 크기를 도로 1로 만들어야한다.
		//스케일벡터 함수는 벡터를 지정한 크기로 만들어주는게 아니라 그저 크기를 키워줄 뿐이라는 걸 테스트로 알아냈다.
		NormalizeVector(anglevector, anglevector);
		//그냥 적당하게 포물선을 그리는 수준으로 한다.
		ScaleVector(anglevector, 1600.0);
		
		clienteyeangle[1] = 0.0;
		
		//만든다
		entity = CreateEntityByName("prop_physics");
		//수박은 정말로 싫었다
		//SetEntityModel(entity, "models/props_junk/watermelon01.mdl");이 방식을 쓰면 맵에 안쓰인 모델은 프리캐싱을 해줘도 문제가 생긴다
		DispatchKeyValue(entity, "model", "models/props_junk/watermelon01.mdl");//이 방식을 써야 문제가 생기지 않는다
		//새카맣게 칠하면 그래도 아무도 모를꺼야.....
		SetEntityRenderMode(entity, RENDER_GLOW);
		SetEntityRenderColor(entity, 0, 0, 0, 255);
		//엔티티의 식별을 위한 고유번호를 만드는 과정
		decl String:id[128];
		createentityidentification(client, PROJECTILE, STATUS_NOTSTRUCTURE, id, 128);
		DispatchKeyValue(entity, "targetname", id);
		DispatchKeyValueFloat(entity, "physdamagescale", 0.01);
		//자 가라 우주로!!!
		DispatchSpawn(entity);
		//물체의 각도를 트레이스레이에서 쓴다
		TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
		
		ownerofprojectile[entity] = client;
		
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, entity);
		WritePackCell(datapack, PROJECTILELIFE);
		WritePackString(datapack, id);
		
		CreateTimer(0.1, projectilebarbdamegecheck, datapack);
		
		playerbarbcooltimehandle[client] = CreateTimer(BARBCOOLTIME, playerbarbattackcooltimer, client);
		
	}
	
}

//특수기술 구현을 위해 부가적으로 필요한 함수

//그랩체크, 현재 잡고있는 사람과 관련된 처리만 한다. 잡은 뒤에 풀린 사람은 playerstatuscheck에서 처리한다.
public Action:playergrabcheck(Handle:Timer, any:client){
	
	//플레이어가 누군가를 잡고있는 상태로 알려진경우
	if(playerisgrabing[client] != 0){
		
		//플레이어가 살아있는 경우
		if(isplayerconnectedingamealive(client)){
			
			//목표가 살아있는 경우
			if(isplayerconnectedingamealive(playerisgrabing[client])){
				
				decl Float:clienteyeposition[3], Float:targeteyeposition[3], Float:anglevector[3], Float:angle[3];
				GetClientEyePosition(client, clienteyeposition);
				GetClientEyePosition(playerisgrabing[client], targeteyeposition);
				
				//몸의 중간부분을 구한다
				clienteyeposition[2] = clienteyeposition[2] - 20.0;
				targeteyeposition[2] = targeteyeposition[2] - 20.0;
				
				MakeVectorFromPoints(clienteyeposition, targeteyeposition, anglevector);
				NormalizeVector(anglevector, anglevector);
				GetVectorAngles(anglevector, angle);
				
				if(100 >= GetVectorDistance(clienteyeposition, targeteyeposition)){
					
					new Handle:traceresulthandle = INVALID_HANDLE;
					
					traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, angle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					
					if(TR_DidHit(traceresulthandle) == true){
						
						if(TR_GetEntityIndex(traceresulthandle) == playerisgrabing[client]){
							
							//올바른 목표인경우
							SetEntityMoveType(playerisgrabing[client], MOVETYPE_NONE);
							playergetgrabattack[playerisgrabing[client]] = client;
							CreateTimer(0.1, playergrabcheck, client);
							
						}else{
					
							//트레이스레이의 결과가 목표가 아닌 경우
							SetEntityMoveType(playerisgrabing[client], MOVETYPE_WALK);
							playergetgrabattack[playerisgrabing[client]] = 0;
							playerisgrabing[client] = 0;
					
						}
						
					}else{
					
						//트레이스레이의 결과가 부적절한 경우
						SetEntityMoveType(playerisgrabing[client], MOVETYPE_WALK);
						playergetgrabattack[playerisgrabing[client]] = 0;
						playerisgrabing[client] = 0;
					
					}
					
					if(traceresulthandle != INVALID_HANDLE){
		
						CloseHandle(traceresulthandle);
		
					}
	
				}else{
					
					//그랩을 유지할 수 있는거리보다 멀리 있는 경우
					SetEntityMoveType(playerisgrabing[client], MOVETYPE_WALK);
					playergetgrabattack[playerisgrabing[client]] = 0;
					playerisgrabing[client] = 0;
					
				}
				
			}else{
					
				//그랩공격의 목표가 죽어잇을 경우
				SetEntityMoveType(playerisgrabing[client], MOVETYPE_WALK);
				playergetgrabattack[playerisgrabing[client]] = 0;
				playerisgrabing[client] = 0;
					
			}
			
		}else{
					
			//그랩공격을 하던 클라이언트가 죽은 경우
			SetEntityMoveType(playerisgrabing[client], MOVETYPE_WALK);
			playergetgrabattack[playerisgrabing[client]] = 0;
			playerisgrabing[client] = 0;
					
		}
		
	}
	
}

//파운스체크
public Action:playerpouncecheck(Handle:Timer, any:client){
	
	if(isplayerconnectedingamealive(client) == true){
				
		if(!(GetEntityFlags(client) & FL_ONGROUND)){

			pouncedamagecheck(client);
					
			CreateTimer(0.1, playerpouncecheck, client);
			
		}
		
	}
	
}

/*
*타이란트의 돌진공격을 위한 부가함수
*데이터의 첫번째 값은 반드시 클라이언트를 나타내는 정수여야 하고,
*두번째 값은 타이머 내부적으로 처리되는 반복을 위한 값
*/
public Action:playertramplecheck(Handle:Timer, Handle:data){
	
	new client, time;
	ResetPack(data);
	client = ReadPackCell(data);
	time = ReadPackCell(data);
	CloseHandle(data);

	if(isplayerconnectedingamealive(client) == true){
		
		if(time <= 60 && time > 30){
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + 0.1);
			
			pouncedamagecheck(client);
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, client);
			WritePackCell(datapack, time - 1);
			
			CreateTimer(0.1, playertramplecheck, datapack);
			
		}else if(time <= 30 && time > 0){
			
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") - 0.1);
			
			pouncedamagecheck(client);
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, client);
			WritePackCell(datapack, time - 1);
			
			CreateTimer(0.1, playertramplecheck, datapack);
			
		}
		
	}
	
}


//드라군의 파운스 공격과 타이란트의 돌진 공격에 쓰이는 부가 함수
public pouncedamagecheck(client){
	
	decl Float:clienteyeposition[3], Float:clienteyeangle[3], Float:clientanglevector[3], Float:targeteyeposition[3], Float:clienttotargetvector[3];
	new Handle:traceresulthandle = INVALID_HANDLE;
	
	if(isplayerconnectedingamealive(client) == true){
	
		GetClientEyePosition(client, clienteyeposition);
	
		for(new target = 1; target <= MaxClients; target++){
		
			if(isplayerconnectedingamealive(target) == true){

				GetClientEyePosition(target, targeteyeposition);
			
				if(client == target){
							
					continue;
							
				}

				if(100 <= GetVectorDistance(clienteyeposition, targeteyeposition)){

					continue;

				}

				if(GetClientTeam(target) == 3){

					GetClientEyeAngles(client, clienteyeangle);
					GetAngleVectors(clienteyeangle, clientanglevector, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(clientanglevector, clientanglevector);
					MakeVectorFromPoints(clienteyeposition, targeteyeposition, clienttotargetvector);
					NormalizeVector(clienttotargetvector, clienttotargetvector);
					
					if(90 >= RadToDeg(ArcCosine(GetVectorDotProduct(clientanglevector, clienttotargetvector)))){
						
						traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienteyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					
						if(TR_DidHit(traceresulthandle) == true){
						
							if(TR_GetEntityIndex(traceresulthandle) == target){
								
								new damageresulttype:result;
								
								if(playerclass[client] == ADVANCEDDRAGOON){
									
									result = makedamage(client, target, 100, "pounce", clienteyeposition);
								
								}
								if(playerclass[client] == TYRANT){
									
									result = makedamage(client, target, 150, "trample", clienteyeposition);
								
								}
								
								if(result == RESULT_ALIVE){
									
									playercredit[client] = playercredit[client] + 10;
								
								}
								
							}
						
						}
						
						if(traceresulthandle != INVALID_HANDLE){
		
							CloseHandle(traceresulthandle);
		
						}
					
					}
				
				}
			
			}
				
		}
				
	}
	
}

//어드벤스드그렌져와 어드벤스드드라군의 가시공던지기기술에 쓰이는 부가 함수
public Action:projectilebarbdamegecheck(Handle:Timer, Handle:data){
	
	decl entity, life, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	life = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//시스템에 의해 가시공으로 정해진 엔티티인 경우
	if(ownerofprojectile[entity] != 0){
		
		//엔티티가 존재하는 경우
		if(IsValidEntity(entity) == true){
			
			decl String:tempentityname[128];
			GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
			//엔티티의 정보를 받아온다
			new userid, type, status;
			getentityidentificationdata(entity, userid, type, status);
			
			//올바른 식별번호를 가진 경우(플레이어가 만든 수박엔티티가 맞는 경우)
			if(StrEqual(tempentityname, id, false)){
				
				//엔티티의 주인으로 정해진 클라이언트가 접속해있을 경우
				if(isplayerconnectedingame(ownerofprojectile[entity]) == true){
					
					//접속한 클라이언트가 수박을 만든 클라이언트인 경우
					if(GetClientUserId(ownerofprojectile[entity]) == userid){
						
						if(life >= 1){
						
							//접속한 클라이언트의 팀이 에일리언인 경우
							if(GetClientTeam(ownerofprojectile[entity]) == 2){
					
								decl Float:m_vecorigin[3], Float:temptargetposition[3], bool:istarget[MaxClients + 1], Float:tempdistance;
								new bool:foundtarget = false;
								GetEntPropVector(entity, Prop_Send, "m_vecOrigin", m_vecorigin);
					
								if(type == PROJECTILE){
						
									tempdistance = 60.0;
									
								}else if(type == BARB){
									
									tempdistance = 120.0;
									
								}
					
								for(new i = 1; i <= MaxClients; i++){
						
									if(isplayerconnectedingamealive(i) == true){
							
										if(GetClientTeam(i) == 3){
								
											GetClientEyePosition(i, temptargetposition);
											temptargetposition[2] = temptargetposition[2] - 20;
											
											new Float:distance = GetVectorDistance(m_vecorigin, temptargetposition);
								
											if(distance <= tempdistance){
											
												decl Float:resultvector[3], Float:resultangle[3];
												
												MakeVectorFromPoints(m_vecorigin, temptargetposition, resultvector);
												GetVectorAngles(resultvector, resultangle);
											
												new Handle:traceresulthandle = INVALID_HANDLE;
												traceresulthandle = TR_TraceRayFilterEx(m_vecorigin, resultangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
											
												if(TR_DidHit(traceresulthandle) == true){
							
													if(TR_GetEntityIndex(traceresulthandle) == i){
													
														istarget[i] = true;
														foundtarget = true;
													
													}else{
													
														istarget[i] = false;
													
													}
							
												}else{
												
													istarget[i] = false;
												
												}
												
												if(traceresulthandle != INVALID_HANDLE){
			
													CloseHandle(traceresulthandle);
			
												}
										
											}else{
									
												istarget[i] = false;
									
											}
							
										}
							
									}
						
								}
					
								//목표가 있는 경우
								if(foundtarget == true){
						
									createprojectilebarbgas(m_vecorigin, type);
						
									for(new i = 1; i <= MaxClients; i++){
						
										if(isplayerconnectedingamealive(i) == true){
							
											if(GetClientTeam(i) == 3){
								
												if(istarget[i] == true){
												
													new damageresulttype:result;
												
													if(type == PROJECTILE){
													
														result = makedamage(ownerofprojectile[entity], i, 20, "projectile", m_vecorigin);
													
													}else if(type == BARB){
													
														result = makedamage(ownerofprojectile[entity], i, 40, "barb", m_vecorigin);
													
													}
												
													if(result == RESULT_ALIVE){
											
														playercredit[ownerofprojectile[entity]] = playercredit[ownerofprojectile[entity]] + 10;
											
													}
											
												}
											
											}
							
										}
								
									}
							
									ownerofprojectile[entity] = 0;
									AcceptEntityInput(entity, "Break");
									AcceptEntityInput(entity, "Kill");
						
								}else{
						
									//목표가 없는 경우
									new Handle:datapack = CreateDataPack();
									WritePackCell(datapack, entity);
									WritePackCell(datapack, life - 1);
									WritePackString(datapack, id);
									
									CreateTimer(0.1, projectilebarbdamegecheck, datapack);
						
								}
								
							}else{
								
								//존재 가능한 시간을 넘긴 경우
								ownerofprojectile[entity] = 0;
								AcceptEntityInput(entity, "Break");
								AcceptEntityInput(entity, "Kill");
								
							}
						
						}else{
							
							//수박을 만든 클라이언트가 팀을 바꾼 경우
							ownerofprojectile[entity] = 0;
							AcceptEntityInput(entity, "Break");
							AcceptEntityInput(entity, "Kill");
							
						}
					
					}else{
						
						//엔티티는 있으나 그 엔티티를 만든 클라이언트가 아닌 다른 클라이언트가 접속해있을 경우
						ownerofprojectile[entity] = 0;
						AcceptEntityInput(entity, "Break");
						AcceptEntityInput(entity, "Kill");
						
					}
					
				}else{
					
					//엔티티는 있으나 그 엔티티를 만든 클라이언트가 접속해있지 않을 경우
					ownerofprojectile[entity] = 0;
					AcceptEntityInput(entity, "Break");
					AcceptEntityInput(entity, "Kill");
					
				}
				
			}else{
				
				//엔티티는 있으나 식별번호가 올바르지 않은 경우(수박이 부서진 뒤 같은 엔티티번호를 가진 엔티티가 생긴 경우)
				ownerofprojectile[entity] = 0;
				
			}
			
		}else{
			
			//엔티티가 없는 경우(수박이 부서진 경우)
			ownerofprojectile[entity] = 0;
			
		}
		
	}
	
	return Plugin_Handled;
	
}

//어드벤스드마라우더의 방전 공격을 위한 보조함수
//이 함수에서 핸들 관리를 더 제대로 해야겠다
//조만간 손봐놔야한다
public Action:electricchargedamagecheck(Handle:Timer, Handle:data){
	
	new client, firsttarget, time;
	ResetPack(data);
	client = ReadPackCell(data);
	firsttarget = ReadPackCell(data);
	time = ReadPackCell(data);
	CloseHandle(data);
	
	if(isplayerconnectedingamealive(client) && isplayerconnectedingamealive(firsttarget)){
		
		if(time <= 60 && time > 0){
			
			if(GetClientTeam(client) == 2 && GetClientTeam(firsttarget) == 3){
			
				new targetlist[4];
				decl Float:clientposition[3], Float:firsttargetposition[3], Float:nexttargetposition[3], Float:tempdistance;
				decl Float:clienttotargetvector[3], Float:clienttotargetangle[3];
				new Handle:traceresulthandle = INVALID_HANDLE;
				targetlist[0] = firsttarget;
				
				//400.0으로 설정
				tempdistance = 400.0;
			
				GetClientEyePosition(client, clientposition);
				GetClientEyePosition(firsttarget, firsttargetposition);
				firsttargetposition[2] = firsttargetposition[2] - 30;
			
				//첫번째 목표가 사정거리에 있는지 확인
				if(GetVectorDistance(clientposition, firsttargetposition) <= 400){
				
					MakeVectorFromPoints(clientposition, firsttargetposition, clienttotargetvector);
					NormalizeVector(clienttotargetvector, clienttotargetvector);
					GetVectorAngles(clienttotargetvector, clienttotargetangle);
					
					traceresulthandle = TR_TraceRayFilterEx(clientposition, clienttotargetangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					
					if(TR_DidHit(traceresulthandle) == true){
						
						if(TR_GetEntityIndex(traceresulthandle) == firsttarget){
							
							if(traceresulthandle != INVALID_HANDLE){
		
								CloseHandle(traceresulthandle);
								traceresulthandle = INVALID_HANDLE;
	
							}
						
							//최대 3명의 추가 목표를 구한다
							for(new i = 1; i <= 3; i++){
								
								decl Float:distancetoplayer[MaxClients + 1];
								decl bool:isreachable[MaxClients + 1];
																
								//전체 플레이어 중에서 인간팀이고, 클라이언트가 아니고, 시작 목표가 아닌 사람만 골라낸다
								//이 포문이 실행되고나면 마지막으로 선택된 목표의 위치에서 접근 가능한 목표들이 골라진다
								for(new player = 1; player <= MaxClients; player++){
								
									new bool:isfiltered = false;
									
									if(player != client && player != firsttarget){
										
										if(isplayerconnectedingamealive(player) == false){
												
											isfiltered = true;
												
										}else{
										
											if(GetClientTeam(player) == 3){
										
												//현재 선택한 목표가 이미 골라져있는 목표인지 본다
												for(new filter = 0; filter <= 3; filter++){
												
													if(targetlist[filter] == player){
													
														isfiltered = true;
													
													}
												
												}
										
											}else{
												
												isfiltered = true;
												
											}
										
										}
									
									}else{
										
										isfiltered = true;
										
									}
								
									//여기까지 걸러지지 않았다면 일단 위치를 비교해서 새 목표로서 추가 될 수 있는지 본다
									if(isfiltered == false){
								
										GetClientEyePosition(player, nexttargetposition);
										nexttargetposition[2] = nexttargetposition[2] - 30;
									
										MakeVectorFromPoints(firsttargetposition, nexttargetposition, clienttotargetvector);
										NormalizeVector(clienttotargetvector, clienttotargetvector);
										GetVectorAngles(clienttotargetvector, clienttotargetangle);
								
										traceresulthandle = TR_TraceRayFilterEx(firsttargetposition, clienttotargetangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, targetlist[i - 1]);
										
										if(TR_DidHit(traceresulthandle) == true){
									
											if(TR_GetEntityIndex(traceresulthandle) == player){
												
												distancetoplayer[player] = GetVectorDistance(firsttargetposition, nexttargetposition);
												isreachable[player] = true;
											
											}else{
											
												distancetoplayer[player] = -1.0;
												isreachable[player] = false;
											
											}
										
										}else{
										
											distancetoplayer[player] = -1.0;
											isreachable[player] = false;
									
										}
										
										if(traceresulthandle != INVALID_HANDLE){
		
											CloseHandle(traceresulthandle);
											traceresulthandle = INVALID_HANDLE;
	
										}
									
									}else{
										
										distancetoplayer[player] = -1.0;
										isreachable[player] = false;
								
									}
					
								}
								
								for(new list = 1; list <= MaxClients; list++){
								
									//다음 목표로 정해지는 것이 가능한 가장 가까운 사람을 구해 목표로 추가한다
									if(isreachable[list] == true){
							
										if(distancetoplayer[list] <= 200 && distancetoplayer[list] <= tempdistance){
											
											tempdistance = distancetoplayer[list];
											targetlist[i] = list;
											
										}
								
									}
					
								}
									
								//목표가 골라졌을 경우 그 목표의 위치를 기록해둔다
								if(targetlist[i] != 0){
									
									GetClientEyePosition(targetlist[i], firsttargetposition);
									firsttargetposition[2] = firsttargetposition[2] - 30;
									
								}else{
									
									break;
									
								}
								
							}
							
							//목표 목록에 담긴 클라이언트들에게 데미지를 주는 부분
							for(new i = 0; i <= 3; i++){
							
								if(targetlist[i] != 0){
									
									new damageresulttype:result;
													
									result = makedamage(client, targetlist[i], 5, "electriccharge", clientposition);
											
									if(result == RESULT_ALIVE){
										
										playercredit[client] = playercredit[client] + 1;
										
									}
								
									//첫 목표인 경우를 위한 전기이펙트 생성
									if(i == 0){
										
										new color[4] = {20, 60, 200, 200};
											
										GetClientEyePosition(client, firsttargetposition);
										firsttargetposition[2] = firsttargetposition[2] - 20.0;
										GetClientEyePosition(targetlist[i], nexttargetposition);
										nexttargetposition[2] = nexttargetposition[2] - 20.0;
										TE_SetupBeamPoints(firsttargetposition, nexttargetposition, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, color, 0);
										TE_SendToAll();
										
									}else{
										
										new color[4] = {20, 60, 200, 200};
										
										//다음 목표와의 사이를 잇는 전기이펙트 생성
										GetClientEyePosition(targetlist[i - 1], firsttargetposition);
										firsttargetposition[2] = firsttargetposition[2] - 20.0;
										GetClientEyePosition(targetlist[i], nexttargetposition);
										nexttargetposition[2] = nexttargetposition[2] - 20.0;
										TE_SetupBeamPoints(firsttargetposition, nexttargetposition, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, color, 0);
										TE_SendToAll();
										
									}
								
								}else{
									
									break;
									
								}
							
							}
						
							new Handle:datapack = CreateDataPack();
							WritePackCell(datapack, client);
							WritePackCell(datapack, firsttarget);
							WritePackCell(datapack, time - 1);
		
							CreateTimer(0.1, electricchargedamagecheck, datapack);
						
						}
						
					}
					
					if(traceresulthandle != INVALID_HANDLE){
		
						CloseHandle(traceresulthandle);
						traceresulthandle = INVALID_HANDLE;
		
					}
					
				}
					
			}
			
		}
			
	}
		
}

//오버마인드에서 쓸 수 있는 가스 이펙트
public createovermindgas(Float:position[3], Float:angle[3]){
	
	new String:positionstring[128], String:anglestring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	Format(anglestring, 128, "%f %f %f", angle[0], angle[1], angle[2]);
	
	new gascloud = CreateEntityByName("env_steam");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"angles", anglestring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "100");
	DispatchKeyValue(gascloud,"Speed", "640");
	DispatchKeyValue(gascloud,"StartSize", "20");
	DispatchKeyValue(gascloud,"EndSize", "640");
	DispatchKeyValue(gascloud,"Rate", "120");
	DispatchKeyValue(gascloud,"JetLength", "100");
	DispatchKeyValue(gascloud,"rollspeed", "30");
	DispatchKeyValue(gascloud,"RenderColor", "0 255 0");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"type", "0");
	DispatchSpawn(gascloud);
	TeleportEntity(gascloud, NULL_VECTOR, angle, NULL_VECTOR);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//하이브에서 쓸 수 있는 가스 이펙트
public createhivegas(Float:position[3], Float:angle[3]){
	
	new String:positionstring[128], String:anglestring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	Format(anglestring, 128, "%f %f %f", angle[0], angle[1], angle[2]);
	
	new gascloud = CreateEntityByName("env_steam");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"angles", anglestring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "100");
	DispatchKeyValue(gascloud,"Speed", "2560");
	DispatchKeyValue(gascloud,"StartSize", "20");
	DispatchKeyValue(gascloud,"EndSize", "640");
	DispatchKeyValue(gascloud,"Rate", "120");
	DispatchKeyValue(gascloud,"JetLength", "600");
	DispatchKeyValue(gascloud,"rollspeed", "30");
	DispatchKeyValue(gascloud,"RenderColor", "0 255 0");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"type", "0");
	DispatchSpawn(gascloud);
	TeleportEntity(gascloud, NULL_VECTOR, angle, NULL_VECTOR);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//에시드튜브에서 쓸 수 있는 가스 이펙트
public createacidtubegas(Float:position[3]){
	
	new String:positionstring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "10");
	DispatchKeyValue(gascloud,"Speed", "160");
	DispatchKeyValue(gascloud,"BaseSpread", "120");
	DispatchKeyValue(gascloud,"EndSize", "240");
	DispatchKeyValue(gascloud,"Rate", "60");
	DispatchKeyValue(gascloud,"JetLength", "100");
	DispatchKeyValue(gascloud,"Twist", "30");
	DispatchKeyValue(gascloud,"RenderColor", "200 95 0");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//바실리스크의 가스공격 이펙트를 위한 가스생성함수
public createbasiliskgas(Float:position[3], Float:angle[3]){
	
	new String:positionstring[128], String:anglestring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	Format(anglestring, 128, "%f %f %f", angle[0], angle[1], angle[2]);
	
	new gascloud = CreateEntityByName("env_steam");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"angles", anglestring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "300");
	DispatchKeyValue(gascloud,"Speed", "640");
	DispatchKeyValue(gascloud,"StartSize", "20");
	DispatchKeyValue(gascloud,"EndSize", "640");
	DispatchKeyValue(gascloud,"Rate", "120");
	DispatchKeyValue(gascloud,"JetLength", "420");
	DispatchKeyValue(gascloud,"rollspeed", "30");
	DispatchKeyValue(gascloud,"RenderColor", "0 255 0");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"type", "0");
	DispatchSpawn(gascloud);
	TeleportEntity(gascloud, NULL_VECTOR, angle, NULL_VECTOR);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//어드벤스드그렌져와 어드벤스드드라군의 가시공을 위한 가스생성함수
public createprojectilebarbgas(Float:position[3], type){
	
	new String:positionstring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "10");
	DispatchKeyValue(gascloud,"Speed", "160");
	DispatchKeyValue(gascloud,"StartSize", "20");
	if(type == PROJECTILE){
		
		DispatchKeyValue(gascloud,"BaseSpread", "30");
		DispatchKeyValue(gascloud,"EndSize", "60");
		
	}
	if(type == BARB){
		
		DispatchKeyValue(gascloud,"BaseSpread", "60");
		DispatchKeyValue(gascloud,"EndSize", "120");
		
	}
	DispatchKeyValue(gascloud,"Rate", "60");
	DispatchKeyValue(gascloud,"JetLength", "100");
	DispatchKeyValue(gascloud,"Twist", "30");
	DispatchKeyValue(gascloud,"RenderColor", "100 179 109");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//가스 효과 제거 함수 : 이 함수는 가스 생성함수에 의해 자동으로 호출된다.
public Action:disablegas(Handle:Timer, any:entity){
	
	AcceptEntityInput(entity, "TurnOff");
	//가스가 자연스럽게 사라지는 충분한 시간을 줘야한다
	CreateTimer(10.0, deletegas, entity);
	return Plugin_Handled;
	
}

//가스 엔티티 제거 함수 : 이 함수는 가스 제거 함수에 의해 자동으로 호출된다.
public Action:deletegas(Handle:Timer, any:entity){
	
	AcceptEntityInput(entity, "Kill");
	
	return Plugin_Handled;
	
}


//에일리언의 자동 체력 회복을 위한 함수
public alienautoheal(client){
	
	if(isplayerconnectedingamealive(client)){
		
		new temphealth = GetEntProp(client, Prop_Data, "m_iHealth");
		
		if(playergetdoubleheal[client] == true){
		
			playergetdoubleheal[client] = false;
			
			if(temphealth < alienmaxhealth[playerclass[client]]){
				
				if(temphealth + alienhealpersec[playerclass[client]] * 2 <= alienmaxhealth[playerclass[client]]){
					
					SetEntProp(client, Prop_Data, "m_iHealth", temphealth + alienhealpersec[playerclass[client]] * 2);
					
				}else{
					
					SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
					
				}
					
			}
		
		}else{
			
			if(temphealth < alienmaxhealth[playerclass[client]]){
				
				if(temphealth + alienhealpersec[playerclass[client]] <= alienmaxhealth[playerclass[client]]){
					
					SetEntProp(client, Prop_Data, "m_iHealth", temphealth + alienhealpersec[playerclass[client]]);
					
				}else{
					
					SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
					
				}
					
			}
			
		}
		
	}
	
}

//인간의 자동 체력 회복을 위한 함수
public humanautoheal(client, amount){
	
	if(isplayerconnectedingamealive(client)){
		
		new temphealth = GetEntProp(client, Prop_Data, "m_iHealth");
		
		if(temphealth < GetEntProp(client, Prop_Data, "m_iMaxHealth")){
			
			if(temphealth + amount <= GetEntProp(client, Prop_Data, "m_iMaxHealth")){
				
				SetEntProp(client, Prop_Data, "m_iHealth", temphealth + amount);
				
			}else{
				
				SetEntProp(client, Prop_Data, "m_iHealth", 100);
				
			}
				
		}
		
	}
	
}

public alienstructureautoheal(entity){
	
	//엔티티가 존재하는 경우
	if(IsValidEntity(entity) == true){
		
		//엔티티의 정보를 받아온다
		new userid, type, status;
		
		if(getentityidentificationdata(entity, userid, type, status)){
			
			new temphealth = GetEntProp(entity, Prop_Data, "m_iHealth");
			
			//에일리언의 건물은 1초마다 체력을 5씩 회복한다
			
			new Float:temptime = GetGameTime();
			
			if(structurelasthealtime[entity] + 1.0 <= temptime){
				
				structurelasthealtime[entity] = temptime;
				
				if(temphealth < structuremaxhealth[type]){
					
					if(temphealth + 5 <= structuremaxhealth[type]){
						
						SetEntProp(entity, Prop_Data, "m_iHealth", temphealth + 2);
						
					}else{
						
						SetEntProp(entity, Prop_Data, "m_iHealth", structuremaxhealth[type]);
						
					}
					
				}
			
			}
			
		}
		
	}
	
}

//에일리언의 무기 뺏기를 위한 함수
public Action:removeweapon(Handle:Timer, any:client){
	
	if(isplayerconnectedingamealive(client)){
		
		if(GetClientTeam(client) == 2){
	
			for(new i = 0; i < 48; i++){
		
				new weapon = GetEntDataEnt2(client, weaponoffset + i);
		
				if(weapon > 0){
				
					decl String:tempweaponname[64];
					GetEdictClassname(weapon, tempweaponname, 64);
					
					//데메와 카솟 구별없는 무기 뺏기
					if(!(StrEqual("weapon_knife", tempweaponname, false) || StrEqual("weapon_stunstick", tempweaponname, false) || StrEqual("weapon_crowbar", tempweaponname, false))){
						
						RemovePlayerItem(client, weapon);
						RemoveEdict(weapon);
									
					}
								
				}
							
			}
			
		}else if(GetClientTeam(client) == 3){
			
			//건설자 클래스일 경우 근접무기와 건총 이외의 무기는 들 수 없다
			if(playerclass[client] == HUMANBUILDER){
				
				for(new i = 0; i < 48; i++){
		
					new weapon = GetEntDataEnt2(client, weaponoffset + i);
		
					if(weapon > 0){
						
						decl String:tempweaponname[64];
						GetEdictClassname(weapon, tempweaponname, 64);
						
						//데메와 카솟 구별없는 무기 뺏기
						if(!(StrEqual("weapon_knife", tempweaponname, false) || StrEqual("weapon_stunstick", tempweaponname, false) ||
							StrEqual("weapon_crowbar", tempweaponname, false) || StrEqual("weapon_pistol", tempweaponname, false) ||
							StrEqual("weapon_usp", tempweaponname, false) || StrEqual("weapon_glock", tempweaponname, false) ||
							StrEqual("weapon_deagle", tempweaponname, false) || StrEqual("weapon_p228", tempweaponname, false) ||
							StrEqual("weapon_elite", tempweaponname, false) || StrEqual("weapon_fiveseven", tempweaponname, false) ||
							StrEqual("weapon_smokegrenade", tempweaponname, false) || StrEqual("weapon_hegrenade", tempweaponname, false) ||
							StrEqual("weapon_flashbang", tempweaponname, false) || StrEqual("weapon_frag", tempweaponname, false) ||
							StrEqual("weapon_slam", tempweaponname, false))){
							
							RemovePlayerItem(client, weapon);
							RemoveEdict(weapon);
										
						}
							
					}
					
				}
				
			}
			
		}
		
		CreateTimer(1.0, removeweapon, client);
		
	}
	
	return Plugin_Handled;
	
}

//건설과 건물을 위한 함수

//이 함수는 클라이언트가 건설 메뉴에서 건물을 골랐을 때 호출된다.
//건설 가능한 상태일 경우 건물 엔티티를 만들어내고, 만들어낸 엔티티의
//위치를 조절해 주고 건물의 상태(건설 확정, 취소, 실패)를 조절해주는 타이머를 호출한다
public startconstruction(client, type){
	
	if(isplayerconnectedingamealive(client)){
		
		if(playerisconstructing[client] == 0){
		
			if(type != NOTTREMULOUSENTITY){
				
				new buildchecktype:check = canstartconstruct(type);
				
				if(check == RESULT_OK){
				
					new entity = CreateEntityByName("prop_physics");
					//모델파일을 설정해준다
					DispatchKeyValue(entity, "model", entitymodel[type]);
					//플레이어와 충돌하지 않게 하기위한 설정
					//SetEntProp(entity, Prop_Data, "m_fFlags", GetEntityFlags(entity) | FL_UNBLOCKABLE_BY_PLAYER);
					SetEntProp(entity, Prop_Data, "m_CollisionGroup", 1);
					SetEntProp(entity, Prop_Data, "m_iEFlags", GetEntProp(entity, Prop_Data, "m_iEFlags") | EFL_NO_PHYSCANNON_INTERACTION);
					//충돌에 의해 데미지를 입지 않게 하려는 시도
					SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") | SF_BREAK_DONT_TAKE_PHYSICS_DAMAGE);
					//SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") & ~SF_BREAK_PHYSICS_BREAK_IMMEDIATELY);
					SetEntProp(entity, Prop_Data, "m_takedamage", 2);
					
					//위치 설정 중인 건물은 초록색의 반투명으로 보여야 한다
					SetEntityRenderMode(entity, RENDER_GLOW);
					SetEntityRenderColor(entity, 0, 255, 0, 150);
					//엔티티의 식별을 위한 고유번호를 만드는 과정
					decl String:id[128];
					createentityidentification(client, type, STATUS_INCONSTRUCTQUEUE, id, 128);
					DispatchKeyValue(entity, "targetname", id);
					//위치 설정 중인 엔티티는 결코 공격에 의해 파괴당해선 안된다
					SetEntProp(entity, Prop_Data, "m_iHealth", 99999);//높은 체력
					DispatchKeyValueFloat(entity, "physdamagescale", 0.000000000000001);
					SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 9999999999);//999999999이상의 데미지를 입는 경우는 아마도 지극히 드물 것이다
					
					//스폰
					DispatchSpawn(entity);
					
					decl Float:clienteyeposition[3], Float:clienteyeangle[3];
					decl Float:resultposition[3], Float:resultnomalvector[3];
					GetClientEyeAngles(client, clienteyeangle);
					GetClientEyePosition(client, clienteyeposition);
					
					new Handle:traceresulthandle = INVALID_HANDLE;
					traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienteyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
					TR_GetEndPosition(resultposition, traceresulthandle);
					TR_GetPlaneNormal(traceresulthandle, resultnomalvector);
					
					if(traceresulthandle != INVALID_HANDLE){
						
						CloseHandle(traceresulthandle);
						
					}
					
					ScaleVector(resultnomalvector, 40.0);
					AddVectors(resultposition, resultnomalvector, resultposition);
					
					//텔레포트
					TeleportEntity(entity, resultposition, clienteyeangle, NULL_VECTOR);
					
					playerisconstructing[client] = entity;//플레이어가 건설중임을 나타낸다.
					
					constructconfirm[client] = false;
					constructcancel[client] = false;
					
					//건물의 위치를 조정하는 함수를 호출해야 한다
					new Handle:datapack = CreateDataPack();
					WritePackCell(datapack, client);
					WritePackString(datapack, id);
					
					CreateTimer(0.1, construct, datapack);
					
				}else if(check == RESULT_NO_REACTOR){
					
					PrintToChat(client, "\x04리엑터가 없으므로 건물을 지을 수 없습니다");
					
				}else if(check == RESULT_NO_OVERMIND){
					
					PrintToChat(client, "\x04오버마인드가 없으므로 건물을 지을 수 없습니다");
					
				}else if(check == RESULT_REACTOREXIST){
					
					PrintToChat(client, "\x04이미 다른 리엑터가있으므로 건물을 지을 수 없습니다");
					
				}else if(check == RESULT_OVERMINDEXIST){
					
					PrintToChat(client, "\x04이미 다른 오버마인드가있으므로 건물을 지을 수 없습니다");
					
				}else if(check == RESULT_OVERMINDINBUILD){
						
					if(type == OVERMIND){
						
						PrintToChat(client, "\x04이미 다른 오버마인드가 건설되고 있으므로 건물을 지을 수 없습니다");
							
					}else{
							
						PrintToChat(client, "\x04오버마인드가 아직 건설중이므로 건물을 지을 수 없습니다");
							
					}
						
				}else if(check == RESULT_REACTORINBUILD){
						
					if(type == REACTOR){
						
						PrintToChat(client, "\x04이미 다른 리엑터가 건설되고 있으므로 건물을 지을 수 없습니다");
							
					}else{
							
						PrintToChat(client, "\x04리엑터가 아직 건설중이므로 건물을 지을 수 없습니다");
							
					}
						
				}else if(check == RESULT_NO_TECH){
					
					PrintToChat(client, "\x04디펜스컴퓨터가 없으므로 건물을 지을 수 없습니다");
					
				}else if(check == RESULT_NO_POINT){
					
					PrintToChat(client, "\x04건설 수치가 한계에 도달했으므로 건물을 지을 수 없습니다");
					
				}
				
			}
		
		}
		
	}
	
}

//건물의 위치를 조정하는 함수
public Action:construct(Handle:Timer, Handle:data){
	
	decl client, String:id[128];
	ResetPack(data);
	client = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//클라이언트가 건설중인 건물이 올바른 엔티티인지 확인한다
	if(IsValidEntity(playerisconstructing[client]) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(playerisconstructing[client], Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우
		if(StrEqual(tempentityname, id, false)){
			
			//건물의 정보를 알아온다
			new userid, type, status;
			getentityidentificationdata(playerisconstructing[client], userid, type, status);
			
			//엔티티의 주인으로 정해진 클라이언트가 살아있을 경우
			if(isplayerconnectedingamealive(client) == true){
				
				new team = GetClientTeam(client);
				
				//에일리언인 경우
				if(team == 2){
					
					//에일리언이 지을 수 없는 건물인 경우
					if(!(type >= OVERMIND && type <= HIVE)){
						
						//에일리언이 지을 수 없는 건물인 경우
						AcceptEntityInput(playerisconstructing[client], "Kill");
						playerisconstructing[client] = 0;
						
						PrintToChat(client, "\x04에일리언이 지을 수 없는 건물입니다");
						
						return Plugin_Handled;
						
					}
					
					if(playerclass[client] != GRANGER && playerclass[client] != ADVANCEDGRANGER && loadstatus != NODATA){
						
						//건설 클래스가 아닌 경우
						AcceptEntityInput(playerisconstructing[client], "Kill");
						playerisconstructing[client] = 0;
						
						PrintToChat(client, "\x04건설 가능한 클래스만이 건물을 지을 수 있습니다");
						
						return Plugin_Handled;
						
					}
				
				}else if(team == 3){//인간인 경우
					
					//인간이 지을 수 없는 건물인 경우
					if(!(type >= REACTOR && type <= REPEATER)){
						
						//인간이 지을 수 없는 건물인 경우
						AcceptEntityInput(playerisconstructing[client], "Kill");
						playerisconstructing[client] = 0;
						PrintToChat(client, "\x04인간이 지을 수 없는 건물입니다");
						
						return Plugin_Handled;
						
					}
					
					if(playerclass[client] != HUMANBUILDER && loadstatus != NODATA){
						
						//건설 클래스가 아닌 경우
						AcceptEntityInput(playerisconstructing[client], "Kill");
						playerisconstructing[client] = 0;
						
						PrintToChat(client, "\x04건설 가능한 클래스만이 건물을 지을 수 있습니다");
						
						return Plugin_Handled;
						
					}
					
				}
				
				//건설을 계속 할 수 있다
				//플레이어의 건설 상태를 확인한다
				if(constructconfirm[client] == true){
					
					new buildchecktype:check = canstartconstruct(type);
				
					if(check == RESULT_OK){
						
						if(getpowerstatus(playerisconstructing[client])){
						
							decl Float:clientposition[3], Float:entityposition[3];
							
							GetClientEyePosition(client, clientposition);
							
							clientposition[2] = clientposition[2] - 20.0;
							GetEntPropVector(playerisconstructing[client], Prop_Send, "m_vecOrigin", entityposition);
							
							if(400 >= GetVectorDistance(clientposition, entityposition)){
							
								SetEntProp(playerisconstructing[client], Prop_Data, "m_CollisionGroup", 0);
								SetEntityMoveType(playerisconstructing[client], MOVETYPE_VPHYSICS);
								SetVariantFloat(999999.9);
								AcceptEntityInput(playerisconstructing[client], "forcetoenablemotion");
								SetVariantInt(999999);
								AcceptEntityInput(playerisconstructing[client], "damagetoenablemotion");
								AcceptEntityInput(playerisconstructing[client], "DisableMotion");
								SetEntProp(playerisconstructing[client], Prop_Data, "m_iHealth", structuremaxhealth[type]);//체력을 건물의 고유 수치로
								DispatchKeyValueFloat(playerisconstructing[client], "physdamagescale", 0.00000000000001);
								SetEntProp(playerisconstructing[client], Prop_Data, "m_iMinHealthDmg", 1);
										
								//건설을 확정했으므로 그에 따라서 건물 등록 코드가 온다
								structureregistration(playerisconstructing[client]);
								
								if(team == 2){
									
									SetEntityRenderColor(playerisconstructing[client], 255, 0, 0, 150);
									
								}else if(team == 3){
									
									SetEntityRenderColor(playerisconstructing[client], 0, 0, 255, 150);
									
								}
								
								SetEntityRenderMode(playerisconstructing[client], RENDER_NORMAL);
								
								//엔티티의 고유번호를 건설중으로 바꿔준다
								createentityidentification(client, type, STATUS_INCONSTRUCTING, tempentityname, 128);
								DispatchKeyValue(playerisconstructing[client], "targetname", tempentityname);
								
								new Handle:datapack = CreateDataPack();
								WritePackCell(datapack, playerisconstructing[client]);
								
								if(loadstatus == NODATA){
									
									WritePackCell(datapack, 1);
									
								}else{
									
									WritePackCell(datapack, structurebuildtime[type]);
									
								}
								WritePackString(datapack, tempentityname);
										
								CreateTimer(0.1, activestructure, datapack);
										
								playerisconstructing[client] = 0;
										
								PrintToChat(client, "\x04건설을 확정하셨습니다");
								return Plugin_Handled;
								
							}else{
								
								PrintToChat(client, "\x04지으려는 건물에 가까이 다가가야 합니다");
								constructconfirm[client] = false;
								
							}
						
						}else{
							
							if(team == 2){
								
								PrintToChat(client, "\x04건물은 오버마인드나 에그 근처에 지어져야 합니다");
								constructconfirm[client] = false;
								
							}else if(team == 3){
								
								PrintToChat(client, "\x04건물은 리엑터나 리피터 근처에 지어져야 합니다");
								constructconfirm[client] = false;
								
							}
							
						}
						
					}else if(check == RESULT_NO_REACTOR){
					
						PrintToChat(client, "\x04리엑터가 없으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}else if(check == RESULT_NO_OVERMIND){
						
						PrintToChat(client, "\x04오버마인드가 없으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}else if(check == RESULT_REACTOREXIST){
						
						PrintToChat(client, "\x04이미 다른 리엑터가 있으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}else if(check == RESULT_OVERMINDEXIST){
						
						PrintToChat(client, "\x04이미 다른 오버마인드가 있으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}else if(check == RESULT_OVERMINDINBUILD){
						
						if(type == OVERMIND){
						
							PrintToChat(client, "\x04이미 다른 오버마인드가 건설되고 있으므로 건물을 지을 수 없습니다");
							
						}else{
							
							PrintToChat(client, "\x04오버마인드가 아직 건설중이므로 건물을 지을 수 없습니다");
							
						}
						
						constructconfirm[client] = false;
						
					}else if(check == RESULT_REACTORINBUILD){
						
						if(type == REACTOR){
						
							PrintToChat(client, "\x04이미 다른 리엑터가 건설되고 있으므로 건물을 지을 수 없습니다");
							
						}else{
							
							PrintToChat(client, "\x04리엑터가 아직 건설중이므로 건물을 지을 수 없습니다");
							
						}
						constructconfirm[client] = false;
						
					}else if(check == RESULT_NO_TECH){
						
						PrintToChat(client, "\x04디펜스컴퓨터가 없으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}else if(check == RESULT_NO_POINT){
						
						PrintToChat(client, "\x04건설 수치가 한계에 도달했으므로 건물을 지을 수 없습니다");
						constructconfirm[client] = false;
						
					}
								
				}else if(constructcancel[client] == true){
								
					AcceptEntityInput(playerisconstructing[client], "Kill");
					playerisconstructing[client] = 0;
								
					PrintToChat(client, "\x04건설을 취소하셨습니다");
					return Plugin_Handled;
								
				}
						
				//위치설정을 계속 한다
				decl Float:clienteyeposition[3], Float:clienteyeangle[3], Float:anglevector[3], Float:resultposition[3];
				new Handle:traceresulthandle = INVALID_HANDLE;
				
				//엔티티가 현재 위치에 건설 가능할 경우 초록색으로 표시하지만, 그렇지 않을 경우 주황색으로 표시한다
				if(getpowerstatus(playerisconstructing[client])){
					
					SetEntityRenderColor(playerisconstructing[client], 0, 255, 0, 150);
					
				}else{
					
					SetEntityRenderColor(playerisconstructing[client], 255, 150, 0, 64);
					
				}
				
				GetClientEyePosition(client, clienteyeposition);
				GetClientEyeAngles(client, clienteyeangle);
						
				traceresulthandle = TR_TraceRayFilterEx(clienteyeposition, clienteyeangle, MASK_SOLID, RayType_Infinite, buildtracerayfilter, client);
				
				//엔티티와 클라이언트를 잇는 빨간 선을 표시한다
				decl Float:m_vecorigin[3];
				
				clienteyeposition[2] = clienteyeposition[2] - 20.0;//클라이언트의 눈 위치에서부터 레이져를 만들면 정작 클라이언트가 보지 못한다
				
				GetEntPropVector(playerisconstructing[client], Prop_Send, "m_vecOrigin", m_vecorigin);
				TE_SetupBeamPoints(clienteyeposition, m_vecorigin, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, red, 0);
				TE_SendToClient(client);
						
				if(TR_DidHit(traceresulthandle) == true){
								
					TR_GetEndPosition(resultposition, traceresulthandle);
					MakeVectorFromPoints(m_vecorigin, resultposition, anglevector);
							
					//끌어당기려는 거리가 200 이하여야만 한다
					/*if(200 >= GetVectorLength(anglevector) && 200 >= GetVectorDistance(clienteyeposition, resultposition)){
						
						TE_SetupBeamPoints(clienteyeposition, resultposition, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, blue, 0);
						TE_SendToClient(client);
						TeleportEntity(playerisconstructing[client], NULL_VECTOR, NULL_VECTOR, anglevector);
							
					}else{
							
						TE_SetupBeamPoints(clienteyeposition, resultposition, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, black, 0);
						TE_SendToClient(client);
								
					}*/
					
					TE_SetupBeamPoints(clienteyeposition, resultposition, beamsprite, halosprite, 0, 0, 1.0, 3.0, 3.0, 0, 0.0, blue, 0);
					TE_SendToClient(client);
					TeleportEntity(playerisconstructing[client], NULL_VECTOR, NULL_VECTOR, anglevector);
								
				}
							
				if(traceresulthandle != INVALID_HANDLE){
								
					CloseHandle(traceresulthandle);
						
				}
							
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, client);
				WritePackString(datapack, id);
						
				CreateTimer(0.1, construct, datapack);
					
			}else{
				
				//클라이언트가 죽거나 올바른 클라이언트가 아닌 경우
				AcceptEntityInput(playerisconstructing[client], "Kill");
				playerisconstructing[client] = 0;
				
			}
			
		}else{
			
			//올바른 식별 번호를 가진 엔티티가 아닌 경우
			playerisconstructing[client] = 0;
			
			if(isplayerconnectedingame(client)){
				
				PrintToChat(client, "\x04올바른 엔티티가 아닙니다");
			
			}
				
		}
		
	}else{
			
		//엔티티가 존재하지 않을 경우
		playerisconstructing[client] = 0;
		
		if(isplayerconnectedingame(client)){
			
			PrintToChat(client, "\x04엔티티가 존재하지 않습니다");
			
		}
		
	}
	
	return Plugin_Handled;
	
}


//위치가 확정된 건물을 활성화시키는 함수
//이 함수에는 두가지 인수가 전달된다.
//엔티티, 그리고 엔티티의 식별번호
public Action:activestructure(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128], time;
	ResetPack(data);
	entity = ReadPackCell(data);
	time = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	//건설 확정 후에 엔티티가 부서질 수도 있으므로, 확인해야한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우
		if(StrEqual(tempentityname, id, false)){
			
			//건설이 끝나는 시간
			if(time == 0){
				
				//건물의 고유번호를 작동 가능함 상태로 바꾼다
				new userid, type, status;
	
				if(getentityidentificationdata(entity, userid, type, status)){
				
					createentityidentification(0, type, STATUS_FUNCTIONING, id, 128);
					DispatchKeyValue(entity, "targetname", id);
					
				}
				
				//건물의 종류에 따른 기능을 시작시키는 함수를 호출한다
				SetEntityRenderMode(entity, RENDER_NORMAL);
				SetEntityRenderColor(entity, 255, 255, 255, 255);
				
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, entity);
				WritePackString(datapack, id);
				
				//각 건물의 종류에 따른 기능 시작
				if(type == OVERMIND){
					
					CreateTimer(0.1, activeovermind, datapack);
					
				}else if(type == EGG){
					
					CreateTimer(0.1, activeegg, datapack);
					
				}else if(type == ACIDTUBE){
					
					CreateTimer(0.1, activeacidtube, datapack);
					
				}else if(type == BARRICADE){
					
					CreateTimer(0.1, activebarricade, datapack);
					
				}else if(type == TRAPPER){
					
					CreateTimer(0.1, activetrapper, datapack);	
					
				}else if(type == BOOSTER){
					
					CreateTimer(0.1, activebooster, datapack);
					
				}else if(type == HOVEL){
					
					CreateTimer(0.1, activehovel, datapack);
					
				}else if(type == HIVE){
					
					CreateTimer(0.1, activehive, datapack);
					
				}else if(type == REACTOR){
					
					CreateTimer(0.1, activereactor, datapack);
					
				}else if(type == TELENODE){
					
					CreateTimer(0.1, activetelenode, datapack);
					
				}else if(type == MACHINEGUNTURRET){
					
					CreateTimer(0.1, activemachinegunturret, datapack);
					
				}else if(type == TESLAGENERATOR){
					
					CreateTimer(0.1, activeteslagenerator, datapack);
					
				}else if(type == ARMOURY){
					
					//아머리는 기능이 없다
					CreateTimer(0.1, activearmoury, datapack);
					
				}else if(type == DEFENCECOMPUTER){
					
					CreateTimer(0.1, activedefencecomputer, datapack);
					
				}else if(type == MEDISTATION){
					
					CreateTimer(0.1, activemedistation, datapack);
					
				}else if(type == REPEATER){
					
					//리피터는 기능이 없으므로 함수를 호출할 필요가 없다
					//CreateTimer(0.1, activerepeater, datapack);
					
				}
				
			}else{
				
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, entity);
				WritePackCell(datapack, time - 1);
				WritePackString(datapack, id);
				
				CreateTimer(0.1, activestructure, datapack);
				
			}
			
		}
		
	}
	
	return Plugin_Handled;
		
}

//완성된 각각의 건물을 작동시킨다, 킵워크 스트럭쳐 함수 하나로 뭉친게 혹시 섭폭의 원인일 지도 모르므로 일단 나눠본다
public Action:activeovermind(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			alienstructureautoheal(entity);
			
			//공격 기능 빼곤 할게 없다
			for(new client = 1; client <= MaxClients; client++){
						
				if(isplayerconnectedingamealive(client)){
							
					//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
					if(GetClientTeam(client) == 3){
								
						//엔티티의 위치를 구해온다
						decl Float:entityposition[3], Float:clientposition[3];
								
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
						GetClientEyePosition(client, clientposition);
						clientposition[2] = clientposition[2] - 20.0;
								
						//거리가 150이하일 경우
						if(GetVectorDistance(entityposition, clientposition) <= 150){
									
							decl Float:vector[3], Float:vectorangle[3];
									
							MakeVectorFromPoints(entityposition, clientposition, vector);
							GetVectorAngles(vector, vectorangle);
									
							new Handle:traceresulthandle = INVALID_HANDLE;
					
							traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
					
							if(TR_DidHit(traceresulthandle) == true){
						
								if(TR_GetEntityIndex(traceresulthandle) == client){
											
									createovermindgas(entityposition, vectorangle);
									makedamage(0, client, 6, "overmind", entityposition);
									fademessage(client, 1000, 1000, FFADE_IN, 0, 255, 0, 100);
											
								}
										
							}
									
							if(traceresulthandle != INVALID_HANDLE){
										
								CloseHandle(traceresulthandle);
										
							}
									
						}
								
					}
							
				}
						
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(0.5, activeovermind, datapack);
			
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activeegg(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
				
			alienstructureautoheal(entity);
				
			//아직 에그에 대해선 해줄 것이 없다
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activeegg, datapack);
				
		}else{
			
			//이것은 에그로 지정되었던 엔티티가 존재하지 않는다는 의미이다.
			//엔티티가 파괴되었다는 의미지만, 자세히 생각해 보면 이것은
			//심지어 에그와 같은 번호의 텔레노드가 생겼을 가능성 마저 있다.
			//혹은 라운드가 끝난 뒤에 곧바로 다시 에그가 지어지는 경우까지 있을 수 있다
			//물론 라운드가 시작되고서 10초 뒤에 건물이 로딩되므로 이것은 불가능하지만
			//그럼에도, 이 경우에 이것이 엄연히 에그로서 지어졌던 건물이 파괴되었음을 의미하므로,
			//게임의 종료 조건을 만족하는지 확인할 필요가 있다
			
			if(loadstatus == LOADED){
					
				//팀이 살아있는가
				new bool:teamisalive = false;
					
				for(new i = 1; i <= MaxClients; i++){
				
					if(isplayerconnectedingamealive(i)){
				
						if(!IsFakeClient(i)){
							
							if(GetClientTeam(i) == 2){
									
								teamisalive = true;
									
							}
								
						}
							
					}
						
				}
				
				//다른 팀원이 살아있지 않을 경우 에그가 남아있는지 확인한다
				if(!teamisalive){
						
					//작동 가능한 에그가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
					if(!getworkablestructure(EGG)){
							
						for(new i = 1; i <= MaxClients; i++){
						
							if(isplayerconnectedingamealive(i)){
						
								if(GetClientTeam(i) == 2){
										
									ForcePlayerSuicide(i);
										
								}
									
							}
								
						}
							
						loadstatus = NOTLOADED;
							
					}
						
				}
					
			}
			
		}
		
	}else{
		
		//이것은 에그로 지정되었던 엔티티가 존재하지 않는다는 의미이다.
		//엔티티가 파괴되었다는 의미지만, 자세히 생각해 보면 이것은
		//심지어 에그와 같은 번호의 텔레노드가 생겼을 가능성 마저 있다.
		//혹은 라운드가 끝난 뒤에 곧바로 다시 에그가 지어지는 경우까지 있을 수 있다
		//물론 라운드가 시작되고서 10초 뒤에 건물이 로딩되므로 이것은 불가능하지만
		//그럼에도, 이 경우에 이것이 엄연히 에그로서 지어졌던 건물이 파괴되었음을 의미하므로,
		//게임의 종료 조건을 만족하는지 확인할 필요가 있다
		
		if(loadstatus == LOADED){
				
			//팀이 살아있는가
			new bool:teamisalive = false;
				
			for(new i = 1; i <= MaxClients; i++){
			
				if(isplayerconnectedingamealive(i)){
			
					if(!IsFakeClient(i)){
						
						if(GetClientTeam(i) == 2){
								
							teamisalive = true;
								
						}
							
					}
						
				}
					
			}
			
			//다른 팀원이 살아있지 않을 경우 에그가 남아있는지 확인한다
			if(!teamisalive){
					
				//작동 가능한 에그가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
				if(!getworkablestructure(EGG)){
						
					for(new i = 1; i <= MaxClients; i++){
					
						if(isplayerconnectedingamealive(i)){
					
							if(GetClientTeam(i) == 2){
									
								ForcePlayerSuicide(i);
									
							}
								
						}
							
					}
						
					loadstatus = NOTLOADED;
						
				}
					
			}
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activeacidtube(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
		//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
				
				alienstructureautoheal(entity);
						
				new bool:istarget[MaxClients + 1];
				new bool:thereistarget;
						
				decl Float:entityposition[3], Float:clientposition[3];
				
				for(new client = 1; client <= MaxClients; client++){
							
					if(isplayerconnectedingamealive(client)){
								
						//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
						if(GetClientTeam(client) == 3){
									
							//엔티티의 위치를 구해온다
									
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
							GetClientEyePosition(client, clientposition);
							clientposition[2] = clientposition[2] - 20.0;
									
							//거리가 200이하일 경우
							if(GetVectorDistance(entityposition, clientposition) <= 200){
										
								decl Float:vector[3], Float:vectorangle[3];
										
								MakeVectorFromPoints(entityposition, clientposition, vector);
								GetVectorAngles(vector, vectorangle);
										
								new Handle:traceresulthandle = INVALID_HANDLE;
						
								traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
						
								if(TR_DidHit(traceresulthandle) == true){
							
									if(TR_GetEntityIndex(traceresulthandle) == client){
												
										istarget[client] = true;
										thereistarget = true;
												
									}
											
								}
										
								if(traceresulthandle != INVALID_HANDLE){
											
									CloseHandle(traceresulthandle);
											
								}
										
							}
									
						}
								
					}
							
				}
						
				if(thereistarget == true){
							
					createacidtubegas(entityposition);
							
					for(new client = 1; client <= MaxClients; client++){
								
						if(istarget[client] == true){
									
							makedamage(0, client, 10, "acidtube", entityposition);
							fademessage(client, 1000, 1000, FFADE_IN, 200, 95, 0, 100);
													
						}
								
					}
						
				}
						
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activeacidtube, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activebarricade(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
			
				alienstructureautoheal(entity);
				
			}
			
			//아직 바리케이트에 대해선 해줄 것이 없다
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activebarricade, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activetrapper(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
			
				alienstructureautoheal(entity);
				
				new Float:time = GetGameTime();
				
				if(structurelastworktime[entity] + TRAPPERDELAY <= time){
					
					structurelastworktime[entity] = time;
				
					decl Float:entityposition[3], Float:distance[MaxClients + 1];
					new bool:istarget[MaxClients + 1];
					new targetselected = 0;
					
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
					
					//공격 가능한 상대 중 가장 가까운 상대를 구해서 그 사람을 향해 마비수박을 발사한다
					for(new client = 1; client <= MaxClients; client++){
						
						new Float:clientposition[3];
						
						if(isplayerconnectedingamealive(client)){
									
							//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
							if(GetClientTeam(client) == 3){
										
								//엔티티의 위치를 구해온다
								GetClientEyePosition(client, clientposition);
								clientposition[2] = clientposition[2] - 20.0;
								
								distance[client] = GetVectorDistance(entityposition, clientposition);
								
								//거리가 600이하일 경우, 이것은 테슬라제네레이터와 같은 값이다
								if(distance[client] <= 600){
											
									decl Float:vector[3], Float:vectorangle[3];
											
									MakeVectorFromPoints(entityposition, clientposition, vector);
									NormalizeVector(vector, vector);
									GetVectorAngles(vector, vectorangle);
											
									new Handle:traceresulthandle = INVALID_HANDLE;
							
									traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
							
									if(TR_DidHit(traceresulthandle) == true){
								
										if(TR_GetEntityIndex(traceresulthandle) == client){
											
											istarget[client] = true;
													
										}
												
									}
											
									if(traceresulthandle != INVALID_HANDLE){
												
										CloseHandle(traceresulthandle);
												
									}
											
								}
										
							}
									
						}
								
					}
					
					//가장 가까운 사람을 구한다
					new Float:tempdistance = 600.0;
									
					for(new client = 1; client <= MaxClients; client++){
										
						if(istarget[client] == true){
											
							if(distance[client] <= tempdistance){
												
								targetselected = client;
								tempdistance = distance[client];
												
							}
											
						}
										
					}
					
					if(targetselected != 0){
										
						//수박이 소환될 위치, 던져질 각도를 구한다
						decl Float:clientposition[3], Float:vector[3], Float:angle[3], Float:resultposition[3];
						
						GetClientEyePosition(targetselected, clientposition);
						clientposition[2] = clientposition[2] - 20.0;
						
						MakeVectorFromPoints(entityposition, clientposition, vector);
						NormalizeVector(vector, vector);
						GetVectorAngles(vector, angle);
						ScaleVector(vector, 50.0);
						AddVectors(entityposition, vector, resultposition);
						ScaleVector(vector, 20.0);//벡터의 길이를 1000으로 부풀려서 속도벡터로 재활용한다
						//이제 벡터값들을 모두 구했다.
						
						//수박을 만들어서 날려보내면 된다
						new projectileentity = CreateEntityByName("prop_physics");
						DispatchKeyValue(projectileentity, "model", "models/props_junk/watermelon01.mdl");//이 방식을 써야 문제가 생기지 않는다
						SetEntityRenderMode(projectileentity, RENDER_GLOW);
						SetEntityRenderColor(projectileentity, 0, 0, 0, 255);
						//엔티티의 식별을 위한 고유번호를 만드는 과정
						decl String:projectileid[128];
						createentityidentification(0, TRAPPERPROJECTILE, STATUS_NOTSTRUCTURE, projectileid, 128);
						DispatchKeyValue(projectileentity, "targetname", projectileid);
						DispatchKeyValueFloat(projectileentity, "physdamagescale", 0.01);
						//자 가라 우주로!!!
						DispatchSpawn(projectileentity);
						
						TeleportEntity(projectileentity, resultposition, angle, vector);
						
						new Handle:datapack = CreateDataPack();
						WritePackCell(datapack, projectileentity);
						WritePackCell(datapack, PROJECTILELIFE);
						WritePackString(datapack, projectileid);
						
						CreateTimer(0.1, trapperprojectilecheck, datapack);
						
					}
					
				}
				
			}
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activetrapper, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activebooster(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			//주위에 있는 에일리언에게 독 공격 능력을 주고, 체력 회복을 2배로 해준다
			if(getpowerstatus(entity)){
				
				alienstructureautoheal(entity);
						
				decl Float:entityposition[3], Float:clientposition[3], Float:distance[MaxClients + 1];
				new bool:istargetted[MaxClients + 1];
				new targetselected = 0;
							
				for(new client = 1; client <= MaxClients; client++){
									
					if(isplayerconnectedingamealive(client)){
										
						if(GetClientTeam(client) == 2){
												
							//엔티티의 위치를 구해온다
												
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
							GetClientEyePosition(client, clientposition);
							clientposition[2] = clientposition[2] - 20.0;
							
							distance[client] = GetVectorDistance(entityposition, clientposition);
											
							//거리가 100이하일 경우, 독 공격 능력을 갖고있지 않을 경우
							if(distance[client] <= 100.0){
								
								decl Float:vector[3], Float:vectorangle[3];
											
								MakeVectorFromPoints(entityposition, clientposition, vector);
								NormalizeVector(vector, vector);
								GetVectorAngles(vector, vectorangle);
											
								new Handle:traceresulthandle = INVALID_HANDLE;
							
								traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
							
								if(TR_DidHit(traceresulthandle) == true){
								
									if(TR_GetEntityIndex(traceresulthandle) == client){
											
										istargetted[client] = true;
													
									}
												
								}
											
								if(traceresulthandle != INVALID_HANDLE){
												
									CloseHandle(traceresulthandle);
												
								}
												
							}
												
						}
											
					}
										
				}
							
				new Float:tempdistance = 100.0;
								
				for(new client = 1; client <= MaxClients; client++){
									
					if(istargetted[client] == true){
										
						if(distance[client] <= tempdistance){
											
							targetselected = client;
							tempdistance = distance[client];
											
						}
										
					}
									
				}
								
				if(targetselected != 0){
									
					GetClientEyePosition(targetselected, clientposition);
					clientposition[2] = clientposition[2] - 20.0;
									
					TE_SetupBeamPoints(entityposition, clientposition, reactorbeamsprite, halosprite, 0, 1, 1.0, 3.0, 3.0, 0, 1.5, fullcolor, 40);
					TE_SendToAll();
					
					if(structurelastworktime[entity] + BOOSTERDELAY <= GetGameTime()){
						
						structurelastworktime[entity] = GetGameTime();
						
						if(playerhaspoisonability[targetselected] == false){
										
							if(playerhaspoisonhandle[targetselected] != INVALID_HANDLE){
												
								KillTimer(playerhaspoisonhandle[targetselected]);
												
							}
											
							playerhaspoisonability[targetselected] = true;
											
							playerhaspoisonhandle[targetselected] = CreateTimer(POISONCOOLTIME, playerhaspoisondisable, targetselected);
							
											
						}
						
					}
									
					playergetdoubleheal[targetselected] = true;
									
				}
								
			}
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(0.1, activebooster, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activehovel(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			//주위에 있는 에일리언에게 천천히 특수 갑각을 준다
			if(getpowerstatus(entity)){
				
				alienstructureautoheal(entity);
						
				//건물의 기능 딜레이
				if(structurelastworktime[entity] + HOVELDELAY <= GetGameTime()){
						
					decl Float:entityposition[3], Float:clientposition[3], Float:distance[MaxClients + 1];
					new bool:istargetted[MaxClients + 1];
					new targetselected = 0;
					
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
					
					for(new client = 1; client <= MaxClients; client++){
										
						if(isplayerconnectedingamealive(client)){
											
							if(GetClientTeam(client) == 2){
												
								//엔티티의 위치를 구해온다			
								GetClientEyePosition(client, clientposition);
								clientposition[2] = clientposition[2] - 20.0;
											
								distance[client] = GetVectorDistance(entityposition, clientposition);
										
								//거리가 80이하일 경우, 가진 특수갑각이 레벨 제한 이하일 경우
								if(distance[client] <= 80 && GetEntProp(client, Prop_Data, "m_ArmorValue") < maxhovelarmor[techlevel]){
									
									decl Float:vector[3], Float:vectorangle[3];
											
									MakeVectorFromPoints(entityposition, clientposition, vector);
									NormalizeVector(vector, vector);
									GetVectorAngles(vector, vectorangle);
												
									new Handle:traceresulthandle = INVALID_HANDLE;
								
									traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
								
									if(TR_DidHit(traceresulthandle) == true){
									
										if(TR_GetEntityIndex(traceresulthandle) == client){
												
											istargetted[client] = true;
														
										}
													
									}
												
									if(traceresulthandle != INVALID_HANDLE){
													
										CloseHandle(traceresulthandle);
													
									}
												
								}
										
							}
											
						}
										
					}
							
					new Float:tempdistance = 80.0;
							
					for(new client = 1; client <= MaxClients; client++){
								
						if(istargetted[client] == true){
									
							if(distance[client] <= tempdistance){
										
								targetselected = client;
								tempdistance = distance[client];
										
							}
									
						}
								
					}
							
					if(targetselected != 0){
								
						if(GetEntProp(targetselected, Prop_Data, "m_ArmorValue") + 6 <= maxhovelarmor[techlevel]){
									
							SetEntProp(targetselected, Prop_Data, "m_ArmorValue", GetEntProp(targetselected, Prop_Data, "m_ArmorValue") + 6);
								
						}else{
									
							SetEntProp(targetselected, Prop_Data, "m_ArmorValue", maxhovelarmor[techlevel]);
									
						}
								
					}
							
					structurelastworktime[entity] = GetGameTime();
						
				}
					
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activehovel, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activehive(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
			
				alienstructureautoheal(entity);
				
				//테슬라제네레이터를 위한 공격 코드
				decl Float:entityposition[3], Float:clientposition[3], Float:distance[MaxClients + 1], Float:vector[3], Float:angle[3];
				new bool:istargetted[MaxClients + 1];
				new targetselected = 0;
					
				//가장 가까운 목표를 구해야 한다		
				for(new client = 1; client <= MaxClients; client++){
										
					if(isplayerconnectedingamealive(client)){
											
						//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
						if(GetClientTeam(client) == 3){
											
							//엔티티의 위치를 구해온다
												
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
							GetClientEyePosition(client, clientposition);
							clientposition[2] = clientposition[2] - 20.0;
								
							MakeVectorFromPoints(entityposition, clientposition, vector);
							GetVectorAngles(vector, angle);
								
							distance[client] = GetVectorDistance(entityposition, clientposition);
											
							new Handle:traceresulthandle = INVALID_HANDLE;
					
							traceresulthandle = TR_TraceRayFilterEx(entityposition, angle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
					
							if(TR_DidHit(traceresulthandle) == true){
						
								if(TR_GetEntityIndex(traceresulthandle) == client){
											
									istargetted[client] = true;
											
								}
										
							}
								
							if(traceresulthandle != INVALID_HANDLE){
									
								CloseHandle(traceresulthandle);
								
							}
												
						}
											
					}
										
				}
					
				new Float:tempdistance = 600.0;
					
				for(new client = 1; client <= MaxClients; client++){
						
					if(istargetted[client] == true){
							
						if(distance[client] <= tempdistance){
								
							tempdistance = distance[client];
							targetselected = client;
								
						}
							
					}
						
				}
								
				if(targetselected != 0){
						
					GetClientEyePosition(targetselected, clientposition);
					clientposition[2] = clientposition[2] - 20.0;
					MakeVectorFromPoints(entityposition, clientposition, vector);
					GetVectorAngles(vector, angle);	
					createhivegas(entityposition, angle);
					makedamage(0, targetselected, 20, "hivegas", entityposition);
					fademessage(targetselected, 1000, 1000, FFADE_IN, 0, 255, 0, 100);
						
				}
				
			}
			
			//아직 하이브의 공격을 만들지 못했다
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activehive, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activereactor(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		decl Float:entityposition[3], Float:clientposition[3];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
			
			//리엑터는 약간의 공격 코드가 있을 뿐 할일은 없다
			for(new client = 1; client <= MaxClients; client++){
						
				if(isplayerconnectedingamealive(client)){
							
					//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
					if(GetClientTeam(client) == 2){
								
						//엔티티의 위치를 구해온다
						GetClientEyePosition(client, clientposition);
						clientposition[2] = clientposition[2] - 20.0;
								
						//거리가 100이하일 경우
						if(GetVectorDistance(entityposition, clientposition) <= 150){
									
							decl Float:vector[3], Float:vectorangle[3];
									
							MakeVectorFromPoints(entityposition, clientposition, vector);
							GetVectorAngles(vector, vectorangle);
									
							new Handle:traceresulthandle = INVALID_HANDLE;
					
							traceresulthandle = TR_TraceRayFilterEx(entityposition, vectorangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
					
							if(TR_DidHit(traceresulthandle) == true){
						
								if(TR_GetEntityIndex(traceresulthandle) == client){
											
									TE_SetupBeamPoints(entityposition, clientposition, reactorbeamsprite, halosprite, 0, 1, 1.0, 3.0, 3.0, 0, 1.5, fullcolor, 40);
									TE_SendToAll();
									makedamage(0, client, 6, "reactor", entityposition);
											
								}
										
							}
									
							if(traceresulthandle != INVALID_HANDLE){
										
								CloseHandle(traceresulthandle);
										
							}
									
						}
								
					}
							
				}
						
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(0.5, activereactor, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activetelenode(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activetelenode, datapack);
				
		}else{
			
			//이것은 텔레노드로 지정되었던 엔티티가 존재하지 않는다는 의미이다.
			//엔티티가 파괴되었다는 의미지만, 자세히 생각해 보면 이것은
			//심지어 텔레노드와 같은 번호의 에그가 생겼을 가능성 마저 있다.
			//혹은 라운드가 끝난 뒤에 곧바로 다시 텔레노드가 지어지는 경우까지 있을 수 있다
			//물론 라운드가 시작되고서 10초 뒤에 건물이 로딩되므로 이것은 불가능하지만
			//그럼에도, 이 경우에 이것이 엄연히 에그로서 지어졌던 건물이 파괴되었음을 의미하므로,
			//게임의 종료 조건을 만족하는지 확인할 필요가 있다
			
			if(loadstatus == LOADED){
					
				//팀이 살아있는가
				new bool:teamisalive = false;
					
				for(new i = 1; i <= MaxClients; i++){
				
					if(isplayerconnectedingamealive(i)){
				
						if(!IsFakeClient(i)){
							
							if(GetClientTeam(i) == 3){
									
								teamisalive = true;
									
							}
								
						}
							
					}
						
				}
				
				//다른 팀원이 살아있지 않을 경우 텔레노드가 남아있는지 확인한다
				if(!teamisalive){
						
					//작동 가능한 텔레노드가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
					if(!getworkablestructure(TELENODE)){
							
						for(new i = 1; i <= MaxClients; i++){
						
							if(isplayerconnectedingamealive(i)){
						
								if(GetClientTeam(i) == 3){
										
									ForcePlayerSuicide(i);
										
								}
									
							}
								
						}
							
						loadstatus = NOTLOADED;
							
					}
						
				}
					
			}
			
		}
		
	}else{
		
		//이것은 텔레노드로 지정되었던 엔티티가 존재하지 않는다는 의미이다.
		//엔티티가 파괴되었다는 의미지만, 자세히 생각해 보면 이것은
		//심지어 텔레노드와 같은 번호의 에그가 생겼을 가능성 마저 있다.
		//혹은 라운드가 끝난 뒤에 곧바로 다시 텔레노드가 지어지는 경우까지 있을 수 있다
		//물론 라운드가 시작되고서 10초 뒤에 건물이 로딩되므로 이것은 불가능하지만
		//그럼에도, 이 경우에 이것이 엄연히 텔레노드로서 지어졌던 건물이 파괴되었음을 의미하므로,
		//게임의 종료 조건을 만족하는지 확인할 필요가 있다
			
		if(loadstatus == LOADED){
					
			//팀이 살아있는가
			new bool:teamisalive = false;
				
			for(new i = 1; i <= MaxClients; i++){
				
				if(isplayerconnectedingamealive(i)){
				
					if(!IsFakeClient(i)){
							
						if(GetClientTeam(i) == 3){
									
							teamisalive = true;
									
						}
								
					}
							
				}
						
			}
				
			//다른 팀원이 살아있지 않을 경우 텔레노드가 남아있는지 확인한다
			if(!teamisalive){
						
				//작동 가능한 텔레노드가 남아있지 않을 경우(혹은 건설중인것만 남아있을 경우) 패배
				if(!getworkablestructure(TELENODE)){
							
					for(new i = 1; i <= MaxClients; i++){
						
						if(isplayerconnectedingamealive(i)){
						
							if(GetClientTeam(i) == 3){
										
								ForcePlayerSuicide(i);
									
							}
									
						}
								
					}
							
					loadstatus = NOTLOADED;
							
				}
						
			}
					
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activemachinegunturret(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
			
				//머신건 터렛을 위한 공격 코드
				decl Float:entityposition[3], Float:clientposition[3], Float:distance[MaxClients + 1], Float:vector[3], Float:angle[3];
				new bool:istargetted[MaxClients + 1];
				new targetselected = 0;
						
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
						
				//가장 가까운 목표를 구해야 한다		
				for(new client = 1; client <= MaxClients; client++){
											
					if(isplayerconnectedingamealive(client)){
												
						//인간일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
						if(GetClientTeam(client) == 2){
													
							//엔티티의 위치를 구해온다
							GetClientEyePosition(client, clientposition);
							clientposition[2] = clientposition[2] - 20.0;
									
							MakeVectorFromPoints(entityposition, clientposition, vector);
							GetVectorAngles(vector, angle);
												
							distance[client] = GetVectorDistance(entityposition, clientposition);
												
							new Handle:traceresulthandle = INVALID_HANDLE;
						
							traceresulthandle = TR_TraceRayFilterEx(entityposition, angle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
						
							if(TR_DidHit(traceresulthandle) == true){
							
								if(TR_GetEntityIndex(traceresulthandle) == client){
												
									istargetted[client] = true;
												
								}
										
							}
									
							if(traceresulthandle != INVALID_HANDLE){
										
								CloseHandle(traceresulthandle);
										
							}
													
						}
												
					}
											
				}
						
				new Float:tempdistance;
									
				if(getworkablestructure(DEFENCECOMPUTER)){
										
					tempdistance = 400.0;
										
				}else{
										
					tempdistance = 250.0;
										
				}
						
				for(new client = 1; client <= MaxClients; client++){
							
					if(istargetted[client] == true){
								
						if(distance[client] <= tempdistance){
									
							tempdistance = distance[client];
							targetselected = client;
									
						}
								
					}
							
				}
									
				if(targetselected != 0){
							
					GetClientEyePosition(targetselected, clientposition);
					clientposition[2] = clientposition[2] - 20.0;
							
					TE_SetupBeamPoints(entityposition, clientposition, beamsprite, halosprite, 0, 1, 1.0, 3.0, 3.0, 0, 1.5, blue, 40);
					TE_SendToAll();
					
					makedamage(0, targetselected, 10, "machinegunturret", entityposition);
							
				}
			
			
			}
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activemachinegunturret, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activeteslagenerator(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
				
				//테슬라제네레이터를 위한 공격 코드
				decl Float:entityposition[3], Float:clientposition[3], Float:distance[MaxClients + 1], Float:vector[3], Float:angle[3];
				new bool:istargetted[MaxClients + 1];
				new targetselected = 0;
					
				//가장 가까운 목표를 구해야 한다		
				for(new client = 1; client <= MaxClients; client++){
										
					if(isplayerconnectedingamealive(client)){
											
						//에일리언일 경우, 일정 거리 안에 있고 트레이스 결과가 올바른지 추적해서 공격하고, 레이져 생성
						if(GetClientTeam(client) == 2){
											
							//엔티티의 위치를 구해온다
												
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
							GetClientEyePosition(client, clientposition);
							clientposition[2] = clientposition[2] - 20.0;
								
							MakeVectorFromPoints(entityposition, clientposition, vector);
							GetVectorAngles(vector, angle);
								
							distance[client] = GetVectorDistance(entityposition, clientposition);
											
							new Handle:traceresulthandle = INVALID_HANDLE;
					
							traceresulthandle = TR_TraceRayFilterEx(entityposition, angle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
					
							if(TR_DidHit(traceresulthandle) == true){
						
								if(TR_GetEntityIndex(traceresulthandle) == client){
											
									istargetted[client] = true;
											
								}
										
							}
								
							if(traceresulthandle != INVALID_HANDLE){
									
								CloseHandle(traceresulthandle);
								
							}
												
						}
											
					}
										
				}
					
				new Float:tempdistance = 600.0;
					
				for(new client = 1; client <= MaxClients; client++){
						
					if(istargetted[client] == true){
							
						if(distance[client] <= tempdistance){
								
							tempdistance = distance[client];
							targetselected = client;
								
						}
							
					}
						
				}
								
				if(targetselected != 0){
						
					GetClientEyePosition(targetselected, clientposition);
					clientposition[2] = clientposition[2] - 20.0;
						
					TE_SetupBeamPoints(entityposition, clientposition, beamsprite, halosprite, 0, 1, 1.0, 3.0, 3.0, 0, 1.5, red, 40);
					TE_SendToAll();
					makedamage(0, targetselected, 20, "teslagenerator", entityposition);
						
				}
				
			}
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activeteslagenerator, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activearmoury(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			/*이 코드는 필요없다
			if(getpowerstatus(entity)){
				
				//파워가 있을 경우엔 있다고 해준다
				createentityidentification(0, ARMOURY, STATUS_FUNCTIONING, id, 128);
				DispatchKeyValue(entity, "targetname", id);
						
			}else{
						
				//파워가 없으므로 없다고 해줘야한다
				createentityidentification(0, ARMOURY, STATUS_UNFUNCTIONING, id, 128);
				DispatchKeyValue(entity, "targetname", id);	
						
			}
			*/
			
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activearmoury, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activedefencecomputer(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
				
				//파워가 있을 경우엔 있다고 해준다
				createentityidentification(0, DEFENCECOMPUTER, STATUS_FUNCTIONING, id, 128);
				DispatchKeyValue(entity, "targetname", id);
						
			}else{
						
				//파워가 없으므로 없다고 해줘야한다
				createentityidentification(0, DEFENCECOMPUTER, STATUS_UNFUNCTIONING, id, 128);
				DispatchKeyValue(entity, "targetname", id);	
						
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activedefencecomputer, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activemedistation(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			if(getpowerstatus(entity)){
						
				decl Float:entityposition[3], Float:angle[3], Float:targeteyeposition[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
				angle[0] = -90.0;
				angle[1] = 0.0;
				angle[2] = 0.0;
						
				new Handle:traceresulthandle = INVALID_HANDLE;
								
				traceresulthandle = TR_TraceRayFilterEx(entityposition, angle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
							
				if(TR_DidHit(traceresulthandle) == true){
								
					new target = TR_GetEntityIndex(traceresulthandle);
								
					if(target >= 1 && target <= MaxClients){
									
						if(isplayerconnectedingamealive(target)){
									
							if(GetClientTeam(target) == 3){
									
								GetClientEyePosition(target, targeteyeposition);
											
								if(100 >= GetVectorDistance(entityposition, targeteyeposition)){
									
									new temphealth = GetEntProp(target, Prop_Data, "m_iHealth");
									
									if(temphealth < GetEntProp(target, Prop_Data, "m_iMaxHealth")){
		
										if(temphealth + 1 < GetEntProp(target, Prop_Data, "m_iMaxHealth")){
												
											SetEntProp(target, Prop_Data, "m_iHealth", temphealth + 1);
												
										}else{
												
											SetEntProp(target, Prop_Data, "m_iHealth", GetEntProp(target, Prop_Data, "m_iMaxHealth"));
											
											//체력을 다 채웠다면 메드킷을 준다
											playerhasmedkit[target] = true;
												
										}
											
										for(new i = 0; i <= 5; i++){
													
											TE_SetupBeamRingPoint(entityposition, 10.0, 100.0, beamsprite, halosprite, 0, 10, 1.0, 10.0, 2.0, blue, 1, 0);
											TE_SendToAll();
											entityposition[2] = entityposition[2] + 20.0;
													
										}
									
									}else{
										
										//체력이 100이더라도, 메드킷이 없다면 줘야한다
										playerhasmedkit[target] = true;
										
									}
											
								}
										
							}
										
						}
										
					}
								
				}
						
				if(traceresulthandle != INVALID_HANDLE){
									
					CloseHandle(traceresulthandle);
									
				}
						
			}
					
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(0.1, activemedistation, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:activerepeater(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//타이머로 지정된 엔티티가 여전히 존재하는지 확인한다
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
			
		//올바른 식별번호를 가진 경우, 무조건 그 건물이 맞다
		if(StrEqual(tempentityname, id, false)){
			
			//리피터는 기능이 없다
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, entity);
			WritePackString(datapack, id);
				
			CreateTimer(1.0, activerepeater, datapack);
				
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action:trapperprojectilecheck(Handle:timer, Handle:data){
	
	//핸들에서 값을 얻는다
	new entity, life, String:id[128];
	ResetPack(data);
	entity = ReadPackCell(data);
	life = ReadPackCell(data);
	ReadPackString(data, id, 128);
	CloseHandle(data);
	
	//엔티티가 존재하는 경우
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
		
		//올바른 식별번호를 가진 경우
		if(StrEqual(tempentityname, id, false)){
		
			if(life >= 1){
			
				decl Float:entityposition[3], Float:temptargetposition[3];
				new bool:foundtarget = false, bool:istarget[MaxClients + 1];
				
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
				
				for(new i = 1; i <= MaxClients; i++){
						
					if(isplayerconnectedingamealive(i) == true){
							
						if(GetClientTeam(i) == 3){
								
							GetClientEyePosition(i, temptargetposition);
							temptargetposition[2] = temptargetposition[2] - 20.0;
											
							new Float:distance = GetVectorDistance(entityposition, temptargetposition);
							
							//100 이하의 위치에 있는 적에게만 반응한다
							if(distance <= 100){
											
								decl Float:resultvector[3], Float:resultangle[3];
													
								MakeVectorFromPoints(entityposition, temptargetposition, resultvector);
								NormalizeVector(resultvector, resultvector);
								GetVectorAngles(resultvector, resultangle);
												
								new Handle:traceresulthandle = INVALID_HANDLE;
								traceresulthandle = TR_TraceRayFilterEx(entityposition, resultangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, entity);
												
								if(TR_DidHit(traceresulthandle) == true){
								
									if(TR_GetEntityIndex(traceresulthandle) == i){
														
										istarget[i] = true;
										foundtarget = true;
														
									}
								
								}
													
								if(traceresulthandle != INVALID_HANDLE){
				
									CloseHandle(traceresulthandle);
				
								}
											
							}
							
						}
							
					}
						
				}
					
				//목표가 있는 경우
				if(foundtarget == true){
					
					createtrappergas(entityposition);
						
					for(new i = 1; i <= MaxClients; i++){
						
						if(isplayerconnectedingamealive(i) == true){
							
							if(GetClientTeam(i) == 3){
								
								if(istarget[i] == true){
												
									playergetadhesiveattack[i] = true;
									
									if(playergetadhesivehandle[i] != INVALID_HANDLE){
									
										KillTimer(playergetadhesivehandle[i]);
										playergetadhesivehandle[i] = INVALID_HANDLE;
										
									}
									
									SetEntityMoveType(i, MOVETYPE_NONE);
									playergetadhesivehandle[i] = CreateTimer(ADHESIVEEFFECTTIME, playergetadhesiveattackdisable, i);
									fademessage(i, 1000, 1000, FFADE_IN, 0, 0, 255, 100);
									
								}
											
							}
							
						}
								
					}
					
					AcceptEntityInput(entity, "Break");
					AcceptEntityInput(entity, "Kill");
						
				}else{
						
					//목표가 없는 경우
					new Handle:datapack = CreateDataPack();
					WritePackCell(datapack, entity);
					WritePackCell(datapack, life - 1);
					WritePackString(datapack, id);
									
					CreateTimer(0.1, trapperprojectilecheck, datapack);
						
				}
				
			}else{
				
				AcceptEntityInput(entity, "Break");
				AcceptEntityInput(entity, "Kill");
				
			}
						
		}
					
	}
	
	return Plugin_Handled;
	
}

public createtrappergas(Float:position[3]){
	
	new String:positionstring[128];
	
	Format(positionstring, 128, "%f %f %f", position[0], position[1], position[2]);
	
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"Origin", positionstring);
	DispatchKeyValue(gascloud,"SpreadSpeed", "10");
	DispatchKeyValue(gascloud,"Speed", "160");
	DispatchKeyValue(gascloud,"StartSize", "20");
	DispatchKeyValue(gascloud,"BaseSpread", "30");
	DispatchKeyValue(gascloud,"EndSize", "60");
	DispatchKeyValue(gascloud,"Rate", "60");
	DispatchKeyValue(gascloud,"JetLength", "100");
	DispatchKeyValue(gascloud,"Twist", "30");
	DispatchKeyValue(gascloud,"RenderColor", "0 0 255");
	DispatchKeyValue(gascloud,"RenderAmt", "100");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	CreateTimer(1.0, disablegas, gascloud);
	
}

//건물을 인덱스캐시에 등록하는 함수
//등록 성공시엔 true, 실패시엔 false를 돌려준다
public bool:structureregistration(entity){
	
	//엔티티가 인간의 건물인지 에일리언의 건물인지 확인한다
	new userid, type, status;
	
	getentityidentificationdata(entity, userid, type, status);
	
	//에일리언의 건물인 경우
	if(type >= OVERMIND && type <= HIVE){
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
			
			//캐시에 이미 등록하려는 엔티티가 등록되있는 경우
			if(structurecacheinfo[ALIENSTRUCTURECACHE][i] == entity){
				
				return true;
				
			}
				
		}
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
			
			new bool:isusedindex = false;
			
			//캐시에 등록된 것이 있을 경우
			if(structurecacheinfo[ALIENSTRUCTURECACHE][i] != 0){
				
				//캐시에 등록된 엔티티가 존재할 경우
				if(IsValidEntity(structurecacheinfo[ALIENSTRUCTURECACHE][i]) == true){
					
					//올바른 트레뮬로우스의 엔티티인지 체크한다
					if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], userid, type, status)){
						
						//건물인지 체크한다
						if(type >= OVERMIND && type <= HIVE){
							
							isusedindex = true;
							
						}
					
					}
					
				}
				
			}
			
			//사용된 인덱스가 아닐 경우
			if(isusedindex == false){
				
				//엔티티를 캐시에 저장해둔다
				structurecacheinfo[ALIENSTRUCTURECACHE][i] = entity;
				return true;
				
			}
			
		}
		
	}else if(type >= REACTOR && type <= REPEATER){
		
		//인간의 건물인 경우	
		for(new i = 0; i < INDEXCACHESIZE; i++){
			
			new bool:isusedindex = false;
			
			//캐시에 등록된 것이 있을 경우
			if(structurecacheinfo[HUMANSTRUCTURECACHE][i] != 0){
				
				//캐시에 등록된 엔티티가 존재할 경우
				if(IsValidEntity(structurecacheinfo[HUMANSTRUCTURECACHE][i]) == true){
					
					//올바른 트레뮬로우스의 엔티티인지 체크한다
					if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], userid, type, status)){
						
						//건물인지 체크한다
						if(type >= REACTOR && type <= REPEATER){
							
							isusedindex = true;
							
						}
					
					}
					
				}
				
			}
			
			//사용된 인덱스가 아닐 경우
			if(isusedindex == false){
				
				//엔티티를 캐시에 저장해둔다
				structurecacheinfo[HUMANSTRUCTURECACHE][i] = entity;
				return true;
				
			}
			
		}
		
	}
	
	return false;
	
}

//기타 함수들

//엔티티식별문자에 관한 주석
//엔티티식별문자는 다음과 같이 만든다.
//Format(buffer, maxLength, "tremulousentity %d %f %f %s %d", userid, GetEngineTime(), GetRandomFloat(0.0, 1.0), entitytype, status);
//client는 그 엔티티를 만들어지게 한 클라이언트
//엔티티 식별 번호를 만드는 함수
public createentityidentification(client, type, status, String:buffer[], maxLength){
	
	decl userid;
	
	if(client != 0){
		
		userid = GetClientUserId(client);
		
	}else{
		
		userid = 0;
		
	}
	
	Format(buffer, maxLength, "tremulousentity %d %f %f %d %d", userid, GetEngineTime(), GetRandomFloat(0.0, 1.0), type, status);
	
}

//엔티티 식별 번호로부터 데이터를 읽어들이는 함수
//올바른 트레뮬로우스의 엔티티일 경우 참을 아닐 경우 거짓을
//넘겨준 변수들에는 데이터를 저장한다
//엔티티는 유저아이디, 타입, 상태 세가지의 정보를 저장한다
public bool:getentityidentificationdata(entity, &userid, &type, &status){
	
	//엔티티가 존재할 경우
	if(IsValidEntity(entity) == true){
			
		decl String:tempentityname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", tempentityname, sizeof(tempentityname));
		
		new String:tempdata[6][128];
		
		ExplodeString(tempentityname, " ", tempdata, 6, 128);
		
		//트레뮬로우스의 엔티티가 아닐 경우
		if(StrEqual(tempdata[0], "tremulousentity", false) == false){
			
			return false;
			
		}
		
		//유저id
		userid = StringToInt(tempdata[1]);
		
		//엔티티타입을 돌려준다
		type = StringToInt(tempdata[4]);
		
		status = StringToInt(tempdata[5]);
		
		return true;
		
	}else{
		
		return false;
		
	}
	
}

//트레이스레이필터
public bool:tracerayfilterdefault(entity, mask, any:data){
	
	if(entity != data){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//건설용트레이스레이필터
public bool:buildtracerayfilter(entity, mask, any:data){
	
	//엔티티가 건설중인 클라이언트와 클라이언트가 건설중인 건물이 아닌 경우
	if(entity != data && entity != playerisconstructing[data]){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//지형을 제외한 모든 것을 걸러내는 트레이스필터
//이것은 건물이 땅으로부터 얼마나 떨어졌는가를 확인하는데 쓰인다
public bool:worldtracerayfilter(entity, mask, any:data){
	
	//지면일 경우
	if(entity != data && entity == 0){
		
		return true;
		
	}else{
		
		return false;

	}
	
}

//지형과 에그, 오버마인드를 제외하고 모든 것을 거르는 필터
//이것은 건물이 리엑터와같은 건물과 벽으로 사이가 막혀있지 않은지 판별하는데 쓰인다
public bool:alienstructuretracerayfilter(entity, mask, any:data){
	
	//일단 시작점의 엔티티는 아닐 경우
	if(entity != data){
		
		decl userid, type, status;
		
		if(getentityidentificationdata(entity, userid, type, status)){
			
			if(type == OVERMIND || type == EGG){
				
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

//지형과 에그, 오버마인드, 위치 설정중인 건물을 제외하고 모든 것을 거르는 필터
//이것은 건물이 리엑터와같은 건물과 벽으로 사이가 막혀있지 않은지 판별하는데 쓰인다
public bool:humanstructuretracerayfilter(entity, mask, any:data){
	
	//일단 시작점의 엔티티는 아닐 경우
	if(entity != data){
		
		decl userid, type, status;
		
		if(getentityidentificationdata(entity, userid, type, status)){
			
			if(type == REACTOR || type == REPEATER){
				
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

//클라이언트 상태 체크 3개를 한꺼번에 해주는 함수
public bool:isplayerconnectedingamealive(client){
	
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
	
}

//클라이언트 상태 체크 2개를 한꺼번에 해주는 함수
//클라이언트가 게임 안에 있는지까지 검사한다.
public bool:isplayerconnectedingame(client){
	
	if(IsClientConnected(client) == true){
		
		if(IsClientInGame(client) == true){
		
			return true;
			
		}else{
			
			return false;
			
		}
		
	}else{
				
		return false;
				
	}
	
}

//재정의된 데스이벤트를 지원하는 함수
//hl2:mp의 규칙을 따라서, 아머는 80퍼센트의 데미지를 흡수한다.
//예 : 체력 100, 아머 100일 경우 100의 공격력은 아머를 모두 제거하고, 헬스는 20이 깎인다.
//hl2:mp와 cs:s에서는 작동하겠지만, 그 이외의 모드에서는 작동을 보장할 수 없다.
public damageresulttype:makedamage(client, target, damage, String:weapon[64], Float:attackposition[3]){
	
	//피해자가 적합한 클라이언트인 경우
	if(target >= 1 && target <= MaxClients){
		
		//피해자는 반드시 살아있어야한다
		if(isplayerconnectedingamealive(target)){
			
			decl m_iarmor, m_ihealth, damageresult, resultarmor, resulthealth;
			
			m_iarmor = GetEntProp(target, Prop_Data, "m_ArmorValue");
			m_ihealth = GetEntProp(target, Prop_Data, "m_iHealth");
			
			//가해지는 데미지의 총 합을 구한다. 물론 양수로 구해야한다. 아머의 방어율은 물론 80퍼센트
			//우선 아머가 방어해주지 못하는 데미지를 구한다
			
			resultarmor = m_iarmor - damage;
			
			//방어한 뒤의 아머가 0이거나 큰 경우, 즉 모든 공격이 아머로 막힌 경우엔 단지 데미지의 20퍼센트만 입는다
			if(resultarmor >= 0){
				
				damageresult = RoundFloat(damage / 5.0);
				
			}else{
				
				//데미지가 아머에 의해 모두 흡수되지 못한 경우
				//resultarmor가 0이 되는 경우는 위쪽에서 처리햇으므로 음수인 경우만 따지므로 이것을 양수로 바꿔주면 아머가 방어해주지 못한 데미지를 구하는것이다.
				//이때 아머는 0이 아닌 이상 데미지를 흡수했을 것이므로, 이것도 계산해준다.
				
				damageresult = -resultarmor + RoundFloat(m_iarmor / 5.0);
				
			}
			
			resulthealth = m_ihealth - damageresult;
			
			//살아남는 경우
			if(resulthealth > 0){
				
				if(resultarmor > 0){
				
					SetEntProp(target, Prop_Data, "m_ArmorValue", resultarmor);
					
				}else{
					
					SetEntProp(target, Prop_Data, "m_ArmorValue", 0);
					
				}
				
				decl String:name[64];
				
				GetClientAuthString(target, name, 64);
				
				DispatchKeyValue(target,"TargetName", name);
				
				new pointhurt = CreateEntityByName("point_hurt");
				
				decl String:positionstring[128];
	
				Format(positionstring, 128, "%f %f %f", attackposition[0], attackposition[1], attackposition[2]);
				
				DispatchKeyValue(pointhurt,"Origin", positionstring);
				
				decl String:number[64];
				
				IntToString(damageresult, number, 64);
				
				DispatchKeyValue(pointhurt,"Damage", number);
				
				IntToString(DMG_FALL, number, 64);
				
				DispatchKeyValue(pointhurt,"DamageType", number);
				DispatchKeyValue(pointhurt,"DamageTarget", name);
				DispatchSpawn(pointhurt);
				
				if(client >= 1 && client <= MaxClients){
				
					if(isplayerconnectedingame(client)){
					
						AcceptEntityInput(pointhurt, "Hurt", client);
						
					}else{
						
						AcceptEntityInput(pointhurt, "Hurt", 0);
						
					}
				
				}else if(client == 0){
					
					AcceptEntityInput(pointhurt, "Hurt", 0);
					
				}else{
					
					//공격자가 올바르지 않을 경우
					return RESULT_FAILED;
					
				}
					
				AcceptEntityInput(pointhurt, "Kill");
				
				playerlasthurttime[target] = GetGameTime();
				
				return RESULT_ALIVE;
				
			}else{
				
				//죽는 경우
				haskilledbysystemevent[target] = true;
				
				decl String:name[64];
				
				GetClientAuthString(target, name, 64);
				
				DispatchKeyValue(target,"TargetName", name);
				
				new pointhurt = CreateEntityByName("point_hurt");
				
				decl String:positionstring[128];
	
				Format(positionstring, 128, "%f %f %f", attackposition[0], attackposition[1], attackposition[2]);
				
				DispatchKeyValue(pointhurt,"Origin", positionstring);
				
				decl String:number[64];
				
				IntToString(damageresult, number, 64);
				
				DispatchKeyValue(pointhurt,"Damage", number);
				
				IntToString(DMG_FALL, number, 64);
				
				DispatchKeyValue(pointhurt,"DamageType", number);
				DispatchKeyValue(pointhurt,"DamageTarget", name);
				DispatchSpawn(pointhurt);
				
				if(client >= 1 && client <= MaxClients){
				
					if(isplayerconnectedingame(client)){
					
						AcceptEntityInput(pointhurt, "Hurt", client);
						
					}else{
						
						AcceptEntityInput(pointhurt, "Hurt", 0);
						
					}
				
				}else if(client == 0){
					
					AcceptEntityInput(pointhurt, "Hurt", 0);
					
				}else{
					
					//공격자가 올바르지 않을 경우
					AcceptEntityInput(pointhurt, "Kill");
					return RESULT_FAILED;
					
				}
				
				AcceptEntityInput(pointhurt, "Kill");
				
				new Handle:event = CreateEvent("player_death");
						
				if(event == INVALID_HANDLE){
					
					//모드에서 데스이벤트를 지원하지 않는 경우
					return RESULT_FAILED;
							
				}
						
				SetEventInt(event, "userid", GetClientUserId(target));
				
				if(client == 0){
					
					SetEventInt(event, "attacker", 0);
					
				}else{
					
					SetEventInt(event, "attacker", GetClientUserId(client));
					
				}
				
				SetEventString(event, "weapon", weapon);
				
				//cs:s를 위한 추가적인 구현
				if(servergametype == GAMETYPE_CSS){
						
					SetEventBool(event, "headshot", false);
						
				}
				
				FireEvent(event);
				
				playerlasthurttime[target] = GetGameTime();
				
				return RESULT_DEAD;
				
			}
			
		}else{
			
			return RESULT_FAILED;
			
		}
		
	}else{
		
		//피해자가 모두 올바른 클라이언트가 아닌 경우
		return RESULT_FAILED;
		
	}
	
}

//인덱스캐시 초기화
public resetcache(){
	
	for(new i = 0; i < INDEXCACHESIZE; i++){
		
		structurecacheinfo[ALIENSTRUCTURECACHE][i] = 0;
		structurecacheinfo[HUMANSTRUCTURECACHE][i] = 0;
		
	}
	
}

//건설을 할 수 있는지를 알려주는 함수
//이 함수는 플레이어가 건설을 시작하려고 할 때 호출되어서, 건설을 할 수 있는 상황인지 아닌지를 판별해서 참 거짓을 돌려준다
//단, 건물이 그 위치에 건설될 수 있는지, 그 건물을 지을 수 있는 레벨인지는 판별하지 않는다
//이 함수는 플레이어가 건설을 할 수 있는 클래스라고 가정한다
public buildchecktype:canstartconstruct(type){
	
	new buildchecktype:check;
	
	//건물에 대해 문의하는지 확인
	if(type >= OVERMIND && type <= REPEATER){
		
		//오버마인드를 지으려고 시도하는 경우
		if(type == OVERMIND){
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_OK;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				return RESULT_OVERMINDEXIST;
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  EGG){//에그를 지으려고 하는 경우
			
			//에그를 지을 수 있는 조건:
			//작동중인 오버마인드가 있을 것, 건물 최대 건설 수치를 넘지 말것
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[EGG] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  ACIDTUBE){//에시드튜브를 지으려고 하는 경우
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[ACIDTUBE] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  BARRICADE){//바리케이트
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[BARRICADE] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  TRAPPER){//트래퍼
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[TRAPPER] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  BOOSTER){//부스터
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[BOOSTER] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  HOVEL){//호벨
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[HOVEL] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  HIVE){//하이브
			
			check = getovermindstatus();
			
			if(check == RESULT_NO_OVERMIND){
			
				return RESULT_NO_OVERMIND;
				
			}else if(check == RESULT_OVERMINDEXIST){
				
				if(getusedstructurepoint(ALIENSTRUCTURECACHE) + structurepoint[HIVE] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_OVERMINDINBUILD){
				
				return RESULT_OVERMINDINBUILD;
				
			}
			
		}else if(type ==  REACTOR){//리엑터
			
			//리엑터가 지어질 수 있는 조건은 간단하다. 다른 리엑터만 없으면 된다
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_OK;
				
			}else if(check == RESULT_REACTOREXIST){
				
				return RESULT_REACTOREXIST;
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  TELENODE){//텔레노드
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[TELENODE] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  MACHINEGUNTURRET){//머신건터렛
				
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[MACHINEGUNTURRET] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  TESLAGENERATOR){//테슬라제네레이터
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getworkablestructure(DEFENCECOMPUTER)){
				
					if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[TESLAGENERATOR] <= maxstructurepoint[techlevel]){
						
						return RESULT_OK;
						
					}else{
						
						return RESULT_NO_POINT;
						
					}
					
				}else{
					
					return RESULT_NO_TECH;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  ARMOURY){//아머리
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[ARMOURY] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  DEFENCECOMPUTER){//디펜스컴퓨터
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[DEFENCECOMPUTER] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  MEDISTATION){//메디스테이션
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[MEDISTATION] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}else if(type ==  REPEATER){//리피터
			
			check = getreactorstatus();
			
			if(check == RESULT_NO_REACTOR){
			
				return RESULT_NO_REACTOR;
				
			}else if(check == RESULT_REACTOREXIST){
				
				if(getusedstructurepoint(HUMANSTRUCTURECACHE) + structurepoint[REPEATER] <= maxstructurepoint[techlevel]){
					
					return RESULT_OK;
					
				}else{
					
					return RESULT_NO_POINT;
					
				}
				
			}else if(check == RESULT_REACTORINBUILD){
				
				return RESULT_REACTORINBUILD;
				
			}
			
		}
		
	}
	
	//기본적으로 RESULT_NO를 반환한다
	return RESULT_NO;
	
}


//사용된 건물 수치를 돌려주는 함수, 각 팀별로 따로 해야 한다
public getusedstructurepoint(cachetype){
	
	new totalpoint = 0;
	new userid, type, status;
	
	if(cachetype == ALIENSTRUCTURECACHE){
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
				
			//건물 정보를 얻어올 수 있을 경우
			if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], userid, type, status)){
				
				if(status != STATUS_NOTSTRUCTURE && status != STATUS_INCONSTRUCTQUEUE){
				
					if(type == OVERMIND){
						
						//오버마인드는 포인트를 쓰지 않는다
						
					}else if(type ==  EGG){//에그
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  ACIDTUBE){//에시드튜브
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  BARRICADE){//바리케이트
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  TRAPPER){//트래퍼
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  BOOSTER){//부스터
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  HOVEL){//호벨
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  HIVE){//하이브
						
						totalpoint = totalpoint + 10;
						
					}
				
				}
					
			}	
				
		}
		
		return totalpoint;
		
	}else if(cachetype == HUMANSTRUCTURECACHE){
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
				
			//건물 정보를 얻어올 수 있을 경우
			if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], userid, type, status)){
				
				if(status != STATUS_NOTSTRUCTURE && status != STATUS_INCONSTRUCTQUEUE){
				
					if(type ==  REACTOR){//리엑터
						
						//리엑터는 포인트를 소모하지 않는다
						
					}else if(type ==  TELENODE){//텔레노드
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  MACHINEGUNTURRET){//머신건터렛
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  TESLAGENERATOR){//테슬라제네레이터
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  ARMOURY){//아머리
						
						totalpoint = totalpoint + 10;
						
					}else if(type ==  DEFENCECOMPUTER){//디펜스컴퓨터
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  MEDISTATION){//메디스테이션
						
						totalpoint = totalpoint + 8;
						
					}else if(type ==  REPEATER){//리피터
						
						totalpoint = totalpoint + 8;
						
					}
					
				}
				
			}
			
		}
		
		return totalpoint;
		
	}else{
		
		//잘못된 캐시 번호에 대해선 -1을 돌려준다
		return -1;
		
	}
	
}

//지정한 종류의 작동 중인 건물이 있는지 알아온다
//캐시타입은 접근할 캐시, 타입은 찾을 건물의 종류
public bool:getworkablestructure(type){
	
	new userid, entitytype, status;
	
	//에일리언의 건물일 경우
	if(type >= OVERMIND && type <= HIVE){
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
				
			//건물 정보를 얻어올 수 있을 경우
			if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], userid, entitytype, status)){
					
				if(entitytype == type){
					
					//원하는 타입과 같은 경우
					
					//작동하는 경우
					if(status == STATUS_FUNCTIONING){
						
						return true;
						
					}
					
				}
					
			}
				
		}
		
		return false;
		
	}else if(type >= REACTOR && type <= REPEATER){
		
		for(new i = 0; i < INDEXCACHESIZE; i++){
				
			//건물 정보를 얻어올 수 있을 경우
			if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], userid, entitytype, status)){
				
				if(entitytype ==  type){
					
					//원하는 타입을 찾은 경우
					
					if(status == STATUS_FUNCTIONING){
						
						return true;
						
					}
					
				}
				
			}
			
		}
		
		return false;
		
	}else{
		
		//잘못된 타입에 대해선 거짓을 돌려준다
		return false;
		
	}
	
}

//오버마인드의 상태만을 확인하는 전용 함수
public buildchecktype:getovermindstatus(){
	
	new userid, entitytype, status;
	
	for(new i = 0; i < INDEXCACHESIZE; i++){
				
		//건물 정보를 얻어올 수 있을 경우
		if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], userid, entitytype, status)){
						
			if(entitytype == OVERMIND){
							
				if(status == STATUS_INCONSTRUCTING){
							
					return RESULT_OVERMINDINBUILD;
								
				}else if(status == STATUS_FUNCTIONING){
					
					return RESULT_OVERMINDEXIST;
					
				}
							
			}
						
		}
					
	}
	
	return RESULT_NO_OVERMIND;
	
}

//리엑터의 상태만을 확인하는 전용 함수
public buildchecktype:getreactorstatus(){
	
	new userid, entitytype, status;
	
	for(new i = 0; i < INDEXCACHESIZE; i++){
				
		//건물 정보를 얻어올 수 있을 경우
		if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], userid, entitytype, status)){
						
			if(entitytype == REACTOR){
							
				if(status == STATUS_INCONSTRUCTING){
								
					return RESULT_REACTORINBUILD;
								
				}else if(status == STATUS_FUNCTIONING){
					
					return RESULT_REACTOREXIST;
					
				}
							
			}
						
		}
					
	}
	
	return RESULT_NO_REACTOR;
	
}

//지정한 건물 엔티티가 작동 가능한지를 검사한다
//이것은 건물이 오버마인드나 에그, 리엑터나 리피터에 의해 전력이나 통제력을 공급받고 있는지를 확인한다
//에그와 텔레노드는 그것이 어디에 존재하건 작동한다.
//그러나 텔레노드는 이 함수를 오직 건설할 때에만 써야한다.
//텔레노드는 리엑터 없이도 작동하지만, 건설은 리엑터와 리피터의 효과범위 안에만 할수 있기 때문이다
public bool:getpowerstatus(entity){
	
	//의뢰한 엔티티가 존재하는지, 존재한다면 어떤 종류의 엔티티인지 판별한다
	new userid, type, status;
	
	if(getentityidentificationdata(entity, userid, type, status)){
		
		//엔티티가 존재한다면, 엔티티의 정보를 얻어와서 그 엔티티가 어느 팀의 건물인지 파악한다
		
		//에일리언의 건물일 경우
		if(type >= ACIDTUBE && type <= HIVE){
			
			//우선 작동중인 오버마인드가 있는지 확인한다. 오버마인드가 없으면, 에그를 제외한 모든 건물은 작동하지 않는다
			if(getworkablestructure(OVERMIND)){
				
				//작동중인 오버마인드가 있다면, 엔티티가 오버마인드나 에그로부터 600이하의 거리에 있는지 확인한다
				decl Float:entityposition[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
				
				for(new i = 0; i < INDEXCACHESIZE; i++){
					
					decl targetentityuserid, targetentitytype, targetentitystatus;
					
					//건물 정보를 얻어올 수 있을 경우
					if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], targetentityuserid, targetentitytype, targetentitystatus)){
						
						//원하는 타입을 찾은 경우
						if(targetentitytype ==  OVERMIND || targetentitytype == EGG){
							
							//작동중인 경우
							if(targetentitystatus == STATUS_FUNCTIONING){
								
								//거리가 600이하이고, 벽으로 가로막혀 있지 않은지 검사한다
								decl Float:targetposition[3];
								GetEntPropVector(structurecacheinfo[ALIENSTRUCTURECACHE][i], Prop_Send, "m_vecOrigin", targetposition);
								
								if(GetVectorDistance(entityposition, targetposition) <= 600){
									
									new Float:resultvector[3], Float:resultangle[3];
									
									MakeVectorFromPoints(entityposition, targetposition, resultvector);
									GetVectorAngles(resultvector, resultangle);
									
									new Handle:traceresulthandle = INVALID_HANDLE;
									
									traceresulthandle = TR_TraceRayFilterEx(entityposition, resultangle, MASK_SOLID, RayType_Infinite, alienstructuretracerayfilter, entity);
									
									if(TR_DidHit(traceresulthandle) == true){
											
										if(TR_GetEntityIndex(traceresulthandle) == structurecacheinfo[ALIENSTRUCTURECACHE][i]){
											
											//반드시 닫아야 한다
											CloseHandle(traceresulthandle);
											
											return true;
											
										}
											
									}
									
									if(traceresulthandle != INVALID_HANDLE){
									
										CloseHandle(traceresulthandle);
									
									}
									
								}
								
							}
							
						}
						
					}
					
				}
				
				return false;
				
			}else{
				
				//작동중인 오버마인드가 없으므로 모든 건물은 작동할 수 없다
				return false;
				
			}
			
		}else if(type >= TELENODE && type <= MEDISTATION){//인간의 건물인 경우
			
			//우선 작동중인 리엑터가 있는지 확인한다. 리엑터가 없으면, 텔레노드를 제외한 모든 건물은 작동하지 않는다
			if(getworkablestructure(REACTOR)){
				
				//작동중인 리엑터가 있다면, 엔티티가 리엑터나 리피터로부터 600이하의 거리에 있는지 확인한다
				decl Float:entityposition[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
				
				for(new i = 0; i < INDEXCACHESIZE; i++){
					
					decl targetentityuserid, targetentitytype, targetentitystatus;
					
					//건물 정보를 얻어올 수 있을 경우
					if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], targetentityuserid, targetentitytype, targetentitystatus)){
						
						//원하는 타입을 찾은 경우
						if(targetentitytype ==  REACTOR || targetentitytype == REPEATER){
							
							//작동중인 경우
							if(targetentitystatus == STATUS_FUNCTIONING){
								
								//거리가 600이하이고, 벽으로 가로막혀 있지 않은지 검사한다
								decl Float:targetposition[3];
								GetEntPropVector(structurecacheinfo[HUMANSTRUCTURECACHE][i], Prop_Send, "m_vecOrigin", targetposition);
								
								if(GetVectorDistance(entityposition, targetposition) <= 600){
									
									new Float:resultvector[3], Float:resultangle[3];
									
									MakeVectorFromPoints(entityposition, targetposition, resultvector);
									GetVectorAngles(resultvector, resultangle);
									
									new Handle:traceresulthandle = INVALID_HANDLE;
									
									traceresulthandle = TR_TraceRayFilterEx(entityposition, resultangle, MASK_SOLID, RayType_Infinite, humanstructuretracerayfilter, entity);
									
									if(TR_DidHit(traceresulthandle) == true){
											
										if(TR_GetEntityIndex(traceresulthandle) == structurecacheinfo[HUMANSTRUCTURECACHE][i]){
											
											CloseHandle(traceresulthandle);
											return true;
											
										}
											
									}
									
									if(traceresulthandle != INVALID_HANDLE){
									
										CloseHandle(traceresulthandle);
									
									}
									
								}
								
							}
							
						}
						
					}
					
				}
				
				return false;
				
			}else{
				
				//작동중인 리엑터가 없으므로 모든 건물은 작동할 수 없다
				return false;
				
			}
			
		}else if(type == OVERMIND || type == REACTOR){
			
			//이 두가지는 언제나 파워를 가진다
			return true;
			
		}else if(type == REPEATER){
			
			if(getworkablestructure(REACTOR)){
				
				return true;
				
			}else{
				
				return false;
				
			}
			
		}else if(type == EGG){
			
			if(getworkablestructure(OVERMIND)){
				
				return true;
				
			}else{
				
				return false;
				
			}
			
		}
		
	}
	
	return false;
	
}

//명령어에 대한 처리

//건설 명령어
public Action:command_construction(client, args){
	
	if(isplayerconnectedingamealive(client)){
		
		new team = GetClientTeam(client);
		
		//에일리언의 경우
		if(team == 2){
			
			if(playerclass[client] == GRANGER || playerclass[client] == ADVANCEDGRANGER || loadstatus == NODATA){
				
				if(args <= 1){
					
					//메뉴를 띄워주어야 할 상황이다
					if(args == 0){
						
						//메뉴는 아직 안되있어
						PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
						PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
						PrintToChat(client, "\x04가능한 건물이름 : 오버마인드[1], 에그[2], 에시드튜브[3], 바리케이트[4]");
						PrintToChat(client, "\x04				   트래퍼[5], 부스터[6], 호벨[7], 하이브[8]");
						return Plugin_Handled;
						
					}
					
					//메뉴를 띄워주지 않을 경우, 명령어에 인수로 전달된 것을 비교해서 작동한다
					decl String:argstring[32];
					GetCmdArg(1, argstring, sizeof(argstring));
					
					if(StrEqual(argstring, "오버마인드", false) || StrEqual(argstring, "1", false)){
						
						startconstruction(client, OVERMIND);
						
					}else if(StrEqual(argstring, "에그", false) || StrEqual(argstring, "2", false)){
						
						startconstruction(client, EGG);
						
					}else if(StrEqual(argstring, "에시드튜브", false) || StrEqual(argstring, "3", false)){
						
						startconstruction(client, ACIDTUBE);
						
					}else if(StrEqual(argstring, "바리케이트", false) || StrEqual(argstring, "4", false)){
						
						startconstruction(client, BARRICADE);
						
					}else if(StrEqual(argstring, "트래퍼", false) || StrEqual(argstring, "5", false)){
						
						if(techlevel >= 2){
						
							startconstruction(client, TRAPPER);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 2 이상이어야 합니다");
							
						}
						
					}else if(StrEqual(argstring, "부스터", false) || StrEqual(argstring, "6", false)){
						
						if(techlevel >= 2){
						
							startconstruction(client, BOOSTER);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 2 이상이어야 합니다");
							
						}
						
					}else if(StrEqual(argstring, "호벨", false) || StrEqual(argstring, "7", false)){
						
						startconstruction(client, HOVEL);
						
					}else if(StrEqual(argstring, "하이브", false) || StrEqual(argstring, "8", false)){
						
						if(techlevel == 3){
						
							startconstruction(client, HIVE);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 3 이어야 합니다");
							
						}
						
					}else{
						
						PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
						PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
						PrintToChat(client, "\x04가능한 건물이름 : 오버마인드[1], 에그[2], 에시드튜브[3], 바리케이트[4]");
						PrintToChat(client, "\x04				   트래퍼[5], 부스터[6], 호벨[7], 하이브[8]");
						
					}
					
					
				}else{
					
					PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
					PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
					PrintToChat(client, "\x04가능한 건물이름 : 오버마인드[1], 에그[2], 에시드튜브[3], 바리케이트[4]");
					PrintToChat(client, "\x04				   트래퍼[5], 부스터[6], 호벨[7], 하이브[8]");
					
				}
				
			}else{
				
				PrintToChat(client, "\x04건설 가능한 클래스만이 건물을 지을 수 있습니다");
				
			}
			
		}else if(team == 3){
			
			if(playerclass[client] == HUMANBUILDER || loadstatus == NODATA){
				
				if(args <= 1){
					
					//메뉴를 띄워주어야 할 상황이다
					if(args == 0){
						
						//아직 안되있다고!
						PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
						PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
						PrintToChat(client, "\x04가능한 건물이름 : 리엑터[1], 텔레노드[2], 머신건터렛[3], 테슬라제네레이터[4]");
						PrintToChat(client, "\x04				   아머리[5], 디펜스컴퓨터[6], 메디스테이션[7], 리피터[8]");
						return Plugin_Handled;
						
					}
					
					//메뉴를 띄워주지 않을 경우, 명령어에 인수로 전달된 것을 비교해서 작동한다
					decl String:argstring[32];
					GetCmdArg(1, argstring, sizeof(argstring));
					
					if(StrEqual(argstring, "리엑터", false) || StrEqual(argstring, "1", false)){
						
						startconstruction(client, REACTOR);
						
					}else if(StrEqual(argstring, "텔레노드", false) || StrEqual(argstring, "2", false)){
						
						startconstruction(client, TELENODE);
						
					}else if(StrEqual(argstring, "머신건터렛", false) || StrEqual(argstring, "3", false)){
						
						startconstruction(client, MACHINEGUNTURRET);
						
					}else if(StrEqual(argstring, "테슬라제네레이터", false) || StrEqual(argstring, "4", false)){
						
						if(techlevel == 3){
						
							startconstruction(client, TESLAGENERATOR);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 3 이어야 합니다");
							
						}
						
					}else if(StrEqual(argstring, "아머리", false) || StrEqual(argstring, "5", false)){
						
						startconstruction(client, ARMOURY);
						
					}else if(StrEqual(argstring, "디펜스컴퓨터", false) || StrEqual(argstring, "6", false)){
						
						if(techlevel >= 2){
						
							startconstruction(client, DEFENCECOMPUTER);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 2 이상이어야 합니다");
							
						}
						
					}else if(StrEqual(argstring, "메디스테이션", false) || StrEqual(argstring, "7", false)){
						
						startconstruction(client, MEDISTATION);
						
					}else if(StrEqual(argstring, "리피터", false) || StrEqual(argstring, "8", false)){
						
						if(techlevel >= 2){
						
							startconstruction(client, REPEATER);
							
						}else{
							
							PrintToChat(client, "\x04그 건물을 짓기 위해선 테크레벨이 2 이상이어야 합니다");
							
						}
						
					}else{
						
						PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
						PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
						PrintToChat(client, "\x04가능한 건물이름 : 리엑터[1], 텔레노드[2], 머신건터렛[3], 테슬라제네레이터[4]");
						PrintToChat(client, "\x04				   아머리[5], 디펜스컴퓨터[6], 메디스테이션[7], 리피터[8]");
						
					}
					
				}else{
					
					PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
					PrintToChat(client, "\x04사용법 : !건설 <건물이름> 혹은 !건설 <건물단축번호> 혹은 !건설");
					PrintToChat(client, "\x04가능한 건물이름 : 리엑터[1], 텔레노드[2], 머신건터렛[3], 테슬라제네레이터[4]");
					PrintToChat(client, "\x04				   아머리[5], 디펜스컴퓨터[6], 메디스테이션[7], 리피터[8]");
					
				}
				
			}else{
				
				PrintToChat(client, "\x04건설 가능한 클래스만이 건물을 지을 수 있습니다");
				
			}
			
		}
		
	}
	
	return Plugin_Handled;
	
}

//건설 취소 명령어
public Action:command_calcelconstruction(client, args){
	
	constructcancel[client] = true;
	
	return Plugin_Handled;
	
}

//건설 확정 명령어
public Action:command_confirmconstruction(client, args){
	
	constructconfirm[client] = true;
	
	return Plugin_Handled;
	
}

//메드킷 사용 명령어
public Action:command_usemedkit(client, args){
	
	if(isplayerconnectedingamealive(client)){
		
		//인간만 가능
		if(GetClientTeam(client) == 3){
			
			if(playerhasmedkit[client] == true){
				
				PrintToChat(client, "\x04메드킷을 사용하셨습니다");
				playerhasmedkit[client] = false;
				playerusedmedkit[client] = true;
				playergetpoisonattack[client] = 0;
				
				CreateTimer(30.0, playerusedmedkitdisable, client);
				
			}else{
				
				PrintToChat(client, "\x04메드킷을 가지고있지 않습니다");
				
			}
			
		}else{
			
			PrintToChat(client, "\x04메드킷은 인간만 사용 가능합니다");
			
		}
		
	}
	
	return Plugin_Handled;
	
}

//진화 명령어
public Action:command_useevolution(client, args){
	
	if(isplayerconnectedingamealive(client)){
		
		//에일리언만 가능
		if(GetClientTeam(client) == 2){
			
			if(args <= 1){
						
				//메뉴를 띄워주어야 할 상황이다
				if(args == 0){
							
					PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
					PrintToChat(client, "\x04사용법 : !진화 <클래스이름> 혹은 !진화 <클래스단축번호> 혹은 !진화");
					PrintToChat(client, "\x04가능한 클래스이름 : 드렛치[1], 바실리스크[2], 어드벤스드바실리스크[3], 마라우더[4]");
					PrintToChat(client, "\x04				   어드벤스드마라우더[5], 드라군[6], 어드벤스드드라군[7], 타이란트[8]");
					
					//메뉴는 아직 안되있어
					return Plugin_Handled;
							
				}
						
				//메뉴를 띄워주지 않을 경우, 명령어에 인수로 전달된 것을 비교해서 작동한다
				decl String:argstring[32];
				GetCmdArg(1, argstring, sizeof(argstring));
						
				if(StrEqual(argstring, "드렛치", false) || StrEqual(argstring, "1", false)){
							
					if(playerclass[client] < DRETCH){
						
						if(getworkablestructure(OVERMIND)){
						
							PrintToChat(client, "\x04드렛치로 진화했습니다");
							playerclass[client] = DRETCH;
							SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
							SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
							
					}else if(playerclass[client] == DRETCH){
						
						PrintToChat(client, "\x04당신은 이미 드렛치입니다");
						
					}else if(playerclass[client] > DRETCH){
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "바실리스크", false) || StrEqual(argstring, "2", false)){
							
					if(playerclass[client] != BASILISK && playerclass[client] != MARAUDER && playerclass[client] != ADVANCEDBASILISK && playerclass[client] != ADVANCEDMARAUDER && playerclass[client] != DRAGOON && playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
						
							if(playercredit[client] >= alienevolvecredit[BASILISK]){
							
								PrintToChat(client, "\x04바실리스크로 진화했습니다");
								playerclass[client] = BASILISK;
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
								SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
								
								playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
							}else{
								
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[BASILISK]);
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == BASILISK){
						
						PrintToChat(client, "\x04당신은 이미 바실리스크입니다");
						
					}else if(playerclass[client] == MARAUDER){
						
						PrintToChat(client, "\x04마라우더에서 바실리스크로 진화할 수 없습니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "어드벤스드바실리스크", false) || StrEqual(argstring, "3", false)){
							
					if(playerclass[client] != ADVANCEDBASILISK && playerclass[client] != MARAUDER && playerclass[client] != ADVANCEDMARAUDER && playerclass[client] != DRAGOON && playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
							
							if(techlevel >= 2){
							
								if(playercredit[client] >= alienevolvecredit[ADVANCEDBASILISK]){
							
									PrintToChat(client, "\x04어드벤스드바실리스크로 진화했습니다");
									playerclass[client] = ADVANCEDBASILISK;
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
									SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
									
									playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[ADVANCEDBASILISK]);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 클래스로 진화하기 위해서는 테크레벨이 2 이상이어야 합니다");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == ADVANCEDBASILISK){
						
						PrintToChat(client, "\x04당신은 이미 어드벤스드바실리스크입니다");
						
					}else if((playerclass[client] == MARAUDER)){
						
						PrintToChat(client, "\x04마라우더에서 어드벤스드바실리스크로 진화할 수 없습니다");
						
					}else if((playerclass[client] == ADVANCEDMARAUDER)){
						
						PrintToChat(client, "\x04어드벤스드마라우더에서 어드벤스드바실리스크로 진화할 수 없습니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "마라우더", false) || StrEqual(argstring, "4", false)){
							
					if(playerclass[client] != BASILISK && playerclass[client] != ADVANCEDBASILISK && playerclass[client] != MARAUDER && playerclass[client] != ADVANCEDMARAUDER && playerclass[client] != DRAGOON && playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
						
							if(playercredit[client] >= alienevolvecredit[MARAUDER]){
							
								PrintToChat(client, "\x04마라우더로 진화했습니다");
								playerclass[client] = MARAUDER;
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
								SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
									
								playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[MARAUDER]);
									
							}
							
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == MARAUDER){
						
						PrintToChat(client, "\x04당신은 이미 바실리스크입니다");
						
					}else if(playerclass[client] == BASILISK){
						
						PrintToChat(client, "\x04바실리스크에서 마라우더로 진화할 수 없습니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "어드벤스드마라우더", false) || StrEqual(argstring, "5", false)){
							
					if(playerclass[client] != BASILISK && playerclass[client] != ADVANCEDBASILISK && playerclass[client] != ADVANCEDMARAUDER && playerclass[client] != DRAGOON && playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
							
							if(techlevel >= 2){
							
								if(playercredit[client] >= alienevolvecredit[ADVANCEDMARAUDER]){
							
									PrintToChat(client, "\x04어드벤스드마라우더로 진화했습니다");
									playerclass[client] = ADVANCEDMARAUDER;
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
									SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
										
									playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[ADVANCEDMARAUDER]);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 클래스로 진화하기 위해서는 테크레벨이 2 이상이어야 합니다");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == ADVANCEDMARAUDER){
						
						PrintToChat(client, "\x04당신은 이미 어드벤스드바실리스크입니다");
						
					}else if((playerclass[client] == BASILISK)){
						
						PrintToChat(client, "\x04바실리스크에서 어드벤스드마라우더로 진화할 수 없습니다");
						
					}else if((playerclass[client] == ADVANCEDMARAUDER)){
						
						PrintToChat(client, "\x04어드벤스드바실리스크에서 어드벤스드마라우더로 진화할 수 없습니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "드라군", false) || StrEqual(argstring, "6", false)){
							
					if(playerclass[client] != DRAGOON && playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
							
							if(techlevel >= 2){
							
								if(playercredit[client] >= alienevolvecredit[DRAGOON]){
							
									PrintToChat(client, "\x04드라군으로 진화했습니다");
									playerclass[client] = DRAGOON;
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
									SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
										
									playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[DRAGOON]);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 클래스로 진화하기 위해서는 테크레벨이 2 이상이어야 합니다");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == DRAGOON){
						
						PrintToChat(client, "\x04당신은 이미 드라군입니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "어드벤스드드라군", false) || StrEqual(argstring, "7", false)){
							
					if(playerclass[client] != ADVANCEDDRAGOON && playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
							
							if(techlevel == 3){
							
								if(playercredit[client] >= alienevolvecredit[ADVANCEDDRAGOON]){
							
									PrintToChat(client, "\x04어드벤스드드라군으로 진화했습니다");
									playerclass[client] = ADVANCEDDRAGOON;
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
									SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
										
									playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[ADVANCEDDRAGOON]);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 클래스로 진화하기 위해서는 테크레벨이 3 이상이어야 합니다");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else if(playerclass[client] == ADVANCEDDRAGOON){
						
						PrintToChat(client, "\x04당신은 이미 어드벤스드드라군입니다");
						
					}else{
						
						PrintToChat(client, "\x04현재 클래스에서 퇴화 할 수 없습니다");
						
					}
							
				}else if(StrEqual(argstring, "타이란트", false) || StrEqual(argstring, "8", false)){
							
					if(playerclass[client] != TYRANT){
						
						if(getworkablestructure(OVERMIND)){
							
							if(techlevel == 3){
							
								if(playercredit[client] >= alienevolvecredit[TYRANT]){
							
									PrintToChat(client, "\x04타이란트로 진화했습니다");
									playerclass[client] = TYRANT;
									SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
									SetEntProp(client, Prop_Data, "m_iHealth", alienmaxhealth[playerclass[client]]);
										
									playercredit[client] = playercredit[client] - alienevolvecredit[playerclass[client]];
								
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", alienevolvecredit[TYRANT]);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 클래스로 진화하기 위해서는 테크레벨이 3 이상이어야 합니다");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04작동중인 오버마인드가 없으므로 진화 할 수 없습니다");
							
						}
						
					}else{
						
						PrintToChat(client, "\x04당신은 이미 타이란트입니다");
						
					}
							
				}else{
							
					PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
					PrintToChat(client, "\x04사용법 : !진화 <클래스이름> 혹은 !진화 <클래스단축번호> 혹은 !진화");
					PrintToChat(client, "\x04가능한 클래스이름 : 드렛치[1], 바실리스크[2], 어드벤스드바실리스크[3], 마라우더[4]");
					PrintToChat(client, "\x04				   어드벤스드마라우더[5], 드라군[6], 어드벤스드드라군[7], 타이란트[8]");
							
				}
					
			}else{
							
				PrintToChat(client, "\x04명령어 사용이 올바르지 않습니다");
				PrintToChat(client, "\x04사용법 : !진화 <클래스이름> 혹은 !진화 <클래스단축번호> 혹은 !진화");
				PrintToChat(client, "\x04가능한 클래스이름 : 드렛치[1], 바실리스크[2], 어드벤스드바실리스크[3], 마라우더[4]");
				PrintToChat(client, "\x04				   어드벤스드마라우더[5], 드라군[6], 어드벤스드드라군[7], 타이란트[8]");
							
			}
			
		}
		
	}
	
	return Plugin_Handled;
	
}

//크레디트를 설정해주는 어드민 전용 명령어
public Action:command_setcredit(client, args){

	if(args < 2){

		PrintToChat(client, "\x04잘못된 명령 사용. 사용법 : sm_크레디트설정 <이름> <값>");
		return Plugin_Handled;

	}else if(args >= 2){

		decl String:targetname[128], String:name[128], String:creditstring[128];
		decl credit;

		GetCmdArg(1, targetname, sizeof(targetname));
		GetCmdArg(2, creditstring, sizeof(creditstring));

		credit = StringToInt(creditstring);
		
		new foundedplayers = 0, target = 0;
		
		for(new i = 1; i <= MaxClients; i++){
					
			if(isplayerconnectedingame(i) == true){
						
				GetClientName(i, name, 128);
	
				//Save:
				if(StrContains(name, targetname, false) != -1){
					
					foundedplayers++;
					
					target = i;
					
				}
					
			}
			
		}

		if(target != 0){

			if(foundedplayers == 1){
				
				GetClientName(target, name, 128);
				PrintToChat(client, "\x04%s 님의 크레디트를 %d 으로 설정합니다.", name, credit);
				playercredit[target] = credit;
				
			}else{
				
				PrintToChat(client, "\x04다음의 이름을 가진 클라이언트가 한명 이상입니다 : %s", targetname);
				
			}

			//Return:
			return Plugin_Handled;

		}else{
			
			PrintToChat(client, "\x04다음의 클라이언트를 찾을 수 없음 : %s", targetname);
			
		}

	}

	return Plugin_Handled;

}

//테크레벨을 강제로 설정해주는 어드민 전용 명령어(이 명령어는 애초에 디버깅을 위해 만든거다)
public Action:command_settechlevel(client, args){

	if(args < 1){

		PrintToChat(client, "\x04잘못된 명령 사용. 사용법 : sm_테크레벨설정 <값 1 ~ 3>");
		return Plugin_Handled;

	}else if(args >= 1){

		decl String:techlevelstring[128];
		decl techleveltoset;

		GetCmdArg(1, techlevelstring, sizeof(techlevelstring));

		techleveltoset = StringToInt(techlevelstring);
		
		if(techleveltoset == 1 || techleveltoset == 2 || techleveltoset == 3){
			
			techlevel = techleveltoset;
			PrintToChat(client, "\x04테크레벨을 다음으로 설정 : %d", techlevel);
			
		}else{
			
			PrintToChat(client, "\x04잘못된 테크레벨 설정입니다");
			
		}

		//Return:
		return Plugin_Handled;

	}

	return Plugin_Handled;

}

//초기건물 저장 명령어, 어드민 전용
public Action:command_savestructure(client, args){
	
	new Handle:keyvalue = CreateKeyValues("tremulousstructuresave");
	
	decl targetentityuserid, targetentitytype, targetentitystatus;
	decl String:savedata[256];
	decl String:buffer[7][32];//버퍼
	decl String:keyname[128];
	decl Float:angle[3], Float:position[3];
	
	KvRewind(keyvalue);
	
	//에일리언 캐시에 저장된 건물부터 저장한다
	for(new i = 0; i < INDEXCACHESIZE; i++){
		
		KvRewind(keyvalue);
		KvJumpToKey(keyvalue, "ALIEN", true);
					
		//건물 정보를 얻어올 수 있을 경우
		if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], targetentityuserid, targetentitytype, targetentitystatus)){
			
			GetEntPropString(structurecacheinfo[ALIENSTRUCTURECACHE][i], Prop_Data, "m_iName", keyname, sizeof(keyname));
			
			GetEntPropVector(structurecacheinfo[ALIENSTRUCTURECACHE][i], Prop_Data, "m_vecOrigin", position);
			GetEntPropVector(structurecacheinfo[ALIENSTRUCTURECACHE][i], Prop_Data, "m_angRotation", angle);
			
			IntToString(targetentitytype, buffer[0], 32);
			FloatToString(position[0], buffer[1], 32);
			FloatToString(position[1], buffer[2], 32);
			FloatToString(position[2], buffer[3], 32);
			FloatToString(angle[0], buffer[4], 32);
			FloatToString(angle[1], buffer[5], 32);
			FloatToString(angle[2], buffer[6], 32);
			
			ImplodeStrings(buffer, 7, " ", savedata, 256);
			
			KvSetString(keyvalue, keyname, savedata);
			
		}
		
	}
	
	//인간 건물
	for(new i = 0; i < INDEXCACHESIZE; i++){
		
		KvRewind(keyvalue);
		KvJumpToKey(keyvalue, "HUMAN", true);
		
		//건물 정보를 얻어올 수 있을 경우
		if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], targetentityuserid, targetentitytype, targetentitystatus)){
			
			GetEntPropString(structurecacheinfo[HUMANSTRUCTURECACHE][i], Prop_Data, "m_iName", keyname, sizeof(keyname));
			
			GetEntPropVector(structurecacheinfo[HUMANSTRUCTURECACHE][i], Prop_Data, "m_vecOrigin", position);
			GetEntPropVector(structurecacheinfo[HUMANSTRUCTURECACHE][i], Prop_Data, "m_angRotation", angle);
			
			IntToString(targetentitytype, buffer[0], 32);
			FloatToString(position[0], buffer[1], 32);
			FloatToString(position[1], buffer[2], 32);
			FloatToString(position[2], buffer[3], 32);
			FloatToString(angle[0], buffer[4], 32);
			FloatToString(angle[1], buffer[5], 32);
			FloatToString(angle[2], buffer[6], 32);
			
			ImplodeStrings(buffer, 7, " ", savedata, 256);
			
			KvSetString(keyvalue, keyname, savedata);
			
		}
		
	}
	
	new String:path[128];
	new String:mapname[64];
	
	//맵 이름을 얻어온다
	GetCurrentMap(mapname, 64);
	
	BuildPath(Path_SM, path, 128, "data/tremulous/%sstructuredata.txt", mapname);
	
	KvRewind(keyvalue);
	
	if(KeyValuesToFile(keyvalue, path)){
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 설정파일을 저장하는데 성공했습니다");
		
		if(client != 0){
			
			PrintToChat(client, "\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 설정파일을 저장하는데 성공했습니다");
		
		}
			
	}else{
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 설정파일을 저장하는데 실패했습니다");
		
		if(client != 0){
			
			PrintToChat(client, "\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 설정파일을 저장하는데 실패했습니다");
		
		}
		
	}
	
	CloseHandle(keyvalue);
	
	return Plugin_Handled;
	
}

//초기건물을 불러오는 명령어, 건물을 데이터파일에서 불러오고 설정해준다
public Action:loadstructure(Handle:timer){
	
	//데이터 파일이 있는지 확인한다
	new String:path[128];
	new String:mapname[64];
	
	//맵 이름을 얻어온다
	GetCurrentMap(mapname, 64);
	
	BuildPath(Path_SM, path, 128, "data/tremulous/%sstructuredata.txt", mapname);
	
	if(FileExists(path) == false){
		
		loadstatus = NODATA;
		
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 데이터 파일을 찾을 수 없었습니다\n찾으려고 시도했던 파일은 %s입니다", path);
		
	}else{
		
		//데이터 파일을 찾았을 때
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 데이터 파일을 찾았습니다\n찾으려고 시도했던 파일은 %s입니다", path);
		
		//데이터파일 로딩 작업
		new Handle:keyvalue = CreateKeyValues("tremulousstructuresave");
		
		FileToKeyValues(keyvalue, path);
		
		//에일리언의 건물의 데이터부터 로드한다
		new totaldatas = 0;
		decl String:keynames[INDEXCACHESIZE][128];
		decl String:values[128];
		
		decl String:buffer[7][32];
		decl type, Float:angle[3], Float:position[3];
		
		KvRewind(keyvalue);
		KvJumpToKey(keyvalue, "ALIEN", true);
		
		KvGotoFirstSubKey(keyvalue,false);
		
		do{
			
			if(KvGetSectionName(keyvalue, keynames[totaldatas], 128)){
				
				totaldatas++;
				
			}
		
		}while(KvGotoNextKey(keyvalue, false));
		
		for(new i = 0; i < totaldatas; i++){
			
			KvRewind(keyvalue);
			KvJumpToKey(keyvalue, "ALIEN", true);
			
			KvGetString(keyvalue, keynames[i], values, 128, "nodata");
			
			if(!StrEqual(values, "nodata")){
				
				ExplodeString(values, " ", buffer, 7, 32);
				
				type = StringToInt(buffer[0]);
				position[0] = StringToFloat(buffer[1]);
				position[1] = StringToFloat(buffer[2]);
				position[2] = StringToFloat(buffer[3]);
				angle[0] = StringToFloat(buffer[4]);
				angle[1] = StringToFloat(buffer[5]);
				angle[2] = StringToFloat(buffer[6]);
				
				new entity = CreateEntityByName("prop_physics");
				decl String:id[128];
				createentityidentification(0, type, STATUS_FUNCTIONING, id, 128);
				//모델파일을 설정해준다
				DispatchKeyValue(entity, "model", entitymodel[type]);
				SetEntProp(entity, Prop_Data, "m_iEFlags", GetEntProp(entity, Prop_Data, "m_iEFlags") | EFL_NO_PHYSCANNON_INTERACTION);
				//충돌에 의해 데미지를 입지 않게 하려는 시도
				SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") | SF_BREAK_DONT_TAKE_PHYSICS_DAMAGE);
				SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") & ~SF_BREAK_PHYSICS_BREAK_IMMEDIATELY);
				DispatchKeyValue(entity, "targetname", id);
				//스폰
				DispatchSpawn(entity);
				
				SetVariantFloat(999999.9);
				AcceptEntityInput(entity, "forcetoenablemotion");
				SetVariantInt(999999);
				AcceptEntityInput(entity, "damagetoenablemotion");
				SetEntProp(entity, Prop_Data, "m_iHealth", structuremaxhealth[type]);//체력을 건물의 고유 수치로
				DispatchKeyValueFloat(entity, "physdamagescale", 0.000000000000001);
				SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 1);
				
				structureregistration(entity);
					
				//텔레포트
				TeleportEntity(entity, position, angle, NULL_VECTOR);
				
				AcceptEntityInput(entity, "DisableMotion");
				
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, entity);
				WritePackCell(datapack, 0);
				WritePackString(datapack, id);
				
				//건물을 바로 작동시킨다
				CreateTimer(0.1, activestructure, datapack);
				
			}
			
		}
		
		//인간의 건물을 로딩한다
		
		totaldatas = 0;
		
		KvRewind(keyvalue);
		KvJumpToKey(keyvalue, "HUMAN", true);
		
		KvGotoFirstSubKey(keyvalue,false);
		
		do{
			
			if(KvGetSectionName(keyvalue, keynames[totaldatas], 128)){
					
				totaldatas++;
				
			}
		
		}while(KvGotoNextKey(keyvalue, false));
		
		for(new i = 0; i < totaldatas; i++){
			
			KvRewind(keyvalue);
			KvJumpToKey(keyvalue, "HUMAN", true);
			
			KvGetString(keyvalue, keynames[i], values, 128, "nodata");
			
			if(!StrEqual(values, "nodata")){
				
				ExplodeString(values, " ", buffer, 7, 32);
				
				type = StringToInt(buffer[0]);
				position[0] = StringToFloat(buffer[1]);
				position[1] = StringToFloat(buffer[2]);
				position[2] = StringToFloat(buffer[3]);
				angle[0] = StringToFloat(buffer[4]);
				angle[1] = StringToFloat(buffer[5]);
				angle[2] = StringToFloat(buffer[6]);
				
				new entity = CreateEntityByName("prop_physics");
				decl String:id[128];
				createentityidentification(0, type, STATUS_FUNCTIONING, id, 128);
				//모델파일을 설정해준다
				DispatchKeyValue(entity, "model", entitymodel[type]);
				SetEntProp(entity, Prop_Data, "m_iEFlags", GetEntProp(entity, Prop_Data, "m_iEFlags") | EFL_NO_PHYSCANNON_INTERACTION);
				//충돌에 의해 데미지를 입지 않게 하려는 시도
				SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") | SF_BREAK_DONT_TAKE_PHYSICS_DAMAGE);
				SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") & ~SF_BREAK_PHYSICS_BREAK_IMMEDIATELY);
				DispatchKeyValue(entity, "targetname", id);
				//스폰
				DispatchSpawn(entity);
				
				SetVariantFloat(999999.9);
				AcceptEntityInput(entity, "forcetoenablemotion");
				SetVariantInt(999999);
				AcceptEntityInput(entity, "damagetoenablemotion");
				SetEntProp(entity, Prop_Data, "m_iHealth", structuremaxhealth[type]);//체력을 건물의 고유 수치로
				DispatchKeyValueFloat(entity, "physdamagescale", 0.000000000000001);
				SetEntProp(entity, Prop_Data, "m_iMinHealthDmg", 1);
				
				structureregistration(entity);
					
				//텔레포트
				TeleportEntity(entity, position, angle, NULL_VECTOR);
				
				AcceptEntityInput(entity, "DisableMotion");
				
				new Handle:datapack = CreateDataPack();
				WritePackCell(datapack, entity);
				WritePackCell(datapack, 0);
				WritePackString(datapack, id);
				
				//건물을 바로 작동시킨다
				CreateTimer(0.1, activestructure, datapack);
				
			}
			
		}
			
		//로드스테이터스 변경은 맨 마지막에 해줘야 한다
		loadstatus = LOADED;
		PrintToServer("[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 데이터 파일 로딩을 완료했습니다");
		PrintToChatAll("\x04[SM] 트레뮬로우스 플러그인 : 맵 초기 구조물 데이터 파일 로딩을 완료했습니다");
		PrintToChatAll("\x04[SM] 트레뮬로우스 플러그인 : E 키를 눌러 스폰하세요");
		
		CloseHandle(keyvalue);
		
	}
	
	return Plugin_Handled;
	
}

//클라이언트를 재스폰시킨다
//카운터스트라이크소스 용이다
public spawnchechtype:cssrespawnclient(client){
	
	if(isplayerconnectedingame(client)){
		
		if(!IsPlayerAlive(client)){
			
			if(GetClientTeam(client) == 2){
				
				//에일리언의 에그 중에서 라스트 워크타임이 가장 작은, 즉 가장 과거인 것을 찾아낸다.
				new userid, entitytype, status;
				
				new select = 0;
				new Float:tempworktime = GetGameTime();
				
				decl Float:eggposition[3];
				
				new bool:thereisegg = false;
				new bool:thereisworkableegg = false;
				
				for(new i = 0; i < INDEXCACHESIZE; i++){
				
					//건물 정보를 얻어올 수 있을 경우
					if(getentityidentificationdata(structurecacheinfo[ALIENSTRUCTURECACHE][i], userid, entitytype, status)){
					
						if(entitytype == EGG){
							
							thereisegg = true;
							
							//작동하는 경우
							if(status == STATUS_FUNCTIONING){
								
								thereisworkableegg = true;
								
								if(structurelastworktime[structurecacheinfo[ALIENSTRUCTURECACHE][i]] <= tempworktime){
									
									select = structurecacheinfo[ALIENSTRUCTURECACHE][i];
									tempworktime = structurelastworktime[structurecacheinfo[ALIENSTRUCTURECACHE][i]];
									GetEntPropVector(structurecacheinfo[ALIENSTRUCTURECACHE][i], Prop_Data, "m_vecOrigin", eggposition);
									
								}
						
							}
					
						}
					
					}
				
				}
				
				//이렇게 해서 가장 이전에 작동한 에그를 골라내서, 그 에그가 4초 이전에 작동한 것이면 스폰시킨다
				if((select != 0) && (tempworktime + 4.0 <= GetGameTime())){
					
					structurelastworktime[select] = GetGameTime();
					
					CS_RespawnPlayer(client);
					eggposition[2] = eggposition[2] + 50.0;
					
					TeleportEntity(client, eggposition, NULL_VECTOR, NULL_VECTOR);
					
					//이동속도를 설정해준다
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", alienwalkspeed[playerclass[client]]);
					
					return RESULT_SPAWN_OK;
					
				}else{
					
					if(thereisegg){
					
						if(thereisworkableegg){
							
							return RESULT_WAIT;
						
						}else{
							
							return RESULT_NOWORKABLESPAWNPOINT;
							
						}
						
					}else{
						
						return RESULT_NOSPAWNPOINT;
						
					}
					
				}
				
			}else if(GetClientTeam(client) == 3){
				
				//인간의 텔레노드 중에서 라스트 워크타임이 가장 작은, 즉 가장 과거인 것을 찾아낸다.
				new userid, entitytype, status;
				
				new select = 0;
				new Float:tempworktime = GetGameTime();
				
				decl Float:telenodeposition[3];
				
				new bool:thereistelenode = false;
				new bool:thereisworkabletelenode = false;
				
				for(new i = 0; i < INDEXCACHESIZE; i++){
				
					//건물 정보를 얻어올 수 있을 경우
					if(getentityidentificationdata(structurecacheinfo[HUMANSTRUCTURECACHE][i], userid, entitytype, status)){
					
						if(entitytype == TELENODE){
							
							thereistelenode = true;
							
							//작동하는 경우
							if(status == STATUS_FUNCTIONING){
								
								thereisworkabletelenode = true;
								
								if(structurelastworktime[structurecacheinfo[HUMANSTRUCTURECACHE][i]] <= tempworktime){
									
									select = structurecacheinfo[HUMANSTRUCTURECACHE][i];
									tempworktime = structurelastworktime[structurecacheinfo[HUMANSTRUCTURECACHE][i]];
									GetEntPropVector(structurecacheinfo[HUMANSTRUCTURECACHE][i], Prop_Data, "m_vecOrigin", telenodeposition);
									
								}
						
							}
					
						}
					
					}
				
				}
				
				//이렇게 해서 가장 이전에 작동한 텔레노드를 골라내서, 그 텔레노드가 4초 이전에 작동한 것이면 스폰시킨다
				if((select != 0) && (tempworktime + 4.0 <= GetGameTime())){
					
					structurelastworktime[select] = GetGameTime();
					
					CS_RespawnPlayer(client);
					telenodeposition[2] = telenodeposition[2] + 50.0;
					
					TeleportEntity(client, telenodeposition, NULL_VECTOR, NULL_VECTOR);
					
					//스폰되었으므로 클래스에 따라 무기를 준다
					if(playerclass[client] == HUMANATTACKER){
						
						GivePlayerItem(client, "weapon_tmp");
						
					}
					
					return RESULT_SPAWN_OK;
					
				}else{
					
					if(thereistelenode){
					
						if(thereisworkabletelenode){
							
							return RESULT_WAIT;
						
						}else{
							
							return RESULT_NOWORKABLESPAWNPOINT;
							
						}
						
					}else{
						
						return RESULT_NOSPAWNPOINT;
						
					}
					
				}
				
			}else{
				
				return RESULT_ERROR;
				
			}
			
		}else{
			
			return RESULT_ERROR;
			
		}
		
	}else{
		
		return RESULT_ERROR;
		
	}
	
}

//메뉴시스템이 여기에 온다
public Action:spawnmenu(client){
	
	new Handle:spawnmenuhandle = CreateMenu(spawnmenuhandler);
	
	SetMenuTitle(spawnmenuhandle, "스폰 클래스 선택");
	
	//에일리언팀인 경우
	if(GetClientTeam(client) == 2){
		
		AddMenuItem(spawnmenuhandle, "드렛치", "드렛치");
		
		if(techlevel >= 2){
			
			AddMenuItem(spawnmenuhandle, "어드벤스드그렌저", "어드벤스드그렌저");
			
		}else{
			
			AddMenuItem(spawnmenuhandle, "그렌저", "그렌저");
			
		}
		
	}else if(GetClientTeam(client) == 3){
		
		AddMenuItem(spawnmenuhandle, "마린", "마린");
		
		if(techlevel >= 2){
			
			AddMenuItem(spawnmenuhandle, "어드벤스드엔지니어", "어드벤스드엔지니어");
			
		}else{
			
			AddMenuItem(spawnmenuhandle, "엔지니어", "엔지니어");
			
		}
		
	}
	
	SetMenuExitButton(spawnmenuhandle, true);
	
	DisplayMenu(spawnmenuhandle, client, 30);
 
	return Plugin_Handled;
	
}


public spawnmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	if(action == MenuAction_Select){
		
		if(select == 0){
			
			if(GetClientTeam(client) == 2){
				
				//에일리언일 경우
				playerclass[client] = DRETCH;
				
				
			}else if(GetClientTeam(client) == 3){
				
				//인간인 경우
				playerclass[client] = HUMANATTACKER;
				
			}
			
		}else if(select == 1){
			
			if(GetClientTeam(client) == 2){
				
				//에일리언일 경우
				if(techlevel >= 2){
					
					playerclass[client] = ADVANCEDGRANGER;
					
				}else{
					
					playerclass[client] = GRANGER;
					
				}
				
			}else if(GetClientTeam(client) == 3){
				
				//인간인 경우
				playerclass[client] = HUMANBUILDER;
				
			}
						
		}
		
		//어쩌면 죽고서 몇초 뒤에 스폰되게 하고싶을지도 모르므로 이 기능을 둔다
		if(playerlasthurttime[client] + 0.0 < GetGameTime()){
		
			new spawnchechtype:result = cssrespawnclient(client);
			
			if(result == RESULT_SPAWN_OK){
				
				PrintToChat(client, "\x04스폰되었습니다");
			
			}else if(result == RESULT_NOSPAWNPOINT){
				
				if(GetClientTeam(client) == 2){
					
					PrintToChat(client, "\x04에그가 없으므로 스폰 될 수 없습니다");
					
				}else if(GetClientTeam(client) == 3){
					
					PrintToChat(client, "\x04텔레노드가 없으므로 스폰 될 수 없습니다");
					
				}
				
			}else if(result == RESULT_WAIT){
				
				if(GetClientTeam(client) == 2){
					
					PrintToChat(client, "\x04에그가 피로하니 잠시 기다려 주십시오");
					
				}else if(GetClientTeam(client) == 3){
					
					PrintToChat(client, "\x04텔레노드가 과부하되었으니 잠시 기다려 주십시오");
					
				}
				
			}else if(result == RESULT_NOWORKABLESPAWNPOINT){
				
				if(GetClientTeam(client) == 2){
					
					PrintToChat(client, "\x04에그가 있지만 건설 중인 것 뿐이므로 스폰 할 수 없습니다");
					
				}else if(GetClientTeam(client) == 3){
					
					PrintToChat(client, "\x04텔레노드가 있지만 건설 중인 것 뿐이므로 스폰 할 수 없습니다");
					
				}
				
			}
			
		}else{
			
			PrintToChat(client, "\x04죽은 뒤 5초간은 스폰할 수 없습니다");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04스폰 클래스 선택 메뉴를 종료하셨습니다");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

//css를 위한 휴드 표시 함수
public Action:csshuddisplay(Handle:timer, any:client){
	
	//살아있어야만한다
	if(isplayerconnectedingamealive(client)){
		
		new team = GetClientTeam(client);
		
		//에일리언팀인 경우
		if(team == 2){
			
			decl String:classname[60];
			decl String:abilitystatus[128];
			decl String:poisonstatus[60];
			
			decl String:gamestatus[256];
			
			if(playerclass[client] == GRANGER){
				
				classname = "그렌저";
				
				abilitystatus = "[특수능력없음]";
				
			}else if(playerclass[client] == ADVANCEDGRANGER){
				
				classname = "어드벤스드그렌저";
				
				if(playerprojectileabilitycooltime[client]){
					
					abilitystatus = "[산성포자사용불가능(R키)]";
					
				}else{
					
					abilitystatus = "[산성포자사용가능(R키)]";
					
				}
				
			}else if(playerclass[client] == DRETCH){
				
				classname = "드렛치";
				
				abilitystatus = "[특수능력없음]";
				
			}else if(playerclass[client] == BASILISK){
				
				classname = "바실리스크";
				
				abilitystatus = "[잡기능력(E키)]";
				
			}else if(playerclass[client] == ADVANCEDBASILISK){
				
				classname = "어드벤스드바실리스크";
				
				if(playergasabilitycooltime[client]){
					
					abilitystatus = "[잡기능력(E키), 독가스사용불가능(R키)]";
					
				}else{
					
					abilitystatus = "[잡기능력(E키), 독가스사용가능(R키)]";
					
				}
				
			}else if(playerclass[client] == MARAUDER){
				
				classname = "마라우더";
				
				if(playerjumpskillcooltime[client]){
					
					abilitystatus = "[점프능력사용불가능(E키)]";
					
				}else{
					
					abilitystatus = "[점프능력사용가능(E키)]";
					
				}
				
			}else if(playerclass[client] == ADVANCEDMARAUDER){
				
				classname = "어드벤스드마라우더";
				
				if(playerjumpskillcooltime[client]){
					
					abilitystatus = "[점프능력사용불가능(E키)";
					
				}else{
					
					abilitystatus = "[점프능력사용가능(E키)";
					
				}
				
				if(playerelectricabilitycooltime[client]){
					
					Format(abilitystatus, 128, "%s, 방전능력불사용가능(R키)]", abilitystatus);
					
				}else{
					
					Format(abilitystatus, 128, "%s, 방전능력사용가능(R키)]", abilitystatus);
					
				}
				
				
				
			}else if(playerclass[client] == DRAGOON){
				
				classname = "드라군";
				
				if(playerpounceskillcooltime[client]){
					
					abilitystatus = "[파운스능력사용불가능(E키)]";
					
				}else{
					
					abilitystatus = "[파운스능력사용가능(E키)]";
					
				}
				
			}else if(playerclass[client] == ADVANCEDDRAGOON){
				
				classname = "어드벤스드드라군";
				
				if(playerpounceskillcooltime[client]){
					
					abilitystatus = "[파운스능력사용불가능(E키)";
					
				}else{
					
					abilitystatus = "[파운스능력사용가능(E키)";
					
				}
				
				if(playerbarbabilitycooltime[client]){
					
					Format(abilitystatus, 128, "%s, 바늘등뼈발사능력사용불가능(R키)]", abilitystatus);
					
				}else{
					
					Format(abilitystatus, 128, "%s, 바늘등뼈발사능력사용가능(R키)]", abilitystatus);
					
				}
				
			}else if(playerclass[client] == TYRANT){
				
				classname = "타이란트";
				
				if(playertrampleskillcooltime[client]){
					
					abilitystatus = "[돌진능력사용불가능(E키)";
					
				}else{
					
					abilitystatus = "[돌진능력사용가능(E키)";
					
				}
				
			}else{
				
				classname = "없음";
				
				abilitystatus = "[특수능력없음]";
				
			}
			
			if(playerhaspoisonability[client] == true){
				
				poisonstatus = "[독공격가능]";
				
			}else{
				
				poisonstatus = "[독공격불가능]";
				
			}
			
			//PrintHintText(client, "[클래스 : %s][크레디트 : %d]\n[체력 : %d][특수갑각 : %d]\n%s\n%s", classname, playercredit[client], GetEntProp(client, Prop_Data, "m_iHealth"), GetEntProp(client, Prop_Data, "m_ArmorValue"), poisonstatus, abilitystatus);
			
			decl String:totalhud[256];
			
			Format(totalhud, 256, "[클래스 : %s][크레디트 : %d]\n[체력 : %d][특수갑각 : %d]\n%s\n%s", classname, playercredit[client], GetEntProp(client, Prop_Data, "m_iHealth"), GetEntProp(client, Prop_Data, "m_ArmorValue"), poisonstatus, abilitystatus);
			
			csssendhudmsg(client, 5, 0.54, 0.62, 255, 120, 0, 255, 255, 120, 0, 225, 1, 0.1, 1.0, 10.0, 4.0, totalhud);
			
			if(techlevel <= 2){
			
				Format(gamestatus, 256, "[테크레벨 : %d][다음 테크레벨까지 남은 킬수 : %d]\n[현재건설수치 : %d][최대건설수치 : %d]", techlevel, killstonextlevel[techlevel] - stagekills, getusedstructurepoint(ALIENSTRUCTURECACHE), maxstructurepoint[techlevel]);
			
			}else{
				
				Format(gamestatus, 256, "[테크레벨 : %d][최종 테크레벨입니다]\n[현재건설수치 : %d][최대건설수치 : %d]", techlevel, getusedstructurepoint(ALIENSTRUCTURECACHE), maxstructurepoint[techlevel]);
				
			}
				
			csssendhudmsg(client, 6, 0.54, 0.06, 255, 120, 0, 255, 255, 120, 0, 225, 1, 0.1, 1.0, 10.0, 4.0, gamestatus);
			
			CreateTimer(0.1, csshuddisplay, client);
			
		}else if(team == 3){
			
			//인간팀인 경우
			decl String:classname[60];
			decl String:medkitstatus[128];
			decl String:poisonstatus[60];
			
			decl String:gamestatus[256];
			
			if(playerclass[client] == HUMANATTACKER){
				
				classname = "마린";
				
			}else if(playerclass[client] == HUMANBUILDER){
				
				if(techlevel >= 2){
				
					classname = "어드벤스드엔지니어";
				
				}else{
					
					classname = "엔지니어";
					
				}
				
			}else{
				
				classname = "없음";
				
			}
			
			if(playerhasmedkit[client]){
					
				medkitstatus = "[메드킷사용가능]";
					
			}else{
					
				medkitstatus = "[메드킷사용불가능]";
					
			}
				
			if(playergetpoisonattack[client] != 0 || playergetgasattack[client] != 0){
					
				poisonstatus = "[독검출됨";
					
			}else{
					
				poisonstatus = "[독검출되지않음";
					
			}
				
			if(playergetadhesiveattack[client] || playergetgrabattack[client] != 0){
					
				Format(poisonstatus, 128, "%s, 이동불가상태]", poisonstatus);
					
			}else{
					
				Format(poisonstatus, 128, "%s, 이동가능상태]", poisonstatus);
					
			}
			
			//PrintHintText(client, "[클래스 : %s][크레디트 : %d]\n[체력 : %d][특수복 : %d]\n%s\n%s", classname, playercredit[client], GetEntProp(client, Prop_Data, "m_iHealth"), GetEntProp(client, Prop_Data, "m_ArmorValue"), medkitstatus, poisonstatus);
			
			decl String:totalhud[256];
			
			Format(totalhud, 256, "[클래스 : %s][크레디트 : %d]\n[체력 : %d][특수복 : %d]\n%s\n%s", classname, playercredit[client], GetEntProp(client, Prop_Data, "m_iHealth"), GetEntProp(client, Prop_Data, "m_ArmorValue"), medkitstatus, poisonstatus);
			
			csssendhudmsg(client, 5, 0.54, 0.62, 255, 120, 0, 255, 255, 120, 0, 225, 1, 0.1, 1.0, 10.0, 4.0, totalhud);
			
			if(techlevel <= 2){
			
				Format(gamestatus, 256, "[테크레벨 : %d][다음 테크레벨까지 남은 킬수 : %d]\n[현재건설수치 : %d][최대건설수치 : %d]", techlevel, killstonextlevel[techlevel] - stagekills, getusedstructurepoint(HUMANSTRUCTURECACHE), maxstructurepoint[techlevel]);
			
			}else{
				
				Format(gamestatus, 256, "[테크레벨 : %d][최종 테크레벨입니다]\n[현재건설수치 : %d][최대건설수치 : %d]", techlevel, getusedstructurepoint(HUMANSTRUCTURECACHE), maxstructurepoint[techlevel]);
				
			}
				
			csssendhudmsg(client, 6, 0.54, 0.06, 255, 120, 0, 255, 255, 120, 0, 225, 1, 0.1, 1.0, 10.0, 4.0, gamestatus);
			
			CreateTimer(0.1, csshuddisplay, client);
			
		}
		
	}
	
}

public csssendhudmsg(client, channel, Float:x, Float:y, r1, g1, b1, a1, r2, g2, b2, a2, effect, Float:fadein, Float:fadeout, Float:holdtime, Float:fxtime, const String:msg[]){
	
	new Handle:hudhandle = INVALID_HANDLE;
	
	if(client == 0){
		
		hudhandle = StartMessageAll("HudMsg");
		
	}else{
		
		hudhandle = StartMessageOne("HudMsg", client);
		
	}
	
	if(hudhandle != INVALID_HANDLE){
		
		BfWriteByte(hudhandle, channel); //channel
		BfWriteFloat(hudhandle, x); // x ( -1 = center )
		BfWriteFloat(hudhandle, y); // y ( -1 = center )
		// second color
		BfWriteByte(hudhandle, r1); //r1
		BfWriteByte(hudhandle, g1); //g1
		BfWriteByte(hudhandle, b1); //b1
		BfWriteByte(hudhandle, a1); //a1 // transparent?
		// init color
		BfWriteByte(hudhandle, r2); //r2
		BfWriteByte(hudhandle, g2); //g2
		BfWriteByte(hudhandle, b2); //b2
		BfWriteByte(hudhandle, a2); //a2
		BfWriteByte(hudhandle, effect); //effect (0 is fade in/fade out; 1 is flickery credits; 2 is write out)
		BfWriteFloat(hudhandle, fadein); //fadeinTime (message fade in time - per character in effect 2)
		BfWriteFloat(hudhandle, fadeout); //fadeoutTime
		BfWriteFloat(hudhandle, holdtime); //holdtime
		BfWriteFloat(hudhandle, fxtime); //fxtime (effect type(2) used)
		BfWriteString(hudhandle, msg); //Message
		EndMessage();
		
	}
	
}

public usearmoury(client){
	
	if(isplayerconnectedingamealive(client)){
		
		//대테러일경우에만
		if(3 == GetClientTeam(client)){
			
			//클라이언트의 눈의 위치로부터 트레이스 써서 아머리 존재 유무 확인
			decl Float:clientposition[3], Float:entityposition[3], Float:clienteyeangle[3];
			
			new Float:distance = -1.0;
			
			new target = 0;
			
			GetClientEyePosition(client, clientposition);	
			GetClientEyeAngles(client, clienteyeangle);				
									
			new Handle:traceresulthandle = INVALID_HANDLE;
							
			traceresulthandle = TR_TraceRayFilterEx(clientposition, clienteyeangle, MASK_SOLID, RayType_Infinite, tracerayfilterdefault, client);
							
			if(TR_DidHit(traceresulthandle) == true){
				
				target = TR_GetEntityIndex(traceresulthandle);
				
				if(0 != target){
					
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", entityposition);
					
					distance = GetVectorDistance(clientposition, entityposition);
					
					//거리 엄수
					if(distance <= 100){
						
						new userid, type, status;
						
						if(getentityidentificationdata(target, userid, type, status)){
							
							//아머리
							if(type == ARMOURY){
								
								if(status == STATUS_FUNCTIONING){
									
									if(getpowerstatus(target)){
									
										decl String:armouryname[128];
											
										GetEntPropString(target, Prop_Data, "m_iName", armouryname, 128);
										
										//아머리 메뉴를 보여줘야한다
										if(servergametype == GAMETYPE_CSS){
											
											//css일 경우의 메뉴
											cssarmourymenu(client, target, armouryname);
											
										}else if(servergametype == GAMETYPE_HL2MP){
											
											//hl2mp의 메뉴
											
										}
										
									}else{
										
										//아머리가 작동하지 않고있다
										PrintToChat(client, "\x04그 아머리는 작동하지 않습니다");
										
									}
									
								}else if(status == STATUS_INCONSTRUCTING){
									
									//건설중인 아머리이다
									PrintToChat(client, "\x04그 아머리는 건설중인 것입니다");
									
								}
								
							}
							
						}
						
					}
					
				}
												
			}
											
			if(traceresulthandle != INVALID_HANDLE){
				
				CloseHandle(traceresulthandle);
				
			}
			
		}
		
	}
	
}

//아머리메뉴시스템이 여기에 온다
//카솟용
public Action:cssarmourymenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmourymenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템");
	
	AddMenuItem(armourymenuhandle, verityname, "병과변경");
	AddMenuItem(armourymenuhandle, verityname, "권총구입");
	AddMenuItem(armourymenuhandle, verityname, "샷건구입");
	AddMenuItem(armourymenuhandle, verityname, "기관단총구입");
	AddMenuItem(armourymenuhandle, verityname, "소총구입");
	AddMenuItem(armourymenuhandle, verityname, "기관총구입");
	AddMenuItem(armourymenuhandle, verityname, "방어장비구입");
	AddMenuItem(armourymenuhandle, verityname, "탄환재보급");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmourymenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(playerclass[client] == HUMANBUILDER || playerclass[client] == HUMANATTACKER){
			
				if(IsValidEntity(target)){
					
					decl String:targetname[128];
					
					GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
				
					//올바른 식별번호를 가진 경우
					if(StrEqual(targetname, entitydata[1], false)){
				
						if(select == 0){
							
							//병과 변경 메뉴를 띄워준다
							cssarmouryclassmenu(client, target, entitydata[1]);
							
						}else if(select == 1){
							
							//권총 구입 메뉴
							cssarmourypistolmenu(client, target, entitydata[1]);
							
						}else if(select == 2){
							
							//샷건 구입 메뉴
							cssarmouryshotgunmenu(client, target, entitydata[1]);
							
						}else if(select == 3){
							
							//기관단총 구입 메뉴
							cssarmourysmgmenu(client, target, entitydata[1]);
							
						}else if(select == 4){
							
							//소총 구입 메뉴
							cssarmouryriflemenu(client, target, entitydata[1]);
							
						}else if(select == 5){
							
							//기관총 구입 메뉴
							cssarmourymachinegunmenu(client, target, entitydata[1]);
							
						}else if(select == 6){
							
							//방어장비 구입 메뉴
							cssarmouryequipmentmenu(client, target, entitydata[1]);
							
						}else if(select == 7){
							
							//재보급 메뉴
							PrintToChat(client, "\x04탄환을 재보급받았습니다.");
							GivePlayerItem(client, "Ammo_338mag");
							GivePlayerItem(client, "Ammo_357sig");
							GivePlayerItem(client, "Ammo_45acp");
							GivePlayerItem(client, "Ammo_50ae");
							GivePlayerItem(client, "Ammo_556mm");
							GivePlayerItem(client, "Ammo_556mm_box");
							GivePlayerItem(client, "Ammo_57mm");
							GivePlayerItem(client, "Ammo_762mm");
							GivePlayerItem(client, "Ammo_9mm");
							GivePlayerItem(client, "Ammo_buckshot");
							
						}
						
					}else{
			
						PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
					}
					
				}else{
			
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
				}
				
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

//병과변경
public Action:cssarmouryclassmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmouryclassmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 병과변경");
	
	AddMenuItem(armourymenuhandle, verityname, "마린");
	AddMenuItem(armourymenuhandle, verityname, "엔지니어");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmouryclassmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(playerclass[client] == HUMANBUILDER || playerclass[client] == HUMANATTACKER){
			
				if(IsValidEntity(target)){
					
					decl String:targetname[128];
					
					GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
				
					//올바른 식별번호를 가진 경우
					if(StrEqual(targetname, entitydata[1], false)){
				
						if(select == 0){
							
							playerclass[client] = HUMANATTACKER;
							PrintToChat(client, "\x04클래스를 마린으로 변경하셨습니다");
							
						}else if(select == 1){
							
							playerclass[client] = HUMANBUILDER;
							cssdeleteallrifle(client);
							PrintToChat(client, "\x04클래스를 엔지니어로 변경하셨습니다");
							
						}else if(select == 2){
							
							//뒤로가기메뉴
							cssarmourymenu(client, target, entitydata[1]);
							
						}
						
					}else{
			
						PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
					}
					
				}else{
			
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
				}
				
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

//권총
public Action:cssarmourypistolmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmourypistolmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 권총구입");
	
	AddMenuItem(armourymenuhandle, verityname, "USP 구입(20크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "Glock 구입(20크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "P228Compact 구입(30크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "DesertEagle 구입(40크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "DualElite 구입(40크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "FiveSeven 구입(30크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmourypistolmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(playerclass[client] == HUMANBUILDER || playerclass[client] == HUMANATTACKER){
			
				if(IsValidEntity(target)){
					
					decl String:targetname[128];
					
					GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
				
					//올바른 식별번호를 가진 경우
					if(StrEqual(targetname, entitydata[1], false)){
				
						if(select == 0){
							
							//usp 구입
							//usp는 1레벨 무기이므로 언제나 살수있다.
							
							if(playercredit[client] >= WEAPON_USP_PRICE){
								
								playercredit[client] -= WEAPON_USP_PRICE;
								
								cssdeleteallpistol(client);
								
								GivePlayerItem(client, "weapon_usp");
								
							}else{
								
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_USP_PRICE);
								
							}
							
						}else if(select == 1){
							
							//Glock 구입
							//Glock 1레벨 무기이므로 언제나 살수있다.
							if(playercredit[client] >= WEAPON_GLOCK_PRICE){
								
								playercredit[client] -= WEAPON_GLOCK_PRICE;
								
								cssdeleteallpistol(client);
								
								GivePlayerItem(client, "weapon_glock");
								
							}else{
								
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_GLOCK_PRICE);
								
							}
							
						}else if(select == 2){
							
							//P228Compact 구입, 2레벨
							if(techlevel >= 2){
								
								if(playercredit[client] >= WEAPON_P228_PRICE){
								
									playercredit[client] -= WEAPON_P228_PRICE;
									
									cssdeleteallpistol(client);
									
									GivePlayerItem(client, "weapon_p228");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_P228_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else if(select == 3){
							
							//DesertEagle 구입
							//DesertEagle 2레벨
							if(techlevel >= 2){
								
								if(playercredit[client] >= WEAPON_DEAGLE_PRICE){
								
									playercredit[client] -= WEAPON_DEAGLE_PRICE;
									
									cssdeleteallpistol(client);
									
									GivePlayerItem(client, "weapon_deagle");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_DEAGLE_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else if(select == 4){
							
							//DualElite 구입, 3레벨
							if(techlevel >= 3){
								
								if(playercredit[client] >= WEAPON_ELITE_PRICE){
								
									playercredit[client] -= WEAPON_ELITE_PRICE;
									
									cssdeleteallpistol(client);
									
									GivePlayerItem(client, "weapon_elite");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_ELITE_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이이어야 합니다.");
								
							}
							
						}else if(select == 5){
							
							//FiveSeven 구입, 3레벨
							if(techlevel == 3){
								
								if(playercredit[client] >= WEAPON_FIVESEVEN_PRICE){
								
									playercredit[client] -= WEAPON_FIVESEVEN_PRICE;
									
									cssdeleteallpistol(client);
									
									GivePlayerItem(client, "weapon_fiveseven");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_FIVESEVEN_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이이어야 합니다.");
								
							}
							
						}else if(select == 6){
							
							//뒤로가기메뉴
							cssarmourymenu(client, target, entitydata[1]);
							
						}
						
					}else{
			
						PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
					}
					
				}else{
			
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
				}
				
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public Action:cssarmouryshotgunmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmouryshotmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 샷건구입");
	
	AddMenuItem(armourymenuhandle, verityname, "M3 구입(100크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "XM1014 구입(180크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmouryshotmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(IsValidEntity(target)){
					
				decl String:targetname[128];
					
				GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
				
				//올바른 식별번호를 가진 경우
				if(StrEqual(targetname, entitydata[1], false)){
				
					if(select == 0){
							
						//수동샷건 구입
						//1레벨무기
							
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_M3_PRICE){
																	
								playercredit[client] -= WEAPON_M3_PRICE;
									
								cssdeleteallrifle(client);
									
								GivePlayerItem(client, "weapon_m3");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_M3_PRICE);
									
							}
								
						}else{
								
							PrintToChat(client, "\x04마린만이 샷건을 사용할 수 있습니다.");
								
						}
							
					}else if(select == 1){
							
						//자동샷건 구입
						//2레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_XM1014_PRICE){
									
									playercredit[client] -= WEAPON_XM1014_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_xm1014");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_XM1014_PRICE);
									
								}
								
							}else{
							
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 샷건을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 2){
						
						//뒤로가기메뉴
						cssarmourymenu(client, target, entitydata[1]);
						
					}
					
				}else{
		
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
				}
				
			}else{
		
				PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public Action:cssarmourysmgmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmourysmgmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 단기관총구입");
	
	AddMenuItem(armourymenuhandle, verityname, "TMP 구입(100크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "MAC10 구입(120크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "MP5NAVY 구입(140크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "UMP45 구입(160크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "P90 구입(180크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmourysmgmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(IsValidEntity(target)){
				
				decl String:targetname[128];
				
				GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
				//올바른 식별번호를 가진 경우
				if(StrEqual(targetname, entitydata[1], false)){
			
					if(select == 0){
						
						//tmp
						//1레벨무기
						
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_TMP_PRICE){
								
								playercredit[client] -= WEAPON_TMP_PRICE;
								
								cssdeleteallrifle(client);
								
								GivePlayerItem(client, "weapon_tmp");
								
							}else{
								
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_TMP_PRICE);
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 기관단총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 1){
						
						//잉그람 구입
						//1레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_MAC10_PRICE){
									
								playercredit[client] -= WEAPON_MAC10_PRICE;
									
								cssdeleteallrifle(client);
									
								GivePlayerItem(client, "weapon_mac10");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_MAC10_PRICE);
									
							}
						
						}else{
							
							PrintToChat(client, "\x04마린만이 기관단총을 사용할 수 있습니다.");
							
						}
							
					}else if(select == 2){
						
						//mp5 구입
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_MP5NAVY_PRICE){
									
								playercredit[client] -= WEAPON_MP5NAVY_PRICE;
									
								cssdeleteallrifle(client);
									
								GivePlayerItem(client, "weapon_mp5navy");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_MP5NAVY_PRICE);
									
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 기관단총을 사용할 수 있습니다.");
							
						}
						
						
					}else if(select == 3){
						
						//ump45 구입
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_UMP45_PRICE){
									
								playercredit[client] -= WEAPON_UMP45_PRICE;
									
								cssdeleteallrifle(client);
									
								GivePlayerItem(client, "weapon_ump45");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_UMP45_PRICE);
									
							}
					
						}else{
							
							PrintToChat(client, "\x04마린만이 기관단총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 4){
						
						//p90 구입
						if(playerclass[client] == HUMANATTACKER){
						
							if(playercredit[client] >= WEAPON_P90_PRICE){
									
								playercredit[client] -= WEAPON_P90_PRICE;
									
								cssdeleteallrifle(client);
									
								GivePlayerItem(client, "weapon_p90");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_P90_PRICE);
									
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 기관단총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 5){
						
						//뒤로가기메뉴
						cssarmourymenu(client, target, entitydata[1]);
						
					}
					
				}else{
		
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
				}
				
			}else{
		
				PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public Action:cssarmouryriflemenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmouryriflemenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 소총구입");
	
	AddMenuItem(armourymenuhandle, verityname, "GALIL 구입(300크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "FAMAS 구입(350크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "AK47 구입(400크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "M4A1 구입(400크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "SteyrScout 구입(450크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "Krieg552 구입(500크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "SteyrAug 구입(500크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "Krieg550Commando 구입(600크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "D3/AU-1 구입(650크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "AIArcticWarfare 구입(700크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmouryriflemenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(IsValidEntity(target)){
				
				decl String:targetname[128];
				
				GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
				//올바른 식별번호를 가진 경우
				if(StrEqual(targetname, entitydata[1], false)){
			
					if(select == 0){
						
						//갈릴
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
								
								if(playercredit[client] >= WEAPON_GALIL_PRICE){
									
									playercredit[client] -= WEAPON_GALIL_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_galil");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_GALIL_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 1){
						
						//파마스
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_FAMAS_PRICE){
										
									playercredit[client] -= WEAPON_FAMAS_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_famas");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_FAMAS_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 2){
						
						//ak47
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_AK47_PRICE){
										
									playercredit[client] -= WEAPON_AK47_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_ak47");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_AK47_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 3){
						
						//엠포
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_M4A1_PRICE){
										
									playercredit[client] -= WEAPON_M4A1_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_m4a1");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_M4A1_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 4){
						
						//스카웃
						//2레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_SCOUT_PRICE){
										
									playercredit[client] -= WEAPON_SCOUT_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_scout");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_SCOUT_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 5){
						
						//크릭
						//2레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_SG552_PRICE){
										
									playercredit[client] -= WEAPON_SG552_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_sg552");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_SG552_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
							
					}else if(select == 6){
						
						//불펍
						//2레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel >= 2){
							
								if(playercredit[client] >= WEAPON_AUG_PRICE){
										
									playercredit[client] -= WEAPON_AUG_PRICE;
										
									cssdeleteallrifle(client);
										
									GivePlayerItem(client, "weapon_aug");
										
								}else{
										
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_AUG_PRICE);
										
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 7){
						
						//크릭코만도
						//3레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel == 3){
							
								if(playercredit[client] >= WEAPON_SG550_PRICE){
									
									playercredit[client] -= WEAPON_SG550_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_sg550");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_SG550_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 8){
						
						//D3/AU-1
						//3레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel == 3){
							
								if(playercredit[client] >= WEAPON_G3SG1_PRICE){
									
									playercredit[client] -= WEAPON_G3SG1_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_g3sg1");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_G3SG1_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이어야 합니다.");
								
							}
						
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
							
					}else if(select == 9){
						
						//에땁
						//3레벨 무기
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel == 3){
							
								if(playercredit[client] >= WEAPON_AWP_PRICE){
									
									playercredit[client] -= WEAPON_AWP_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_awp");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_AWP_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 소총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 10){
						
						//뒤로가기메뉴
						cssarmourymenu(client, target, entitydata[1]);
						
					}
					
				}else{
		
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
				}
				
			}else{
		
				PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public Action:cssarmourymachinegunmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmourymachinegunmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 기관총구입");
	
	AddMenuItem(armourymenuhandle, verityname, "M249 구입(700크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmourymachinegunmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(IsValidEntity(target)){
					
				decl String:targetname[128];
				
				GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
				//올바른 식별번호를 가진 경우
				if(StrEqual(targetname, entitydata[1], false)){
			
					if(select == 0){
						
						if(playerclass[client] == HUMANATTACKER){
						
							if(techlevel == 3){
							
								if(playercredit[client] >= WEAPON_M249_PRICE){
									
									playercredit[client] -= WEAPON_M249_PRICE;
									
									cssdeleteallrifle(client);
									
									GivePlayerItem(client, "weapon_m249");
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_M249_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이어야 합니다.");
								
							}
							
						}else{
							
							PrintToChat(client, "\x04마린만이 기관총을 사용할 수 있습니다.");
							
						}
						
					}else if(select == 1){
						
						//뒤로가기메뉴
						cssarmourymenu(client, target, entitydata[1]);
						
					}
					
				}else{
		
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
				}
				
			}else{
		
				PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
					
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public Action:cssarmouryequipmentmenu(client, armouryentity, String:armouryname[]){
	
	decl String:verityname[128];
	
	Format(verityname, 128, "%d^%s", armouryentity, armouryname);
	
	new Handle:armourymenuhandle = CreateMenu(cssarmouryequipmentmenuhandler);
	
	SetMenuTitle(armourymenuhandle, "아머리 시스템 - 보조장비구입");
	
	AddMenuItem(armourymenuhandle, verityname, "보병용장갑 구입(300크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "보병용특수강화장갑 구입(500크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "섬광수류탄 구입(20크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "연막수류탄 구입(20크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "고폭수류탄 구입(20크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "야간투시경 구입(50크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "생체강화복 구입(600크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "특수생체강화복 구입(800크레디트)");
	AddMenuItem(armourymenuhandle, verityname, "뒤로");
	
	SetMenuExitButton(armourymenuhandle, true);
	
	DisplayMenu(armourymenuhandle, client, 30);
	
	return Plugin_Handled;
	
}

public cssarmouryequipmentmenuhandler(Handle:menu, MenuAction:action, client, select){
	
	//아머리 메뉴에서 어떤 아미러를 선택했는지에 대한 정보를 얻어낸다
	decl String:infobuffer[128], String:displaybuffer[128], style, String:entitydata[2][128];
	
	decl target;
	
	GetMenuItem(menu, 0, infobuffer, 128, style, displaybuffer, 128);
	
	ExplodeString(infobuffer, "^", entitydata, 2, 128);
	
	target = StringToInt(entitydata[0]);
	
	if(action == MenuAction_Select){
		
		if(GetClientTeam(client) == 3){
			
			if(playerclass[client] == HUMANBUILDER || playerclass[client] == HUMANATTACKER){
			
				if(IsValidEntity(target)){
					
					decl String:targetname[128];
					
					GetEntPropString(target, Prop_Data, "m_iName", targetname, sizeof(targetname));
				
					//올바른 식별번호를 가진 경우
					if(StrEqual(targetname, entitydata[1], false)){
				
						if(select == 0){
							
							//보병용장갑 1레벨
							
							if(playercredit[client] >= ARMOR_PRICE){
								
								playercredit[client] -= ARMOR_PRICE;
								
								GivePlayerItem(client, "item_assaultsuit");
								
							}else{
								
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", ARMOR_PRICE);
								
							}
							
						}else if(select == 1){
							
							//특수보병용장갑 2레벨
							if(techlevel >= 2){
							
								if(playercredit[client] >= HEAVYARMOR_PRICE){
									
									playercredit[client] -= HEAVYARMOR_PRICE;
									
									GivePlayerItem(client, "item_assaultsuit");
									SetEntProp(client, Prop_Data, "m_ArmorValue", 200);
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", HEAVYARMOR_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04특수보병용장갑을 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else if(select == 2){
							
							//섬광수류탄 1레벨
							if(playercredit[client] >= WEAPON_FLASHBANG_PRICE){
								
								playercredit[client] -= WEAPON_FLASHBANG_PRICE;
									
								GivePlayerItem(client, "weapon_flashbang");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_FLASHBANG_PRICE);
									
							}
							
						}else if(select == 3){
							
							//연막수류탄1레벨
							if(playercredit[client] >= WEAPON_SMOKEGRENADE_PRICE){
								
								playercredit[client] -= WEAPON_SMOKEGRENADE_PRICE;
									
								GivePlayerItem(client, "weapon_smokegrenade");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_SMOKEGRENADE_PRICE);
									
							}
							
						}else if(select == 4){
							
							//고폭수류탄
							if(playercredit[client] >= WEAPON_HEGRENADE_PRICE){
								
								playercredit[client] -= WEAPON_HEGRENADE_PRICE;
									
								GivePlayerItem(client, "weapon_hegrenade");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_HEGRENADE_PRICE);
									
							}
							
						}else if(select == 5){
							
							//야간투시경1레벨
							if(playercredit[client] >= NIGHTVISION_PRICE){
								
								playercredit[client] -= NIGHTVISION_PRICE;
								
								GivePlayerItem(client, "item_nvgs");
									
							}else{
									
								PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", NIGHTVISION_PRICE);
									
							}
							
						}else if(select == 6){
							
							//생체강화특수복2레벨
							if(techlevel >= 2){
								
								if(playercredit[client] >= BIOSUIT_PRICE){
								
									playercredit[client] -= BIOSUIT_PRICE;
									
									SetEntProp(client, Prop_Data, "m_iMaxHealth", BIOSUIT_MAXHEALTH);
									
									SetEntProp(client, Prop_Data, "m_iHealth", BIOSUIT_MAXHEALTH);
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", BIOSUIT_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 2 이상이어야 합니다.");
								
							}
							
						}else if(select == 7){
							
							//특수생체강화특수복3레벨
							if(techlevel == 3){
								
								if(playercredit[client] >= WEAPON_FIVESEVEN_PRICE){
								
									playercredit[client] -= WEAPON_FIVESEVEN_PRICE;
									
									SetEntProp(client, Prop_Data, "m_iMaxHealth", HEAVYBIOSUIT_MAXHEALTH);
									
									SetEntProp(client, Prop_Data, "m_iHealth", HEAVYBIOSUIT_MAXHEALTH);
									
								}else{
									
									PrintToChat(client, "\x04크레디트가 부족합니다. 필요한 크레디트 : %d", WEAPON_FIVESEVEN_PRICE);
									
								}
								
							}else{
								
								PrintToChat(client, "\x04그 무기를 사려면 테크레벨이 3 이이어야 합니다.");
								
							}
							
						}else if(select == 8){
							
							//뒤로가기메뉴
							cssarmourymenu(client, target, entitydata[1]);
							
						}
						
					}else{
			
						PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
					}
					
				}else{
			
					PrintToChat(client, "\x04사용하려는 아머리는 파괴된 것 같습니다.");
						
				}
				
			}
			
		}else{
			
			PrintToChat(client, "\x04인간만이 아머리 시스템을 사용할 수 있습니다.");
			
		}
		
	}else if(action == MenuAction_Cancel){
			
		PrintToChat(client, "\x04아머리 시스템을 종료하셨습니다.");
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

public cssdeleteallpistol(client){
	
	if(isplayerconnectedingamealive(client)){
	
		for(new i = 0; i < 48; i++){
		
			new weapon = GetEntDataEnt2(client, weaponoffset + i);
		
			if(weapon > 0){
				
				decl String:tempweaponname[64];
				GetEdictClassname(weapon, tempweaponname, 64);
				
				if(StrEqual("weapon_usp", tempweaponname, false) || StrEqual("weapon_glock", tempweaponname, false) ||
					StrEqual("weapon_deagle", tempweaponname, false) || StrEqual("weapon_p228", tempweaponname, false) ||
					StrEqual("weapon_elite", tempweaponname, false) || StrEqual("weapon_fiveseven", tempweaponname, false)){
						
					RemovePlayerItem(client, weapon);
					RemoveEdict(weapon);
									
				}
								
			}
						
		}
		
	}
	
}

public cssdeleteallrifle(client){
	
	if(isplayerconnectedingamealive(client)){
	
		for(new i = 0; i < 48; i++){
		
			new weapon = GetEntDataEnt2(client, weaponoffset + i);
		
			if(weapon > 0){
				
				decl String:tempweaponname[64];
				GetEdictClassname(weapon, tempweaponname, 64);
					
				if(StrEqual("weapon_m4a1", tempweaponname, false) || StrEqual("weapon_ak47", tempweaponname, false) ||
					StrEqual("weapon_aug", tempweaponname, false) || StrEqual("weapon_sg552", tempweaponname, false) ||
					StrEqual("weapon_galil", tempweaponname, false) || StrEqual("weapon_famas", tempweaponname, false) ||
					StrEqual("weapon_scout", tempweaponname, false) || StrEqual("weapon_sg550", tempweaponname, false) ||
					StrEqual("weapon_m249", tempweaponname, false) || StrEqual("weapon_g3sg1", tempweaponname, false) ||
					StrEqual("weapon_ump45", tempweaponname, false) || StrEqual("weapon_mp5navy", tempweaponname, false) ||
					StrEqual("weapon_m3", tempweaponname, false) || StrEqual("weapon_xm1014", tempweaponname, false) ||
					StrEqual("weapon_tmp", tempweaponname, false) || StrEqual("weapon_mac10", tempweaponname, false) ||
					StrEqual("weapon_p90", tempweaponname, false) || StrEqual("weapon_awp", tempweaponname, false)){
						
					RemovePlayerItem(client, weapon);
					RemoveEdict(weapon);
									
				}
								
			}
						
		}
		
	}
	
}