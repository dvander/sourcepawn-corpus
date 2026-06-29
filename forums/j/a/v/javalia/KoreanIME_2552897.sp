/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.3.6";

public Plugin:myinfo = {
	
	name = "Korean IME",
	author = "javalia",
	description = "korean input support for some server owners/players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>

//semicolon!!!!
#pragma semicolon 1

//derpherp
new const TRANSCODE_EMPTY =  0;
new const TRANSCODE_FIRST_SYLLABLE = 1;
new const TRANSCODE_SECOND_SYLLABLE = 2;
new const TRANSCODE_LAST_SYLLABLE = 3;

/*ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ */
/* r R s e E f a q Q t T d w W c z x v h */
new const FIRST_SYLLABLE[] = {

	0x3131, 0x3132, 0x3134, 0x3137, 0x3138, 0x3139, 0x3141, 0x3142, 0x3143, 0x3145,
	0x3146, 0x3147, 0x3148, 0x3149, 0x314a, 0x314b, 0x314c, 0x314d, 0x314e
	
};

/*ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ*/
/* k o i O j p u P h hk ho hl y n nj np nl b m ml l */
new const SECOND_SYLLABLE[] = {

	0x314f, 0x3150, 0x3151, 0x3152, 0x3153, 0x3154, 0x3155, 0x3156, 0x3157, 0x3158,
	0x3159, 0x315a, 0x315b, 0x315c, 0x315d, 0x315e, 0x315f, 0x3160, 0x3161, 0x3162,
	0x3163
	
};


/*\0 ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ*/
/*\0 r R rt s sw sg e f fr fa fq ft fx fv fg a q qt t T d w c z x v g */
new const LAST_SYLLABLE[] = {

	0x0000, 0x3131, 0x3132, 0x3133, 0x3134, 0x3135, 0x3136, 0x3137, 0x3139, 0x313a,
	0x313b, 0x313c, 0x313d, 0x313e, 0x313f, 0x3140, 0x3141, 0x3142, 0x3144, 0x3145,
	0x3146, 0x3147, 0x3148, 0x314a, 0x314b, 0x314c, 0x314d, 0x314e
	
};

new const String:FIRST_SYLLABLE_ENGLISH_TYPE[][] = {

	"r", "R", "s,S", "e", "E", "f,F", "a,A", "q", "Q", "t", "T", "d,D", "w", "W", "c,C", "z,Z", "x,X", "v,V", "g,G", ""

};

new const String:SECOND_SYLLABLE_ENGLISH_TYPE[][] = {

	"k,K", "o", "i,I", "O", "j,J", "p", "u,U", "P", "h,H", "hk,HK,Hk,hK", "ho,HO,Ho", "hl,HL,Hl,hL", "y,Y", "n,N", "nj,NJ,Nj,nJ",
		"np,Np,", "nl,NL,Nl,nL", "b,B", "m,M", "ml,ML,Ml,mL", "l,L", ""

};

new const String:LAST_SYLLABLE_ENGLISH_TYPE[][] = {

	"", "r", "R", "rt", "s,S", "sw,Sw", "sg,SG,Sg,sG", "e", "f,F", "fr,Fr", "fa,FA,Fa,fA", "fq,Fq", "ft,Ft",
		"fx,FX,Fx,fX", "fv,FV,Fv,fV", "fg,FG,Fg,fG", "a,A", "q", "qt", "t", "T", "d,D", "w", "c,C", "z,Z", "x,X", "v,V", "g,G", ""

};
	
new Handle:g_cvarTrigger = INVALID_HANDLE;
new Handle:g_cvarClientTrigger = INVALID_HANDLE;
new Handle:g_cvarServerTrigger = INVALID_HANDLE;

new Handle:g_hFilter[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

public OnPluginStart(){
	
	for(new i = 0; i <= MAXPLAYERS; i++){
	
		g_hFilter[i] = CreateArray(ByteCountToCells(256));
	
	}
	
	CreateConVar("KoreanIME_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_cvarTrigger = CreateConVar("KoreanIME_trigger", ".", "trigger string/char to do transcoding. setting this to empty string will disable plugin");
	g_cvarClientTrigger = CreateConVar("KoreanIME_clienttrigger", "1", "0 = disable, 1 = enable");
	g_cvarServerTrigger = CreateConVar("KoreanIME_servertrigger", "1", "0 = disable, 1 = enable");
	
	AddCommandListener(cmdSay, "say");
	AddCommandListener(cmdSay, "say_team");
	
}

public OnPluginEnd(){

	for(new i = 0; i <= MAXPLAYERS; i++){
	
		CloseHandle(g_hFilter[i]);
		
	}

}

public OnMapStart(){

	AutoExecConfig();

}

public Action:cmdSay(client, String:cmdname[], args){
	
	if(client == 0){
	
		if(!GetConVarBool(g_cvarServerTrigger)) return Plugin_Continue;
	
	}else{
	
		if(!GetConVarBool(g_cvarClientTrigger)) return Plugin_Continue;
	
	}
	
	decl String:text[255];
	GetCmdArgString(text, 255);
	if(client != 0){StripQuotesOnce(text, 255);}
	new textlength = strlen(text);
	
	decl String:trigger[255];
	GetConVarString(g_cvarTrigger, trigger, 255);
	new triggerlength = strlen(trigger);
	
	if(!StrEqual(trigger, "") && StrContains(text, trigger, false) == 0){
		
		//this prevents feedback of changed say cmd
		//this will take O(1) at most of it`s runtime.
		for(new i = 0; i < GetArraySize(g_hFilter[client]); i++){
		
			new String:comparebuffer[256];
			GetArrayString(g_hFilter[client], i, comparebuffer, 256);
			if(StrEqual(text, comparebuffer, true)){
				
				RemoveFromArray(g_hFilter[client], i);
				return Plugin_Continue;
			
			}
		
		}
		
		new byteswritten;
		new String:resulttext[255];
		
		new transcodestatus;//to flag syllable detect
		new String:first, String:second[3], String:last[3];//to save syllable index that detected.
		
		for(new i = triggerlength; i < textlength; i++){
			
			new String:temp[3];
			temp[0] = text[i];
			
			if(transcodestatus == TRANSCODE_EMPTY){//초성중성종성 아무것도 없다
				
				//한 글자로 입력된 자모는 모두 초성이거나 중성이다.
				
				if(getFirstSyllableIndex(temp[0]) != -1){
					
					first = temp[0];
					transcodestatus = TRANSCODE_FIRST_SYLLABLE;
				
				}else if(getSecondSyllableIndex(temp) != -1){
					
					second[0] = temp[0];
					transcodestatus = TRANSCODE_SECOND_SYLLABLE;
				
				}else{//위의 두 조건을 모두 만족시키지 못한 경우 한글 자모가 아님
				
					putasciicharintobuffer(resulttext, 255, temp[0], byteswritten);
				
				}
			
			}else if(transcodestatus == TRANSCODE_FIRST_SYLLABLE){//초성까지 입력된 경우
				
				//초성이 1개 입력된 상황이므로, 앞으로의 가능성은
				//다른 초성이 들어오고, 그것이 현재 있는 초성과 합쳐지는 게 가능할 경우(두 문자를 종성으로 전환)
				//다른 중성이 들어오고, 그것이 현재 있는 초성에 이어지는 경우
				//그 이외의 문자가 들어와서 조합이 중단될 경우
				
				//초성으로 사용 가능한 문자가 들어올 경우, 그것이 조합 가능한지부터 확인
				if(getFirstSyllableIndex(temp[0]) != -1){
					
					new String:temp2[3];
					temp2[0] = first;
					temp2[1] = temp[0];
					
					//앞 글자와 조합이 가능하므로 종성이 입력된 것이다.
					if(getLastSyllableIndex(temp2) != -1){
						
						first = '\0';
						Format(last, 3, "%s", temp2);
						transcodestatus = TRANSCODE_LAST_SYLLABLE;
					
					}else{
						
						//앞 글자와 조합이 안되므로 초성을 남기고 내보낸다.
						//초성 이후에 종성으로 조합되지 않는 초성 입력이 들어왔다. 완성된 글자를 내보내야 한다.
						pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
						first = temp[0];
						transcodestatus = TRANSCODE_FIRST_SYLLABLE;
						
					}
				
				}else if(getSecondSyllableIndex(temp) != -1){
				
					second[0] = temp[0];
					transcodestatus = TRANSCODE_SECOND_SYLLABLE;
					
				}else{
				
					//초성이 입력된 상태로 한글이 아닌 다른 문자가 들어왔다. 완성된 글자를 내보낸다.
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = '\0';
					transcodestatus = TRANSCODE_EMPTY;//입력 초기화
					putasciicharintobuffer(resulttext, 255, temp[0], byteswritten);
				
				}
			
			}else if(transcodestatus == TRANSCODE_SECOND_SYLLABLE){//중성까지 입력된 상태
				
				//초성과 중성이 모두 있거나, 중성만 있다.
				
				if(getLastSyllableIndex(temp) != -1){//종성이 들어왔다.
				
					//종성이 들어왔다.
					
					if(first != '\0'){//종성을 받아들일 수 있다
						
						last[0] = temp[0];
						transcodestatus = TRANSCODE_LAST_SYLLABLE;
						
					}else{
					
						//초성없는 상태로 종성이 되는 초성을 받은 상태, 현재 글자는 내보낸다.
						pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
						first = temp[0];
						second[0] = second[1] = second[2] = '\0';
						last[0] = last[1] = last[2] = '\0';
						transcodestatus = TRANSCODE_FIRST_SYLLABLE;//입력중인 초성 글자를 다시 버퍼에 남긴다
					
					}
				
				}else if(getFirstSyllableIndex(temp[0]) != -1){
				
					//종성이 될 수 없는 초성 입력이 들어왔다. 완성된 글자를 내보내야 한다.
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = temp[0];
					second[0] = second[1] = second[2] = '\0';
					last[0] = last[1] = last[2] = '\0';
					transcodestatus = TRANSCODE_FIRST_SYLLABLE;//입력중인 초성 글자를 다시 버퍼에 남긴다
				
				}else if(getSecondSyllableIndex(temp) != -1){
				
					//중성이 들어왔다.
					
					if(second[1] != '\0'){//중성이 2개인 상태
					
						//중성 입력이 들어왔지만 받아들일 수 없으므로 완성된 글자를 내보낸다.
						pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
						first = '\0';
						second[0] = temp[0];
						second[1] = '\0';
						//새 중성이 조합중이다
					
					}else{//중성이 1개뿐인 상태
						
						new String:temp2[3];
						temp2[0] = second[0];
						temp2[1] = temp[0];
						
						//이중 모음 중성이 입력된 것이다.
						if(getSecondSyllableIndex(temp2) != -1){
							
							second[1] = temp[0];
							
						}else{
							
							pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
							first = '\0';
							second[0] = temp[0];
							//새 중성이 조합중이다.
							
						}
						
					}
				
				}else{
				
					//중성이 입력된 상태로 한글이 아닌 다른 문자가 들어왔다. 완성된 글자를 내보낸다.
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = '\0';
					second[0] = second[1] = second[2] = '\0';
					last[0] = last[1] = last[2] = '\0';
					transcodestatus = TRANSCODE_EMPTY;
					putasciicharintobuffer(resulttext, 255, temp[0], byteswritten);
				
				}
			
			}else if(transcodestatus == TRANSCODE_LAST_SYLLABLE){
				
				//초성과 중성, 종성이 모두 있거나 종성만 있는 상태이다.
				
				//종성이 온다면 기존 종성과 조합 가능한지 확인
				if(getLastSyllableIndex(temp) != -1){
				
					if(last[1] != '\0'){//종성이 2개인 상태
						
						pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
						first = temp[0];//모든 단일 종성은 초성으로 갈 수 있으므로 초성에 보낸다.
						second[0] = second[1] = second[2] = '\0';
						last[0] = last[1] = last[2] = '\0';
						transcodestatus = TRANSCODE_FIRST_SYLLABLE;//입력중인 초성 글자를 다시 버퍼에 남긴다
						
					}else{//종성이 1개뿐인 상태
					
						//조합 가능한 종성 입력인지 확인
						new String:temp2[3];
						temp2[0] = last[0];
						temp2[1] = temp[0];
						
						//이중 종성이 입력된 것이다.
						if(getLastSyllableIndex(temp2) != -1){
							
							last[1] = temp[0];
							
						}else{
							
							//종성이 이미 있는데 조합될 수 없는 종성이 왔다
							pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
							first = temp[0];//모든 단일 종성은 초성으로 갈 수 있으므로 초성에 보낸다.
							second[0] = second[1] = second[2] = '\0';
							last[0] = last[1] = last[2] = '\0';
							transcodestatus = TRANSCODE_FIRST_SYLLABLE;//입력중인 초성 글자를 다시 버퍼에 남긴다
							
						}
						
					}
				
				}else if(getFirstSyllableIndex(temp[0]) != -1){
				
					//종성까지 입력되었을 때 조합 불가능한 초성이 왔다.
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = temp[0];
					second[0] = second[1] = second[2] = '\0';
					last[0] = last[1] = last[2] = '\0';
					transcodestatus = TRANSCODE_FIRST_SYLLABLE;//입력중인 초성 글자를 다시 버퍼에 남긴다
					
				}else if(getSecondSyllableIndex(temp) != -1){
					
					//종성이 있을 때 중성이 입력된 경우, 종성을 다음 중성에 떼어주고 자신은 완성된다.
					new String:temp2;
					if(last[1] != '\0'){
						
						temp2 = last[1];
						last[1] = '\0';
						
					}else{
					
						temp2 = last[0];
						last[0] = '\0';
					
					}
					
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = temp2;//초성에 보낸다.
					second[0] = temp[0];
					second[1] = '\0';
					last[0] = last[1] = last[2] = '\0';
					transcodestatus = TRANSCODE_SECOND_SYLLABLE;//입력중인 중성 글자를 다시 버퍼에 남긴다
					
				}else{
					
					//한글 자모가 아닌 문자가 들어왔다
					pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
					first = '\0';
					second[0] = second[1] = second[2] = '\0';
					last[0] = last[1] = last[2] = '\0';
					transcodestatus = TRANSCODE_EMPTY;//입력 초기화
					putasciicharintobuffer(resulttext, 255, temp[0], byteswritten);
					
				}
			
			}
		
		}
		
		pututf8charintobuffer(resulttext, 255, first, second, last, byteswritten);
		
		//server`s cmd args cannot take whitespace characters on start of it. so lets just remove it.
		if(client == 0){
		
			while(IsCharSpace(resulttext[0])){
				
				new String:replace[2];
				replace[0] = resulttext[0];
				ReplaceStringEx(resulttext, 255, replace, "");
			
			}
		
		}
		
		PushArrayString(g_hFilter[client], resulttext); 
		
		if(client != 0){
		
			FakeClientCommandEx(client, "%s \"%s\"", cmdname, resulttext);
			
		}else{
		
			ServerCommand("%s %s", cmdname, resulttext);
		
		}
		
		return Plugin_Handled;
		
	}
	
	return Plugin_Continue;

}

putasciicharintobuffer(String:buffer[], maxlength, String:asciichar, &byteswritten){

	if(byteswritten < maxlength - 1){
	
		buffer[byteswritten] = asciichar;
		buffer[byteswritten + 1] = '\0';
		byteswritten++;
	
	}

}

pututf8charintobuffer(String:buffer[], maxlength, String:first, String:second[3], String:last[3], &byteswritten){

	if(byteswritten < maxlength - 3){
		
		new String:utf8buffer[4];
		
		new utf8written = transcodeCharacter(first, second, last, utf8buffer);
		
		if(utf8written == 3){
			
			StrCat(buffer, maxlength, utf8buffer);
			byteswritten = byteswritten + 3;
		
		}
	
	}

}

transcodeCharacter(String:first, String:second[3], String:last[3], String:buffer[4]){

	if(first != '\0'){
		
		if(second[0] != '\0'){
		
			//초성, 중성, 종성까지 모두 있을 수 있다.
			new lastindex = getLastSyllableIndex(last);
			new bitpattern = (0xAC00) + ((getFirstSyllableIndex(first)) * 21 + (getSecondSyllableIndex(second))) * 28 + (lastindex != -1 ? lastindex : 0);
			new character[3];
			character[0] = 0xE0 | ((bitpattern & ~0xFFFF0000) >> 12);
			character[1] = 0x80 | ((bitpattern & ~0xFFFFF000) >> 6);
			character[2] = 0x80 | (bitpattern & ~0xFFFFFFC0);
			return Format(buffer, 4, "%c%c%c", character[0], character[1], character[2]);
		
		}else{//중성이 없으므로 이 글자는 초성만 있는 것이다.
		
			new bitpattern = FIRST_SYLLABLE[getFirstSyllableIndex(first)];
			new character[3];
			character[0] = 0xE0 | ((bitpattern & ~0xFFFF0000) >> 12);
			character[1] = 0x80 | ((bitpattern & ~0xFFFFF000) >> 6);
			character[2] = 0x80 | (bitpattern & ~0xFFFFFFC0);
			return Format(buffer, 4, "%c%c%c", character[0], character[1], character[2]);
		
		}
	
	}else{
	
		//초성이 없다면 중성이나 종성 뿐이다.
		if(second[0] != '\0'){
		
			//종성 뿐이다.
			new bitpattern = SECOND_SYLLABLE[getSecondSyllableIndex(second)];
			new character[3];
			character[0] = 0xE0 | ((bitpattern & ~0xFFFF0000) >> 12);
			character[1] = 0x80 | ((bitpattern & ~0xFFFFF000) >> 6);
			character[2] = 0x80 | (bitpattern & ~0xFFFFFFC0);
			return Format(buffer, 4, "%c%c%c", character[0], character[1], character[2]);
		
		}else if(last[0] != '\0'){
		
			//종성 뿐이다.
			new bitpattern = LAST_SYLLABLE[getLastSyllableIndex(last)];
			new character[3];
			character[0] = 0xE0 | ((bitpattern & ~0xFFFF0000) >> 12);
			character[1] = 0x80 | ((bitpattern & ~0xFFFFF000) >> 6);
			character[2] = 0x80 | (bitpattern & ~0xFFFFFFC0);
			return Format(buffer, 4, "%c%c%c", character[0], character[1], character[2]);
		
		}
		
	}
	
	return 0;

}

getFirstSyllableIndex(String:character){

	for(new i = 0; !StrEqual(FIRST_SYLLABLE_ENGLISH_TYPE[i], ""); i++){
		
		new String:comparebuffer[6][32];//bigger than needed but who carez?
		new count = ExplodeString(FIRST_SYLLABLE_ENGLISH_TYPE[i], ",", comparebuffer, 6, 32);
		
		for(new i2 = 0; i2 < count; i2++){
		
			if(FindCharInString(comparebuffer[i2], character) != -1){
			
				return i;
			
			}
		
		}
	
	}
	
	return -1;

}

getSecondSyllableIndex(String:string[]){
	
	for(new i = 0; !StrEqual(SECOND_SYLLABLE_ENGLISH_TYPE[i], ""); i++){
		
		new String:comparebuffer[6][32];//bigger than needed but who carez?
		new count = ExplodeString(SECOND_SYLLABLE_ENGLISH_TYPE[i], ",", comparebuffer, 6, 32);
		
		for(new i2 = 0; i2 < count; i2++){
		
			if(StrEqual(comparebuffer[i2], string, true)){
			
				return i;
			
			}
		
		}
	
	}
	
	return -1;

}

getLastSyllableIndex(String:string[]){
	
	if(StrEqual(string, "")){
	
		return 0;
	
	}
	
	for(new i = 1; !StrEqual(LAST_SYLLABLE_ENGLISH_TYPE[i], ""); i++){
		
		new String:comparebuffer[6][32];//bigger than needed but who carez?
		new count = ExplodeString(LAST_SYLLABLE_ENGLISH_TYPE[i], ",", comparebuffer, 6, 32);
		
		for(new i2 = 0; i2 < count; i2++){
		
			if(StrEqual(comparebuffer[i2], string, true)){
			
				return i;
			
			}
		
		}
	
	}
	
	return -1;

}

stock bool:StripQuotesOnce(String:targetstring[], maxlength){

	if(targetstring[0] == '"' && targetstring[strlen(targetstring) - 1] == '"'){
		
		ReplaceStringEx(targetstring, maxlength, "\"", "");
		targetstring[strlen(targetstring) - 1] = '\0';
		return true;
	}
	
	return false;

}