new const String:PluginVersion[60] = "1.0.0.4";

public Plugin:myinfo = {
	
	name = "SoundWrapper",
	author = "javalia",
	description = "provide SoundWrapper for other plugins",
	version = PluginVersion,
	url = "http://www.sourcemod.net/"
	
};

#include <sourcemod>
#include <sdktools>
#include "sdkhooks"

#pragma semicolon 1

#define MASTERKEYMAXLENGTH 128
#define SOUNDMAXLENGTH 128

#define ELEMENT_CHANNAL 0
#define ELEMENT_LEVEL 1
#define ELEMENT_FLAGS 2
#define ELEMENT_VOLUME 3
#define ELEMENT_PITCH 4
#define SOUNDDATASIZE 5

new Handle:forwardSWOnRegistSound = INVALID_HANDLE;

/*comment in english for devolopers whom cannot understand any korean comments in this code
 *masterkeytrie is trie that saves masterkey`s handle
 *masterkey is trie that saves group of sound`s path and data, or group of sound`s abstraction
 *sounditeratortrie is trie that saves array which is saving list of soundpath of masterkey with same trie key name as masterkey
 *masterkeyiterator is array that saves list of masterkey
*/

//이것은 각각의 소리의 마스터키의 이름을 키로하고 [해당 마스터키의 소리경로를 키로 삼아 소리정보를 배열로 저장하는 트리의 핸들]을 저장한다
new Handle:masterkeytrie = INVALID_HANDLE;
//이것은 각각의 소리의 마스터키의 이름을 키로하고 [해당 마스터키의 소리경로를 이터레이터 목적으로 저장해두는 어레이의 핸들]을 저장한다
new Handle:sounditeratortrie = INVALID_HANDLE;
//이것은 마스터키와 사운드 이터레이터에서 이터레이터로 사용할 마스터키의 목록을 저장한다
new Handle:masterkeyiterator = INVALID_HANDLE;

public OnPluginStart(){
	
	//모든 자유 저장공간 객체를 생성해야한다
	masterkeytrie = CreateTrie();
	sounditeratortrie = CreateTrie();
	masterkeyiterator = CreateArray(MASTERKEYMAXLENGTH);
	
	RegServerCmd("sm_soundwrapper_dump_handles", cmd_admin_dump_handles, "show every handles on soundwrapper for debug");
	
}

public OnPluginEnd(){

	//모든 자유 저장공간 객체를 할당 해체해야 한다
	
	//마스터키 이터레이터로부터 모든 마스터키의 이름을 얻어와서 마스터키를 할당 해제하고, 해당 마스터키를 트리에서 제거한다
	//소리 이터레이터에서 해당 마스터키의 이터레이터 어레이를 얻어와서 할당해제하고, 소리 이터레이터로부터 해당 마스터키의 정보를 제거한다
	new masterkeyiteratorsize = GetArraySize(masterkeyiterator); 
	
	for(new i = 0; i < masterkeyiteratorsize; i++){
	
		decl String:masterkeytoremove[MASTERKEYMAXLENGTH];
		GetArrayString(masterkeyiterator, i, masterkeytoremove, MASTERKEYMAXLENGTH);
		
		decl Handle:masterkey;
	
		//해당 마스터키가 마스터키 트리에 존재하는지 확인
		if(GetTrieValue(masterkeytrie, masterkeytoremove, masterkey)){
			
			//마스터키 트리가 존재하므로 마스터키(의 트리)를 할당해제한다
			CloseHandle(masterkey);
			PrintToServer("[SW] Closed Handle of Masterkey <%s>", masterkeytoremove);
			
		}
		
		//소리 이터레이터에서 해당 마스터키의 트리와 그 트리가 가진 어레이를 제거한다
		decl Handle:sounditerator;
		
		//해당 소리 이터레이터 어레이가 존재하는지 확인
		if(GetTrieValue(sounditeratortrie, masterkeytoremove, sounditerator)){
			
			//이터레이터 어레이가 존재한다
			//이터레이터 어레이를 할당 해제한다
			CloseHandle(sounditerator);
			PrintToServer("[SW] Closed Handle of Sound Iterator of Masterkey <%s>", masterkeytoremove);
			
		}
	
	}
	
	CloseHandle(masterkeytrie);
	CloseHandle(sounditeratortrie);
	CloseHandle(masterkeyiterator);
	PrintToServer("[SW] Closed MasterKeyTrie Handle");
	PrintToServer("[SW] Closed MasterKeySoundIteratorTrie Handle");
	PrintToServer("[SW] Closed MasterKeyIteratorArray Handle");

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	
	//네티브 함수등록
	
	CreateNative("SW_RegSound", Native_SW_RegSound);
	CreateNative("SW_DeleteSound", Native_SW_DeleteSound);
	CreateNative("SW_GetRandomSoundFromMasterKey", Native_SW_GetSoundOfMasterKey);
	CreateNative("SW_StopSound", Native_SW_StopSound);
	
	forwardSWOnRegistSound = CreateGlobalForward("SWRegistSoundOnMapStart", ET_Event);
	
	RegPluginLibrary("SoundWrapper");
	
	return APLRes_Success;
	
}

public OnMapStart(){
	
	PrintToServer("[SW] Loading Sound Regist List");
	
	if(GetForwardFunctionCount(forwardSWOnRegistSound) > 0){
			
		Call_StartForward(forwardSWOnRegistSound);
		Call_Finish();
		
	}
	
	//등록된 모든 소리를 프리캐시 해야 한다
	precacheregisteredsound();
	
}


//네이티브 함수 정의

public Native_SW_RegSound(Handle:plugin, args){
	
	decl String:masterkeyname[MASTERKEYMAXLENGTH], String:soundpath[SOUNDMAXLENGTH];
	GetNativeString(1, masterkeyname, MASTERKEYMAXLENGTH);
	GetNativeString(2, soundpath, SOUNDMAXLENGTH);
	new defaultchannel = GetNativeCell(3);
	new defaultlevel = GetNativeCell(4);
	new defaultflags = GetNativeCell(5);
	new Float:defaultvolume = Float:GetNativeCell(6);
	new defaultpitch = GetNativeCell(7);
	
	decl Handle:masterkey;
	//해당 마스터키가 마스터키 트리가 존재하는지 확인
	if(!GetTrieValue(masterkeytrie, masterkeyname, masterkey)){
		
		//마스터키가 존재하지 않는다
		
		//마스터키를 생성한다
		masterkey = CreateTrie();
		SetTrieValue(masterkeytrie, masterkeyname, masterkey, false);
		//마스터키의 이름을 이터레이터를 추가한다
		PushArrayString(masterkeyiterator, masterkeyname); 
		
	}
	//마스터키에 소리경로를 키로 하는 트리항목을 추가(있을 경우 덮어쓰기)한다
	//내용은 소리의 정보를 담은 배열로 한다
	decl sounddata[SOUNDDATASIZE];
	writesounddata(sounddata, defaultchannel, defaultlevel, defaultflags, defaultvolume, defaultpitch);
	SetTrieArray(masterkey, soundpath, sounddata, SOUNDDATASIZE);
	
	
	//소리 경로를 이터레이터에 추가해야 한다
	//소리경로 이터레이터에 해당 마스터키의 어레이가 있는지 확인 후 없으면 추가
	decl Handle:sounditerator;
	//해당 소리 이터레이터 어레이가 존재하는지 확인
	if(!GetTrieValue(sounditeratortrie, masterkeyname, sounditerator)){
		
		//이터레이터 어레이가 존재하지 않는다
		//이터레이터 어레이를 생성한다
		sounditerator = CreateArray(SOUNDMAXLENGTH);
		SetTrieValue(sounditeratortrie, masterkeyname, sounditerator, false);
		
	}
	//소리 이터레이터 어레이에 소리경로를 추가한다
	if(FindStringInArray(sounditerator, soundpath) == -1){
	
		PushArrayString(sounditerator, soundpath);
	
	}

}

public Native_SW_DeleteSound(Handle:plugin, args){

	decl String:masterkeyname[MASTERKEYMAXLENGTH], String:soundname[SOUNDMAXLENGTH];
	GetNativeString(1, masterkeyname, MASTERKEYMAXLENGTH);
	GetNativeString(2, soundname, SOUNDMAXLENGTH);
	
	new bool:removemasterkey = false;
	if(StrEqual(soundname, "")){
	
		removemasterkey = true;
	
	}
	
	new Handle:masterkey = INVALID_HANDLE;
	
	//해당 마스터키가 마스터키 트리에 존재하는지 확인
	if(GetTrieValue(masterkeytrie, masterkeyname, masterkey)){
		
		//마스터키 전체를 삭제해야 한다
		if(removemasterkey){
		
			//마스터키가 마스터키 트리에 존재하므로 마스터키(의 트리)를 할당해제한다
			CloseHandle(masterkey);
			
			//마스터키 트리에서 해당 마스터키를 제거한다
			RemoveFromTrie(masterkeytrie, masterkeyname);
			//마스터키의 이름을 마스터키 이터레이터에서 제거한다
			RemoveFromArray(masterkeyiterator, FindStringInArray(masterkeyiterator, masterkeyname));
		
		}else{
		
			//마스터키에서 해당 소리에 대한 정보만 삭제한다
			RemoveFromTrie(masterkey, soundname);
		
		}
		
	}
	
	//소리 이터레이터에서 해당 마스터키의 트리와 그 트리가 가진 어레이를 제거한다
	new Handle:sounditerator = INVALID_HANDLE;
	
	//해당 소리 이터레이터 어레이가 존재하는지 확인
	if(GetTrieValue(sounditeratortrie, masterkeyname, sounditerator)){
		
		//이터레이터 전체를 삭제해야 한다
		if(removemasterkey){
		
			//이터레이터 어레이가 존재한다
			//이터레이터 어레이를 할당 해제한다
			CloseHandle(sounditerator);
			//소리 이터레이터 트리에서 해당 마스터키의 소리 이터레이터를 제거한다
			RemoveFromTrie(sounditeratortrie, masterkeyname);
			
		}else{
		
			//이터레이터에서 해당 소리 부분만 삭제해야한다
			new iteratorindextoremove = FindStringInArray(sounditerator, soundname);
			if(iteratorindextoremove != -1){
	
				RemoveFromArray(sounditerator, iteratorindextoremove);
			
			}
		
		}
		
	}
	
	//부분삭제인 경우, 만약 삭제 뒤에 마스터키에 아무것도 안 남아있다면, 마스터키와 이터레이터를 정리해야한다
	if(!removemasterkey){
		
		if(masterkey != INVALID_HANDLE && sounditerator != INVALID_HANDLE){
			
			//마스터키의 사운드 이터레이터 목록이 비었을 경우 마스터키 삭제
			if(GetArraySize(sounditerator) == 0){
			
				//마스터키가 마스터키 트리에 존재하므로 마스터키(의 트리)를 할당해제한다
				CloseHandle(masterkey);
				//마스터키 트리에서 해당 마스터키를 제거한다
				RemoveFromTrie(masterkeytrie, masterkeyname);
				//마스터키의 이름을 마스터키 이터레이터에서 제거한다
				RemoveFromArray(masterkeyiterator, FindStringInArray(masterkeyiterator, masterkeyname));
				//이터레이터 어레이를 할당 해제한다
				CloseHandle(sounditerator);
				//소리 이터레이터 트리에서 해당 마스터키의 소리 이터레이터를 제거한다
				RemoveFromTrie(sounditeratortrie, masterkeyname);
			
			}
			
		}
	
	}

}

public Native_SW_GetSoundOfMasterKey(Handle:plugin, args){

	decl String:masterkeyname[MASTERKEYMAXLENGTH], String:tempsound[SOUNDMAXLENGTH];
	GetNativeString(1, masterkeyname, MASTERKEYMAXLENGTH);
	
	decl channel, level, flags, Float:volume, pitch;
	
	if(getrandomsoundfrommasterkey(masterkeyname, tempsound, SOUNDMAXLENGTH, channel, level, flags, volume, pitch)){
	
		SetNativeString(2, tempsound, GetNativeCell(3));
		
		SetNativeCellRef(4, channel);
		SetNativeCellRef(5, level);
		SetNativeCellRef(6, flags);
		SetNativeCellRef(7, volume);
		SetNativeCellRef(8, pitch);
		
	}else{
	
		ThrowNativeError(SP_ERROR_PARAM, "MasterKey <%s> not found", masterkeyname);
	
	}
	
}

public Native_SW_StopSound(Handle:plugin, args){

	//마스터키에 등록된 모든 소리를 꺼야한다
	new entity = GetNativeCell(1);
	decl String:masterkeyname[MASTERKEYMAXLENGTH];
	GetNativeString(2, masterkeyname, MASTERKEYMAXLENGTH);
	new bool:override = GetNativeCell(3);
	new channel = GetNativeCell(4);
	
	decl Handle:sounditerator;
	
	decl Handle:masterkey;
	
	//해당 마스터키가 마스터키 트리에 존재하는지 확인
	if(!GetTrieValue(masterkeytrie, masterkeyname, masterkey)){
	
		//마스터키가 없으므로 리턴
		return;
	
	}
	
	//해당 소리 이터레이터 어레이가 존재하는지 확인
	if(GetTrieValue(sounditeratortrie, masterkeyname, sounditerator)){
		
		new sounditeratorsize = GetArraySize(sounditerator);
		
		decl String:soundpath[SOUNDMAXLENGTH];
		
		for(new sounditeratorindex = 0; sounditeratorindex < sounditeratorsize; sounditeratorindex++){
			
			//사운드 이터레이터에서 소리 경로를 얻어낸다
			if(GetArrayString(sounditerator, sounditeratorindex, soundpath, SOUNDMAXLENGTH)){
				
				//이 시점에서는 마스터키가 존재하는 것이 확실하므로, 곧장 자료를 읽어들인다
				decl tempsounddata[SOUNDDATASIZE];
					
				if(GetTrieArray(masterkey, soundpath, tempsounddata, SOUNDDATASIZE)){
					
					//이제 설정에 따라 스톱사운드를 수행
					if(override){
					
						StopSound(entity, channel, soundpath);
					
					}else{
					
						StopSound(entity, tempsounddata[ELEMENT_CHANNAL], soundpath);
					
					}
					
				}
				
			}
		
		}
		
	}

}

writesounddata(array[SOUNDDATASIZE], channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS,
				Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL){
				
	array[ELEMENT_CHANNAL] = channel;
	array[ELEMENT_LEVEL] = level;
	array[ELEMENT_FLAGS] = flags;
	array[ELEMENT_VOLUME] = any:volume;
	array[ELEMENT_PITCH] = pitch;
				
}

readsounddata(array[SOUNDDATASIZE], &channel, &level, &flags, &Float:volume, &pitch){

	channel = array[ELEMENT_CHANNAL];
	level = array[ELEMENT_LEVEL];
	flags = array[ELEMENT_FLAGS];
	volume = Float:array[ELEMENT_VOLUME];
	pitch = array[ELEMENT_PITCH];

}

precacheregisteredsound(){

	new masterkeyiteratorsize = GetArraySize(masterkeyiterator); 
	
	decl String:masterkey[MASTERKEYMAXLENGTH];
	
	for(new i = 0; i < masterkeyiteratorsize; i++){
	
		GetArrayString(masterkeyiterator, i, masterkey, MASTERKEYMAXLENGTH);
		
		//PrintToServer("마스터키 발견 : %s", masterkey);
		
		decl Handle:sounditerator;
		
		//해당 소리 이터레이터 어레이가 존재하는지 확인
		if(GetTrieValue(sounditeratortrie, masterkey, sounditerator)){
			
			//PrintToServer("마스터키 %s 의 사운드 이터레이터 발견", masterkey);
			
			new sounditeratorsize = GetArraySize(sounditerator);
			
			decl String:soundpath[SOUNDMAXLENGTH];
			
			for(new sounditeratorindex = 0; sounditeratorindex < sounditeratorsize; sounditeratorindex++){
				
				GetArrayString(sounditerator, sounditeratorindex, soundpath, SOUNDMAXLENGTH);
				PrecacheSound(soundpath, true);
				
				//PrintToServer("%s 를 프리캐시 했습니다", soundpath);
			
			}
			
		}
	
	}

}

//마스터키에서 무작위의 소리를 가져온다
bool:getrandomsoundfrommasterkey(const String:masterkeyname[], String:sound[], soundlength, &channel, &level, &flags, &Float:volume, &pitch){

	//소리 이터레이터에서 해당 마스터키의 소리를 랜덤하게 선택한다.
	//그리고 선택한 소리를 키로 마스터키의 값에 접근
	decl Handle:sounditerator;
		
	//해당 소리 이터레이터 어레이가 존재하는지 확인
	if(GetTrieValue(sounditeratortrie, masterkeyname, sounditerator)){
		
		//아무 소리나 랜덤하게 가져온다
		GetArrayString(sounditerator, GetRandomInt(0, GetArraySize(sounditerator) - 1), sound, soundlength);
		
		//마스터키 트리에서 해당 마스터키의 해당 소리의 정보를 가져와야 한다
		decl Handle:masterkey;
	
		//해당 마스터키가 마스터키 트리에 존재하는지 확인
		if(GetTrieValue(masterkeytrie, masterkeyname, masterkey)){
			
			//마스터키가 마스터키 트리에 존재하므로 마스터키에서 선택한 소리의 정보를 얻어온다
			decl tempsounddata[SOUNDDATASIZE];
			
			if(GetTrieArray(masterkey, sound, tempsounddata, SOUNDDATASIZE)){
			
				readsounddata(tempsounddata, channel, level, flags, volume, pitch);
				return true;
			
			}
			
		}
		
	}
	
	return false;

}

public Action:cmd_admin_dump_handles(args){
	
	PrintToServer("[SW] Dumping Every Masterkey Handle Datas");
	
	//수집해야 할 정보 : 
	//마스터키 이터레이터에 등록된 마스터키의 갯수
	//실제로 마스터키 트리에 존재하는 마스터키의 갯수
	//마스터키 트리에 존재하지 않는 마스터키의 갯수
	//마스터키 소리 이터레이터 중 존재하는 것의 갯수
	//마스터키 소리 이터레이터 중 존재하지 않는 것의 갯수
	//마스터키 소리 중 마스터키에 존재하는 소리의 갯수
	//마스터키 소리 중 마스터키에 존재하지 않는 소리의 갯수
	new totalmasterkey = 0,
		totalexistmasterkey = 0, totalerrormasterkey = 0,
		totalmasterkeyiterator = 0, totalerrormasterkeyiterator = 0,
		totalregisteredsound = 0, totalerrersound = 0;
	
	totalmasterkey = GetArraySize(masterkeyiterator);
	
	for(new i = 0; i < totalmasterkey; i++){
		
		//등록된 마스터키의 갯수를 더한다
		decl String:masterkeyname[MASTERKEYMAXLENGTH];
		GetArrayString(masterkeyiterator, i, masterkeyname, MASTERKEYMAXLENGTH);
		
		decl Handle:masterkey;
	
		//해당 마스터키가 마스터키 트리에 존재하는지 확인
		if(GetTrieValue(masterkeytrie, masterkeyname, masterkey)){
			
			totalexistmasterkey++;
			PrintToServer("[SW] Masterkey <%s>`s trie handle has found from MasterKey trie", masterkeyname);
			
		}else{
			
			//트리에 존재하지 않는 마스터키
			totalerrormasterkey++;
			PrintToServer("[SW] ERROR : Masterkey <%s>`s trie handle has not found from MasterKey trie", masterkeyname);
		
		}
		
		decl Handle:sounditerator;
		
		//해당 소리 이터레이터 어레이가 존재하는지 확인
		if(GetTrieValue(sounditeratortrie, masterkeyname, sounditerator)){
			
			totalmasterkeyiterator++;
			
			new temptotalsound = 0;
			new temptotalerrorsound = 0;
			
			PrintToServer("[SW] Masterkey <%s>`s iterator has found", masterkeyname);
			
			new sounditeratorsize = GetArraySize(sounditerator);
			
			decl String:soundpath[SOUNDMAXLENGTH];
			
			for(new sounditeratorindex = 0; sounditeratorindex < sounditeratorsize; sounditeratorindex++){
				
				if(GetArrayString(sounditerator, sounditeratorindex, soundpath, SOUNDMAXLENGTH)){
					
					PrintToServer("[SW] Masterkey <%s>`s sound <%s> has found from iterator", masterkeyname, soundpath);
					
					decl tempsounddata[SOUNDDATASIZE];
			
					if(GetTrieArray(masterkey, soundpath, tempsounddata, SOUNDDATASIZE)){
						
						totalregisteredsound++;
						temptotalsound++;
						PrintToServer("[SW] Masterkey <%s>`s sound <%s>`s data has found from Masterkey", masterkeyname, soundpath);
					
					}else{
					
						totalerrersound++;
						temptotalerrorsound++;
						PrintToServer("[SW] ERROR : Masterkey <%s>`s sound <%s> has no data on Masterkey", masterkeyname, soundpath);
					
					}
					
				}
			
			}
			
			PrintToServer("[SW] Masterkey <%s> has %d sound and %d error sound", masterkeyname, temptotalsound, temptotalerrorsound);
			
		}else{
			
			totalerrormasterkeyiterator++;
			PrintToServer("[SW] ERROR : Masterkey <%s> has no iterator", masterkeyname);
		
		}
	
	}
	
	PrintToServer("[SW] SoundWrapper has total %d Masterkey in list", totalmasterkey);
	PrintToServer("[SW] SoundWrapper has total %d Exist Masterkey", totalexistmasterkey);
	PrintToServer("[SW] SoundWrapper has total %d Error Masterkey", totalerrormasterkey);
	PrintToServer("[SW] SoundWrapper has total %d Exist Masterkey Sound Iterator", totalmasterkeyiterator);
	PrintToServer("[SW] SoundWrapper has total %d Error Masterkey Sound Iterator", totalerrormasterkeyiterator);
	PrintToServer("[SW] SoundWrapper has total %d Registered Sound", totalregisteredsound);
	PrintToServer("[SW] SoundWrapper has total %d Error Sound", totalerrersound);
	
	return Plugin_Handled;

}