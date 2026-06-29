#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define MAX_CALLS			1		// How many times to print each forward

#pragma newdecls required
#pragma semicolon 1

#define CLIENTS		0
#define EVENT			1
#define ROUND			2
#define TIMELEFT	3
#define TOTAL			4

#define GAMEDATA_FILE           "staggersolver"

#define PL_VERSION "1.0.2"
#define DEBUG		0

public Plugin myinfo =
{
  name        = "Execute Configs",
  author      = "Tsunami",
  description = "Execute configs on certain events.",
  version     = PL_VERSION,
  url         = "http://www.tsunami-productions.nl"
};



/**
 * Globals
 */
int g_iRound;
bool g_bSection;
SMCParser g_hConfigParser;
ConVar g_hEnabled;
ConVar g_hIncludeBots;
ConVar g_hIncludeSpec;
Handle g_hTimer;
Handle g_hTimers[TOTAL];
StringMap g_hTries[TOTAL];
StringMap g_hTypes;
char g_sConfigFile[PLATFORM_MAX_PATH + 1];
char g_sMap[32];

//new variables
int clientinpos1 = 0;
int clientinpos2 = 0;
bool g_bLeft4Dead2;
bool g_bLateLoad;
Handle hGameConf;
Handle hIsStaggering;
bool g_bStagger[MAXPLAYERS+1];
int clientAnim[MAXPLAYERS+1];
char g_NewName[MAXPLAYERS+1][MAX_NAME_LENGTH];

bool g_bLibraryActive;
bool g_bTestForwards =		true;	// To enable forwards testing
int g_iForwardsMax;					// Total forwards we expect to see
int g_iForwards;
Handle g_hTimerAnim;
Handle g_hTimerExecAMR1;
Handle g_hTimerExecAMR2; 

/**
 * Forwards
 */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	// (+2 for "L4D2_OnEndVersusModeRound_Post" and "L4D2_OnSelectTankAttackPre")
	if( g_bLeft4Dead2 )
		g_iForwardsMax = 43;
	else
		g_iForwardsMax = 33;
	g_bLateLoad = late;
	
	RegPluginLibrary("left4dhooks");


	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = false;
}

public void OnAllPluginsLoaded()
{
	if( g_bLibraryActive == false )
		LogError("Required plugin left4dhooks is missing.");
}

void ResetPlugin()
{
	delete g_hTimer;
}

public void OnPluginStart()
{
	CreateConVar("sm_executeconfigs_version", PL_VERSION, "Execute configs on certain events.", FCVAR_NOTIFY);
	g_hEnabled      = CreateConVar("sm_executeconfigs_enabled",      "1", "Enable/disable executing configs");
	g_hIncludeBots  = CreateConVar("sm_executeconfigs_include_bots", "1", "Enable/disable including bots when counting number of clients");
	g_hIncludeSpec  = CreateConVar("sm_executeconfigs_include_spec", "1", "Enable/disable including spectators when counting number of clients");

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/executeconfigs.txt");
	RegServerCmd("sm_executeconfigs_reload", Command_Reload, "Reload the configs");
	RegServerCmd("sm_detectanim", Command_Anim, "Anim");
	RegAdminCmd("sm_prueba", ExecConfigCmd, ADMFLAG_ROOT, "PRobando.");


	g_hConfigParser = new SMCParser();
	g_hConfigParser.OnEnterSection = ReadConfig_NewSection;
	g_hConfigParser.OnKeyValue     = ReadConfig_KeyValue;
	g_hConfigParser.OnLeaveSection = ReadConfig_EndSection;

	g_hTypes        = new StringMap();
	g_hTypes.SetValue("clients",  CLIENTS);
	g_hTypes.SetValue("event",    EVENT);
	g_hTypes.SetValue("round",    ROUND);
	g_hTypes.SetValue("timeleft", TIMELEFT);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i] = new StringMap();

	char sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));

	if (StrEqual(sGameDir, "insurgency"))
		HookEvent("game_newmap",            Event_GameStart,  EventHookMode_PostNoCopy);
	else
		HookEvent("game_start",             Event_GameStart,  EventHookMode_PostNoCopy);

	if (StrEqual(sGameDir, "dod"))
		HookEvent("dod_round_start",        Event_RoundStart, EventHookMode_PostNoCopy);
	else if (StrEqual(sGameDir, "tf"))
	{
		HookEvent("teamplay_restart_round", Event_GameStart,  EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start",   Event_RoundStart, EventHookMode_PostNoCopy);
	}
	else
		HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			player_spawn);
	
	//HookEvent("player_hurt_concise",verifyStagger, EventHookMode_Pre);
	//HookEvent("hegrenade_detonate",verifyStagger, EventHookMode_Pre);
	//HookEvent("charger_impact",verifyStagger, EventHookMode_Pre);
	//HookEvent("player_shoved",verifyStagger, EventHookMode_Pre);
	HookEvent("round_end",Event_RoundEnd);
	HookEvent("map_transition", 		Event_RoundEnd); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", 			Event_RoundEnd); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd); //救援載具離開之時  (沒有觸發round_end)

	for (int i = 1; i <= MaxClients; i++)
	{
		g_bStagger[i]=false;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		clientAnim[i]=0;
	}
	
/*	
    // sdkhook
    hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
    if (hGameConf == INVALID_HANDLE)
    SetFailState("[aidmgfix] Could not load game config file (staggersolver.txt).");
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IsStaggering"))
    SetFailState("[aidmgfix] Could not find signature IsStaggering.");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	
    hIsStaggering = EndPrepSDKCall();
    if (hIsStaggering == INVALID_HANDLE)
    SetFailState("[aidmgfix] Failed to load signature IsStaggering");
    CloseHandle(hGameConf);
	*/
	
	if (g_bLateLoad)
	{
		g_bLateLoad = false;
	}
}
/*
public Action L4D2_OnStagger(int target, int source)
{	
		return Plugin_Handled;
	//return Plugin_Continue;
}
*/
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		AnimHookDisable(i, OnAnim, OnAnimPost);
	}

}

public void OnMapEnd()
{

	clientinpos1 = 0;
	clientinpos2 = 0;

}

public void OnMapStart()
{
	g_iRound = 0;
	g_hTimer = null;

	for (int i = 0; i < TOTAL; i++)
		g_hTimers[i] = null;

	GetCurrentMap(g_sMap, sizeof(g_sMap));
	ParseConfig();
}

public void OnMapTimeLeftChanged()
{
	delete g_hTimer;

	int iTimeleft;
	if (GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
		g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	ExecClientsConfig(0);
}

public void OnClientDisconnect(int client)
{
	ExecClientsConfig(-1);
}


/**
 * Commands
 */
public Action Command_Reload(int args)
{
	ParseConfig();
}

public Action Command_Anim(int args)
{
	delete g_hTimerAnim;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2)//&& !SDKCall(hIsStaggering, target))
		{
			#if DEBUG
			PrintToChatAll("DetectAnim Iniciado clientAnim para el cliente %d, inicial: %d",i,clientAnim[i]);
			#endif
			g_hTimer = CreateTimer(0.1, Timer_DetectAnim, i, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
	}
}


/**
 * Events
 */
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound = 0;
}

public void Event_Hook(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hEnabled.BoolValue)
		ExecConfig(EVENT, name);
}

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && GetClientTeam(client) == 2)
		AnimHookEnable(client, OnAnim, OnAnimPost);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound++;

	if (!g_hEnabled.BoolValue)
		return;

	char sRound[4];
	IntToString(g_iRound, sRound, sizeof(sRound));
	ExecConfig(ROUND, sRound);
	
	
		
		
}


/**
 * Timers
 */
public Action Timer_ExecConfig(Handle timer, DataPack pack)
{
	pack.Reset();

	char sConfig[32];
	int iType = pack.ReadCell();
	pack.ReadString(sConfig, sizeof(sConfig));	
	
	ServerCommand("exec \"%s\"", sConfig);
	g_hTimers[iType] = null;
}

public Action Timer_ExecTimeleftConfig(Handle timer)
{
	if (!g_hEnabled.BoolValue)
		return Plugin_Handled;

	int iTimeleft;
	if (!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
		return Plugin_Handled;

	char sTimeleft[4];
	IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
	ExecConfig(TIMELEFT, sTimeleft);

	return Plugin_Handled;
}


public Action Timer_ExecConfigCommand(Handle timer, DataPack pack)
{
	delete g_hTimerExecAMR1;
	delete g_hTimerExecAMR2;
	pack.Reset();
	char sConfig[32];
	int iType = pack.ReadCell();
	pack.ReadString(sConfig, sizeof(sConfig));
	if (isCorrectPositionsandHaveCorrectWeapons())
	{
		ServerCommand("sm_cvar st_mr_force_file default1");
		ServerCommand("sm_cvar st_mr_play \"%d\"",clientinpos1);
		g_hTimerExecAMR1 = CreateTimer(0.4, Timer_ExecAMovementReader, clientinpos1, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		ServerCommand("sm_cvar st_mr_force_file default2");
		ServerCommand("sm_cvar st_mr_play \"%d\"",clientinpos2);
		g_hTimerExecAMR2 = CreateTimer(0.4, Timer_ExecAMovementReader, clientinpos2, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	else
	{	
		#if DEBUG
		PrintToChatAll("no cumple con posicion o armas o vida o zombies lejos");
		#endif
		PrintToServer("no cumple con posicion o armas o vida o zombies lejos");		
	}
	g_hTimers[iType] = null;
}

public void OnPlayEnd(int client, const char[] name)
{	
	if (client==clientinpos1)
	{	
		delete g_hTimerExecAMR1;
	}
	if (client==clientinpos2)
	{	
		ServerCommand("sm_cvar l4d2_grenade_detonation_chance 5");
		delete g_hTimerExecAMR2;
	}
}





public void OnPlayLine(int client, const char[] name,int ticks,int buttons)
{
	
	
	//ServerCommand("sm_cvar l4d2_grenade_detonation_chance 5");
}


public Action Timer_ExecAMovementReader(Handle timer,int target)
{
	#if DEBUG
	PrintToChatAll("Timer_ExecAMovementReader target %d, clientinpos1 %d, clientinpos2 %d", target,clientinpos1,clientinpos2);
	#endif
	float DISTANCESETTING = float(18);
	float DISTANCESETTINGINFECTED = float(100);
	float targetVector[3];
	float impact1[3];	
	GetClientAbsOrigin(target, impact1);
	int infected = -1;	
	/*while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact1);
		if (distance < DISTANCESETTINGINFECTED)
		{
			#if DEBUG
			PrintToChatAll("Infectado: Parar ejecucion de:%d",target);
			#endif
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;		
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);
		}
	}		*/
	if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
	{
		#if DEBUG
		PrintToChatAll("Timer condiciones de vivo target %d",target);
		#endif	
		GetClientAbsOrigin(target, targetVector);
		float fHealth = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
		ConVar g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
		fHealth -= (GetGameTime() - GetEntPropFloat(target, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
		if( fHealth < 0.0 )
			fHealth = 0.0;										
		if ((GetClientHealth(target)+RoundFloat(fHealth))>=40)
		{					
			int anim;	
			anim=clientAnim[target];
			bool validAnimation = false;
			int validAnims[330];
			validAnims[1]=10;
			validAnims[2]=11;
			validAnims[3]=14;
			validAnims[4]=85;
			validAnims[5]=97;
			validAnims[6]=109;
			validAnims[7]=110;
			validAnims[8]=131;
			validAnims[9]=132;
			validAnims[10]=133;
			validAnims[11]=312;
			validAnims[12]=313;
			validAnims[13]=314;
			validAnims[14]=315;
			validAnims[15]=316;
			validAnims[16]=317;
			validAnims[17]=318;
			validAnims[18]=319;
			validAnims[19]=320;
			validAnims[20]=321;
			validAnims[21]=322;
			validAnims[22]=323;
			validAnims[23]=325;
			validAnims[24]=326;
			validAnims[25]=332;
			validAnims[26]=334;
			validAnims[27]=335;
			validAnims[28]=338;
			validAnims[29]=339;
			validAnims[30]=340;
			validAnims[31]=341;
			validAnims[32]=342;
			validAnims[33]=343;
			validAnims[34]=344;
			validAnims[35]=345;
			validAnims[36]=346;
			validAnims[37]=347;
			validAnims[38]=348;
			validAnims[39]=349;
			validAnims[40]=350;
			validAnims[41]=351;
			validAnims[42]=352;
			validAnims[43]=353;
			validAnims[44]=354;
			validAnims[45]=355;
			validAnims[46]=356;
			validAnims[47]=357;
			validAnims[48]=358;
			validAnims[49]=359;
			validAnims[50]=360;
			validAnims[51]=361;
			validAnims[52]=362;
			validAnims[53]=363;
			validAnims[54]=364;
			validAnims[55]=365;
			validAnims[56]=366;
			validAnims[57]=367;
			validAnims[58]=368;
			validAnims[59]=369;
			validAnims[60]=370;
			validAnims[61]=371;
			validAnims[62]=372;
			validAnims[63]=373;
			validAnims[64]=374;
			validAnims[65]=375;
			validAnims[66]=376;
			validAnims[67]=377;
			validAnims[68]=378;
			validAnims[69]=512;
			validAnims[70]=513;
			validAnims[71]=514;
			validAnims[72]=515;
			validAnims[73]=516;
			validAnims[74]=517;
			validAnims[75]=518;
			validAnims[76]=519;
			validAnims[77]=520;
			validAnims[78]=942;
			validAnims[79]=946;
			validAnims[80]=947;
			validAnims[81]=948;
			validAnims[82]=949;
			validAnims[83]=950;
			validAnims[84]=951;
			validAnims[85]=952;
			validAnims[86]=953;
			validAnims[87]=954;
			validAnims[88]=955;
			validAnims[89]=956;
			validAnims[90]=957;
			validAnims[91]=958;
			validAnims[92]=959;
			validAnims[93]=960;
			validAnims[94]=961;
			validAnims[95]=962;
			validAnims[96]=963;
			validAnims[97]=964;
			validAnims[98]=965;
			validAnims[99]=966;
			validAnims[100]=967;
			validAnims[101]=968;
			validAnims[102]=969;
			validAnims[103]=970;
			validAnims[104]=971;
			validAnims[105]=972;
			validAnims[106]=973;
			validAnims[107]=974;
			validAnims[108]=976;
			validAnims[109]=977;
			validAnims[110]=978;
			validAnims[111]=979;
			validAnims[112]=980;
			validAnims[113]=983;
			validAnims[114]=984;
			validAnims[115]=985;
			validAnims[116]=986;
			validAnims[117]=987;
			validAnims[118]=988;
			validAnims[119]=991;
			validAnims[120]=992;
			validAnims[121]=993;
			validAnims[122]=994;
			validAnims[123]=997;
			validAnims[124]=998;
			validAnims[125]=999;
			validAnims[126]=1000;
			validAnims[127]=1001;
			validAnims[128]=1002;
			validAnims[129]=1004;
			validAnims[130]=1005;
			validAnims[131]=1006;
			validAnims[132]=1009;
			validAnims[133]=1010;
			validAnims[134]=1011;
			validAnims[135]=1013;
			validAnims[136]=1014;
			validAnims[137]=1015;
			validAnims[138]=1016;
			validAnims[139]=1017;
			validAnims[140]=1020;
			validAnims[141]=1021;
			validAnims[142]=1023;
			validAnims[143]=1024;
			validAnims[144]=1025;
			validAnims[145]=1026;
			validAnims[146]=1027;
			validAnims[147]=1030;
			validAnims[148]=1031;
			validAnims[149]=1032;
			validAnims[150]=1033;
			validAnims[151]=1034;
			validAnims[152]=1037;
			validAnims[153]=1038;
			validAnims[154]=1039;
			validAnims[155]=1040;
			validAnims[156]=1041;
			validAnims[157]=1045;
			validAnims[158]=1046;
			validAnims[159]=1047;
			validAnims[160]=1048;
			validAnims[161]=1049;
			validAnims[162]=1050;
			validAnims[163]=1051;
			validAnims[164]=1053;
			validAnims[165]=1054;
			validAnims[166]=1055;
			validAnims[167]=1058;
			validAnims[168]=1059;
			validAnims[169]=1060;
			validAnims[170]=1061;
			validAnims[171]=1062;
			validAnims[172]=1063;
			validAnims[173]=1067;
			validAnims[174]=1068;
			validAnims[175]=1069;
			validAnims[176]=1070;
			validAnims[177]=1071;
			validAnims[178]=1072;
			validAnims[179]=1073;
			validAnims[180]=1074;
			validAnims[181]=1075;
			validAnims[182]=1076;
			validAnims[183]=1080;
			validAnims[184]=1081;
			validAnims[185]=1082;
			validAnims[186]=1083;
			validAnims[187]=1084;
			validAnims[188]=1085;
			validAnims[189]=1086;
			validAnims[190]=1087;
			validAnims[191]=1088;
			validAnims[192]=1089;
			validAnims[193]=1090;
			validAnims[194]=1091;
			validAnims[195]=1092;
			validAnims[196]=1094;
			validAnims[197]=1095;
			validAnims[198]=1096;
			validAnims[199]=1098;
			validAnims[200]=1099;
			validAnims[201]=1100;
			validAnims[202]=1101;
			validAnims[203]=1102;
			validAnims[204]=1104;
			validAnims[205]=1105;
			validAnims[206]=1106;
			validAnims[207]=1108;
			validAnims[208]=1109;
			validAnims[209]=1110;
			validAnims[210]=1111;
			validAnims[211]=1112;
			validAnims[212]=1114;
			validAnims[213]=1115;
			validAnims[214]=1116;
			validAnims[215]=1117;
			validAnims[216]=1118;
			validAnims[217]=1121;
			validAnims[218]=1122;
			validAnims[219]=1123;
			validAnims[220]=1124;
			validAnims[221]=1125;
			validAnims[222]=1126;
			validAnims[223]=1127;
			validAnims[224]=1128;
			validAnims[225]=1129;
			validAnims[226]=1130;
			validAnims[227]=1131;
			validAnims[228]=1132;
			validAnims[229]=1133;
			validAnims[230]=1134;
			validAnims[231]=1135;
			validAnims[232]=1136;
			validAnims[233]=1137;
			validAnims[234]=1139;
			validAnims[235]=1140;
			validAnims[236]=1142;
			validAnims[237]=1144;
			validAnims[238]=1145;
			validAnims[239]=1146;
			validAnims[240]=1147;
			validAnims[241]=1148;
			validAnims[242]=1149;
			validAnims[243]=1150;
			validAnims[244]=1151;
			validAnims[245]=1152;
			validAnims[246]=1153;
			validAnims[247]=1154;
			validAnims[248]=1155;
			validAnims[249]=1156;
			validAnims[250]=1157;
			validAnims[251]=1158;
			validAnims[252]=1159;
			validAnims[253]=1161;
			validAnims[254]=1162;
			validAnims[255]=1164;
			validAnims[256]=1166;
			validAnims[257]=1167;
			validAnims[258]=1168;
			validAnims[259]=1169;
			validAnims[260]=1170;
			validAnims[261]=1171;
			validAnims[262]=1172;
			validAnims[263]=1173;
			validAnims[264]=1174;
			validAnims[265]=1175;
			validAnims[266]=1176;
			validAnims[267]=1177;
			validAnims[268]=1178;
			validAnims[269]=1179;
			validAnims[270]=1180;
			validAnims[271]=1181;
			validAnims[272]=1182;
			validAnims[273]=1183;
			validAnims[274]=1184;
			validAnims[275]=1185;
			validAnims[276]=1187;
			validAnims[277]=1188;
			validAnims[278]=1190;
			validAnims[279]=1192;
			validAnims[280]=1193;
			validAnims[281]=1194;
			validAnims[282]=1195;
			validAnims[283]=1196;
			validAnims[284]=1197;
			validAnims[285]=1198;
			validAnims[286]=1199;
			validAnims[287]=1200;
			validAnims[288]=1201;
			validAnims[289]=1202;
			validAnims[290]=1203;
			validAnims[291]=1204;
			validAnims[292]=1205;
			validAnims[293]=1206;
			validAnims[294]=1207;
			validAnims[295]=1209;
			validAnims[296]=1210;
			validAnims[297]=1212;
			validAnims[298]=1214;
			validAnims[299]=1215;
			validAnims[300]=1216;
			validAnims[301]=1217;
			validAnims[302]=1218;
			validAnims[303]=1219;
			validAnims[304]=1220;
			validAnims[305]=1221;
			validAnims[306]=1222;
			validAnims[307]=1223;
			validAnims[308]=1225;
			validAnims[309]=1227;
			validAnims[310]=1228;
			validAnims[311]=1229;
			validAnims[312]=1230;
			validAnims[313]=1231;
			validAnims[314]=1232;
			validAnims[315]=1233;
			validAnims[316]=1234;
			validAnims[317]=1235;
			validAnims[318]=1236;
			validAnims[319]=1237;
			validAnims[320]=1238;
			validAnims[321]=1239;
			validAnims[322]=1241;
			validAnims[323]=1242;
			validAnims[324]=1244;
			validAnims[325]=1246;
			validAnims[326]=1247;
			validAnims[327]=1248;
			validAnims[328]=1249;
			validAnims[329]=693;
			
			for (int validation = 1; validation <= 329; validation++)
			{
				if (anim==validAnims[validation])
				{
					validAnimation=true;
				}				
			}		
			
			/*
			bool validAnimation = true;
			int invalidAnims[1939];
			invalidAnims[1]=10;
			invalidAnims[2]=12;			
			for (int validation = 1; validation <= 1939; validation++)
			{
				if (anim==invalidAnims[validation])
				{
					validAnimation=false;
				}				
			}	
			*/
			
			if (!validAnimation)
			{
				ServerCommand("st_mr_stop %d",target);
				#if DEBUG
				PrintToChatAll("Anim: Parar ejecucion de:%d",target);
				#endif			
				if (target==clientinpos1)
					delete g_hTimerExecAMR1;
				if (target==clientinpos2)
					delete g_hTimerExecAMR2;		
				ServerCommand("st_mr_stop %d",clientinpos1);
				ServerCommand("st_mr_stop %d",clientinpos2);		
			}			
			
			//if ((anim != 515)||(anim != 520)||!((anim >= 973)&&(anim <= 982))||!((anim >= 987)&&(anim <= 1008)))
			/*if ((anim != 972)||(anim != 974)||!((anim >= 10)&&(anim <= 11))||(anim != 14)||(anim != 85)||(anim != 97)||!((anim >= 109)&&(anim <= 110))||!((anim >= 131)&&(anim <= 133))||!((anim >= 312)&&(anim <= 323))||!((anim >= 325)&&(anim <= 326))||(anim != 332)||!((anim >= 334)&&(anim <= 335))||!((anim >= 338)&&(anim <= 350))||!((anim >= 351)&&(anim <= 378))||!((anim >= 512)&&(anim <= 520))||(anim != 520)||(anim != 942)||!((anim >= 946)&&(anim <= 974))||((anim >= 976)&&(anim <= 980))||!((anim >= 983)&&(anim <= 989))||!((anim >= 991)&&(anim <= 994))||!((anim >= 997)&&(anim <= 1002))||!((anim >= 1004)&&(anim <= 1006))||!((anim >= 1009)&&(anim <= 1011))||!((anim >= 1013)&&(anim <= 1017))||!((anim >= 1020)&&(anim <= 1021))||!((anim >= 1023)&&(anim <= 1027))||!((anim >= 1030)&&(anim <= 1034))||!((anim >= 1037)&&(anim <= 1041))||!((anim >= 1045)&&(anim <= 1051))||!((anim >= 1053)&&(anim <= 1055))||!((anim >= 1058)&&(anim <= 1063))||!((anim >= 1067)&&(anim <= 1076))||!((anim >= 1080)&&(anim <= 1092))||!((anim >= 1094)&&(anim <= 1096))||!((anim >= 1098)&&(anim <= 1102))||!((anim >= 1104)&&(anim <= 1106))||!((anim >= 1108)&&(anim <= 1112))||!((anim >= 1114)&&(anim <= 1118))||!((anim >= 1121)&&(anim <= 1137))||!((anim >= 1139)&&(anim <= 1140))||(anim != 1142)||!((anim >= 1144)&&(anim <= 1159))||!((anim >= 1161)&&(anim <= 1162))||(anim != 1164)||!((anim >= 1166)&&(anim <= 1185))||!((anim >= 1187)&&(anim <= 1188))||(anim != 1190)||!((anim >= 1192)&&(anim <= 1207))||!((anim >= 1209)&&(anim <= 1210))||(anim != 1212)||!((anim >= 1214)&&(anim <= 1223))||(anim != 1225)||!((anim >= 1227)&&(anim <= 1239))||!((anim >= 1241)&&(anim <= 1242))||(anim != 1244)||!((anim >= 1246)&&(anim <= 1249)))
			{
				ServerCommand("st_mr_stop %d",target);
				#if DEBUG
				PrintToChatAll("Anim: Parar ejecucion de:%d",target);
				#endif			
				if (target==clientinpos1)
					delete g_hTimerExecAMR1;
				if (target==clientinpos2)
					delete g_hTimerExecAMR2;		
				ServerCommand("st_mr_stop %d",clientinpos1);
				ServerCommand("st_mr_stop %d",clientinpos2);	
			}
			*/
		}
		else
		{
			#if DEBUG
			PrintToChatAll("Vida> Parar ejecucion de:%d",target);
			#endif		
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;	
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);		
		}
	}
	else
	{
			#if DEBUG
			PrintToChatAll("Client> Parar ejecucion de:%d",target);
			#endif		
			ServerCommand("st_mr_stop %d",target);
			if (target==clientinpos1)
				delete g_hTimerExecAMR1;
			if (target==clientinpos2)
				delete g_hTimerExecAMR2;	
			ServerCommand("st_mr_stop %d",clientinpos1);
			ServerCommand("st_mr_stop %d",clientinpos2);		
	}	
	
	
}

bool isCorrectPositionsandHaveCorrectWeapons()
{
	#if DEBUG
	PrintToChatAll("isCorrectPositionsandHaveCorrectWeapons");
	#endif					
	float DISTANCESETTING = float(18);
	float DISTANCESETTINGINFECTED = float(100);
    float targetVector[3];
	float impact1[3];
    impact1[0] = -2894.811;
    impact1[1] = 3132.176;
    impact1[2] = 6.732;
	float impact2[3];
	impact2[0] = -3125.485;
    impact2[1] = 3138.832;
    impact2[2] = 10.905;
	clientinpos1=0;
	clientinpos2=0;
	//1ra posicion	
	int infected = -1;	
	bool infectedinarea=false;
	/*
	while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact1);
		if (distance < DISTANCESETTINGINFECTED)
		{
			infectedinarea=true;
			#if DEBUG
			PrintToChatAll("infectedinarea 1");
			#endif		
			break;		
		}
	}	
	
	while( (infected = FindEntityByClassname(infected, "infected")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(infected, Prop_Data, "m_vecOrigin", targetVector);
		float distance = GetVectorDistance(targetVector, impact2);
		if (distance < DISTANCESETTINGINFECTED)
		{
			infectedinarea=true;
			#if DEBUG
			PrintToChatAll("infectedinarea 2");
			#endif
			break;	
		}
	}	
	*/
	if (!infectedinarea)
	{	
		#if DEBUG
		PrintToChatAll("no hay infectados");
		#endif					
		for (int target=1;target<=MaxClients;target++)
		{
				
			if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
			{
				#if DEBUG
				PrintToChatAll("condiciones de vivo 1");
				#endif	
				
				
				
				GetClientAbsOrigin(target, targetVector);
				float distance = GetVectorDistance(targetVector, impact1);
				if (distance < DISTANCESETTING)
				{
					#if DEBUG
					PrintToChatAll("Distancia Correcta %d",target);
					#endif
					static char sClass[25];
					int iWeapon = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
					if( iWeapon != -1 )
					{
						GetEdictClassname(iWeapon, sClass, sizeof(sClass));
						PrintToServer("Weapon si esta %d",iWeapon);
						if( strcmp(sClass[7], "grenade_launcher") == 0 )
						{
							#if DEBUG
							PrintToChatAll("Clase es grenade_launcher %s",sClass);
							#endif
							int iAmmoinClip = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
							if( iAmmoinClip > 0 )
							{
								#if DEBUG
								PrintToChatAll("Si tiene balas %d",iAmmoinClip);
								#endif
								/*
								int test;
								test=L4D2_OnStagger(clientinpos1,clientinpos2);
								if (test) PrintToChatAll("L4D2_OnStagger(target) test if %d",clientinpos1);
									else PrintToChatAll("L4D2_OnStagger(target) test else %d",clientinpos1);
								PrintToChatAll("L4D2_OnStagger(target) test %d",clientinpos1);		
								*/								
								//if (!g_bStagger[clientinpos1])
								//{		
							
								int anim;	
								anim=clientAnim[target];
								bool validAnimation = false;
								int validAnims[330];
								validAnims[1]=10;
								validAnims[2]=11;
								validAnims[3]=14;
								validAnims[4]=85;
								validAnims[5]=97;
								validAnims[6]=109;
								validAnims[7]=110;
								validAnims[8]=131;
								validAnims[9]=132;
								validAnims[10]=133;
								validAnims[11]=312;
								validAnims[12]=313;
								validAnims[13]=314;
								validAnims[14]=315;
								validAnims[15]=316;
								validAnims[16]=317;
								validAnims[17]=318;
								validAnims[18]=319;
								validAnims[19]=320;
								validAnims[20]=321;
								validAnims[21]=322;
								validAnims[22]=323;
								validAnims[23]=325;
								validAnims[24]=326;
								validAnims[25]=332;
								validAnims[26]=334;
								validAnims[27]=335;
								validAnims[28]=338;
								validAnims[29]=339;
								validAnims[30]=340;
								validAnims[31]=341;
								validAnims[32]=342;
								validAnims[33]=343;
								validAnims[34]=344;
								validAnims[35]=345;
								validAnims[36]=346;
								validAnims[37]=347;
								validAnims[38]=348;
								validAnims[39]=349;
								validAnims[40]=350;
								validAnims[41]=351;
								validAnims[42]=352;
								validAnims[43]=353;
								validAnims[44]=354;
								validAnims[45]=355;
								validAnims[46]=356;
								validAnims[47]=357;
								validAnims[48]=358;
								validAnims[49]=359;
								validAnims[50]=360;
								validAnims[51]=361;
								validAnims[52]=362;
								validAnims[53]=363;
								validAnims[54]=364;
								validAnims[55]=365;
								validAnims[56]=366;
								validAnims[57]=367;
								validAnims[58]=368;
								validAnims[59]=369;
								validAnims[60]=370;
								validAnims[61]=371;
								validAnims[62]=372;
								validAnims[63]=373;
								validAnims[64]=374;
								validAnims[65]=375;
								validAnims[66]=376;
								validAnims[67]=377;
								validAnims[68]=378;
								validAnims[69]=512;
								validAnims[70]=513;
								validAnims[71]=514;
								validAnims[72]=515;
								validAnims[73]=516;
								validAnims[74]=517;
								validAnims[75]=518;
								validAnims[76]=519;
								validAnims[77]=520;
								validAnims[78]=942;
								validAnims[79]=946;
								validAnims[80]=947;
								validAnims[81]=948;
								validAnims[82]=949;
								validAnims[83]=950;
								validAnims[84]=951;
								validAnims[85]=952;
								validAnims[86]=953;
								validAnims[87]=954;
								validAnims[88]=955;
								validAnims[89]=956;
								validAnims[90]=957;
								validAnims[91]=958;
								validAnims[92]=959;
								validAnims[93]=960;
								validAnims[94]=961;
								validAnims[95]=962;
								validAnims[96]=963;
								validAnims[97]=964;
								validAnims[98]=965;
								validAnims[99]=966;
								validAnims[100]=967;
								validAnims[101]=968;
								validAnims[102]=969;
								validAnims[103]=970;
								validAnims[104]=971;
								validAnims[105]=972;
								validAnims[106]=973;
								validAnims[107]=974;
								validAnims[108]=976;
								validAnims[109]=977;
								validAnims[110]=978;
								validAnims[111]=979;
								validAnims[112]=980;
								validAnims[113]=983;
								validAnims[114]=984;
								validAnims[115]=985;
								validAnims[116]=986;
								validAnims[117]=987;
								validAnims[118]=988;
								validAnims[119]=991;
								validAnims[120]=992;
								validAnims[121]=993;
								validAnims[122]=994;
								validAnims[123]=997;
								validAnims[124]=998;
								validAnims[125]=999;
								validAnims[126]=1000;
								validAnims[127]=1001;
								validAnims[128]=1002;
								validAnims[129]=1004;
								validAnims[130]=1005;
								validAnims[131]=1006;
								validAnims[132]=1009;
								validAnims[133]=1010;
								validAnims[134]=1011;
								validAnims[135]=1013;
								validAnims[136]=1014;
								validAnims[137]=1015;
								validAnims[138]=1016;
								validAnims[139]=1017;
								validAnims[140]=1020;
								validAnims[141]=1021;
								validAnims[142]=1023;
								validAnims[143]=1024;
								validAnims[144]=1025;
								validAnims[145]=1026;
								validAnims[146]=1027;
								validAnims[147]=1030;
								validAnims[148]=1031;
								validAnims[149]=1032;
								validAnims[150]=1033;
								validAnims[151]=1034;
								validAnims[152]=1037;
								validAnims[153]=1038;
								validAnims[154]=1039;
								validAnims[155]=1040;
								validAnims[156]=1041;
								validAnims[157]=1045;
								validAnims[158]=1046;
								validAnims[159]=1047;
								validAnims[160]=1048;
								validAnims[161]=1049;
								validAnims[162]=1050;
								validAnims[163]=1051;
								validAnims[164]=1053;
								validAnims[165]=1054;
								validAnims[166]=1055;
								validAnims[167]=1058;
								validAnims[168]=1059;
								validAnims[169]=1060;
								validAnims[170]=1061;
								validAnims[171]=1062;
								validAnims[172]=1063;
								validAnims[173]=1067;
								validAnims[174]=1068;
								validAnims[175]=1069;
								validAnims[176]=1070;
								validAnims[177]=1071;
								validAnims[178]=1072;
								validAnims[179]=1073;
								validAnims[180]=1074;
								validAnims[181]=1075;
								validAnims[182]=1076;
								validAnims[183]=1080;
								validAnims[184]=1081;
								validAnims[185]=1082;
								validAnims[186]=1083;
								validAnims[187]=1084;
								validAnims[188]=1085;
								validAnims[189]=1086;
								validAnims[190]=1087;
								validAnims[191]=1088;
								validAnims[192]=1089;
								validAnims[193]=1090;
								validAnims[194]=1091;
								validAnims[195]=1092;
								validAnims[196]=1094;
								validAnims[197]=1095;
								validAnims[198]=1096;
								validAnims[199]=1098;
								validAnims[200]=1099;
								validAnims[201]=1100;
								validAnims[202]=1101;
								validAnims[203]=1102;
								validAnims[204]=1104;
								validAnims[205]=1105;
								validAnims[206]=1106;
								validAnims[207]=1108;
								validAnims[208]=1109;
								validAnims[209]=1110;
								validAnims[210]=1111;
								validAnims[211]=1112;
								validAnims[212]=1114;
								validAnims[213]=1115;
								validAnims[214]=1116;
								validAnims[215]=1117;
								validAnims[216]=1118;
								validAnims[217]=1121;
								validAnims[218]=1122;
								validAnims[219]=1123;
								validAnims[220]=1124;
								validAnims[221]=1125;
								validAnims[222]=1126;
								validAnims[223]=1127;
								validAnims[224]=1128;
								validAnims[225]=1129;
								validAnims[226]=1130;
								validAnims[227]=1131;
								validAnims[228]=1132;
								validAnims[229]=1133;
								validAnims[230]=1134;
								validAnims[231]=1135;
								validAnims[232]=1136;
								validAnims[233]=1137;
								validAnims[234]=1139;
								validAnims[235]=1140;
								validAnims[236]=1142;
								validAnims[237]=1144;
								validAnims[238]=1145;
								validAnims[239]=1146;
								validAnims[240]=1147;
								validAnims[241]=1148;
								validAnims[242]=1149;
								validAnims[243]=1150;
								validAnims[244]=1151;
								validAnims[245]=1152;
								validAnims[246]=1153;
								validAnims[247]=1154;
								validAnims[248]=1155;
								validAnims[249]=1156;
								validAnims[250]=1157;
								validAnims[251]=1158;
								validAnims[252]=1159;
								validAnims[253]=1161;
								validAnims[254]=1162;
								validAnims[255]=1164;
								validAnims[256]=1166;
								validAnims[257]=1167;
								validAnims[258]=1168;
								validAnims[259]=1169;
								validAnims[260]=1170;
								validAnims[261]=1171;
								validAnims[262]=1172;
								validAnims[263]=1173;
								validAnims[264]=1174;
								validAnims[265]=1175;
								validAnims[266]=1176;
								validAnims[267]=1177;
								validAnims[268]=1178;
								validAnims[269]=1179;
								validAnims[270]=1180;
								validAnims[271]=1181;
								validAnims[272]=1182;
								validAnims[273]=1183;
								validAnims[274]=1184;
								validAnims[275]=1185;
								validAnims[276]=1187;
								validAnims[277]=1188;
								validAnims[278]=1190;
								validAnims[279]=1192;
								validAnims[280]=1193;
								validAnims[281]=1194;
								validAnims[282]=1195;
								validAnims[283]=1196;
								validAnims[284]=1197;
								validAnims[285]=1198;
								validAnims[286]=1199;
								validAnims[287]=1200;
								validAnims[288]=1201;
								validAnims[289]=1202;
								validAnims[290]=1203;
								validAnims[291]=1204;
								validAnims[292]=1205;
								validAnims[293]=1206;
								validAnims[294]=1207;
								validAnims[295]=1209;
								validAnims[296]=1210;
								validAnims[297]=1212;
								validAnims[298]=1214;
								validAnims[299]=1215;
								validAnims[300]=1216;
								validAnims[301]=1217;
								validAnims[302]=1218;
								validAnims[303]=1219;
								validAnims[304]=1220;
								validAnims[305]=1221;
								validAnims[306]=1222;
								validAnims[307]=1223;
								validAnims[308]=1225;
								validAnims[309]=1227;
								validAnims[310]=1228;
								validAnims[311]=1229;
								validAnims[312]=1230;
								validAnims[313]=1231;
								validAnims[314]=1232;
								validAnims[315]=1233;
								validAnims[316]=1234;
								validAnims[317]=1235;
								validAnims[318]=1236;
								validAnims[319]=1237;
								validAnims[320]=1238;
								validAnims[321]=1239;
								validAnims[322]=1241;
								validAnims[323]=1242;
								validAnims[324]=1244;
								validAnims[325]=1246;
								validAnims[326]=1247;
								validAnims[327]=1248;
								validAnims[328]=1249;
								validAnims[329]=693;
								for (int validation = 1; validation <= 329; validation++)
								{
									if (anim==validAnims[validation])
									{
										validAnimation=true;
									}				
								}		
								
								/*
								bool validAnimation = true;
								int invalidAnims[1939];
								invalidAnims[1]=10;
								invalidAnims[2]=12;			
								for (int validation = 1; validation <= 1939; validation++)
								{
									if (anim==invalidAnims[validation])
									{
										validAnimation=false;
									}				
								}	
								*/
								//if ((anim != 515)||(anim != 520)||!((anim >= 973)&&(anim <= 982))||!((anim >= 987)&&(anim <= 1008)))
								//if ((anim != 972)||(anim != 974)||!((anim >= 10)&&(anim <= 11))||(anim != 14)||(anim != 85)||(anim != 97)||!((anim >= 109)&&(anim <= 110))||!((anim >= 131)&&(anim <= 133))||!((anim >= 312)&&(anim <= 323))||!((anim >= 325)&&(anim <= 326))||(anim != 332)||!((anim >= 334)&&(anim <= 335))||!((anim >= 338)&&(anim <= 350))||!((anim >= 351)&&(anim <= 378))||!((anim >= 512)&&(anim <= 520))||(anim != 520)||(anim != 942)||!((anim >= 946)&&(anim <= 974))||((anim >= 976)&&(anim <= 980))||!((anim >= 983)&&(anim <= 989))||!((anim >= 991)&&(anim <= 994))||!((anim >= 997)&&(anim <= 1002))||!((anim >= 1004)&&(anim <= 1006))||!((anim >= 1009)&&(anim <= 1011))||!((anim >= 1013)&&(anim <= 1017))||!((anim >= 1020)&&(anim <= 1021))||!((anim >= 1023)&&(anim <= 1027))||!((anim >= 1030)&&(anim <= 1034))||!((anim >= 1037)&&(anim <= 1041))||!((anim >= 1045)&&(anim <= 1051))||!((anim >= 1053)&&(anim <= 1055))||!((anim >= 1058)&&(anim <= 1063))||!((anim >= 1067)&&(anim <= 1076))||!((anim >= 1080)&&(anim <= 1092))||!((anim >= 1094)&&(anim <= 1096))||!((anim >= 1098)&&(anim <= 1102))||!((anim >= 1104)&&(anim <= 1106))||!((anim >= 1108)&&(anim <= 1112))||!((anim >= 1114)&&(anim <= 1118))||!((anim >= 1121)&&(anim <= 1137))||!((anim >= 1139)&&(anim <= 1140))||(anim != 1142)||!((anim >= 1144)&&(anim <= 1159))||!((anim >= 1161)&&(anim <= 1162))||(anim != 1164)||!((anim >= 1166)&&(anim <= 1185))||!((anim >= 1187)&&(anim <= 1188))||(anim != 1190)||!((anim >= 1192)&&(anim <= 1207))||!((anim >= 1209)&&(anim <= 1210))||(anim != 1212)||!((anim >= 1214)&&(anim <= 1223))||(anim != 1225)||!((anim >= 1227)&&(anim <= 1239))||!((anim >= 1241)&&(anim <= 1242))||(anim != 1244)||!((anim >= 1246)&&(anim <= 1249)))
								if (!validAnimation)
								{
									#if DEBUG
									PrintToChatAll("clientinpos1 Animacion INCorrecta");
									#endif	
								}
								else
								{
									#if DEBUG
									PrintToChatAll("clientinpos1 Animacion Correcta");
									#endif	
									clientinpos1=target;	
									#if DEBUG
									PrintToChatAll("clientinpos1 %d",clientinpos1);
									#endif	
								}
														
								//}
								break;
							}
						}
					}
				}
			}
		}
	}
	if (clientinpos1!=0)
	{
		for (int target=1;target<=MaxClients;target++)
		{
						
			//if (SDKCall(hIsStaggering, target))
			//	PrintToChatAll("SDKCall(hIsStaggering, target)");
				
			if (IsValidClient(target) && GetClientTeam(target) == 2 && !IsClientPinned(target) && !(GetEntProp(target, Prop_Send, "m_isIncapacitated")) )//&& !SDKCall(hIsStaggering, target))
			{
				#if DEBUG
				PrintToChatAll("condiciones de vivo 2");
				#endif	
				if(target != clientinpos1)
				{
					GetClientAbsOrigin(target, targetVector);
					float distance = GetVectorDistance(targetVector, impact2);
					if (distance < DISTANCESETTING)
					{
						#if DEBUG
						PrintToChatAll("Distancia Correcta %d",target);
						#endif
						float fHealth = GetEntPropFloat(target, Prop_Send, "m_healthBuffer");
						ConVar g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
						fHealth -= (GetGameTime() - GetEntPropFloat(target, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
						if( fHealth < 0.0 )
							fHealth = 0.0;										
						if ((GetClientHealth(target)+RoundFloat(fHealth))>=40)
						{		
							#if DEBUG
							PrintToChatAll("clientinpos2 tiene la vida necesaria.");
							#endif
							//if (!g_bStagger[clientinpos2])
							//{
							int anim;	
							anim=clientAnim[target];
							bool validAnimation = false;
							int validAnims[330];
							validAnims[1]=10;
							validAnims[2]=11;
							validAnims[3]=14;
							validAnims[4]=85;
							validAnims[5]=97;
							validAnims[6]=109;
							validAnims[7]=110;
							validAnims[8]=131;
							validAnims[9]=132;
							validAnims[10]=133;
							validAnims[11]=312;
							validAnims[12]=313;
							validAnims[13]=314;
							validAnims[14]=315;
							validAnims[15]=316;
							validAnims[16]=317;
							validAnims[17]=318;
							validAnims[18]=319;
							validAnims[19]=320;
							validAnims[20]=321;
							validAnims[21]=322;
							validAnims[22]=323;
							validAnims[23]=325;
							validAnims[24]=326;
							validAnims[25]=332;
							validAnims[26]=334;
							validAnims[27]=335;
							validAnims[28]=338;
							validAnims[29]=339;
							validAnims[30]=340;
							validAnims[31]=341;
							validAnims[32]=342;
							validAnims[33]=343;
							validAnims[34]=344;
							validAnims[35]=345;
							validAnims[36]=346;
							validAnims[37]=347;
							validAnims[38]=348;
							validAnims[39]=349;
							validAnims[40]=350;
							validAnims[41]=351;
							validAnims[42]=352;
							validAnims[43]=353;
							validAnims[44]=354;
							validAnims[45]=355;
							validAnims[46]=356;
							validAnims[47]=357;
							validAnims[48]=358;
							validAnims[49]=359;
							validAnims[50]=360;
							validAnims[51]=361;
							validAnims[52]=362;
							validAnims[53]=363;
							validAnims[54]=364;
							validAnims[55]=365;
							validAnims[56]=366;
							validAnims[57]=367;
							validAnims[58]=368;
							validAnims[59]=369;
							validAnims[60]=370;
							validAnims[61]=371;
							validAnims[62]=372;
							validAnims[63]=373;
							validAnims[64]=374;
							validAnims[65]=375;
							validAnims[66]=376;
							validAnims[67]=377;
							validAnims[68]=378;
							validAnims[69]=512;
							validAnims[70]=513;
							validAnims[71]=514;
							validAnims[72]=515;
							validAnims[73]=516;
							validAnims[74]=517;
							validAnims[75]=518;
							validAnims[76]=519;
							validAnims[77]=520;
							validAnims[78]=942;
							validAnims[79]=946;
							validAnims[80]=947;
							validAnims[81]=948;
							validAnims[82]=949;
							validAnims[83]=950;
							validAnims[84]=951;
							validAnims[85]=952;
							validAnims[86]=953;
							validAnims[87]=954;
							validAnims[88]=955;
							validAnims[89]=956;
							validAnims[90]=957;
							validAnims[91]=958;
							validAnims[92]=959;
							validAnims[93]=960;
							validAnims[94]=961;
							validAnims[95]=962;
							validAnims[96]=963;
							validAnims[97]=964;
							validAnims[98]=965;
							validAnims[99]=966;
							validAnims[100]=967;
							validAnims[101]=968;
							validAnims[102]=969;
							validAnims[103]=970;
							validAnims[104]=971;
							validAnims[105]=972;
							validAnims[106]=973;
							validAnims[107]=974;
							validAnims[108]=976;
							validAnims[109]=977;
							validAnims[110]=978;
							validAnims[111]=979;
							validAnims[112]=980;
							validAnims[113]=983;
							validAnims[114]=984;
							validAnims[115]=985;
							validAnims[116]=986;
							validAnims[117]=987;
							validAnims[118]=988;
							validAnims[119]=991;
							validAnims[120]=992;
							validAnims[121]=993;
							validAnims[122]=994;
							validAnims[123]=997;
							validAnims[124]=998;
							validAnims[125]=999;
							validAnims[126]=1000;
							validAnims[127]=1001;
							validAnims[128]=1002;
							validAnims[129]=1004;
							validAnims[130]=1005;
							validAnims[131]=1006;
							validAnims[132]=1009;
							validAnims[133]=1010;
							validAnims[134]=1011;
							validAnims[135]=1013;
							validAnims[136]=1014;
							validAnims[137]=1015;
							validAnims[138]=1016;
							validAnims[139]=1017;
							validAnims[140]=1020;
							validAnims[141]=1021;
							validAnims[142]=1023;
							validAnims[143]=1024;
							validAnims[144]=1025;
							validAnims[145]=1026;
							validAnims[146]=1027;
							validAnims[147]=1030;
							validAnims[148]=1031;
							validAnims[149]=1032;
							validAnims[150]=1033;
							validAnims[151]=1034;
							validAnims[152]=1037;
							validAnims[153]=1038;
							validAnims[154]=1039;
							validAnims[155]=1040;
							validAnims[156]=1041;
							validAnims[157]=1045;
							validAnims[158]=1046;
							validAnims[159]=1047;
							validAnims[160]=1048;
							validAnims[161]=1049;
							validAnims[162]=1050;
							validAnims[163]=1051;
							validAnims[164]=1053;
							validAnims[165]=1054;
							validAnims[166]=1055;
							validAnims[167]=1058;
							validAnims[168]=1059;
							validAnims[169]=1060;
							validAnims[170]=1061;
							validAnims[171]=1062;
							validAnims[172]=1063;
							validAnims[173]=1067;
							validAnims[174]=1068;
							validAnims[175]=1069;
							validAnims[176]=1070;
							validAnims[177]=1071;
							validAnims[178]=1072;
							validAnims[179]=1073;
							validAnims[180]=1074;
							validAnims[181]=1075;
							validAnims[182]=1076;
							validAnims[183]=1080;
							validAnims[184]=1081;
							validAnims[185]=1082;
							validAnims[186]=1083;
							validAnims[187]=1084;
							validAnims[188]=1085;
							validAnims[189]=1086;
							validAnims[190]=1087;
							validAnims[191]=1088;
							validAnims[192]=1089;
							validAnims[193]=1090;
							validAnims[194]=1091;
							validAnims[195]=1092;
							validAnims[196]=1094;
							validAnims[197]=1095;
							validAnims[198]=1096;
							validAnims[199]=1098;
							validAnims[200]=1099;
							validAnims[201]=1100;
							validAnims[202]=1101;
							validAnims[203]=1102;
							validAnims[204]=1104;
							validAnims[205]=1105;
							validAnims[206]=1106;
							validAnims[207]=1108;
							validAnims[208]=1109;
							validAnims[209]=1110;
							validAnims[210]=1111;
							validAnims[211]=1112;
							validAnims[212]=1114;
							validAnims[213]=1115;
							validAnims[214]=1116;
							validAnims[215]=1117;
							validAnims[216]=1118;
							validAnims[217]=1121;
							validAnims[218]=1122;
							validAnims[219]=1123;
							validAnims[220]=1124;
							validAnims[221]=1125;
							validAnims[222]=1126;
							validAnims[223]=1127;
							validAnims[224]=1128;
							validAnims[225]=1129;
							validAnims[226]=1130;
							validAnims[227]=1131;
							validAnims[228]=1132;
							validAnims[229]=1133;
							validAnims[230]=1134;
							validAnims[231]=1135;
							validAnims[232]=1136;
							validAnims[233]=1137;
							validAnims[234]=1139;
							validAnims[235]=1140;
							validAnims[236]=1142;
							validAnims[237]=1144;
							validAnims[238]=1145;
							validAnims[239]=1146;
							validAnims[240]=1147;
							validAnims[241]=1148;
							validAnims[242]=1149;
							validAnims[243]=1150;
							validAnims[244]=1151;
							validAnims[245]=1152;
							validAnims[246]=1153;
							validAnims[247]=1154;
							validAnims[248]=1155;
							validAnims[249]=1156;
							validAnims[250]=1157;
							validAnims[251]=1158;
							validAnims[252]=1159;
							validAnims[253]=1161;
							validAnims[254]=1162;
							validAnims[255]=1164;
							validAnims[256]=1166;
							validAnims[257]=1167;
							validAnims[258]=1168;
							validAnims[259]=1169;
							validAnims[260]=1170;
							validAnims[261]=1171;
							validAnims[262]=1172;
							validAnims[263]=1173;
							validAnims[264]=1174;
							validAnims[265]=1175;
							validAnims[266]=1176;
							validAnims[267]=1177;
							validAnims[268]=1178;
							validAnims[269]=1179;
							validAnims[270]=1180;
							validAnims[271]=1181;
							validAnims[272]=1182;
							validAnims[273]=1183;
							validAnims[274]=1184;
							validAnims[275]=1185;
							validAnims[276]=1187;
							validAnims[277]=1188;
							validAnims[278]=1190;
							validAnims[279]=1192;
							validAnims[280]=1193;
							validAnims[281]=1194;
							validAnims[282]=1195;
							validAnims[283]=1196;
							validAnims[284]=1197;
							validAnims[285]=1198;
							validAnims[286]=1199;
							validAnims[287]=1200;
							validAnims[288]=1201;
							validAnims[289]=1202;
							validAnims[290]=1203;
							validAnims[291]=1204;
							validAnims[292]=1205;
							validAnims[293]=1206;
							validAnims[294]=1207;
							validAnims[295]=1209;
							validAnims[296]=1210;
							validAnims[297]=1212;
							validAnims[298]=1214;
							validAnims[299]=1215;
							validAnims[300]=1216;
							validAnims[301]=1217;
							validAnims[302]=1218;
							validAnims[303]=1219;
							validAnims[304]=1220;
							validAnims[305]=1221;
							validAnims[306]=1222;
							validAnims[307]=1223;
							validAnims[308]=1225;
							validAnims[309]=1227;
							validAnims[310]=1228;
							validAnims[311]=1229;
							validAnims[312]=1230;
							validAnims[313]=1231;
							validAnims[314]=1232;
							validAnims[315]=1233;
							validAnims[316]=1234;
							validAnims[317]=1235;
							validAnims[318]=1236;
							validAnims[319]=1237;
							validAnims[320]=1238;
							validAnims[321]=1239;
							validAnims[322]=1241;
							validAnims[323]=1242;
							validAnims[324]=1244;
							validAnims[325]=1246;
							validAnims[326]=1247;
							validAnims[327]=1248;
							validAnims[328]=1249;
							validAnims[329]=693;
							for (int validation = 1; validation <= 329; validation++)
							{
								if (anim==validAnims[validation])
								{
									validAnimation=true;
								}				
							}		
							
							/*
							bool validAnimation = true;
							int invalidAnims[1939];
							invalidAnims[1]=10;
							invalidAnims[2]=12;			
							for (int validation = 1; validation <= 1939; validation++)
							{
								if (anim==invalidAnims[validation])
								{
									validAnimation=false;
								}				
							}	
							*/
							if (!validAnimation)
							{
								#if DEBUG
								PrintToChatAll("clientinpos2 Animacion INCorrecta");
								#endif	
							}
							else
							{
								#if DEBUG
								PrintToChatAll("clientinpos2 animacion correcta.");
								#endif
								clientinpos2=target;	
								#if DEBUG
								PrintToChatAll("clientinpos2 %d",clientinpos2);
								#endif	
							}				
							//}							
							break;
						}
					}
				}
			}
		}
	}
	if ((clientinpos1!=0) && (clientinpos2!=0))
	{
		#if DEBUG
		PrintToChatAll("Cumplio condiciones");
		#endif
		return true;
	}
	return false;
}




/**
 * Config Parser
 */
public SMCResult ReadConfig_EndSection(SMCParser smc) {}

public SMCResult ReadConfig_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!g_bSection || !key[0])
		return SMCParse_Continue;

	int iType;
	char sKeys[2][32];
	ExplodeString(key, ":", sKeys, sizeof(sKeys), sizeof(sKeys[]));
	if (!g_hTypes.GetValue(sKeys[0], iType))
		return SMCParse_Continue;

	g_hTries[iType].SetString(sKeys[1], value);
	if (iType == EVENT)
		HookEvent(sKeys[1], Event_Hook);

	return SMCParse_Continue;
}

public SMCResult ReadConfig_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	g_bSection = StrEqual(name, "*") || strncmp(g_sMap, name, strlen(name), false) == 0;
}


/**
 * Stocks
 */
void ExecClientsConfig(int iClients)
{
	if (!g_hEnabled.BoolValue)
		return;

	bool bIncludeBots = g_hIncludeBots.BoolValue;
	bool bIncludeSpec = g_hIncludeSpec.BoolValue;
	if (bIncludeBots && bIncludeSpec)
		iClients += GetClientCount();
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			bool bBot  = IsFakeClient(i);
			bool bSpec = IsClientObserver(i);
			if ((!bBot && !bSpec) ||
				(bIncludeBots && bBot) ||
				(bIncludeSpec && bSpec))
				iClients++;
		}
	}

	char sClients[4];
	IntToString(iClients, sClients, sizeof(sClients));
	ExecConfig(CLIENTS, sClients);
}

void ExecConfig(int iType, const char[] sKey)
{
	char sValue[64];
	if (!g_hTries[iType].GetString(sKey, sValue, sizeof(sValue)))
		return;

	char sValues[2][32];
	ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));

	DataPack hPack = new DataPack();
	hPack.WriteCell(iType);
	hPack.WriteString(sValues[1]);
	g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

public Action ExecConfigCmd(int client, int args)
{

	//if( client == 0 )
	//{
		//PrintToConsole(client, "[Prueba] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
	//	return Plugin_Handled;
	//}

	char sCmd[256];
	GetCmdArgString(sCmd, sizeof(sCmd));

	StripQuotes(sCmd);

	
	
	//char sValue[64];
	//if (!g_hTries[iType].GetString(sKey, sValue, sizeof(sValue)))
	//	return;

	//char sValues[2][32];
	//ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));
	int iType=EVENT;
	DataPack hPack = new DataPack();
	hPack.WriteCell(iType);
	hPack.WriteString(sCmd);
	g_hTimers[iType] = CreateTimer(0.1, Timer_ExecConfigCommand, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
	
	
	return Plugin_Handled;
}

void ParseConfig()
{
	if (!FileExists(g_sConfigFile))
		SetFailState("File Not Found: %s", g_sConfigFile);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i].Clear();

	SMCError iError = g_hConfigParser.ParseFile(g_sConfigFile);
	if (iError)
	{
		char sError[64];
		if (g_hConfigParser.GetErrorString(iError, sError, sizeof(sError)))
			LogError(sError);
		else
			LogError("Fatal parse error");
		return;
	}
}


public bool IsValidClient(int client)
{
	if (client <= 0)
		return false;
	
	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
	//	return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

public bool IsValidClientandNotBot(int client)
{
	if (client <= 0)
		return false;
	
	if (client > MaxClients)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}


//Es cliente?
public bool IsValidClientTon(int client)
{
	//Si no es BOT = false // cliente es falso	
	if (!IsFakeClient(client))
		return false;
	
	//Si no es Superviviente  = false // cliente es falso	
	if (IsFakeClient(client))//no es bot entonces es superviviente//a la inversa no es superviviente
		return false;
	
	//Si no estan Vivos = False
	if (!IsPlayerAlive(client))
		return false;

	return true;
}


bool IsClientPinned(int client)
{
	if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0
	) return true;

	if( g_bLeft4Dead2 &&
	(
		GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ||
		GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0
	)) return true;

	return false;
}



public Action verifyStagger (Event event, const char[] name, bool dontBroadcast)
{
	int id = GetClientOfUserId(event.GetInt("userid"));
	#if DEBUG
	PrintToChatAll("verifyStagger evento %s, jugador %d",name,id);
	#endif
	g_bStagger[id]=true;
	RequestFrame(Stagger,id);	
	//if( IsClientInGame(id) )
	//	AnimHookEnable(id, OnAnim, OnAnimPost);
	//ServerCommand("st_mr_stop");
}

void Stagger(int i)
{
	if (g_bStagger[i])
	{		
		g_bStagger[i]=false;
		#if DEBUG
		PrintToChatAll("Staggereado, pasar a no staggereado %d",i);
		#endif
	}
	else
	{
		g_bStagger[i]=true;
		#if DEBUG
		PrintToChatAll("No Staggereado, pasar a staggereado %d",i);
		#endif
	}
}

public Action Timer_DetectAnim(Handle timer,int target)
{
	if (IsValidClient(target) && GetClientTeam(target) == 2)//&& !SDKCall(hIsStaggering, target))
	{
		#if DEBUG
		PrintToChatAll("Anim cliente %d clientAnim %d",target,clientAnim[target]);
		#endif
		char animacion[MAX_NAME_LENGTH];
		IntToString(clientAnim[target],animacion,sizeof(animacion));
		RenameClient(target,animacion);
		
	}
}

public Action RenameClient(int client, char rename[MAX_NAME_LENGTH])
{	
	SetClientName(client, rename);
	PrintToChatAll("Cambiar nombre");
	return Plugin_Handled;
}




// Uses "Activity" numbers, which means 1 animation number is the same for all Survivors.	
Action OnAnim(int client, int &anim)
{
	//#if DEBUG
	//PrintToChatAll("OnAnim client %d, anim %d",client,anim);
	//#endif	
	//if (clientinpos2==client)
	//{		
	clientAnim[client]=anim;
	//}
	//if (clientinpos1==client)
	//{	
	//}
	//return Plugin_Continue;
}

// Uses "m_nSequence" animation numbers, which are different for each model.
Action OnAnimPost(int client, int &anim)
{
	/*
	if( g_bCrawling )
	{
		static char model[40];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		switch( model[29] )
		{
			// case 'c': { Format(model, sizeof(model), "coach");		anim = -1; }
			case 'b': { Format(model, sizeof(model), "gambler");	anim = 631; }
			case 'h': { Format(model, sizeof(model), "mechanic");	anim = 636; }
			case 'd': { Format(model, sizeof(model), "producer");	anim = 639; }
			case 'v': { Format(model, sizeof(model), "NamVet");		anim = 539; }
			case 'e': { Format(model, sizeof(model), "Biker");		anim = 542; }
			case 'a': { Format(model, sizeof(model), "Manager");	anim = 539; }
			case 'n': { Format(model, sizeof(model), "TeenGirl");	anim = 529; }
		}
		return Plugin_Changed;
	}
	// */

	return Plugin_Continue;
}