/*
silencenades.sp

Description:
		The silence nades plugin control 'Fire in the hole' text and sound

Versions:
		1.0
				* Initial Release
		1.1
				* Fix: radio w/o location
		1.2
				* Add: individual customization
		1.3
				* Add: places translation
		1.4
				* Fix: MaxClients issue
				* Fix: STEAM_ID_PENDING issue
				* Mod: Changed defaults
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.4"
#define MAX_STR_LEN		256

#define NADE_IDX_HE		0
#define NADE_IDX_FL		1
#define NADE_IDX_SM		2

#define NADE_CNT		3

//user settings kv
#define CFG_SND_HE		"s_he"
#define CFG_TXT_HE		"t_he"
#define CFG_SND_FL		"s_fl"
#define CFG_TXT_FL		"t_fl"
#define CFG_SND_SM		"s_sm"
#define CFG_TXT_SM		"t_sm"

//server kv for snd and txt lists
#define NODE_HE			"he"
#define NODE_FL			"fl"
#define NODE_SM			"sm"
#define SND_MASK		"s_%d"
#define TXT_MASK		"t_%d"
#define MAX_CNT			20

#define TEAM_SPEC		1

#define ITEM_SND		0
#define ITEM_TXT		1
#define ITEM_CNT		2

// Plugin definitions
public Plugin:myinfo = {
	name = "silencenades",
	author = "grif_ssa",
	description = "The silence nades plugin control 'Fire in the hole' text and sound by sm_silence_nades",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new g_LastPlaceName = -1;

new Handle:g_CvarSndDefHE = INVALID_HANDLE;
new Handle:g_CvarTxtDefHE = INVALID_HANDLE;
new Handle:g_CvarSndDefFl = INVALID_HANDLE;
new Handle:g_CvarTxtDefFl = INVALID_HANDLE;
new Handle:g_CvarSndDefSm = INVALID_HANDLE;
new Handle:g_CvarTxtDefSm = INVALID_HANDLE;

new bool:g_lateLoaded;
new UserMsg:g_umRadioText;
new UserMsg:g_umSendAudio;
new Handle:g_kvCfg = INVALID_HANDLE;
new Handle:g_kvSndTxt = INVALID_HANDLE;
new String:g_snd[NADE_CNT][MAXPLAYERS+1][MAX_STR_LEN];
new String:g_txt[NADE_CNT][MAXPLAYERS+1][MAX_STR_LEN];
new String:g_fnameCfg[MAX_STR_LEN];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	g_lateLoaded = late;

	return APLRes_Success;
}

public OnPluginStart(){
LogMessage("OnPluginStart");
	decl String:tmp[PLATFORM_MAX_PATH];

	LoadTranslations("plugin.silencenades.phrases");
	LoadTranslations("plugin.silencenades.places");

	CreateConVar("sm_silence_nades_version", PLUGIN_VERSION, "silence nades version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarSndDefHE = CreateConVar("sm_silence_nades_sound_he_default", "");
	g_CvarTxtDefHE = CreateConVar("sm_silence_nades_text_he_default", "");
	g_CvarSndDefFl = CreateConVar("sm_silence_nades_sound_flash_default", "");
	g_CvarTxtDefFl = CreateConVar("sm_silence_nades_text_flash_default", "");
	g_CvarSndDefSm = CreateConVar("sm_silence_nades_sound_smoke_default", "");
	g_CvarTxtDefSm = CreateConVar("sm_silence_nades_text_smoke_default", "Fire in the hole! [smoke]");

	//um: RadioText
	if((g_umRadioText=GetUserMessageId("RadioText")) != INVALID_MESSAGE_ID)
		HookUserMessage(g_umRadioText, UserMsgRadioText, true);
	else
		SetFailState("GetUserMessageId for RadioText");

	//um: RadioText
	if((g_umSendAudio=GetUserMessageId("SendAudio")) != INVALID_MESSAGE_ID)
		HookUserMessage(g_umSendAudio, UserMsgSendAudio, true);
	else
		SetFailState("GetUserMessageId for SendAudio");

	//hook weapon_fire
	HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Pre);

	//prop location
	g_LastPlaceName = FindSendPropOffs("CBasePlayer", "m_szLastPlaceName");

	//user settings
	RegConsoleCmd("sm_silence_nades", SettingsMenu);
	if((g_kvCfg=CreateKeyValues("snCfg")) != INVALID_HANDLE){
		BuildPath(Path_SM, g_fnameCfg, PLATFORM_MAX_PATH, "data/silencenades.txt");
		if(!FileToKeyValues(g_kvCfg, g_fnameCfg)) KeyValuesToFile(g_kvCfg, g_fnameCfg);
	}else
		SetFailState("CreateKeyValues for snCfg");

	//snd and txt
	if((g_kvSndTxt=CreateKeyValues("snSndTxt")) != INVALID_HANDLE){
		BuildPath(Path_SM, tmp, PLATFORM_MAX_PATH, "configs/silencenades.cfg");
		if(!FileToKeyValues(g_kvSndTxt, tmp)) KeyValuesToFile(g_kvSndTxt, tmp);
	}else
		SetFailState("CreateKeyValues for snSndTxt");

	//late loaded
	if(g_lateLoaded)
		for(new i=1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				InitClient(i);
}

//no snd
public Action:UserMsgSendAudio(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
LogMessage("UserMsgSendAudio");
	decl String:msg_str[MAX_STR_LEN];

	BfReadString(bf, msg_str, sizeof(msg_str));

	if(!strcmp(msg_str, "Radio.FireInTheHole", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

//no txt
public Action:UserMsgRadioText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init){
LogMessage("UserMsgRadioText");
	decl String:radio_text[MAX_STR_LEN];

	BfReadWord(bf);
	BfReadString(bf, radio_text, sizeof(radio_text));
	if(!strcmp(radio_text, "#Game_radio_location", false))
		BfReadString(bf, radio_text, sizeof(radio_text));
	BfReadString(bf, radio_text, sizeof(radio_text));
	BfReadString(bf, radio_text, sizeof(radio_text));

	if(!strcmp(radio_text, "#Cstrike_TitlesTXT_Fire_in_the_hole", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

public OnClientConnected(client){
LogMessage("OnClientConnected");
	InitClient(client);
}

public OnClientPostAdminCheck(client){
LogMessage("OnClientPostAdminCheck");
	InitClient(client);
}

public InitClient(client){
LogMessage("InitClient");
	if(IsFakeClient(client)) return;

	//defaults
	GetConVarString(g_CvarSndDefHE, g_snd[NADE_IDX_HE][client], MAX_STR_LEN);
	GetConVarString(g_CvarTxtDefHE, g_txt[NADE_IDX_HE][client], MAX_STR_LEN);
	GetConVarString(g_CvarSndDefFl, g_snd[NADE_IDX_FL][client], MAX_STR_LEN);
	GetConVarString(g_CvarTxtDefFl, g_txt[NADE_IDX_FL][client], MAX_STR_LEN);
	GetConVarString(g_CvarSndDefSm, g_snd[NADE_IDX_SM][client], MAX_STR_LEN);
	GetConVarString(g_CvarTxtDefSm, g_txt[NADE_IDX_SM][client], MAX_STR_LEN);

	decl String:authStr[64];
	if(GetClientAuth(client, authStr, sizeof(authStr))){
		KvRewind(g_kvCfg);
		if(KvJumpToKey(g_kvCfg, authStr)){
			ReadKVus(NADE_IDX_HE, CFG_SND_HE, g_snd[NADE_IDX_HE][client]);
			ReadKVus(NADE_IDX_HE, CFG_TXT_HE, g_txt[NADE_IDX_HE][client]);
			ReadKVus(NADE_IDX_FL, CFG_SND_FL, g_snd[NADE_IDX_FL][client]);
			ReadKVus(NADE_IDX_FL, CFG_TXT_FL, g_txt[NADE_IDX_FL][client]);
			ReadKVus(NADE_IDX_SM, CFG_SND_SM, g_snd[NADE_IDX_SM][client]);
			ReadKVus(NADE_IDX_SM, CFG_TXT_SM, g_txt[NADE_IDX_SM][client]);
		}
	}
}

public ReadKVus(nade_type, const String:src[], String:dst[]){
	decl String:tmp[MAX_STR_LEN];

	KvGetString(g_kvCfg, src, tmp, MAX_STR_LEN);
	if(tmp[0]){
		if(tmp[0] != '-'){
			KvRewind(g_kvSndTxt);
			if(KvJumpToKey(g_kvSndTxt, nade_type == NADE_IDX_HE ? NODE_HE : (nade_type == NADE_IDX_FL ? NODE_FL : NODE_SM))){
				KvGetString(g_kvSndTxt, tmp, tmp, MAX_STR_LEN);
				if(tmp[0]) strcopy(dst, MAX_STR_LEN, tmp);
			}
		}else
			dst[0] = 0;
	}
}

public OnMapStart(){
LogMessage("OnMapStart");
	decl String:tmp[MAX_STR_LEN];

	GetConVarString(g_CvarSndDefHE, tmp, MAX_STR_LEN);
	if(tmp[0]) PrepareSnd(tmp);

	GetConVarString(g_CvarSndDefFl, tmp, MAX_STR_LEN);
	if(tmp[0]) PrepareSnd(tmp);

	GetConVarString(g_CvarSndDefSm, tmp, MAX_STR_LEN);
	if(tmp[0]) PrepareSnd(tmp);

	LoadSnd(NODE_HE);
	LoadSnd(NODE_FL);
	LoadSnd(NODE_SM);
}

public LoadSnd(const String:src[]){
	decl String:tmp[MAX_STR_LEN];

	//cache sounds
	KvRewind(g_kvSndTxt);
	if(KvJumpToKey(g_kvSndTxt, src)){
		for(new idx=1; idx <= MAX_CNT; idx++){
			Format(tmp, MAX_STR_LEN, SND_MASK, idx);
			KvGetString(g_kvSndTxt, tmp, tmp, MAX_STR_LEN);
			if(tmp[0]) PrepareSnd(tmp);
		}
	}
}

public PrepareSnd(const String:src[]){
	decl String:down[PLATFORM_MAX_PATH];

	PrecacheSound(src, true);
	Format(down, PLATFORM_MAX_PATH, "sound/%s", src);
	AddFileToDownloadsTable(down);
}

public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast){
LogMessage("EventWeaponFire");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[MAX_STR_LEN];
	GetEventString(event, "weapon", weapon, MAX_STR_LEN);

	//he
	if(!strcmp(weapon, "hegrenade", false)){
		FireNade(client, NADE_IDX_HE);

	//fl
	}else if(!strcmp(weapon, "flashbang", false)){
		FireNade(client, NADE_IDX_FL);

	//sm
	}else if(!strcmp(weapon, "smokegrenade", false)){
		FireNade(client, NADE_IDX_SM);

	//other weapon
	}else return Plugin_Continue;

	return Plugin_Handled;
}

public FireNade(client, nade_type){
LogMessage("FireNade");
	decl String:name[MAX_STR_LEN];
	decl String:place[MAX_STR_LEN];

	if(!GetClientName(client, name, MAX_STR_LEN)) return;

	//get location
	place[0] = 0;
	if(g_LastPlaceName != -1) GetEntDataString(client, g_LastPlaceName, place, MAX_STR_LEN);

	new clentteam = GetClientTeam(client);
	for(new idx=1; idx <= MaxClients; idx++){
		if(IsClientInGame(idx) && ((!IsFakeClient(idx) && clentteam == GetClientTeam(idx)) || GetClientTeam(idx) == TEAM_SPEC)){

			//txt
			if(g_txt[nade_type][idx][0]){
				decl String:message[MAX_STR_LEN];

				//YELLOW 1, TEAMCOLOR 3, GREEN 4
				if(place[0])
					Format(message, MAX_STR_LEN, "\x03%s\x01 @\x04 %T\x01 (%T): %s", name, place, idx, "radio", idx, g_txt[nade_type][idx]);
				else
					Format(message, MAX_STR_LEN, "\x03%s\x01 (%T): %s", name, "radio", idx, g_txt[nade_type][idx]);

				new Handle:hBf = StartMessageOne("SayText2", idx);
				if(hBf != INVALID_HANDLE){
					BfWriteByte(hBf, client);
					BfWriteByte(hBf, true);
					BfWriteString(hBf, message);
					EndMessage();
				}
			}

			//snd
			if(g_snd[nade_type][idx][0])
				EmitSoundToClient(idx, g_snd[nade_type][idx]);
		}
	}
}

public SettingsMenuHandler(Handle:menu, MenuAction:action, param1, param2){
LogMessage("SettingsMenuHandler");
	if(action == MenuAction_Select){
		switch(param2){
			case 0:
				ItemMenu(param1, ITEM_SND, NADE_IDX_HE);
			case 1:
				ItemMenu(param1, ITEM_TXT, NADE_IDX_HE);
			case 2:
				ItemMenu(param1, ITEM_SND, NADE_IDX_FL);
			case 3:
				ItemMenu(param1, ITEM_TXT, NADE_IDX_FL);
			case 4:
				ItemMenu(param1, ITEM_SND, NADE_IDX_SM);
			case 5:
				ItemMenu(param1, ITEM_TXT, NADE_IDX_SM);
		}
	}else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Action:SettingsMenu(client, args){
LogMessage("SettingsMenu");
	decl String:item[MAX_STR_LEN];
	new Handle:menu;

	if(!client || !IsClientInGame(client)) return Plugin_Handled;

	menu = CreateMenu(SettingsMenuHandler);
	Format(item, MAX_STR_LEN, "%T", "sn menu", client);
	SetMenuTitle(menu, item);

	if(g_snd[NADE_IDX_HE][client][0])
		Format(item, MAX_STR_LEN, "%T", "he snd", client, g_snd[NADE_IDX_HE][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no he snd", client);
	AddMenuItem(menu, "menu item", item);

	if(g_txt[NADE_IDX_HE][client][0])
		Format(item, MAX_STR_LEN, "%T", "he txt", client, g_txt[NADE_IDX_HE][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no he txt", client);
	AddMenuItem(menu, "menu item", item);

	if(g_snd[NADE_IDX_FL][client][0])
		Format(item, MAX_STR_LEN, "%T", "fl snd", client, g_snd[NADE_IDX_FL][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no fl snd", client);
	AddMenuItem(menu, "menu item", item);

	if(g_txt[NADE_IDX_FL][client][0])
		Format(item, MAX_STR_LEN, "%T", "fl txt", client, g_txt[NADE_IDX_FL][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no fl txt", client);
	AddMenuItem(menu, "menu item", item);

	if(g_snd[NADE_IDX_SM][client][0])
		Format(item, MAX_STR_LEN, "%T", "sm snd", client, g_snd[NADE_IDX_SM][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no sm snd", client);
	AddMenuItem(menu, "menu item", item);

	if(g_txt[NADE_IDX_SM][client][0])
		Format(item, MAX_STR_LEN, "%T", "sm txt", client, g_txt[NADE_IDX_SM][client]);
	else
		Format(item, MAX_STR_LEN, "%T", "no sm txt", client);
	AddMenuItem(menu, "menu item", item);

	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 15);

	return Plugin_Handled;
}

public ItemMenuHandler(Handle:menu, MenuAction:action, param1, param2){
LogMessage("ItemMenuHandler");
	decl String:info[MAX_STR_LEN];
	decl String:disp[MAX_STR_LEN];

	if(action == MenuAction_Select){
		if(GetMenuItem(menu, param2, info, MAX_STR_LEN, _, disp, MAX_STR_LEN)){
			new item_type = info[0]-'0';
			new nade_type = info[1]-'0';
			if(item_type >= 0 && nade_type >= 0 && item_type < ITEM_CNT && nade_type < NADE_CNT){

				//save mem
				if(item_type == ITEM_SND){
					if(info[2] != '-'){
						strcopy(g_snd[nade_type][param1], MAX_STR_LEN, disp[2]);
						EmitSoundToClient(param1, disp[2]);
					}else
						g_snd[nade_type][param1][0] = 0;
				}else{
					if(info[2] != '-')
						strcopy(g_txt[nade_type][param1], MAX_STR_LEN, disp[2]);
					else
						g_txt[nade_type][param1][0] = 0;
				}

				//save kv
				decl String:authStr[64];
				if(GetClientAuth(param1, authStr, sizeof(authStr))){
					KvRewind(g_kvCfg);
					if(KvJumpToKey(g_kvCfg, authStr, true)){
						KvSetString(g_kvCfg, nade_type == NADE_IDX_HE ? (item_type == ITEM_SND ? CFG_SND_HE : CFG_TXT_HE ) : (nade_type == NADE_IDX_FL ? (item_type == ITEM_SND ? CFG_SND_FL : CFG_TXT_FL ) : (item_type == ITEM_SND ? CFG_SND_SM : CFG_TXT_SM )), info[2]);
						KvRewind(g_kvCfg);
						KeyValuesToFile(g_kvCfg, g_fnameCfg);
					}
				}

				SettingsMenu(param1, 0);
			}
		}
	}else if(action == MenuAction_End)
		CloseHandle(menu);
}

public ItemMenu(client, item_type, nade_type){
LogMessage("ItemMenu");
	decl String:item[MAX_STR_LEN];
	decl String:kv_idx[MAX_STR_LEN];
	decl String:kv_val[MAX_STR_LEN];
	new Handle:menu;

	if(!client || !IsClientInGame(client)) return;

	menu = CreateMenu(ItemMenuHandler);
	Format(item, MAX_STR_LEN, "%T", item_type == ITEM_SND ? "snd menu" : "txt menu", client);
	SetMenuTitle(menu, item);

	Format(item, MAX_STR_LEN, (item_type == ITEM_SND ? g_snd[nade_type][client][0] : g_txt[nade_type][client][0]) ? "  %T" : "* %T", "---", client);
	Format(kv_val, MAX_STR_LEN, "%1d%1d-", item_type, nade_type);
	AddMenuItem(menu, kv_val, item);

	KvRewind(g_kvSndTxt);
	if(KvJumpToKey(g_kvSndTxt, nade_type == NADE_IDX_HE ? NODE_HE : (nade_type == NADE_IDX_FL ? NODE_FL : NODE_SM))){
		for(new idx=1; idx <= MAX_CNT; idx++){
			Format(kv_idx, MAX_STR_LEN, item_type == ITEM_SND ? SND_MASK : TXT_MASK, idx);
			KvGetString(g_kvSndTxt, kv_idx, kv_val, MAX_STR_LEN);
			if(kv_val[0]){
				Format(item, MAX_STR_LEN, strcmp(kv_val, item_type == ITEM_SND ? g_snd[nade_type][client] : g_txt[nade_type][client]) ? "  %s" : "* %s", kv_val);
				Format(kv_val, MAX_STR_LEN, "%1d%1d%s", item_type, nade_type, kv_idx);
				AddMenuItem(menu, kv_val, item);
			}
		}
	}

	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 15);
}

public bool:GetClientAuth(client, String:auth[], maxlen){
LogMessage("GetClientAuth");
	if(!GetClientAuthString(client, auth, maxlen) && !GetClientIP(client, auth, maxlen) && !strcopy(auth, maxlen, "STEAM_ID_PENDING"))
		return false;

	return true;
}
