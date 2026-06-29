
//1.3.1
// 修复了第一局无法生成墓碑的问题

/*********************************************************************
*
*							CD意识:
*
*		This plugin is inspired by novels "Ghost Blows Out the Light" that I read when I was a student
*
*		复活功能的签名用了自动复活的。抱歉，签名是我还未涉及的领域..
*
*		插件下一步发展打算:
*		1.*盗墓进度条改为需要不停按E增加，在这过程中进度条会不断快速下降
*		2.?多人盗墓增加复活概率
*		3.?QTE盗墓
*		4.?盗墓过程中让角色跳舞、蹦迪（跳舞插件类似，但是我还没研究过源码）
*
*********************************************************************/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define DEBUG 0
//respawn
#define GAMEDATA	"grave_survivor_respawn"
Handle g_hSDKRoundRespawn, g_hSDKGoAwayFromKeyboard;
Address g_pStatsCondition;

char g_aGraveModels[][] = {
	// graves
	"models/props_cemetery/grave_07.mdl",

	"models/props_cemetery/gibs/grave_07a_gibs.mdl",
	"models/props_cemetery/gibs/grave_07b_gibs.mdl",
	"models/props_cemetery/gibs/grave_07c_gibs.mdl",
	"models/props_cemetery/gibs/grave_07d_gibs.mdl",
	"models/props_cemetery/gibs/grave_07e_gibs.mdl",
	"models/props_cemetery/gibs/grave_07f_gibs.mdl"
};
char g_candy[][] = {
	"models/lighthouse/candle.mdl",
	"models/lighthouse/candle_fire.mdl"
};

enum struct Grave {
	int RespawnCount;
	int ModelRef;
	int CandyRef;
	int CandyFireRef;
	int SpriteRef;
	int ButtonRef;
	void reset(){
		// this.RespawnCount = 0;
		this.ModelRef = 0;
		this.CandyRef = 0;
		this.CandyFireRef = 0;
		this.SpriteRef = 0;
		this.ButtonRef = 0;
	}
}

Grave playerList[MAXPLAYERS + 1];
ConVar Grave_Plugin_On, Grave_Respawn_Time, Grave_Respawn_Chance, Grave_Witch_Percent, Grave_Glow_Switch, Grave_Glow_Color;
int g_wichPercent;
bool g_Grave_Glow_Switch;
char g_Grave_Glow_Color[64], g_Grave_Respawn_Time[8];

public Plugin myinfo = {
	name = "Grave robber",
	author = "CD意识STEAM_1:0:211123334 (Alliedmods:kazya3)",
	description = "Do you wanna be a Mojin-Hunter",
	version = "1.3.1",
	url = ""
}

public void OnPluginStart(){
	vLoadGameData();
	LoadTranslations("l4d2_grave_killer.phrases");

	Grave_Plugin_On 		= CreateConVar("L4D2_Grave_Plugin_On", 			"1", 			"Plugin On/Off",		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Grave_Respawn_Time 		= CreateConVar("L4D2_Grave_Respawn_Time", 		"3", 			"Using time(seconds)",		FCVAR_NOTIFY, true, 0.0, true, 100.0);
	Grave_Respawn_Chance 	= CreateConVar("L4D2_Grave_Respawn_Chance", 	"3", 			"Respawn chance",			FCVAR_NOTIFY, true, 0.0, true, 99.0);

	Grave_Witch_Percent 	= CreateConVar("L4D2_Grave_Witch_Percent", 		"50", 			"Probability of turning into witch",		FCVAR_NOTIFY, true, 0.0, true, 100.0);

	Grave_Glow_Switch		= CreateConVar("L4D2_Grave_Glow_Switch", 		"1", 			"Grave glowing switch",			FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Grave_Glow_Color		= CreateConVar("L4D2_Grave_Glow_Color", 		"255 255 255", 	"Grave glowing color",			FCVAR_NOTIFY);

	Grave_Respawn_Time.AddChangeHook(ConVarChanges);
	Grave_Respawn_Chance.AddChangeHook(ConVarChanges2);
	Grave_Witch_Percent.AddChangeHook(ConVarChanges);
	Grave_Glow_Switch.AddChangeHook(ConVarChanges);
	Grave_Glow_Color.AddChangeHook(ConVarChanges);

	AutoExecConfig(true, "l4d2_graveKiller_v1.3");
}
/*********************************************************************
*
*							MARK: Inital
*
*********************************************************************/
public void OnConfigsExecuted(){
	IsAllowed();
}

void IsAllowed()
{
	bool PluginOn = Grave_Plugin_On.BoolValue;
	if(PluginOn)
	{
		ConVarChanges(null, "", "");
		ConVarChanges2(null, "", "");
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	}
	else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	}
}

void ConVarChanges(ConVar convar, const char[] oldValue, const char[] newValue){
	GetCvars();
}
//修改参数会重置所有玩家复活次数，因此需要单独处理
void ConVarChanges2(ConVar convar, const char[] oldValue, const char[] newValue){
	for(int i; i <= MAXPLAYERS; i++){
		//不应该在这里重置所有属性，改变参数后场上如果有墓碑会导致bug
		// playerList[i].reset();
		playerList[i].RespawnCount = Grave_Respawn_Chance.IntValue;
	}
}
void GetCvars(){
	Grave_Respawn_Time.GetString(g_Grave_Respawn_Time, sizeof(g_Grave_Respawn_Time));
	g_wichPercent		= Grave_Witch_Percent.IntValue;
	g_Grave_Glow_Switch	= Grave_Glow_Switch.BoolValue;
	if(g_Grave_Glow_Switch){
		Grave_Glow_Color.GetString(g_Grave_Glow_Color, sizeof(g_Grave_Glow_Color));
	}
}
/*********************************************************************
*
*							MARK: Precache
*
*********************************************************************/
public void OnMapStart(){
	for (int i = 0; i < sizeof(g_aGraveModels); i++ )
		PrecacheModel(g_aGraveModels[i]);
	for (int i = 0; i < sizeof(g_candy); i++ )
		PrecacheModel(g_candy[i]);
	PrecacheModel("sprites/glow03.vmt", true);
}
/*********************************************************************
*
*							MARK: Reset
*
*********************************************************************/
Action Event_RoundStart(Event event, const char[] name, bool dontbroadcast){
	for (int i = 1; i <= MaxClients; i++){
		if (isSurvivor(i)){
			playerList[i].reset();
			playerList[i].RespawnCount = Grave_Respawn_Chance.IntValue;
		}
	}
	//检测间隔不应该过长,我设定了按钮按下后3s可以再次按下。如果3s内没被检测到移除，可能导致玩家再次按下过程中按钮被删除，然后导致玩家定身
	CreateTimer(0.5, Timer_RemoveGrave, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

Action Timer_RemoveGrave(Handle timer, DataPack entities){
	for (int i = 1; i <= MaxClients; i++){
		if (isAliveSurvivor(i) && playerList[i].ModelRef != 0){
			int Grave_Index = EntRefToEntIndex(playerList[i].ModelRef);
			if(Grave_Index != INVALID_ENT_REFERENCE) AcceptEntityInput(Grave_Index, "Kill");
			playerList[i].reset();
			//不应该在这里重置次数，会导致无限复活
			// playerList[i].RespawnCount = Grave_Respawn_Chance.IntValue;
		}
	}
	return Plugin_Continue;
}
/*********************************************************************
*
*						MARK: Spawn Grave
*
*********************************************************************/
Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (isSurvivor(victim) && playerList[victim].RespawnCount > 0){
		#if DEBUG
			CPrintToChatAll("%t", "RC", playerList[victim].RespawnCount);
		#endif
		float origin[3];
		GetClientAbsOrigin(victim, origin);
		char targetname[32];
		//grave
		int Grave_Index = CreateEntityByName("prop_dynamic_override");
		playerList[victim].ModelRef = EntIndexToEntRef(Grave_Index);
		DispatchKeyValue(Grave_Index, "model", g_aGraveModels[0]);
		DispatchKeyValue(Grave_Index, "solid", "0");
		FormatEx(targetname,32,"l4d2@Grave%d@Body",victim);
		DispatchKeyValue(Grave_Index, "targetname", targetname);
		DispatchSpawn(Grave_Index);
		TeleportEntity(Grave_Index, origin, NULL_VECTOR, NULL_VECTOR);
		if(g_Grave_Glow_Switch){
			SetEntProp(Grave_Index, Prop_Send, "m_iGlowType", 3);
			SetEntProp(Grave_Index, Prop_Send, "m_glowColorOverride", GetColor(g_Grave_Glow_Color));
			// SetEntProp(Grave_Index, Prop_Send, "m_nGlowRange", 99999999);
		}

		//button
		// origin[2] += 32;
		int Button_Index =  CreateEntityByName("func_button_timed");
		playerList[victim].ButtonRef = EntIndexToEntRef(Button_Index);
		DispatchKeyValue(Button_Index, "use_time", g_Grave_Respawn_Time);
		DispatchKeyValue(Button_Index, "auto_disable", "1");
		DispatchKeyValue(Button_Index, "use_string", "Mojin ing..");
		DispatchKeyValue(Button_Index, "use_sub_string", " ");
		TeleportEntity(Button_Index, origin, NULL_VECTOR, NULL_VECTOR);
		FormatEx(targetname,32,"l4d2@Grave%d@Button",victim);
		DispatchKeyValue(Button_Index, "targetname", targetname);
		DispatchSpawn(Button_Index);
		SetEntityModel(Button_Index, g_aGraveModels[0]);
		SetEntityRenderMode(Button_Index, RENDER_NONE);
		//2选1无碰撞方法
		// DispatchKeyValue(Button_Index, "solid", "0");
		SetEntProp(Button_Index, Prop_Send, "m_nSolidType", 0);

		//不要使用min和max拉func_button_timed这个实体的范围，这会导致使用距离的判定非常诡异
		// SetEntPropVector(Button_Index, Prop_Send, "m_vecMins", {20.0, 20.0, 32.0});
		// SetEntPropVector(Button_Index, Prop_Send, "m_vecMaxs", {-20.0, -20.0, -32.0});
		// SetEntProp(Button_Index, Prop_Send, "m_nSolidType", 2);
		
		SetVariantString("!activator");
		AcceptEntityInput(Button_Index, "SetParent", Grave_Index);
		HookSingleEntityOutput(Button_Index, "OnTimeUp", Button_OnTimeUp);
		SetVariantString("OnTimeUp !self:enable::3.0:-1");
		AcceptEntityInput(Button_Index, "AddOutput");

		//candy
		float origin2[3];
		GetClientAbsOrigin(victim, origin2);
		origin2[0] += 20;
		int Candy_Index =  CreateEntityByName("prop_dynamic_override");
		playerList[victim].CandyRef = EntIndexToEntRef(Candy_Index);
		DispatchKeyValue(Candy_Index, "model", g_candy[0]);
		DispatchKeyValue(Candy_Index, "solid", "0");
		FormatEx(targetname, 32, "l4d2@Grave%d@Candy",victim);
		DispatchKeyValue(Candy_Index, "targetname", targetname);
		DispatchSpawn(Candy_Index);
		TeleportEntity(Candy_Index, origin2, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(Candy_Index, "SetParent", Grave_Index);

		//candyFire
		origin2[2] += 9;
		int CandyFire_Index =  CreateEntityByName("prop_dynamic_override");
		playerList[victim].CandyFireRef = EntIndexToEntRef(CandyFire_Index);
		DispatchKeyValue(CandyFire_Index, "model", "models/lighthouse/candle_fire.mdl");
		DispatchKeyValue(CandyFire_Index, "solid", "0");
		FormatEx(targetname, 32, "l4d2@Grave%d@CandyFire", victim);
		DispatchKeyValue(CandyFire_Index, "targetname", targetname);
		DispatchSpawn(CandyFire_Index);
		TeleportEntity(CandyFire_Index, origin2, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(CandyFire_Index, "SetParent", Candy_Index);

		//Sprite
		int Sprite_Index = CreateEntityByName("env_sprite");
		playerList[victim].SpriteRef = EntIndexToEntRef(Sprite_Index);
		DispatchKeyValueVector(Sprite_Index, "origin", origin2);
		DispatchKeyValue(Sprite_Index, "model", "sprites/glow03.vmt");
		DispatchKeyValue(Sprite_Index, "rendermode", "9");
		DispatchKeyValue(Sprite_Index, "scale", "0.25");
		DispatchKeyValue(Sprite_Index, "spawnflags", "1");
		DispatchKeyValue(Sprite_Index, "GlowProxySize", "6");
		DispatchKeyValue(Sprite_Index, "HDRColorScale", ".5");
		DispatchKeyValue(Sprite_Index, "renderamt", "200");
		FormatEx(targetname, 32, "l4d2@Grave%d@Sprite", victim);
		DispatchKeyValue(Sprite_Index, "targetname", targetname);
		DispatchSpawn(Sprite_Index);
		SetVariantString("!activator");
		AcceptEntityInput(Sprite_Index, "SetParent", Candy_Index);
		SetVariantString("235 141 109");
		AcceptEntityInput(Sprite_Index, "Color");
	}
	return Plugin_Handled;
}
/*********************************************************************
*
*						MARK: IO Output
*
*********************************************************************/
void Button_OnTimeUp(const char[] name, int caller, int activator, float delay){
	if(!isSurvivorNoBot(activator)) return;
	//死掉的玩家index
	int p_dead;
	//寻找数组中对应使用的对象
	for(int i = 1; i <= MaxClients; i++){
		if(caller == EntRefToEntIndex(playerList[i].ButtonRef)){
			p_dead = i;
			break;
		}
	}
	#if DEBUG
		CPrintToChatAll("%t", "PD", p_dead);
	#endif
	int Grave_Index = EntRefToEntIndex(playerList[p_dead].ModelRef);
	if(Grave_Index == INVALID_ENT_REFERENCE) return;
	//生成墓碑时候我做了复活次数检测，没次数不会生成
	//虽然不太可能，但是万一出现场上有墓碑，但是对应的死人没有复活次数的情况，盗墓后直接删除墓碑
	if (playerList[p_dead].RespawnCount <= 0) {
		AcceptEntityInput(Grave_Index, "Kill");
		return;
	}

	// if(isDeadSurvivor(activator)) return;
	//墓碑所在坐标
	float VecOrigin[3], VecAngles[3];
	GetEntPropVector(Grave_Index, Prop_Send, "m_vecOrigin", VecOrigin);
	GetEntPropVector(Grave_Index, Prop_Data, "m_angRotation", VecAngles);
	#if DEBUG
		PrintToChatAll("m_vecOrigin: %f %f %f", VecOrigin[0], VecOrigin[1], VecOrigin[2]);
		PrintToChatAll("m_angRotation: %f %f %f", VecAngles[0], VecAngles[1], VecAngles[2]);
	#endif
	int percent = GetRandomInt(0,100);
	//生成witch
	if(percent < g_wichPercent){
		#if DEBUG
			CPrintToChatAll("%t", "CW");
		#endif
		int witch = CreateEntityByName("witch");
		int Button_Index = EntRefToEntIndex(playerList[p_dead].ButtonRef);
		if (witch != -1 && Button_Index != INVALID_ENT_REFERENCE){
			TeleportEntity(witch, VecOrigin, VecAngles, NULL_VECTOR);
			DispatchSpawn(witch);
			CPrintToChatAll("%t", "Failed", activator, p_dead);
		}
	}
	//复活玩家
	else{
		#if DEBUG
			CPrintToChatAll("%t", "RP", p_dead);
		#endif
		if(isDeadSurvivor(p_dead)){
			vRoundRespawn(p_dead);
			TeleportEntity(p_dead, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			playerList[p_dead].RespawnCount = playerList[p_dead].RespawnCount > 0 ? playerList[p_dead].RespawnCount - 1 : 0;
			#if DEBUG
				CPrintToChatAll("%t", "RRT", playerList[p_dead].RespawnCount);
			#endif
			PrintHintText(p_dead, "%t", "RR", playerList[p_dead].RespawnCount);
			CPrintToChatAll("%t", "Succes", activator, p_dead);
		}
	}
}
/*********************************************************************
*
*								MARK: Delete Deadbody
*
*********************************************************************/
public void OnEntityCreated(int entity, const char[] classname){
	if (!IsValidEntityIndex(entity)){return;}
	if (strcmp(classname , "survivor_death_model") == 0){
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
	}
}
void OnNextFrame(int entityRef){
	int entity = EntRefToEntIndex(entityRef);
	if (entity == INVALID_ENT_REFERENCE) return;
	AcceptEntityInput(entity, "kill");
}
/*********************************************************************
*
*								MARK: Respawn
*
*********************************************************************/
void vRoundRespawn(int client){
	vStatsConditionPatch(true);
	SDKCall(g_hSDKRoundRespawn, client);
	vStatsConditionPatch(false);
}

//https://forums.alliedmods.net/showthread.php?t=323220
void vStatsConditionPatch(bool bPatch){
	static bool bPatched;
	if(!bPatched && bPatch){
		bPatched = true;
		StoreToAddress(g_pStatsCondition, 0x79, NumberType_Int8);
	}
	else if(bPatched && !bPatch){
		bPatched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

void vLoadGameData(){
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
	g_hSDKRoundRespawn = EndPrepSDKCall();
	if(g_hSDKRoundRespawn == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::GoAwayFromKeyboard");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKGoAwayFromKeyboard = EndPrepSDKCall();
	if(g_hSDKGoAwayFromKeyboard == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::GoAwayFromKeyboard");

	vRegisterStatsConditionPatch(hGameData);

	delete hGameData;
}

void vRegisterStatsConditionPatch(GameData hGameData = null){
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if(iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if(iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	g_pStatsCondition = hGameData.GetAddress("CTerrorPlayer::RoundRespawn");
	if(!g_pStatsCondition)
		SetFailState("Failed to find address: CTerrorPlayer::RoundRespawn");

	g_pStatsCondition += view_as<Address>(iOffset);

	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if(iByteOrigin != iByteMatch)
		SetFailState("Failed to load 'CTerrorPlayer::RoundRespawn', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}
/*********************************************************************
*
*								MARK: STOCK
*
*********************************************************************/
stock bool IsValidEntityIndex(int entity){
	return (MaxClients+1 <= entity <= GetMaxEntities());
}
//根据字符串获取上色值
stock int GetColor(char[] sTemp){
	if (strcmp(sTemp, "") == 0) return 0;
	char sColors[3][4];
	int	 iColor = ExplodeString(sTemp, " ", sColors, 3, 4);
	if (iColor != 3) return 0;
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);
	return iColor;
}
//判断是否是死亡的幸存者（包括bot）
stock bool isDeadSurvivor(int client){
	return isSurvivor(client) && !IsPlayerAlive(client);
}
//判断是否是活着的幸存者（包括bot）
stock bool isAliveSurvivor(int client){
	return isSurvivor(client) && IsPlayerAlive(client);
}
//判断是否是幸存者阵营（包括bot）
stock bool isSurvivor(int client){
	return isClientValid(client, false) && GetClientTeam(client) == 2;
}

//判断是否是死亡的幸存者（无bot）
stock bool isDeadSurvivorNoBot(int client){
	return isSurvivorNoBot(client) && !IsPlayerAlive(client);
}
//判断是否是活着的幸存者（无bot）
stock bool isAliveSurvivorNoBot(int client){
	return isSurvivorNoBot(client) && IsPlayerAlive(client);
}
//判断是否是幸存者阵营（无bot）
stock bool isSurvivorNoBot(int client){
	return isClientValid(client) && GetClientTeam(client) == 2;
}

//判断玩家是否valid
stock bool isClientValid(int client, bool NoBot = true){
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	if (NoBot){
		if (IsFakeClient(client)) return false;
	}
	return true;
}

/**************************************************************************
 *                                                                        *
 *          	 	     	 New color inc   				    	      *
 *                          Author: Ernecio (updated by pan0s)            *
 *                           Version: 1.0.1                               *
 *                                                                        *
 **************************************************************************/
enum
{
	SERVER_INDEX	= 0,
	NO_INDEX		= -1,
	NO_PLAYER		= -2,
	BLUE_INDEX		= 2,
	RED_INDEX		= 3,
}

stock const char CTag[][] 				= { "{DEFAULT}", "{ORANGE}", "{CYAN}", "{RED}", "{BLUE}", "{GREEN}" };
stock const char CTagCode[][] 			= { "\x01", "\x04", "\x03", "\x03", "\x03", "\x05" };
stock const bool CTagReqSayText2[]	 	= { false, false, true, true, true, false };
stock const int CProfile_TeamIndex[] 	= { NO_INDEX, NO_INDEX, SERVER_INDEX, RED_INDEX, BLUE_INDEX, NO_INDEX };

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Supports color tags.
 *
 * @param client 		Client index.
 * @param sMessage 		Message (formatting rules).
 * @return 				No return
 *
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] sMessage, any ...)
{
	if( client <= 0 || client > MaxClients )
		ThrowError( "Invalid client index %d", client);

	if( !IsClientInGame(client) )
		ThrowError( "Client %d is not in game", client);

	static char sBuffer[250];
	static char sCMessage[250];
	SetGlobalTransTarget(client);
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat( sCMessage, sizeof( sCMessage ), sBuffer, 3);

	int index = CFormat(sCMessage, sizeof(sCMessage));
	if( index == NO_INDEX )
		PrintToChat(client, sCMessage);
	else
		CSayText2(client, index, sCMessage);
}

/**
 * @note Prints a message to all clients in the chat area.
 * @note Supports color tags.
 *
 * @param client		Client index.
 * @param sMessage 		Message (formatting rules)
 * @return 				No return
 */
stock void CPrintToChatAll(const char[] sMessage, any ...)
{
	static char sBuffer[250];

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(sBuffer, sizeof(sBuffer), sMessage, 2);
			CPrintToChat(i, sBuffer);
		}
	}
}

/**
 * @note Replaces color tags in a string with color codes
 *
 * @param sMessage    String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 *
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock int CFormat(char[] sMessage, int maxlength)
{
	int iRandomPlayer = NO_INDEX;

	for( int i = 0; i < sizeof(CTagCode); i++ )											//	Para otras etiquetas de color se requiere un bucle.
	{
		if( StrContains( sMessage, CTag[i]) == -1 ) 										//	Si no se encuentra la etiqueta, omitir.
			continue;
		else if( !CTagReqSayText2[i] )
			ReplaceString(sMessage, maxlength, CTag[i], CTagCode[i]); 					//	Si la etiqueta no necesita Saytext2 simplemente reemplazará.
		else																				//	La etiqueta necesita Saytext2.
		{
			if( iRandomPlayer == NO_INDEX )													//	Si no se especificó un cliente aleatorio para la etiqueta, reemplaca la etiqueta y busca un cliente para la etiqueta.
			{
				iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]); 			//	Busca un cliente válido para la etiqueta, equipo de infectados oh supervivientes.
				if( iRandomPlayer == NO_PLAYER )
					ReplaceString(sMessage, maxlength, CTag[i], CTagCode[5]);	 			//	Si no se encuentra un cliente valido, reemplasa la etiqueta con una etiqueta de color verde.
				else
					ReplaceString(sMessage, maxlength, CTag[i], CTagCode[i]); 				// 	Si el cliente fue encontrado simplemente reemplasa.
			}
			else 																			//	Si en caso de usar dos colores de equipo infectado y equipo de superviviente juntos se mandará un mensaje de error.
				ThrowError("Using two team colors in one message is not allowed"); 			//	Si se ha usadó una combinación de colores no validad se registrara en la carpeta logs.
		}
	}

	return iRandomPlayer;
}

/**
 * @note Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam(int color_team)
{
	if( color_team == SERVER_INDEX )
		return 0;
	else
		for( int i = 1; i <= MaxClients; i++ )
			if( IsClientInGame(i) && GetClientTeam(i) == color_team )
				return i;

	return NO_PLAYER;
}

/**
 * @note Sends a SayText2 usermessage to a client
 *
 * @param sMessage 		Client index
 * @param maxlength 	Author index
 * @param sMessage 		Message
 * @return 				No return.
 */
stock void CSayText2(int client, int author, const char[] sMessage)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, sMessage);
	EndMessage();
}