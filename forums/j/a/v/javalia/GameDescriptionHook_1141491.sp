/*****************************게임의 설명문을 바꾸는 플러그인***********************/
/*to use this plugin, u need sourcemod 1.3 or later and sdkhooks
 *after install all need things, just add gamedescription = "your descriptions" on server.cfg
 *or u can just type it in server console or via rcon
 *to make edited description to default one, just type gamedescription ""
 *if u use non ascii character on gamedescription and u are using server.cfg or other cfgfile for setting, u must
 *besure file format of cfgfile must be utf-8
 *if u feel all of these thing are so hard, just edit defaultgamedescription as u wish.
 *
 *이 플러그인을 쓰려면 소스모드 1.3 혹은 이후 버전과 sdkhooks가 필요하다.
 *필요한 것들을 모두 설치한 뒤에는 그냥 gamedescription = "당신이 원하는 설명" 을 server.cfg에 추가하면 된다.
 *혹은 그냥 서버콘솔에 입력하거나 rcon을 통해 입력해도 된다
 *수정한 설명을 기본값으로 되돌리려면 그냥 gamedescription "" 을 치면 된다
 *만약 게임데스크립션에 아스키문자가 아닌 문자를 쓰고, server.cfg나 다른 설정파일을 설정에 이용한다면,
 *당신은 반드시 파일의 형식을 utf-8로 해야한다.
 *만약 이 모든 것이 다 너무 어렵다면, 그냥 defaultgamedescription을 당신이 원하는 대로 수정하면 된다
 *
 */


public Plugin:myinfo = {
	
	name = "Game Description Hook",
	author = "javalia",
	description = "Game Description Hook(using SDKHooks)",
	version = "1.1.0.0",
	url = "http://www.sourcemod.net/"
	
};

//인클루드문장
#include <sourcemod>
#include <sdktools>
#include "sdkhooks"

//문법정의
#pragma semicolon 1

new const String:defaultgamedescription[] = "賢狼호로";

new bool:maproadfinish = false;

new Handle:cvargamedescription = INVALID_HANDLE;

public Action:OnGetGameDescription(String:gamedesc[64]){
		
	if(maproadfinish && cvargamedescription != INVALID_HANDLE){
		
		decl String:buffer[64];
		
		GetConVarString(cvargamedescription, buffer, 64);
		
		if(!StrEqual(buffer, "")){
			
			strcopy(gamedesc, 64, buffer);
		
			return Plugin_Changed;
		
		}
		
	}
	
	return Plugin_Continue;

}

public OnPluginStart(){
	
	cvargamedescription = CreateConVar("gamedescription", defaultgamedescription, "game description of server", FCVAR_NOTIFY | FCVAR_PLUGIN);
	
}

public OnMapStart(){
	
	maproadfinish = true;
	
}

public OnMapEnd(){
	
	maproadfinish = false;
	
}