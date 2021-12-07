/*******************************************************************************

  SM Parachute

  Version: 2.5
  Author: SWAT_88

  1.0 	First version, should work on basically any mod
  1.1	Linear fallspeed added.
  1.2	Key assignment amended
  1.3	Added +use Button support. No keybinding required!
		Fixed some bugs in linear Flight mode:
		You dont stay hanging on the wall.
		You don't bounce when you touch the ground.
		You dont have Gravity 0.1 when you jump holding the E button.
  1.4	Fixed a	serious bug: 
		Maxplayers are now correctly counted.
  1.5	Added new features:
		Information, welcome and status messages in Chat, Panel or BottomCenterText!
		Buy Parachute and Sell Parachute added ! (CS ONLY)
		Translations added !
		Works on basically any mod !
  1.6	Model Added!
  1.7	Fixed another bug in linear Flight mode.
		Linear Flight mode should be bugfree now!
		Added Cvar for model display.
  1.7b	Fixed a small bug for checking the model.
		Added a better check for Parachute ending.
  1.7c	Fixed a stupid bug in HandleSay.
  1.8	Fixed a bug in OnPlayerDisconnect.
		Changed /bp /sp to !bp !sp
		Added new features:
			Realistic velocity-decrease.
			More detail on model textures.
			A new parachute.
  1.9	Added a new button: Space.
		Added automatic button change for TF2.
  2.0	Fixed some bugs:
			in RoundMsg
			in Chat Commands
  2.5   Fixed this error: "Can't create physics object for model/parachute/parachute_carbon.mdl".
   
  Description:
  
	If cost = 0 then Everybody have a parachute.
	To use your parachute press and hold your E(+use)/Space(+jump) button while falling.
	If you are running a TF2 server the button will automatic change to Space.
	I checked whether cstrike is running or not, so dont be afraid of crashing the plugin in another Mod, It's safe!!!
	Sidenote:
	To change the model you have to edit the global variables for the names. Afterwards recompile sm_parachute.sp. Here is a tutorial.
	To change the texture you have to recompile the smd and change its content. Here is the Model source.
	
  Commands:
  
	Press E(+use) to slow down your fall.
	No more binding Keys!
	Write !bp or !buy_parachute in Chat to buy a parachute (Only if cost > 0) !
	Write !sp or !sell_parachute in Chat to sell your parachute (Only if cost > 0) !

  Cvars:

	sm_parachute_enabled 	"1"		- 0: disables the plugin - 1: enables the plugin

	sm_parachute_fallspeed "100"	- speed of the fall when you use the parachute
	
	sm_parachute_linear 	"1"		- 0: disables linear fallspeed - 1: enables it
	
	sm_parachute_msgtype 	"1"		- 0: disables Information - 1: Chat - 2: Panel - 3: BottomCenter
	
	sm_parachute_cost 		"0"		- cost of the parachute (CS ONLY) (If cost = 0 then free for everyone)

	sm_parachute_payback 	"75"	- how many percent of the parachute cost you get when you sell your parachute (ie. 75% of 1000 = 750$)
	
	sm_parachute_welcome	"1"		- 0: disables Welcome Message - 1: enables it
	
	sm_parachute_roundmsg	"1"		- 0: disables Round Message - 1: enables it
	
	sm_parachute_model		"1"		- 0: dont use the model - 1: display the Model
	
	sm_parachute_decrease	"50"	- 0: dont use Realistic velocity-decrease - x: sets the velocity-decrease.
	
	sm_parachute_button		"1"		- 1: uses button +USE for parachute usage. - 2: uses button +JUMP.
	
  Supported Languages:
  
	en	English
	de	German
	
  If you write a Translation post it in this thread.

  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	Install the translation file to addons\sourcemod\translations.
	(Re)Load Plugin or change Map.
	
  TO DO:
  
	Smooth model movement.(I will need expert help for this)
	Animations.(I will not code it, it's too complicate, but any other expert can code it. It's Open Source)
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
  
	Greyscale
	Pinkfairie
	bl4nk
	theY4Kman
	Knagg0
	KRoT@L
	JTP10181
	
  HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PARACHUTE_VERSION 	"2.5"

//Parachute Model
#define PARACHUTE_MODEL		"parachute_carbon"

//Parachute Textures
#define PARACHUTE_PACK		"pack_carbon"
#define PARACHUTE_TEXTURE	"parachute_carbon"

new g_iVelocity = -1;
new g_iMoney = -1;
new g_maxplayers = -1;

new String:g_game[30];
new String:path_model[256];
new String:path_pack[256];
new String:path_texture[256];

new Handle:g_fallspeed = INVALID_HANDLE;
new Handle:g_enabled = INVALID_HANDLE;
new Handle:g_linear = INVALID_HANDLE;
new Handle:g_msgtype = INVALID_HANDLE;
new Handle:g_cost = INVALID_HANDLE;
new Handle:g_payback = INVALID_HANDLE;
new Handle:g_welcome = INVALID_HANDLE;
new Handle:g_roundmsg = INVALID_HANDLE;
new Handle:g_version = INVALID_HANDLE;
new Handle:g_model = INVALID_HANDLE;
new Handle:g_decrease = INVALID_HANDLE;
new Handle:g_button = INVALID_HANDLE;

new x;
new cl_flags;
new cl_buttons;
new Float:speed[3];
new bool:isfallspeed;

new USE_BUTTON;
new String:ButtonText[265];

new bool:inUse[MAXPLAYERS+1];
new bool:hasPara[MAXPLAYERS+1];
new bool:hasModel[MAXPLAYERS+1];
new Parachute_Ent[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM Parachute",
	author = "SWAT_88",
	description = "To use your parachute press and hold your E(+use) button while falling.",
	version = PARACHUTE_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations ("sm_parachute.phrases");

	g_enabled = CreateConVar("sm_parachute_enabled","1");
	g_fallspeed = CreateConVar("sm_parachute_fallspeed","100");
	g_linear = CreateConVar("sm_parachute_linear","1");
	g_msgtype = CreateConVar("sm_parachute_msgtype","1");
	g_cost = CreateConVar("sm_parachute_cost","0");
	g_payback = CreateConVar("sm_parachute_payback","75");
	g_welcome = CreateConVar("sm_parachute_welcome","1");
	g_roundmsg = CreateConVar("sm_parachute_roundmsg","1");
	g_version = CreateConVar("sm_parachute_version", PARACHUTE_VERSION,	"SM Parachute Version", FCVAR_NOTIFY);
	g_model = CreateConVar("sm_parachute_model","1");
	g_decrease = CreateConVar("sm_parachute_decrease","50");
	g_button = CreateConVar("sm_parachute_button","1");
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	g_iMoney = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_maxplayers = GetMaxClients();
	SetConVarString(g_version, PARACHUTE_VERSION);
	
	InitModel();
	InitGameMode();
	
	RegConsoleCmd("say",HandleSay,"",FCVAR_GAMEDLL);
	RegConsoleCmd("say_team",HandleSay,"",FCVAR_GAMEDLL);
	HookEvent("player_death",PlayerDeath);
	HookEvent("player_spawn",PlayerSpawn);
	HookConVarChange(g_enabled, CvarChange_Enabled);
	HookConVarChange(g_linear, CvarChange_Linear);
	HookConVarChange(g_cost, CvarChange_Cost);
	HookConVarChange(g_model, CvarChange_Model);
	HookConVarChange(g_button, CvarChange_Button);
}

public OnPluginEnd(){
	CloseHandle(g_fallspeed);
	CloseHandle(g_enabled);
	CloseHandle(g_linear);
	CloseHandle(g_msgtype);
	CloseHandle(g_cost);
	CloseHandle(g_payback);
	CloseHandle(g_welcome);
	CloseHandle(g_roundmsg);
	CloseHandle(g_version);
	CloseHandle(g_model);
	CloseHandle(g_decrease);
}

public InitModel(){
	Format(path_model,255,"models/parachute/%s",PARACHUTE_MODEL);
	Format(path_pack,255,"materials/models/parachute/%s",PARACHUTE_PACK);
	Format(path_texture,255,"materials/models/parachute/%s",PARACHUTE_TEXTURE);
}

public InitGameMode(){
	GetGameFolderName(g_game, 29);
	if(StrEqual(g_game,"tf",false)){
		SetConVarInt(g_button,2);
		SetButton(2);
	}
	else{
		SetButton(1);
	}
}

public OnMapStart(){
	new String:path[256];
	
	strcopy(path,255,path_model);
	StrCat(path,255,".mdl")
	PrecacheModel(path,true);

	strcopy(path,255,path_model);
	StrCat(path,255,".dx80.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path,255,".dx90.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path,255,".mdl")
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path,255,".sw.vtx")
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_model);
	StrCat(path,255,".vvd")
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path,255,".xbox.vtx")
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_pack);
	StrCat(path,255,".vmt")
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_pack);
	StrCat(path,255,".vtf")
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_texture);
	StrCat(path,255,".vmt")
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_texture);
	StrCat(path,255,".vtf")
	AddFileToDownloadsTable(path);
}

public OnEventShutdown()
{
	UnhookEvent("player_death",PlayerDeath);
	UnhookEvent("player_spawn",PlayerSpawn);
}

public OnClientPutInServer(client)
{
	inUse[client] = false;
	hasPara[client] = false;
	hasModel[client] = false;
	g_maxplayers = GetMaxClients();
	CreateTimer (20.0, WelcomeMsg, client);
}

public OnClientDisconnect(client){
	g_maxplayers = GetMaxClients();
	CloseParachute(client);
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(g_cost) == 0){
		CreateTimer (1.0, RoundMsg, client);
	}
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	hasPara[client] = false;
	EndPara(client);
	return Plugin_Continue;
}

public Action:RoundMsg(Handle:timer, any:client){
	if(GetConVarInt(g_roundmsg) == 1){
		if(IsClientConnected (client) && IsClientInGame(client))
			PrintMsg(client,"Have Got Free Parachute");
	}
	return Plugin_Continue;
}

public StartPara(client,bool:open)
{
	decl Float:velocity[3];
	decl Float:fallspeed;
	if (g_iVelocity == -1) return;
	if((GetConVarInt(g_enabled)== 1 && hasPara[client]) || (GetConVarInt(g_enabled) == 1 && GetConVarInt(g_cost) == 0)){
		fallspeed = GetConVarFloat(g_fallspeed)*(-1.0);
		GetEntDataVector(client, g_iVelocity, velocity);
		if(velocity[2] >= fallspeed){
			isfallspeed = true;
		}
		if(velocity[2] < 0.0) {
			if(isfallspeed && GetConVarInt(g_linear) == 0){
			}
			else if((isfallspeed && GetConVarInt(g_linear) == 1) || GetConVarFloat(g_decrease) == 0.0){
				velocity[2] = fallspeed;
			}
			else{
				velocity[2] = velocity[2] + GetConVarFloat(g_decrease);
			}
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			SetEntDataVector(client, g_iVelocity, velocity);
			SetEntityGravity(client,0.1);
			if(open) OpenParachute(client);
		}
	}
}

public EndPara(client)
{
	if(GetConVarInt(g_enabled)== 1 ){
		SetEntityGravity(client,1.0);
		inUse[client]=false;
		CloseParachute(client);
	}
}

public OpenParachute(client){
	decl String:path[256];
	strcopy(path,255,path_model);
	StrCat(path,255,".mdl")
	
	if(GetConVarInt(g_model) == 1){
		Parachute_Ent[client] = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(Parachute_Ent[client],"model",path);
		SetEntityMoveType(Parachute_Ent[client], MOVETYPE_NOCLIP);
		DispatchSpawn(Parachute_Ent[client]);
		
		hasModel[client]=true;
		TeleportParachute(client);
	}
}

public TeleportParachute(client){
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client])){
		decl Float:Client_Origin[3];
		decl Float:Client_Angles[3];
		decl Float:Parachute_Angles[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client,Client_Origin);
		GetClientAbsAngles(client,Client_Angles);
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(Parachute_Ent[client], Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

public CloseParachute(client){
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client])){
		RemoveEdict(Parachute_Ent[client]);
		hasModel[client]=false;
	}
}

public Check(client){
	if(GetConVarInt(g_enabled)== 1 ){
		GetEntDataVector(client,g_iVelocity,speed);
		cl_flags = GetEntityFlags(client);
		if(speed[2] >= 0 || (cl_flags & FL_ONGROUND)) EndPara(client);
	}
}

public OnGameFrame()
{
	if(GetConVarInt(g_enabled) == 0) return;
	for (x = 1; x <= g_maxplayers; x++)
	{
		if (IsClientInGame(x) && IsPlayerAlive(x))
		{
			cl_buttons = GetClientButtons(x);
			if (cl_buttons & USE_BUTTON)
			{
				if (!inUse[x])
				{
					inUse[x] = true;
					isfallspeed = false;
					StartPara(x,true);
				}
				StartPara(x,false);
				TeleportParachute(x);
			}
			else
			{
				if (inUse[x])
				{
					inUse[x] = false;
					EndPara(x);
				}
			}
			Check(x);
		}
	}
}

stock GetNextSpaceCount(String:text[],CurIndex){
    new Count=0;
    new len = strlen(text);
    for(new i=CurIndex;i<len;i++){
        if(text[i] == ' ') return Count;
        else Count++;
    }
    return Count;
}

stock SendHintText(client, String:text[], any:...){
    new String:message[192];

    VFormat(message,191,text, 2);
    new len = strlen(message);
    if(len > 30){
        new LastAdded=0;
        
        for(new i=0;i<len;i++){
            if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34)){
                message[i] = '\n';
                LastAdded = 0;
            }
            else LastAdded++;
        }
    }
    new Handle:HintMessage = StartMessageOne("HintText",client);
    BfWriteByte(HintMessage,-1);
    BfWriteString(HintMessage,message);
    EndMessage();
}

public PrintMsg(client,String:msg[]){
	new String:translation[256];
	if(GetConVarInt(g_enabled) == 0) return;
	Format(translation, 255, "%T", msg, LANG_SERVER, ButtonText);
	if(GetConVarInt(g_msgtype) == 1){		
		PrintToChat(client,"\x01\x04[SM Parachute]\x01 %s", translation);
	}
	else if(GetConVarInt(g_msgtype) == 2) {
		new Handle:panel = CreatePanel();
		DrawPanelText(panel,translation);
		SendPanelToClient(panel,client,PanelHandle,5);
	}
	else if(GetConVarInt(g_msgtype) == 3){
		SendHintText(client,translation);
	}
}

public PanelHandle(Handle:menu, MenuAction:action, param1, param2){
}

public BuyParachute(client){
	new money;
	new cost;
	if (g_iMoney == -1) return;
	if (hasPara[client] == false){
		money = GetEntData(client,g_iMoney);
		cost = GetConVarInt(g_cost);
		if (cost == 0){
			PrintMsg(client,"Have Free Parachute");
		}
		else{
			if((money - cost)<0){
				PrintMsg(client,"No Money");
			}
			else{
				hasPara[client] = true;
				SetEntData(client,g_iMoney,money-cost);
				PrintMsg(client,"Have Bought Parachute");
			}
		}
	}
	else{
		PrintMsg(client,"Have Parachute");
	}
	
}

public SellParachute(client){
	new money;
	new Float:payback;
	new String:pb[10];
	if (g_iMoney == -1) return;
	if (hasPara[client] == true){
		money = GetEntData(client,g_iMoney);
		payback = GetConVarInt(g_cost)*(GetConVarFloat(g_payback)/100);
		if ((money + payback) > 16000){
			SetEntData(client,g_iMoney,16000);
		}
		else{
			FloatToString(payback,pb,9);
			SetEntData(client,g_iMoney,money+StringToInt(pb));
		}
		hasPara[client] = false;
		PrintMsg(client,"Sold Parachute");
	}
	else{
		if (GetConVarInt(g_cost)==0){
			PrintMsg(client,"Sell Free Parachute");
		}
		else{
			PrintMsg(client,"No Parachute");
		}
	}
}

public Action:HandleSay(client, args){
	new String:line[30];
	if(GetConVarInt(g_enabled) == 0) return Plugin_Continue;
	if (args > 0){
		GetCmdArg(1,line,sizeof(line));
		if (strcmp(g_game,"cstrike",false)==0){
			if (StrEqual(line, "!bp", false) || StrEqual(line, "!buy_parachute", false)) BuyParachute(client);
			else if(StrEqual(line, "!sp", false) || StrEqual(line, "!sell_parachute", false)) SellParachute(client);
		}
		else{
			SetConVarInt(g_cost,0);
			if (StrEqual(line, "!bp", false) || StrEqual(line, "!buy_parachute", false)) PrintMsg(client,"Have Free Parachute");
			else if(StrEqual(line, "!sp", false) || StrEqual(line, "!sell_parachute", false)) PrintMsg(client,"Sell Free Parachute");
		}
	}
	return Plugin_Continue;
}


public Action:WelcomeMsg (Handle:timer, any:client)
{
	if(GetConVarInt(g_enabled) == 0) return Plugin_Continue;

	if (GetConVarInt (g_welcome) == 1 && IsClientConnected (client) && IsClientInGame (client))
	{
		PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Welcome", LANG_SERVER);
		if (GetConVarInt(g_cost)==0){
			PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Parachute For Everyone", LANG_SERVER);
		}
		else{
			PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Buy Help", LANG_SERVER);
			PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Sell Help", LANG_SERVER);
		}
	}
	return Plugin_Continue;
}


public CvarChange_Enabled(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if (StringToInt(newvalue) == 0){
		for (new client = 1; client <= g_maxplayers; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client)){
				if (hasPara[client]){
					SetEntityGravity(client,1.0);
					SetEntityMoveType(client,MOVETYPE_WALK);
					SellParachuteOff(client,GetConVarInt(g_cost));
				}
				PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Disabled", LANG_SERVER);
			}
		}
	}
	else{
		for (new client = 1; client <= g_maxplayers; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client)){
				PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Enabled", LANG_SERVER);
				if (GetConVarInt(g_cost)==0){
					PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Parachute For Everyone", LANG_SERVER);
				}
				else{
					PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Buy Help", LANG_SERVER);
					PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Sell Help", LANG_SERVER);
				}
			}
		}
	}
}

public CvarChange_Linear(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if (StringToInt(newvalue) == 0){
		for (new client = 1; client <= g_maxplayers; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client) && hasPara[client]){
				SetEntityMoveType(client,MOVETYPE_WALK);
			}
		}
	}
}

public CvarChange_Cost(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if (StringToInt(newvalue) == 0){
		for (new client = 1; client <= g_maxplayers; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client)){
				if (hasPara[client]) SellParachuteOff(client,StringToInt(oldvalue));
				PrintToChat(client,"\x01\x04[SM Parachute]\x01 %T", "Parachute For Everyone", LANG_SERVER);
			}
		}
	}
	else{
		if (strcmp(g_game,"cstrike",false) != 0) SetConVarInt(g_cost,0);
	}
}

public CvarChange_Button(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if (StringToInt(newvalue) == 1){
		SetButton(1);
	}
	else if(StringToInt(newvalue) == 2){
		SetButton(2);
	}
}

public CvarChange_Model(Handle:cvar, const String:oldvalue[], const String:newvalue[]){
	if (StringToInt(newvalue) == 0){
		for (new client = 1; client <= g_maxplayers; client++){
			if (IsClientInGame(client) && IsPlayerAlive(client)){
				CloseParachute(client);
			}
		}
	}
}

public SellParachuteOff(client,cost){
	new money;
	new Float:payback;
	new String:pb[10];
	if (g_iMoney == -1) return;
	if (hasPara[client] == true){
		money = GetEntData(client,g_iMoney);
		payback = cost*(GetConVarFloat(g_payback)/100);
		if ((money + payback) > 16000){
			SetEntData(client,g_iMoney,16000);
		}
		else{
			FloatToString(payback,pb,9);
			SetEntData(client,g_iMoney,money+StringToInt(pb));
		}
		hasPara[client] = false;
	}
}

public SetButton(button){
	if (button == 1){
		USE_BUTTON = IN_USE;
		ButtonText = "E";
	}
	else if(button == 2){
		USE_BUTTON = IN_JUMP;
		ButtonText = "Space";
	}
}
